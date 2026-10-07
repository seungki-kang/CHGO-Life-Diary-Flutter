class LifeDiaryDraftLifecycle {
  bool _completedEntryIsClosing = false;

  bool get shouldPersist => !_completedEntryIsClosing;

  void markCompletedEntryClosing() {
    _completedEntryIsClosing = true;
  }

  void beginDraft() {
    _completedEntryIsClosing = false;
  }
}
