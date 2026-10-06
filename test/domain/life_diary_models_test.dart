import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LifeDiaryEntry buildEntry() => LifeDiaryEntry(
    entryId: 'entry-001',
    ownerUserId: 'owner-001',
    seasonNumber: 1,
    sessionNumber: 1,
    entryDate: DateTime(2026, 10, 6),
    status: LifeDiaryEntryStatus.draft,
    canonicalVersion: '1.0.0',
    questions: LifeDiaryQuestions(
      q1: Q1Payload(
        narrative: '오늘의 기록',
        oldPersonIds: const ['JL-OLD-01', 'JL-OLD-01', 'JL-OLD-02'],
      ),
      q2: Q2Payload(
        explanationVersion: '1.0.0',
        acknowledgedAt: DateTime.utc(2026, 10, 6, 10),
        appliedOldPersonIds: const ['JL-OLD-01'],
      ),
      q3: Q3Payload(
        contexts: const [KingdomContext.inner],
        narrative: '하나님 나라를 누렸습니다',
        declaration: '나는 새생명입니다',
        fruitIds: const ['JL-FRUIT-01'],
      ),
      q4: const Q4Payload(narrative: '긍휼로 바라봅니다', revisitedQ1Q2: false),
      q5: const Q5Payload(
        communionType: CommunionType.asked,
        narrative: '성령님께 여쭈었습니다',
      ),
      q6: Q6Payload(
        items: const [
          GratitudeItem(who: '가족', what: '도움', why: '사랑'),
          GratitudeItem(what: '말씀', why: '깨달음'),
          GratitudeItem(what: '오늘', why: '은혜'),
        ],
      ),
      q7: Q7Payload(actions: const ['감사 표현하기']),
    ),
  );

  test('LD-001 preserves the exact Korean Q2 Canonical confession', () {
    expect(buildEntry().questions.q2.confession, q2CanonicalConfessionKo);
    expect(
      () => Q2Payload(
        confession: '다른 문장',
        explanationVersion: '1.0.0',
        appliedOldPersonIds: const [],
      ),
      throwsFormatException,
    );
  });

  test('LD-010 stores each old-person Canonical ID once', () {
    expect(buildEntry().questions.q1.oldPersonIds, const [
      'JL-OLD-01',
      'JL-OLD-02',
    ]);
  });

  test('rejects unregistered old-person and fruit IDs', () {
    expect(
      () => Q1Payload(narrative: '', oldPersonIds: const ['OLD-01']),
      throwsFormatException,
    );
    expect(
      () => Q3Payload(
        contexts: const [],
        narrative: '',
        fruitIds: const ['FRUIT-01'],
      ),
      throwsFormatException,
    );
  });

  test('entry and all Q1-Q7 payloads round-trip through JSON', () {
    final original = buildEntry();
    final decoded = LifeDiaryEntry.fromJson(original.toJson());

    expect(decoded.toJson(), original.toJson());
    expect(decoded.schemaVersion, lifeDiarySchemaVersion);
    expect(decoded.questions.q6.items, hasLength(3));
  });

  test('enforces season and 50-session boundaries', () {
    final json = buildEntry().toJson();
    json['session_number'] = 51;
    expect(() => LifeDiaryEntry.fromJson(json), throwsFormatException);
  });
}
