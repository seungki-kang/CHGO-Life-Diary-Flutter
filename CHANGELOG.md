# Changelog

## Unreleased — LD-FL-024

- SQLite: reverted the LD-FL-023 owner/season/session reconciliation. It turned a
  numbering collision into a silent UPDATE of another diary (a completed diary for
  another date, or a deleted, restorable one). The repository again matches only by
  entry ID, so a collision is refused instead of overwriting.
- Session numbering: deleted entries keep their session number, and Q7 re-checks the
  draft's number against stored entries at final save, moving to the next free number
  when another diary already holds it.
- Date screen: an unfinished draft whose number went stale is renumbered and kept;
  only a draft whose final save already happened is discarded.
- Draft resume: "작성 중인 생명일기" re-enables draft persistence (it stayed off after a
  completion in the same app run).
- Q3: completed entries now store the per-realm records (`q3_enjoyment_records`);
  previously the stored Q3 narrative and declaration were always empty.
- Regression tests for each of the above.

## 1.1.0+2 — 2026-10-09

- Life Diary 5: clarified the daily-communion completion action in the `both` branch.
- Life Diary 6: normalized three-or-more gratitude completion and removed implicit editing from the app-bar back action.
- Life Diary 7: blocked duplicate final-save submissions while persistence is running.
- SQLite: reconciled writes by the stable owner/season/session identity before updating revisions.
- Completion validation: validates Q5 branch data and counts only unique, complete Q6 gratitude records.
- Added regression coverage for natural-key updates and Q5/Q6 completion rules.

Canonical wording and Governance meaning are unchanged.
