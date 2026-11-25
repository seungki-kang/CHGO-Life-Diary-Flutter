# Life Diary State Architecture

## Source of truth

The in-memory `LifeDiarySessionDraft` is the editing source of truth until final completion. Every question writes its fields and stage to that draft before route replacement. `LifeDiaryDraftStore` persists the serialized draft as a recoverable checkpoint.

The completed `LifeDiaryEntry` is the durable source of truth after final completion. It is written through `LifeDiaryRepository` and identified by owner, season, and session. A regenerated display entry ID must not create a duplicate logical session.

## State rules

1. A text controller is transient UI state, not proof of completion.
2. A question stage describes the visible workflow position, not the answer by itself.
3. `LifeDiaryCompletionValidator` combines stage and required branch data.
4. Question navigation saves and awaits the draft write before replacing the route.
5. Editing a saved list item requires an explicit edit action; app-bar back navigation never creates or duplicates an item.
6. Final completion is single-flight: a second tap is ignored while the first save is pending.
7. Repository writes reconcile by `(owner_user_id, season_number, session_number)` and append answer revisions to the existing entry.

## Question 6 invariant

- Fewer than three unique complete gratitude items: entry state.
- Three or more unique complete gratitude items: summary/complete state.
- Additional gratitude entry is entered only through the explicit add action.
- An exact duplicate does not increase the completion count.

## Compatibility

Serialized fields remain additive and older draft stages are normalized on load. Canonical sentences, Canonical IDs, and Governance meaning are not changed by UI state migrations.
