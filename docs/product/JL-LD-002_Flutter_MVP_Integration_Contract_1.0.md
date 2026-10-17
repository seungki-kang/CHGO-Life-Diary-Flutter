# JL-LD-002 Flutter MVP Integration Contract 1.0

Status: IMPLEMENTATION-READY CANDIDATE

## 1. Purpose

This contract maps the JL-LD-001 runtime schema to the existing Flutter Life Diary application without changing JesusLife Canonical meaning, IDs, or wording authority.

## 2. Implementation boundary

The Flutter application owns presentation, navigation, local draft persistence, completion validation, and local export. CHGO owns Canonical IDs, schema versions, privacy classes, growth-event boundaries, and future synchronization contracts.

The first integration remains offline-first. No server, SSO, AI coach, pastor dashboard, or raw-text analytics is required for this milestone.

## 3. Flutter layers

| Layer | Initial responsibility | Required rule |
|---|---|---|
| `models` | Typed Q1-Q7 payloads and entry metadata | Preserve Canonical IDs and `schema_version` |
| `repositories` | Save/load drafts, answers, revisions, and consent | No silent destructive overwrite |
| `services` | Autosave, completion validation, season/session calculation | Business rules stay out of widgets |
| `pages/widgets` | Q1-Q7 editing and free navigation | Draft survives navigation and restart |
| `export` | User-triggered local backup | Raw text excluded from analytics events |

## 4. Required domain model mapping

`LifeDiaryEntry` maps one-to-one to `life_diary_entry`. Each question payload is encoded as JSON and stored in `life_diary_answer.payload_json` under its stable question ID.

| Question | Canonical ID | Minimum Flutter payload |
|---|---|---|
| Q1 | `JL-LD-Q01` | `narrative`, unique `old_person_ids` |
| Q2 | `JL-LD-Q02` | exact `confession`, `explanation_version`, `acknowledged_at`, `applied_old_person_ids` |
| Q3 | `JL-LD-Q03` | `contexts`, `narrative`, `declaration`, unique `fruit_ids` |
| Q4 | `JL-LD-Q04` | `narrative`, `revisited_q1_q2` |
| Q5 | `JL-LD-Q05` | `communion_type`, `narrative` |
| Q6 | `JL-LD-Q06` | `items` containing `who`, `what`, `why` |
| Q7 | `JL-LD-Q07` | one or more concrete `actions` |

## 5. State transitions

Allowed status transitions:

- new entry -> `DRAFT`;
- `DRAFT` -> `COMPLETED` after validation;
- `COMPLETED` -> `REOPENED` only by explicit user action;
- `REOPENED` -> `COMPLETED` after a new validation pass;
- any retained entry -> `DELETED` according to the deletion policy.

Every transition appends a `life_diary_revision_event`. Reopening or revisiting Q1/Q2 creates a new answer revision and preserves earlier revisions.

## 6. Autosave and exit behavior

- Debounced autosave should run after meaningful edits and before question navigation.
- Explicit save remains available.
- App lifecycle pause/exit attempts a local save.
- If the save fails or unsaved changes remain, the user receives a save/discard/cancel choice.
- A failed save must never be reported as successful.

## 7. Completion policy

Completion is blocked unless:

1. all required Q1-Q7 payload objects exist;
2. Q2 contains the exact Korean Canonical confession for Korean locale;
3. Q2 explanation version is recorded;
4. Q6 has at least three valid gratitude items;
5. Q7 has at least one non-empty action;
6. all old-person and fruit values use registered Canonical IDs.

The UI should explain missing items gently and take the user to the first incomplete question.

## 8. Q4 return rule

When Q4 identifies judgment or resistance and the user chooses to return:

1. append `REVISITED_Q1_Q2`;
2. navigate to Q1;
3. preserve the existing Q1/Q2 revisions;
4. save later changes as new revisions;
5. return to Q4 without losing its draft.

## 9. Season and session rule

The next session is calculated from the latest non-deleted completed entry. After season N session 50, the next entry is season N+1 session 1. Draft creation must not consume a session permanently; abandoned drafts remain addressable by ID.

## 10. Privacy and growth-event boundary

- Q1-Q7 narrative is `PRIVATE_RAW` and owner-only by default.
- Category selections are `PRIVATE_STRUCTURED`.
- Church membership, coach role, or pastor role grants no diary access.
- Analytics events contain Canonical IDs, timestamps, and allowed status signals only.
- Raw narrative can leave the device only through a separate explicit user grant and export/share flow.

## 11. Implementation sequence

1. Add typed domain models and JSON codecs.
2. Apply SQLite V001 and create repository adapters.
3. Connect draft save/load to the existing Q1-Q7 screens.
4. Add autosave and lifecycle protection.
5. Add completion validator and status transitions.
6. Add revision/event history for Q4 returns and reopened entries.
7. Implement season/session calculation.
8. Execute acceptance tests LD-001 through LD-015.

## 12. Definition of done

The milestone is complete only when all 15 acceptance scenarios pass on Android emulator and at least one physical Android device, app restart preserves a draft, Q4 return preserves revisions, completion validation works, and no raw narrative appears in analytics/event export fixtures.
