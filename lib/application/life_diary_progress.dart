import '../domain/life_diary_models.dart';

const lifeDiarySessionsPerSeason = 50;

class LifeDiaryProgress {
  const LifeDiaryProgress({
    required this.seasonNumber,
    required this.sessionNumber,
  });

  final int seasonNumber;
  final int sessionNumber;
  String get label => '시즌 $seasonNumber · $sessionNumber/50회';
}

int _absoluteSession(int season, int session) =>
    (season - 1) * lifeDiarySessionsPerSeason + session;

LifeDiaryProgress _fromAbsolute(int absolute) => LifeDiaryProgress(
  seasonNumber: ((absolute - 1) ~/ lifeDiarySessionsPerSeason) + 1,
  sessionNumber: ((absolute - 1) % lifeDiarySessionsPerSeason) + 1,
);

/// The next unused season/session for a new diary.
///
/// Deleted (tombstoned) entries keep their number: the row still exists, it can
/// be restored, and the storage key (owner, season, session) is unique. Reusing
/// a deleted number made a new diary collide with, or overwrite, that entry.
LifeDiaryProgress resolveLifeDiaryProgress(
  Iterable<LifeDiaryEntry> entries,
  DateTime date,
) {
  var greatestAbsoluteSession = 0;
  for (final entry in entries) {
    final absolute = _absoluteSession(entry.seasonNumber, entry.sessionNumber);
    if (absolute > greatestAbsoluteSession) greatestAbsoluteSession = absolute;
  }
  return _fromAbsolute(greatestAbsoluteSession + 1);
}

/// Session to store a draft under when it is completed.
///
/// A draft is numbered when it is started, but several drafts (one per date)
/// can be in progress at once and receive the same number. If another stored
/// entry already holds the draft's number, the draft moves to the next unused
/// number instead of colliding with or replacing that entry. Re-saving the same
/// entry (same [entryId]) keeps its number.
LifeDiaryProgress resolveCompletionSession({
  required Iterable<LifeDiaryEntry> entries,
  required String entryId,
  required int draftSeason,
  required int draftSession,
}) {
  final takenByOther = entries.any(
    (entry) =>
        entry.entryId != entryId &&
        entry.seasonNumber == draftSeason &&
        entry.sessionNumber == draftSession,
  );
  if (!takenByOther) {
    return LifeDiaryProgress(
      seasonNumber: draftSeason,
      sessionNumber: draftSession,
    );
  }
  return resolveLifeDiaryProgress(entries, DateTime.now());
}
