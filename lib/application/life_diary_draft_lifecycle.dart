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
}
