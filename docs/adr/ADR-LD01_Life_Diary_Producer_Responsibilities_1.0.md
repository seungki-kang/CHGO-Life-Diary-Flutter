# ADR-LD01 Life Diary Producer Responsibilities 1.0

Status: **PROPOSED** — depends on open decisions LD-D1 to LD-D4  
Date: 2026-10-17  
Normative companion: [`CHGO-Platform/docs/adr/ADR-LD01_Life_Diary_Platform_Role_Separation_1.0.md`](https://github.com/seungki-kang/CHGO-Platform/blob/main/docs/adr/ADR-LD01_Life_Diary_Platform_Role_Separation_1.0.md)  
Canonical/Governance meaning changes: none

The roles, data boundary, legal constraints, options, and open decisions are defined once, in the Platform ADR. This document records what the Life Diary application must do as the producer. Where the two differ, the Platform ADR governs shared decisions. LD-P1 (Life Diary follows the application) governs the application's own data.

## 1. What Life Diary owns

- Raw diary text, selections, drafts, revisions, deletion and restore (`lib/data/life_diary_database.dart` is authoritative).
- Consent records (`life_diary_consent_grant`) and the user's choice to send or not send signals.
- The **export signal contract**: the only data that may leave the application for CHGO Platform.
- Its runtime schema and storage structure. Platform copies of these move here (Platform ADR, Section 4).

Canonical IDs and wording (old persons, fruits, questions) remain under Canonical governance. The application pins a register version.

## 2. Current state (2026-10-17)

- **No transmission exists.** The application has no network client, and `LifeDiaryAnalyticsExporter.growthEvent` (`lib/application/life_diary_privacy.dart`) is not called anywhere.
- **`growthEvent` must not be sent in its current form.** It contains:
  - `entry_id` and the exact `entry_date`, which allow re-identification when combined with community membership.
  - `season_number` and `session_number`, which form a per-person progress fingerprint.
  - `old_person_ids`, `fruit_ids`, `kingdom_contexts` and `communion_type`, which arise from religious practice and are likely sensitive information under PIPA Art. 23.
- **The consent store covers a different use.** It models per-entry grants to a named recipient (`SUMMARY` / `RAW_ENTRY`). That is user-initiated sharing (Platform ADR option D), not engine signals. Signal consent needs its own record (LD-D2).
- **The user is not yet identified.** The only user is `local-device-user`. There is no link to a church community (LD-D4).

## 3. Obligations before the first transmission release

1. **Never send raw text.** No narrative, declaration, gratitude text, or action text appears in any signal or request.
2. **Separate consent.**
   - Signal sending is off by default.
   - It is enabled only through the separate consent defined by LD-D2, distinct from any other consent.
   - Withdrawal stops future signals immediately.
3. **Minimize at the source.**
   - Replace `growthEvent` with a signal built from the export signal contract.
   - The signal carries no `entry_id`, no exact date (ISO week only), and no season or session number.
   - Sensitive selections are sent only in the form LD-D2 allows.
4. **Use a per-community pseudonym.** The subject identifier comes from the LD-D4 community link and differs per community. It is never a device ID, account ID, phone number, or email.
5. **Contract tests.** The export signal contract has tests in this repository that fail if a forbidden field appears. Platform runs a consumer-contract test against the same contract.
6. **Offline first.** Writing and completing a diary never depends on the network or on Platform availability.

## 4. Export signal contract — illustrative draft (non-normative)

This sketch shows the intended shape only. Contract 1.0 is written after LD-D1 to LD-D4 are decided.

```json
{
  "contract": "life-diary-export-signal",
  "version": "0.1-draft",
  "community_pseudonym": "per-community value from LD-D4",
  "iso_week": "2026-W42",
  "canonical_register_version": "1.0",
  "completed_entries": 1,
  "questions_completed": { "q1": 1, "q2": 1, "q3": 1, "q4": 1, "q5": 1, "q6": 1, "q7": 1 },
  "sensitive_distributions": "omitted unless LD-D2 permits; then category counts only"
}
```

Forbidden in every version: `entry_id`, `entry_date`, `season_number`, `session_number`, any free text, `owner_user_id`, device or account identifiers.

## 5. Closure

This ADR moves to ACCEPTED together with the Platform ADR. Until then, the application keeps working offline and sends nothing.
