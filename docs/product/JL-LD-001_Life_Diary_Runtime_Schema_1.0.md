# JL-LD-001 Life Diary Runtime Schema 1.0

Status: CANDIDATE FOR AUTHOR AND DEVELOPER REVIEW

## 1. Scope

This contract defines the minimum executable data model for the JESUSLIFE ONE Life Diary MVP. It separates private raw reflection from structured growth signals and preserves the Q1–Q7 spiritual movement.

## 2. Aggregate

`LifeDiaryEntry` is the aggregate root.

| Field | Type | Rule |
|---|---|---|
| `entry_id` | UUID/string | Stable and never reused |
| `owner_user_id` | opaque ID | Required; no email or name embedded |
| `season_number` | integer | Starts at 1 |
| `session_number` | integer | 1–50 inside a season |
| `entry_date` | local date | Asia/Seoul for Korean default |
| `status` | enum | `DRAFT`, `COMPLETED`, `REOPENED`, `DELETED` |
| `schema_version` | string | Starts at `1.0.0` |
| `canonical_version` | string | Canonical projection version |
| `created_at`, `updated_at` | timestamp | Required |
| `completed_at` | timestamp/null | Set only after completion |

## 3. Question payloads

- Q1 stores private narrative first and old-person category selections second.
- Q2 stores the exact representative confession, acknowledgement time, explanation version, and selected categories to which it was applied. The user may copy or confess it with understanding; the system must not imply magical efficacy from typing alone.
- If Q1 has no category selection, Q2 may present all seven categories for reflection as an authored runtime rule.
- Q3 stores `INNER`, `COMMUNITY`, or both, narrative evidence, confession/declaration, and fruit selections. If no concrete experience is found, the runtime may guide reflection through all nine fruit terms.
- Q4 stores compassion/reflection and whether a return to Q1/Q2 occurred. A return appends a revision event; it must not silently erase previous text.
- Q5 stores communion type and narrative. Supported initial types: `ASKED`, `WHISPER`, `SCRIPTURE_INSIGHT`, `NONE_WITH_THANKS`.
- Q6 stores at least three gratitude items at final completion. Each item supports `who`, `what`, and `why`.
- Q7 stores one or more concrete actions.

## 4. Navigation and persistence

- Questions 1–7 remain freely navigable before final completion.
- Drafts auto-save locally and can also be explicitly saved.
- App exit with unsaved changes prompts the user to save.
- Completion runs validation and creates an immutable completion event.
- Later edits use `REOPENED` plus revision history; no destructive overwrite of completed evidence.
- Season advances after session 50. Session numbering restarts at 1.

## 5. Privacy boundary

| Data class | Examples | Default visibility |
|---|---|---|
| `PRIVATE_RAW` | Q1–Q7 narrative text | Owner only |
| `PRIVATE_STRUCTURED` | Selected old-person/fruit terms | Owner only |
| `DERIVED_PERSONAL` | Personal trend | Owner only unless separately consented |
| `SHARED_SUMMARY` | User-selected testimony or group summary | Explicit recipient/scope/expiry |
| `AGGREGATED` | Minimum-threshold anonymous community metric | Policy-controlled |

Church membership, coach role, or pastor role never grants raw diary access. Product consent is not equivalent to diary-sharing consent.

## 6. Growth-engine interface

The MVP exports only consented structured events. Raw narrative is excluded by default.

Initial structured signals:

- old-person category occurrence;
- Spirit-fruit experience;
- reduced judgment/resistance;
- gratitude completion;
- action completion when later confirmed;
- session continuity.

The engine must return evidence references and uncertainty. It must not diagnose mental illness, declare spiritual rank, or treat frequency as moral worth.

## 7. Offline-first storage

- SQLite is the initial runtime store.
- Database migrations are sequential and reversible where practical.
- Sensitive backups require encryption and explicit user action.
- A future server sync adapter must preserve local IDs, revision history, consent, and deletion state.

## 8. Validation invariants

1. Season and session are positive; session is at most 50.
2. Completed entries contain Q1–Q7 payloads required by the current policy.
3. Q2 confession text equals the canonical Korean value for Korean locale.
4. Old-person and fruit selections reference canonical IDs.
5. Raw text never appears in analytics/export events without explicit grant.
6. Every reopen, share, export, and deletion produces an audit event without storing the raw diary in the audit log.

