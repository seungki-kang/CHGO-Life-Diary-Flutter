/// What the date screen does with the saved draft for the chosen date.
enum RestoredDraftAction {
  /// No usable draft: start an empty diary numbered with the next session.
  startFresh,

  /// Continue the draft unchanged.
  keepAsIs,

  /// Continue the draft's written content under the next session number.
  keepRenumbered,
}

class LifeDiaryDraftLifecycle {
  bool _completedEntryIsClosing = false;

  bool get shouldPersist => !_completedEntryIsClosing;

  void markCompletedEntryClosing() {
    _completedEntryIsClosing = true;
  }

  void beginDraft() {
    _completedEntryIsClosing = false;
  }

  bool matchesNextSession({
    required int draftSeason,
    required int draftSession,
    required int nextSeason,
    required int nextSession,
  }) {
    return draftSeason == nextSeason && draftSession == nextSession;
  }

  /// Decides how a restored draft is reused.
  ///
  /// Only a draft whose final save already happened ([finalCompleted]) is
  /// discarded; it is a leftover of a stored entry. An unfinished draft is never
  /// deleted just because its session number went stale (for example because a
  /// diary for another date was completed first); its written reflections are
  /// kept and it is renumbered to the next session.
  RestoredDraftAction restoredDraftAction({
    required bool restored,
    required bool finalCompleted,
    required int draftSeason,
    required int draftSession,
    required int nextSeason,
    required int nextSession,
  }) {
    if (!restored || finalCompleted) return RestoredDraftAction.startFresh;
    return matchesNextSession(
          draftSeason: draftSeason,
          draftSession: draftSession,
          nextSeason: nextSeason,
          nextSession: nextSession,
        )
        ? RestoredDraftAction.keepAsIs
        : RestoredDraftAction.keepRenumbered;
  }
}
