import 'dart:io';

import 'package:chgo_life_diary/data/life_diary_database.dart';
import 'package:chgo_life_diary/data/life_diary_draft_store.dart';
import 'package:chgo_life_diary/data/sqlite_life_diary_repository.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:chgo_life_diary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('Q3 text survives navigation, resume and Q7 completion', (
    tester,
  ) async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfiNoIsolate;
    final folder = Directory.systemTemp.createTempSync('life-diary-q3-');
    addTearDown(() => folder.deleteSync(recursive: true));
    final path = '${folder.path}/flow.sqlite';
    final db = (await tester.runAsync(
      () => factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: lifeDiaryDatabaseVersion,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) async {
            await LifeDiaryDatabase.createV001(db);
            await LifeDiaryDatabase.createV002(db);
            await LifeDiaryDatabase.createV003(db);
          },
        ),
      ),
    ))!;
    addTearDown(() async {
      if (db.isOpen) await db.close();
    });
    final store = lifeDiaryDraftStore = LifeDiaryDraftStore(db);
    lifeDiaryRepository = SqliteLifeDiaryRepository(db);
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final date = DateTime(2026, 10, 6);
    const event = '합성 사건 기록: 동료의 말을 끝까지 들었다.';
    const declaration = '합성 선언 기록: 사랑으로 먼저 다가가겠다.';
    currentLifeDiaryDraft.loadJson(date, {
      'q1_step': 4,
      'q1_completed': true,
      'q1_detail': '합성 기록',
      'q1_old_selves': ['두려움'],
      'q1_awareness': '알고 있었다',
      'q2_completed_old_selves': ['두려움'],
      'q3_stage': 1,
      'q3_selected_realms': ['내 안'],
      'q3_realm_queue': ['내 안'],
      'q4_stage': 5,
      'q4_no_record': true,
      'q5_stage': 4,
      'q5_selection': 'daily',
      'q5_daily_record': '합성 일상 기록',
      'q6_stage': 2,
      'q6_gratitudes': [
        {'person': '가족', 'what': '도움'},
        {'person': '친구', 'what': '대화'},
        {'person': '이웃', 'what': '인사'},
      ],
      'q7_stage': 2,
      'q7_action': '먼저 인사하기',
      'q7_reason': '사랑을 실천하기 위해',
    });

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> jumpTo(int question) async {
      await tap(find.byTooltip('1~7번 문항 이동'));
      await tap(find.textContaining('$question번 ·'));
    }

    await tester.pumpWidget(
      MaterialApp(home: LifeDiaryQuestion3Page(diaryDate: date)),
    );
    await tester.enterText(find.byType(TextField).at(0), event);
    await tester.enterText(find.byType(TextField).at(1), declaration);
    await jumpTo(4);
    expect(find.byType(LifeDiaryQuestion4Page), findsOneWidget);
    await jumpTo(3);
    expect(find.text(event), findsOneWidget);
    expect(find.text(declaration), findsOneWidget);
    await tap(find.text('성령의 열매 확인하기'));
    for (final fruit in [
      '사랑',
      '기쁨',
      '평안(화평)',
      '오래 참음',
      '자비',
      '양선',
      '충성',
      '온유',
      '절제',
    ]) {
      await tap(find.widgetWithText(CheckboxListTile, fruit));
    }
    await tap(find.text('선택하지 않은 열매 확인'));
    expect(find.textContaining(event), findsOneWidget);
    expect(find.textContaining(declaration), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    currentLifeDiaryDraft.reset(date);
    final checkpoint = (await store.load(date))!;
    expect(checkpoint['q3_stage'], 4);
    expect(checkpoint['q3_enjoyment_records'], [
      allOf(
        containsPair('event', event),
        containsPair('declaration', declaration),
      ),
    ]);

    await tester.pumpWidget(const ChgoLifeDiaryApp());
    await tap(find.text('작성 중인 생명일기'));
    await tap(find.text('7번 문항부터 이어쓰기'));
    expect(find.byType(LifeDiaryQuestion7Page), findsOneWidget);
    await jumpTo(3);
    expect(find.textContaining(event), findsOneWidget);
    expect(find.textContaining(declaration), findsOneWidget);
    await jumpTo(7);
    await tap(find.text('생명일기 최종 완성'));
    await tap(find.text('최종 완성'));
    expect(find.text('오늘의 생명일기를 완성했습니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await db.close();

    final reopened = (await tester.runAsync(() => factory.openDatabase(path)))!;
    try {
      final entries = await SqliteLifeDiaryRepository(reopened)
          .findByOwner(lifeDiaryEntryFactory.ownerUserId);
      expect(entries, hasLength(1));
      expect(entries.single.status, LifeDiaryEntryStatus.completed);
      expect(entries.single.questions.q3.narrative, '[내 안] $event');
      expect(entries.single.questions.q3.declaration, '[내 안] $declaration');
      expect(await LifeDiaryDraftStore(reopened).load(date), isNull);
    } finally {
      await reopened.close();
    }
  });
}
