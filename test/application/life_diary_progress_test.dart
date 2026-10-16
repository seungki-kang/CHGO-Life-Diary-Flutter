import 'package:chgo_life_diary/application/life_diary_progress.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts season 2 after session 50', () {
    final progress = resolveLifeDiaryProgress([
      _entry(season: 1, session: 50, date: DateTime(2026, 10, 6)),
    ], DateTime(2026, 10, 7));

    expect(progress.seasonNumber, 2);
    expect(progress.sessionNumber, 1);
    expect(progress.label, '시즌 2 · 1/50회');
  });

  test('allocates the next session for another entry on the same date', () {
    final original = _entry(
      season: 3,
      session: 12,
      date: DateTime(2026, 10, 6),
    );
    final progress = resolveLifeDiaryProgress([
      original,
    ], DateTime(2026, 10, 6, 23, 59));

    expect(progress.seasonNumber, 3);
    expect(progress.sessionNumber, 13);
  });

  test('a deleted latest diary keeps its session number', () {
    // Regression: skipping deleted entries handed their number to the next
    // diary, which then collided with (or overwrote) the restorable tombstone.
    final progress = resolveLifeDiaryProgress([
      _entry(season: 1, session: 4, date: DateTime(2026, 10, 4)),
      _entry(
        season: 1,
        session: 5,
        date: DateTime(2026, 10, 5),
        status: LifeDiaryEntryStatus.deleted,
      ),
    ], DateTime(2026, 10, 16));

    expect(progress.seasonNumber, 1);
    expect(progress.sessionNumber, 6);
  });

  group('resolveCompletionSession', () {
    final stored = [
      _entry(season: 1, session: 4, date: DateTime(2026, 10, 4)),
      _entry(
        season: 1,
        session: 5,
        date: DateTime(2026, 10, 12),
        entryId: 'diary-10-12',
      ),
    ];

    test('keeps a free draft number', () {
      final session = resolveCompletionSession(
        entries: stored,
        entryId: 'diary-10-10',
        draftSeason: 1,
        draftSession: 6,
      );
      expect((session.seasonNumber, session.sessionNumber), (1, 6));
    });

    test('moves a draft whose number another diary already took', () {
      // Two drafts (10/10 and 10/12) both started as session 5; 10/12 was
      // completed first. 10/10 must become session 6, not replace 10/12.
      final session = resolveCompletionSession(
        entries: stored,
        entryId: 'diary-10-10',
        draftSeason: 1,
        draftSession: 5,
      );
      expect((session.seasonNumber, session.sessionNumber), (1, 6));
    });

    test('keeps the number when re-saving the same diary', () {
      final session = resolveCompletionSession(
        entries: stored,
        entryId: 'diary-10-12',
        draftSeason: 1,
        draftSession: 5,
      );
      expect((session.seasonNumber, session.sessionNumber), (1, 5));
    });

    test('a deleted diary still blocks its number', () {
      final session = resolveCompletionSession(
        entries: [
          _entry(
            season: 1,
            session: 5,
            date: DateTime(2026, 10, 5),
            entryId: 'deleted-5',
            status: LifeDiaryEntryStatus.deleted,
          ),
        ],
        entryId: 'new-diary',
        draftSeason: 1,
        draftSession: 5,
      );
      expect((session.seasonNumber, session.sessionNumber), (1, 6));
    });
  });
}

LifeDiaryEntry _entry({
  required int season,
  required int session,
  required DateTime date,
  String? entryId,
  LifeDiaryEntryStatus status = LifeDiaryEntryStatus.completed,
}) => LifeDiaryEntry(
  entryId: entryId ?? 'entry-$season-$session',
  ownerUserId: 'owner',
  seasonNumber: season,
  sessionNumber: session,
  entryDate: date,
  status: status,
  canonicalVersion: '1.0.0',
  questions: LifeDiaryQuestions(
    q1: Q1Payload(narrative: '', oldPersonIds: const []),
    q2: Q2Payload(explanationVersion: '1.0.0', appliedOldPersonIds: const []),
    q3: Q3Payload(contexts: const [], narrative: '', fruitIds: const []),
    q4: const Q4Payload(narrative: '', revisitedQ1Q2: false),
    q5: const Q5Payload(
      communionType: CommunionType.noneWithThanks,
      narrative: '',
    ),
    q6: Q6Payload(items: const []),
    q7: Q7Payload(actions: const []),
  ),
);
