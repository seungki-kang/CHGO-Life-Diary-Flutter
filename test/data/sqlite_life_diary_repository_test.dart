import 'package:chgo_life_diary/data/life_diary_database.dart';
import 'package:chgo_life_diary/data/sqlite_life_diary_repository.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late SqliteLifeDiaryRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: lifeDiaryDatabaseVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => LifeDiaryDatabase.createV001(db),
      ),
    );
    repository = SqliteLifeDiaryRepository(
      database,
      clock: () => DateTime.utc(2026, 10, 6, 12),
    );
  });

  tearDown(() => repository.close());

  test('V001 creates all Life Diary tables', () async {
    final rows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    final names = rows.map((row) => row['name']).toSet();

    expect(
      names,
      containsAll(const [
        'life_diary_entry',
        'life_diary_answer',
        'life_diary_revision_event',
        'life_diary_consent_grant',
      ]),
    );
  });

  test('LD-003 saves and reloads a complete Q1-Q7 draft', () async {
    final entry = buildEntry();
    await repository.save(entry);

    final loaded = await repository.findById(entry.entryId);

    expect(loaded, isNotNull);
    expect(loaded!.toJson(), entry.toJson());
    expect(await repository.findByOwner(entry.ownerUserId), hasLength(1));
  });

  test(
    'saving a changed answer appends a revision without overwrite',
    () async {
      await repository.save(buildEntry());
      await repository.save(buildEntry(q1Narrative: '수정한 기록'));

      final revisions = await database.query(
        'life_diary_answer',
        where: 'entry_id = ? AND question_id = ?',
        whereArgs: ['entry-001', 'JL-LD-Q01'],
        orderBy: 'revision_number',
      );
      final unchangedQuestion = await database.query(
        'life_diary_answer',
        where: 'entry_id = ? AND question_id = ?',
        whereArgs: ['entry-001', 'JL-LD-Q02'],
      );

      expect(revisions.map((row) => row['revision_number']), [1, 2]);
      expect(revisions.first['payload_json'], contains('처음 기록'));
      expect(revisions.last['payload_json'], contains('수정한 기록'));
      expect(unchangedQuestion, hasLength(1));
      expect(
        (await repository.findById('entry-001'))!.questions.q1.narrative,
        '수정한 기록',
      );
    },
  );

  test('LD-015 tombstones entry and emits no raw narrative', () async {
    await repository.save(buildEntry(q1Narrative: '민감한 원문'));
    await repository.tombstone('entry-001');

    final loaded = await repository.findById('entry-001');
    final events = await database.query(
      'life_diary_revision_event',
      where: 'entry_id = ? AND event_type = ?',
      whereArgs: ['entry-001', 'DELETED'],
    );

    expect(loaded!.status, LifeDiaryEntryStatus.deleted);
    expect(events, hasLength(1));
    expect(events.single['metadata_json'], '{}');
    expect(events.single.values.join(' '), isNot(contains('민감한 원문')));
  });

  test('LD-FL-006 records reopen and recomplete state transitions', () async {
    final completed = buildEntry(status: LifeDiaryEntryStatus.completed);
    await repository.save(completed);
    await repository.save(buildEntry(status: LifeDiaryEntryStatus.reopened));
    await repository.save(
      buildEntry(
        status: LifeDiaryEntryStatus.completed,
        q1Narrative: '수정 완료한 기록',
      ),
    );

    final loaded = await repository.findById('entry-001');
    final events = await database.query(
      'life_diary_revision_event',
      where: 'entry_id = ?',
      whereArgs: ['entry-001'],
      orderBy: 'rowid',
    );

    expect(loaded!.status, LifeDiaryEntryStatus.completed);
    expect(loaded.questions.q1.narrative, '수정 완료한 기록');
    expect(
      events.map((row) => row['event_type']),
      containsAllInOrder(['CREATED', 'REOPENED', 'COMPLETED']),
    );
  });
}

LifeDiaryEntry buildEntry({
  String q1Narrative = '처음 기록',
  LifeDiaryEntryStatus status = LifeDiaryEntryStatus.draft,
}) => LifeDiaryEntry(
  entryId: 'entry-001',
  ownerUserId: 'owner-001',
  seasonNumber: 1,
  sessionNumber: 1,
  entryDate: DateTime(2026, 10, 6),
  status: status,
  canonicalVersion: '1.0.0',
  questions: LifeDiaryQuestions(
    q1: Q1Payload(narrative: q1Narrative, oldPersonIds: const ['JL-OLD-01']),
    q2: Q2Payload(
      explanationVersion: '1.0.0',
      acknowledgedAt: DateTime.utc(2026, 10, 6, 10),
      appliedOldPersonIds: const ['JL-OLD-01'],
    ),
    q3: Q3Payload(
      contexts: const [KingdomContext.inner],
      narrative: '하나님 나라를 누렸습니다',
      fruitIds: const ['JL-FRUIT-01'],
    ),
    q4: const Q4Payload(narrative: '긍휼로 바라봅니다', revisitedQ1Q2: false),
    q5: const Q5Payload(
      communionType: CommunionType.asked,
      narrative: '성령님께 여쭈었습니다',
    ),
    q6: Q6Payload(
      items: const [
        GratitudeItem(what: '말씀', why: '깨달음'),
        GratitudeItem(what: '가족', why: '사랑'),
        GratitudeItem(what: '오늘', why: '은혜'),
      ],
    ),
    q7: Q7Payload(actions: const ['감사 표현하기']),
  ),
);
