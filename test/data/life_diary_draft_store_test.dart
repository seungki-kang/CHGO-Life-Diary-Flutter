import 'package:chgo_life_diary/data/life_diary_database.dart';
import 'package:chgo_life_diary/data/life_diary_draft_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;
  late LifeDiaryDraftStore store;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await LifeDiaryDatabase.createV001(database);
    await LifeDiaryDatabase.createV002(database);
    await LifeDiaryDatabase.createV003(database);
    store = LifeDiaryDraftStore(database);
  });

  tearDown(() => database.close());

  test('saves and restores a Q1-Q7 UI draft by date', () async {
    final date = DateTime(2026, 10, 6);
    final payload = <String, Object?>{
      'q1_detail': '오늘의 기록',
      'q1_old_selves': ['수치심'],
      'q7_action': '감사 인사를 전한다',
      'q7_final_completed': false,
    };

    await store.save(date, payload);

    expect(await store.load(date), payload);
  });

  test('replaces the same date without creating duplicate drafts', () async {
    final date = DateTime(2026, 10, 6);
    await store.save(date, {'q1_detail': '처음'});
    await store.save(date, {'q1_detail': '수정'});

    expect(await store.load(date), {'q1_detail': '수정'});
    final rows = await database.rawQuery(
      'SELECT COUNT(*) FROM life_diary_ui_draft',
    );
    expect(rows.single.values.single, 1);
  });

  test('returns null when the selected date has no draft', () async {
    expect(await store.load(DateTime(2026, 10, 7)), isNull);
  });
}
