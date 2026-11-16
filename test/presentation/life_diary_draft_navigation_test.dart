import 'package:chgo_life_diary/data/life_diary_draft_store.dart';
import 'package:chgo_life_diary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DraftStore implements LifeDiaryDraftStore {
  bool failing = false;
  int attempts = 0;
  Map<String, Object?>? payload;

  @override
  Future<void> save(DateTime date, Map<String, Object?> value) async {
    attempts++;
    if (failing) throw StateError('simulated write failure');
    payload = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'duplicate edit preserves records and failed saves block navigation',
    (tester) async {
      final store = _DraftStore();
      lifeDiaryDraftStore = store;
      final date = DateTime(2026, 10, 6);
      currentLifeDiaryDraft.loadJson(date, {
        'q6_stage': 2,
        'q6_gratitudes': [
          {'person': 'A', 'what': 'first'},
          {'person': 'B', 'what': 'second'},
          {'person': 'C', 'what': 'third'},
        ],
      });
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LifeDiaryQuestion6Page(diaryDate: date),
                  ),
                ),
                child: const Text('Open Q6'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Q6'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'B');
      await tester.enterText(find.byType(TextField).at(1), 'second');
      final save = find.text('수정 내용 저장');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.textContaining('이미 같은 감사 기록'), findsOneWidget);
      expect(currentLifeDiaryDraft.q6Gratitudes.map((item) => item['person']), [
        'A',
        'B',
        'C',
      ]);

      await tester.enterText(find.byType(TextField).at(0), 'D');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('현재 3가지 감사를 기록했습니다.'), findsOneWidget);
      expect(store.payload?['q6_gratitudes'], hasLength(3));

      Future<void> selectQ5() async {
        await tester.tap(find.byTooltip('1~7번 문항 이동'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('5번 ·'));
        await tester.pump();
      }

      Future<void> exhaustRetries() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      }

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final before = store.attempts;
      store.failing = true;
      await selectQ5();
      await exhaustRetries();
      expect(store.attempts - before, 3);
      expect(find.textContaining('임시저장에 실패했습니다'), findsOneWidget);
      expect(find.byType(LifeDiaryQuestion6Page), findsOneWidget);
      store.failing = false;
      await selectQ5();
      await tester.pumpAndSettle();
      expect(find.byType(LifeDiaryQuestion5Page), findsOneWidget);
      store.failing = true;
      await tester.binding.handlePopRoute();
      await exhaustRetries();
      expect(find.byType(LifeDiaryQuestion5Page), findsOneWidget);
      store.failing = false;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open Q6'), findsOneWidget);
      expect(store.payload?['q6_gratitudes'], hasLength(3));
    },
  );
}
