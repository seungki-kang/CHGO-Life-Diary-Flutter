import '../domain/life_diary_models.dart';

abstract interface class LifeDiaryRepository {
  Future<void> save(LifeDiaryEntry entry);

  /// Commits the completed entry and removes its UI draft atomically.
  Future<void> completeDraft(LifeDiaryEntry entry);

  Future<LifeDiaryEntry?> findById(String entryId);

  Future<List<LifeDiaryEntry>> findByOwner(String ownerUserId);

  Future<void> tombstone(String entryId);

  Future<void> restore(String entryId);

  Future<void> close();
}
