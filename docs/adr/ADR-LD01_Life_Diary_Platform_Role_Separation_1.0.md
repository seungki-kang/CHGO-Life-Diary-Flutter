# ADR-LD01 Life Diary and CHGO Platform Role Separation 1.0

Status: **PROPOSED** — LD-D1, LD-D5, LD-D6, LD-D7 decided; LD-D2 to LD-D4 open  
Date: 2026-10-17  
Companion: [`ADR-LD01_Life_Diary_Producer_Responsibilities_1.0.md`](ADR-LD01_Life_Diary_Producer_Responsibilities_1.0.md)  
Related: `CHGO_Cross-Platform_Modular_Monorepo_ADR_1.0.md` (superseded, see 4.4), Review 1.0 of Audit 2.4 (decision LD-P1, in `JesusLife-Church-OS/docs/governance/`), `docs/product/JL-LD-002_Flutter_MVP_Integration_Contract_1.0.md`  
Canonical/Governance meaning changes: none

> **Moved here on 2026-10-17.** This ADR was written in `CHGO-Platform`. That repository was renamed `JesusLife-Church-OS` and now holds Church OS only, so the ADR lives with Life Diary. Its text is unchanged except for this note, these header lines, Section 4.4 and the 2.1 repository row. In it, "CHGO Platform" or "Platform" means the **CHGO engine**, which is being rebuilt in the new `CHGO` repository. Sections 4.1 to 4.3 describe `CHGO-Platform` as it was at commit `b64dd9a`.

## 1. Context

### 1.1 Intended roles

- **Life Diary** is developed independently and integrated by API. It owns the diary: the raw text, the selections, drafts, editing, deletion, and restore.
- **CHGO Platform** is an engine that receives Life Diary data only within the limits of personal-information law. It does not evaluate or score anyone. It gives a community enough visibility to understand how its members are growing.

### 1.2 Current state (2026-10-17)

- **The repositories are already separate.** Life Diary lives in `CHGO-Life-Diary-Flutter`. The Monorepo ADR says a product may move to its own repository only after its API/event contract, identity contract, data ownership, migration path and rollback plan are stable. None of these is defined yet for Life Diary.
- **Platform defines the application's internal structure.** It holds the Life Diary runtime schema, the Flutter mapping, the application's SQLite structure, the Flutter backlog, and the application acceptance tests (Section 4). JL-LD-002 assigns "schema versions, privacy classes, growth-event boundaries" to CHGO. This contradicts LD-P1, under which the application is the source of truth for Life Diary.
- **Platform designs a raw-diary vault.** `/me/vaults/{vaultId}/entries` and `db/migrations/chgo/PDV-003_*.sql` store encrypted diary content on the Platform side. This overlaps with an independent Life Diary that keeps its own raw text.
- **The application has no integration code yet.**
  - `LifeDiaryAnalyticsExporter.growthEvent` exists but is never called, and the application has no network client.
  - The event it builds contains `entry_id`, the exact `entry_date`, and `old_person_ids`. Sent as is, these would allow re-identification and would carry likely-sensitive data.
- **Platform already has the parts this design needs.**
  - Outbox guards against raw text
  - Privacy-gateway decision and pseudonym-link tables
  - Aggregate-only pastor endpoints with minimum-cohort suppression (`/pastor/pulse`, `/pastor/community-growth`)
  - A schema assertion that forbids spiritual score columns
  - Monorepo ADR rule 7: raw diary is never a general CHGO growth record

### 1.3 Legal constraints

This section is not legal advice. Counsel specializing in personal information must review the design before release.

- **Sensitive information.** Personal Information Protection Act Art. 23 classifies "thought and belief" (사상·신념) as sensitive information. Processing requires consent separate from any other consent, or a legal basis. Old-person categories, fruits of the Spirit, and communion records arise from religious practice and are likely to be treated as sensitive information.
- **Pseudonymized information.** Art. 28-2 allows pseudonymized information to be processed without consent for statistics, scientific research, or public-interest archiving. Removing direct identifiers is not sufficient by itself: re-identification risk from combinations of attributes, such as dates and affiliation, must also be reduced. Whether this exemption covers sensitive information is unconfirmed.

The design therefore assumes all three safeguards: **separate consent, pseudonymization, and community-level aggregation.**

## 2. Decision (proposed)

### 2.1 Roles

| | Life Diary (application, and the end-to-end encrypted backup service of LD-D1) | CHGO Platform (engine) |
| --- | --- | --- |
| Owns | Raw text, selections, drafts, revisions, consent records | No raw text. Consented, pseudonymized signals and the aggregates built from them |
| Does | Write, edit, delete, restore; manage consent; build export signals | Accept signals, aggregate per community, suppress small cohorts, show community trends |
| Never does | Send anything without consent | Per-person views, rankings or scores; requests for raw text |
| Repository | `CHGO-Life-Diary-Flutter` | `CHGO` (new; formerly part of `CHGO-Platform`) |

### 2.2 Data boundary

1. **Raw text stays on the Life Diary side.** No API, event, or Platform table carries diary narrative.
2. **A privacy gateway sits on the boundary (option B in Section 3).**
   - The application sends signals to the gateway.
   - The gateway checks consent, pseudonymizes, and suppresses cohorts below the minimum size (LD-D3).
   - Only community-level aggregates leave the gateway for the engine. Individual-level signals do not reach the engine.
3. **Sensitive items are reduced at the source (option C principles).**
   - Old-person categories, fruits, and communion types leave the device only as counts, or as community distributions, according to LD-D2.
   - Time is coarsened to the ISO week. Entry IDs and exact dates are not sent.
4. **Consent withdrawal stops future signals.** How already-aggregated data is handled is part of LD-D2.

### 2.3 Contract ownership

| Contract | Owner | Verified by |
| --- | --- | --- |
| Life Diary export signal | Life Diary | Life Diary tests, plus a Platform consumer-contract test that the signal is accepted |
| Platform ingest acceptance rules (consent, purpose, suppression) | Platform | Platform tests |
| Canonical IDs and wording (old persons, fruits, questions) | JesusLife Canonical governance (register in Platform) | Life Diary pins a register version |

This supersedes, for Life Diary, the JL-LD-002 statement that CHGO owns "schema versions, privacy classes, growth-event boundaries". Canonical IDs remain under Canonical governance.

### 2.4 Guardrails ("visible, not evaluated")

- **Aggregates only.** No endpoint returns an individual's Life Diary signals to a pastor, coach, or administrator.
- **No scores.** No score, rank, level, or comparison between people or between communities. The existing forbidden-column assertion stays.
- **Small cohorts suppressed.** Cohorts below the minimum size (LD-D3) are suppressed, including secondary suppression of differences.
- **Membership is not consent.** Membership in a community never implies consent to send signals.

## 3. Options considered

### 3.1 Integration

| Option | Platform receives | Privacy risk | Insight | Effort |
| --- | --- | --- | --- | --- |
| A. Individual signals | Pseudonymous person ID and per-session selections | Medium: individual-level, sensitive | Detailed | Low |
| **B. Gateway aggregation** (proposed) | Community aggregates only, after consent check, pseudonymization and suppression | Low | Community trends | Medium |
| C. On-device aggregation / local differential privacy | Pre-aggregated or noised values | Very low | Broad tendencies | High |
| D. Personal vault with access grants | Raw content the user grants to a named person | High within the grant | Individual coaching | High |

- **A** is rejected: Platform would accumulate per-person religious records, which conflicts with "not evaluated" and with Art. 23.
- **C** is adopted as a principle for sensitive items (Section 2.2), not as the whole design.
- **D** is out of scope for the engine. If user-initiated sharing with a coach is needed, it is designed as a separate Life Diary feature.

### 3.2 Contract ownership

| Option | Description | Status |
| --- | --- | --- |
| **1. Life Diary owns the export contract** | Platform runs consumer-contract tests | Proposed; consistent with LD-P1 |
| 2. Separate contract repository | Shared repository for API contracts only | Revisit when more producers exist |
| 3. Platform owns the contract | Life Diary conforms to Platform | Rejected; contradicts LD-P1 |

## 4. Repository relocation (executed 2026-10-17)

Executed under LD-D6 from commit `f44e3a1`. Each moved file is replaced here by `<file>.MOVED.md`, which records its new path, last SHA-256 here, and reason. Every notice was checked against the Life Diary copy. Only the schema and mapping differ, because they were aligned to the application under LD-P1.

### 4.1 Moved

| Platform path | Life Diary path |
| --- | --- |
| `ontology/schemas/life-diary-runtime-schema-v1.json` | `contracts/life-diary/` (aligned: Q6 `why` may be empty) |
| `ontology/projections/life-diary-flutter-mapping-v1.json` | `contracts/life-diary/` (aligned: storage authority is the application) |
| `db/migrations/life_diary/V001__life_diary_sqlite_foundation.sql` | `contracts/life-diary/legacy/` (history only) |
| `docs/product/JL-LD-001`, `JL-LD-002`, `JL-LD-003` | `docs/product/` |
| `tests/acceptance/life-diary/LIFE_DIARY_MVP_ACCEPTANCE_1.0.csv` | `docs/qa/` |
| `docs/privacy-security/PDV-006_*` | `docs/privacy/` |
| `docs/privacy-security/PDV-002_*`, `PDV-005_*`, `CHGO_Personal_Data_Vault_and_Life_Diary_Storage_Architecture_1.0.docx`; `docs/architecture/PDV-003_*`, `PDV-004_*`, `PDV-007_*`; `db/migrations/chgo/PDV-003_*.sql` | `docs/backup-service/platform-era/` (input only; see LD-D1) |
| `tools/validation/validate_jl_life_diary_*.py` | Replaced by `tools/contract/validate_life_diary_contract.py` |

### 4.2 Kept in Platform

- `canonical/sources/JESUSLIFE_CANONICAL_OBJECT_REGISTER_1.0.csv`: the Canonical original. Life Diary keeps a pinned copy (LD-D7).
- `docs/privacy-security/CHGO_Identity_Tenant_and_Personal_Vault_Boundary_Specification_1.0.docx`: identity and tenant boundaries are a Platform concern.

### 4.3 Remaining in Platform, pending extraction

These belong to the Life Diary backup and sharing service. They are tied to Platform gates (B-04, B-03/E5 static regression), so they stay until those gates are re-baselined:

- Vault and coach-sharing endpoints in `api/openapi/v2/CHGO_Public_and_Headless_OpenAPI_v2_Consolidated_Baseline_1.0.yaml`: 23 `/me/vaults*` operations, 2 `/coach/shared-vault-resources*` operations, 2 `/integrations/vault/*` operations. These are checked by `validate_b04_openapi.py` and the PDV-008 static validation.
- `tests/acceptance/pdv008/`, `tests/acceptance/PDV-008_*.docx`, `releases/manifests/CHGO_PDV008_*`.
- The R4 Vault part of `docs/handoff/packages/CHGO_API_R3_Auth_and_R4_Vault_Privacy_Negative_Test_Pack_1.0/` and `tests/security/CHGO_API_R3_Auth_and_R4_Vault_Privacy_Negative_Test_Pack_1.0.docx`.

Until extracted, these endpoints are **not** a Platform commitment. Their design is superseded by the end-to-end encryption requirement of LD-D1.

### 4.4 Repository split (2026-10-17)

The product owner decided to split `CHGO-Platform` by product:

| Former content | New home |
| --- | --- |
| Church OS | `JesusLife-Church-OS` (the renamed `CHGO-Platform`; history kept) |
| CHGO engine, Canonical register and governance, ontology | New `CHGO` repository, re-established by the owner from the archived originals |
| Life Diary contract, documents and this ADR | `CHGO-Life-Diary-Flutter` |

Effect on Sections 4.1 to 4.3:
- The 17 "moved" notices were removed from `JesusLife-Church-OS`. Its split record (`docs/governance/Repository_Split_Record_2026-10-17.md`) lists every removed file and where it went.
- The Canonical register (4.2) left `JesusLife-Church-OS`. Its home is the `CHGO` repository. The Life Diary pin stays at `f44e3a1` until the register is published there.
- From 4.3, the PDV-008 pack and its release manifest were removed and the E5 regression suite E5-R05 was retired. The Vault and coach endpoints and the R4 tests remain in the Church OS API baseline 1.0 because its test packs are bound to that file's hash. They are removed in Church OS API baseline 2.0.
- The Monorepo ADR was removed as superseded: each product now has its own repository and connects by API.

## 5. Decisions

### 5.1 Decided (product owner, 2026-10-17)

| ID | Decision | Consequence |
| --- | --- | --- |
| LD-D1 | **(b) Backup on a Life Diary-only server.** Owner requirement: *users must be certain that no one can see their diary unless they allow it.* | Backup is end-to-end encrypted with keys held only on the user's devices. The backup server, Life Diary operators, church staff, and CHGO Platform cannot decrypt. There is no operator recovery and no break-glass access. Option (c) is rejected. The Platform-era vault design (server-side KMS decryption, break-glass) does not meet the requirement and is kept only as input. Requirements: `CHGO-Life-Diary-Flutter/docs/backup-service/README.md` |
| LD-D5 | **Coach sharing is offered.** The user grants access, and the coach reads the shared content and coaches. | Each share names the coach, scope, purpose and expiry. Content is encrypted to the coach on the user's device and is revocable. The user sees grants and an access log. Shared content never reaches the CHGO engine. It is a Life Diary feature, not a Platform one |
| LD-D6 | **(b) Relocate**, leaving "moved" notices in Platform | Executed (Section 4) |
| LD-D7 | **(a) Life Diary keeps a pinned copy** of the Canonical register | Executed. The original stays in Platform; the Life Diary validator fails if the copy diverges from its pin |

### 5.2 Open

| ID | Question | Options | Recommendation | Owner |
| --- | --- | --- | --- | --- |
| LD-D2 | How is separate consent for sensitive information obtained and withdrawn? | (a) One consent covering all signals. (b) Per-category consent (activity counts vs. selection distributions). Withdrawal: stop future signals only, or also delete contributions not yet aggregated | (b), with withdrawal stopping future signals and deleting unaggregated contributions | Product owner + counsel |
| LD-D3 | Minimum cohort size for any published aggregate | Policy value (k) plus secondary suppression; Platform currently leaves it OPEN | Decide with counsel; record with C-02 privacy policy | Product owner + counsel |
| LD-D4 | How is an application user linked to a church community? | (a) Community join code entered by the user. (b) Invitation from the church. (c) Shared CHGO identity account. Identity contract must not merge accounts by email (Monorepo ADR rule 4) | (a) or (b) for MVP, producing a per-community pseudonym; (c) later | Product owner + Platform engineering |

## 6. Consequences

- **Monorepo ADR exception.** Life Diary is the first product admitted as a separate repository. This ADR records that exception. The Monorepo ADR's preconditions become this ADR's closure conditions (Section 7).
- **Life Diary changes.** `growthEvent` is redesigned before any transmission: no `entry_id`, week instead of date, sensitive selections only as LD-D2 allows. The Life Diary-side obligations are in the companion ADR.
- **Platform changes.** `/integrations/chgo/events` (currently Church OS events) is either extended or joined by a separate Life Diary ingest endpoint behind the privacy gateway. The pastor endpoints keep their aggregate-only design.
- **Unchanged.** Audit 2.4 Review decisions D-3 and D-4 (database roles) remain open and are unchanged.

## 7. Closure conditions

This ADR moves from PROPOSED to ACCEPTED when:

1. LD-D2 to LD-D4 are decided and recorded here. (LD-D1 and LD-D5 to LD-D7 are decided.)
2. The Life Diary export signal contract 1.0 is published in `CHGO-Life-Diary-Flutter` (API/event contract).
3. The user-to-community link from LD-D4 is specified (identity contract). Coach identity for LD-D5 depends on it.
4. The remaining items of Section 4.3 (Vault/coach endpoints, R4 tests) are removed by Church OS API baseline 2.0 (data ownership). Sections 4.1, 4.2 and 4.4 are done.
5. The migration path for existing application data and a rollback plan for the first transmission release are written.
6. Counsel review of Section 1.3 and LD-D2/LD-D3 is recorded.

This ADR establishes boundaries only. It is not runtime evidence.
