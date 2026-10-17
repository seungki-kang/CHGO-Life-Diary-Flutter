#!/usr/bin/env python3
"""Validate the Life Diary contract against the application.

Replaces CHGO-Platform's validate_jl_life_diary_foundation.py and
validate_jl_life_diary_flutter_contract.py, which were retired when the contract
moved to this repository (ADR-LD01, decision LD-D6). Under LD-P1 the application
is the source of truth, so these checks compare the contract with the app code.

Requires: Python 3.10+, `pip install jsonschema`.
Run from the repository root: python tools/contract/validate_life_diary_contract.py
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = ROOT / "contracts/life-diary/life-diary-runtime-schema-v1.json"
MAPPING = ROOT / "contracts/life-diary/life-diary-flutter-mapping-v1.json"
FIXTURE = ROOT / "contracts/life-diary/fixtures/app_completed_entry.json"
LEGACY_SQL = ROOT / "contracts/life-diary/legacy/V001__life_diary_sqlite_foundation.sql"
REGISTER = ROOT / "contracts/canonical/JESUSLIFE_CANONICAL_OBJECT_REGISTER_1.0.csv"
PIN = ROOT / "contracts/canonical/CANONICAL_PIN.json"
ACCEPTANCE = ROOT / "docs/qa/LIFE_DIARY_MVP_ACCEPTANCE_1.0.csv"
APP_MODELS = ROOT / "lib/domain/life_diary_models.dart"
LIB = ROOT / "lib"

errors: list[str] = []
checks: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    checks.append(f"{'PASS' if ok else 'FAIL'} {name}{': ' + detail if detail and not ok else ''}")
    if not ok:
        errors.append(f"{name}: {detail}" if detail else name)


def main() -> int:
    try:
        import jsonschema
    except ImportError:
        print("jsonschema is required: pip install jsonschema", file=sys.stderr)
        return 2

    required = [SCHEMA, MAPPING, FIXTURE, LEGACY_SQL, REGISTER, PIN, ACCEPTANCE, APP_MODELS]
    missing = [str(p.relative_to(ROOT)) for p in required if not p.is_file()]
    check("required files present", not missing, ", ".join(missing))
    if missing:
        return report()

    # Canonical copy is the pinned version (decision LD-D7).
    pin = json.loads(PIN.read_text(encoding="utf-8"))
    digest = hashlib.sha256(REGISTER.read_bytes()).hexdigest()
    check("canonical copy matches pin", digest == pin.get("sha256"), f"sha256 {digest} != pin {pin.get('sha256')}")

    with REGISTER.open(encoding="utf-8-sig", newline="") as stream:
        register = {row["canonical_id"]: row for row in csv.DictReader(stream)}
    expected_ids = {"JL-LD-Q02-CONFESSION"}
    expected_ids |= {f"JL-LD-Q0{n}" for n in range(1, 8)}
    expected_ids |= {f"JL-OLD-{n:02d}" for n in range(1, 8)}
    expected_ids |= {f"JL-FRUIT-{n:02d}" for n in range(1, 10)}
    check("register has Life Diary IDs", expected_ids <= register.keys(),
          ",".join(sorted(expected_ids - register.keys())))

    # Every Canonical ID used by the app exists in the pinned register.
    app_ids: set[str] = set()
    for dart in LIB.rglob("*.dart"):
        app_ids |= set(re.findall(r"'(JL-(?:OLD|FRUIT|LD)-[A-Z0-9-]+)'", dart.read_text(encoding="utf-8")))
    check("app Canonical IDs exist in register", app_ids <= register.keys(),
          ",".join(sorted(app_ids - register.keys())))

    # Q2 confession is identical in register, schema, mapping and app.
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    mapping = json.loads(MAPPING.read_text(encoding="utf-8"))
    models = APP_MODELS.read_text(encoding="utf-8")
    app_confession = re.search(r"q2CanonicalConfessionKo\s*=\s*'([^']+)'", models)
    confessions = {
        "register": register.get("JL-LD-Q02-CONFESSION", {}).get("ko_label"),
        "schema": schema["$defs"]["q2"]["properties"]["confession"]["const"],
        "mapping": mapping.get("canonical_confession_ko"),
        "app": app_confession.group(1) if app_confession else None,
    }
    check("Q2 confession identical", len(set(confessions.values())) == 1 and None not in confessions.values(),
          json.dumps(confessions, ensure_ascii=False))

    app_schema_version = re.search(r"lifeDiarySchemaVersion\s*=\s*'([^']+)'", models)
    check("schema version matches app",
          app_schema_version is not None and schema["properties"]["schema_version"]["const"] == app_schema_version.group(1))

    # Mapping points at the application's storage (LD-P1).
    check("mapping question IDs", mapping.get("question_mapping") == {f"q{i}": f"JL-LD-Q0{i}" for i in range(1, 8)})
    check("mapping storage authority is the application",
          mapping.get("storage_authority") == "application" and (ROOT / mapping.get("storage_migration", "")).is_file(),
          str(mapping.get("storage_migration")))
    check("raw text excluded from analytics", mapping.get("analytics_excludes_raw_text_by_default") is True)
    check("season size 50", mapping.get("season_size") == 50)

    # An entry shaped exactly as the app stores it must pass the schema.
    jsonschema.Draft202012Validator.check_schema(schema)
    validator = jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker())
    fixture_errors = [f"{list(e.absolute_path)} {e.message}" for e in
                      validator.iter_errors(json.loads(FIXTURE.read_text(encoding="utf-8")))]
    check("app-shaped completed entry passes schema", not fixture_errors, "; ".join(fixture_errors[:5]))

    # Legacy storage contract still applies (kept for history; the app is authoritative).
    try:
        connection = sqlite3.connect(":memory:")
        connection.executescript(LEGACY_SQL.read_text(encoding="utf-8"))
        connection.close()
        check("legacy SQLite contract applies", True)
    except sqlite3.Error as exc:
        check("legacy SQLite contract applies", False, str(exc))

    with ACCEPTANCE.open(encoding="utf-8-sig", newline="") as stream:
        acceptance_ids = {row["test_id"] for row in csv.DictReader(stream)}
    check("acceptance LD-001..LD-015 present", {f"LD-{i:03d}" for i in range(1, 16)} <= acceptance_ids)

    return report()


def report() -> int:
    result = {"gate": "LIFE-DIARY-CONTRACT", "status": "PASS" if not errors else "FAIL",
              "checks": checks, "errors": errors}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
