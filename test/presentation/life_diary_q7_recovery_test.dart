import 'package:chgo_life_diary/data/life_diary_draft_store.dart';
import 'package:chgo_life_diary/data/life_diary_repository.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:chgo_life_diary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DraftStore implements LifeDiaryDraftStore {
  Map<String, Object?>? payload;
  @override
  Future<Map<String, Object?>?> load(DateTime date) async => payload;
  @override
  Future<void> save(DateTime date, Map<String, Object?> value) async {
    payload = value;
  }

  @override
  Future<void> delete(DateTime date) async {
    payload = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EntryRepository implements LifeDiaryRepository {
  LifeDiaryEntry? entry;
  @override
  Future<LifeDiaryEntry?> findById(String id) async =>
      entry?.entryId == id ? entry : null;
  @override
  Future<List<LifeDiaryEntry>> findByOwner(String ownerUserId) async => [
    ?entry,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'compact date screen scrolls to start and recovers legacy drafts',
    (tester) async {
      final store = _DraftStore();
      final repository = _EntryRepository();
      lifeDiaryDraftStore = store;
      lifeDiaryRepository = repository;
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> startDate() async {
        await tester.pumpWidget(const MaterialApp(home: LifeDiaryDatePage()));
        await tester.pumpAndSettle();
        final start = find.widgetWithText(FilledButton, '이 날짜로 시작');
        await tester.scrollUntilVisible(start, 120);
        await tester.ensureVisible(start);
        expect(tester.takeException(), isNull);
        await tester.tap(start.hitTestable());
        await tester.pumpAndSettle();
        expect(find.byType(LifeDiaryReadyPage), findsOneWidget);
      }

      const payload = {
        'q7_final_completed': true,
        'q7_stage': 2,
        'q7_action': 'pending test draft',
      };
      store.payload = Map.of(payload);
      await startDate();
      expect(currentLifeDiaryDraft.q7Action, 'pending test draft');
      expect(currentLifeDiaryDraft.q7FinalCompleted, isFalse);
      expect(store.payload, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      store.payload = Map.of(payload);
      repository.entry = lifeDiaryEntryFactory.fromUiDraft(
        DateTime.now(),
        payload,
        completed: true,
      );
      await startDate();
      expect(store.payload, isNull);
      expect(currentLifeDiaryDraft.sessionNumber, 2);
      expect(currentLifeDiaryDraft.q7Action, isEmpty);
    },
  );
}
