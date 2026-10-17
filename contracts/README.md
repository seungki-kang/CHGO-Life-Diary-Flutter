# Life Diary contracts

Relocated from `CHGO-Platform` at commit `f44e3a1` on 2026-10-17 (ADR-LD01, decision LD-D6). Under LD-P1 the application is the source of truth for Life Diary, so the contract lives with the application.

| Path | What it is | Changes since relocation |
| --- | --- | --- |
| `life-diary/life-diary-runtime-schema-v1.json` | JSON schema of a stored Life Diary entry | Q6 `why` may be empty, matching the application (LD-P1, D-2) |
| `life-diary/life-diary-flutter-mapping-v1.json` | Question IDs, Q2 confession, privacy defaults, season size | 1.1.0: storage authority is `lib/data/life_diary_database.dart`; canonical register path and pin added |
| `life-diary/legacy/V001__life_diary_sqlite_foundation.sql` | Original SQLite storage contract | None. Kept for history only; the application's database code is authoritative |
| `life-diary/fixtures/app_completed_entry.json` | A completed entry in the exact shape the application stores | New |
| `canonical/JESUSLIFE_CANONICAL_OBJECT_REGISTER_1.0.csv` | Copy of the Canonical register | None. The original stays in CHGO-Platform (LD-D7) |
| `canonical/CANONICAL_PIN.json` | Source commit and SHA-256 of the copy | New |

Validate with:

```bash
pip install jsonschema
python tools/contract/validate_life_diary_contract.py
```

The validator checks:
- The Canonical copy matches its pin.
- Every Canonical ID used in `lib/` exists in the register.
- The Q2 confession is identical in the register, schema, mapping and app.
- The app-shaped entry passes the schema.
- The legacy SQL still applies.
- Acceptance cases LD-001 to LD-015 are present.

Related documents relocated in the same change:
- `docs/product/JL-LD-001`, `JL-LD-002`, `JL-LD-003`
- `docs/qa/LIFE_DIARY_MVP_ACCEPTANCE_1.0.csv`
- `docs/privacy/PDV-006`
- `docs/backup-service/platform-era/`

JL-LD-002 still says CHGO owns schema versions and growth-event boundaries. ADR-LD01 supersedes that statement.
