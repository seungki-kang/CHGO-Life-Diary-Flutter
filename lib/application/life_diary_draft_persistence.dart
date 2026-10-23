import 'dart:convert';

typedef DraftSave = Future<void> Function(
  DateTime date,
  Map<String, Object?> payload,
);

/// Serializes draft checkpoints so an older slow write cannot replace a newer
/// one. Each request owns a JSON snapshot, even while it waits in the queue.
///
/// Callers observe failures through the returned future. [settled] only waits
/// for the queue to finish; it does not claim that persistence succeeded.
class LifeDiaryDraftPersistence {
  LifeDiaryDraftPersistence({
    required DraftSave save,
    Future<void> Function(Duration)? delay,
    void Function(int attempt, Object error)? onRetry,
  }) : _save = save,
       _delay = delay ?? _defaultDelay,
       _onRetry = onRetry;

  final DraftSave _save;
  final Future<void> Function(Duration) _delay;
  final void Function(int attempt, Object error)? _onRetry;
  Future<void> _tail = Future<void>.value();

  Future<void> get settled => _tail;

  Future<void> enqueue(DateTime date, Map<String, Object?> payload) {
    final snapshot = Map<String, Object?>.from(
      jsonDecode(jsonEncode(payload)) as Map,
    );
    final write = _tail.then((_) => _saveWithRetry(date, snapshot));
    // A failed checkpoint must not prevent later checkpoints from being saved.
    _tail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  Future<void> _saveWithRetry(
    DateTime date,
    Map<String, Object?> payload,
  ) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _save(date, payload);
        return;
      } catch (error) {
        if (attempt == 3) rethrow;
        _onRetry?.call(attempt, error);
        await _delay(Duration(milliseconds: 50 * attempt));
      }
    }
  }

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
