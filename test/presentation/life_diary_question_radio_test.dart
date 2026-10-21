import 'package:chgo_life_diary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the radio choices on question screens 1, 4 and 5.
///
/// The question pages read and write the global [currentLifeDiaryDraft].
/// Each test resets it and clears `diaryDate`, so draft persistence returns
/// early and no database is touched.
void main() {
  final diaryDate = DateTime(2026, 10, 21);

  setUp(() {
    currentLifeDiaryDraft.reset(diaryDate);
    currentLifeDiaryDraft.diaryDate = null;
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FilledButton buttonLabeled(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

  String? selectedValue(WidgetTester tester) =>
      tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue;

  group('Q1 awareness', () {
    setUp(() => currentLifeDiaryDraft.q1Step = 3);

    testWidgets('next is disabled until an awareness choice is made', (
      tester,
    ) async {
      await pumpPage(tester, LifeDiaryReadyPage(diaryDate: diaryDate));

      expect(buttonLabeled(tester, '다음').onPressed, isNull);

      await tapText(tester, '깨달아졌다');

      expect(selectedValue(tester), '깨달아졌다');
      expect(buttonLabeled(tester, '다음').onPressed, isNotNull);
    });

    testWidgets('partial awareness shows the slider, others hide it', (
      tester,
    ) async {
      await pumpPage(tester, LifeDiaryReadyPage(diaryDate: diaryDate));
      expect(find.byType(Slider), findsNothing);

      await tapText(tester, '어느 정도 깨달아졌다');
      expect(find.byType(Slider), findsOneWidget);

      await tapText(tester, '아직 모르겠다');
      expect(selectedValue(tester), '아직 모르겠다');
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('restores the saved awareness choice', (tester) async {
      currentLifeDiaryDraft.q1Awareness = '아직 모르겠다';

      await pumpPage(tester, LifeDiaryReadyPage(diaryDate: diaryDate));

      expect(selectedValue(tester), '아직 모르겠다');
      expect(buttonLabeled(tester, '다음').onPressed, isNotNull);
    });
  });

  group('Q4 new old self discovery', () {
    setUp(() => currentLifeDiaryDraft.q4Stage = 1);

    testWidgets('button is disabled until a choice is made', (tester) async {
      await pumpPage(tester, LifeDiaryQuestion4Page(diaryDate: diaryDate));

      expect(buttonLabeled(tester, '4번 마치기').onPressed, isNull);

      await tapText(tester, '새롭게 발견한 옛사람이 없습니다.');

      expect(selectedValue(tester), 'none');
      expect(buttonLabeled(tester, '4번 마치기').onPressed, isNotNull);
    });

    testWidgets('choosing a different old self changes the button label', (
      tester,
    ) async {
      await pumpPage(tester, LifeDiaryQuestion4Page(diaryDate: diaryDate));

      await tapText(tester, '1번과 다른 옛사람을 새롭게 발견했습니다.');
      expect(selectedValue(tester), 'different');
      expect(find.text('추가 1·2번 처리 선택'), findsOneWidget);

      await tapText(tester, '1번에서 발견한 옛사람과 같습니다.');
      expect(selectedValue(tester), 'same');
      expect(find.text('4번 마치기'), findsOneWidget);
    });
  });

  group('Q5 fellowship selection', () {
    testWidgets('selecting a choice saves it to the draft', (tester) async {
      await pumpPage(tester, LifeDiaryQuestion5Page(diaryDate: diaryDate));

      expect(buttonLabeled(tester, '선택한 내용 기록하기').onPressed, isNull);

      await tapText(tester, '두 가지 모두 기록합니다.');

      expect(selectedValue(tester), 'both');
      expect(currentLifeDiaryDraft.q5Selection, 'both');
      expect(buttonLabeled(tester, '선택한 내용 기록하기').onPressed, isNotNull);
    });

    testWidgets('choosing none changes the button label', (tester) async {
      await pumpPage(tester, LifeDiaryQuestion5Page(diaryDate: diaryDate));

      await tapText(tester, '오늘 5번에 구체적으로 기록할 것이 없습니다.');

      expect(currentLifeDiaryDraft.q5Selection, 'none');
      expect(find.text('감사문 기록하기'), findsOneWidget);
    });

    testWidgets('restores the saved selection', (tester) async {
      currentLifeDiaryDraft.q5Selection = 'word';

      await pumpPage(tester, LifeDiaryQuestion5Page(diaryDate: diaryDate));

      expect(selectedValue(tester), 'word');
    });
  });
}
