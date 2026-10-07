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
}

LifeDiaryEntry _entry({
  required int season,
  required int session,
  required DateTime date,
}) => LifeDiaryEntry(
  entryId: 'entry-$season-$session',
  ownerUserId: 'owner',
  seasonNumber: season,
  sessionNumber: session,
  entryDate: date,
  status: LifeDiaryEntryStatus.completed,
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
