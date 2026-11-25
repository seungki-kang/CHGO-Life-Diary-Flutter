import 'package:chgo_life_diary/application/life_diary_completion_validator.dart';
import 'package:chgo_life_diary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Screen navigation only: match the existing question widget tests by disabling
// disk persistence. No personal database, restart, or process-death claim.
void main() {
  final date = DateTime(2026, 11, 1);
  const event = 'Synthetic LD01 event';
  const declaration = 'Synthetic LD01 declaration';
  const fruits = ['사랑', '기쁨', '평안(화평)', '오래 참음', '자비', '양선', '충성', '온유', '절제'];

  setUp(() {
    currentLifeDiaryDraft.reset(date);
    currentLifeDiaryDraft.diaryDate = null;
    currentLifeDiaryDraft.q1OldSelves.add('수치심');
    currentLifeDiaryDraft.q2CompletedOldSelves.add('수치심');
  });

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> navigate(WidgetTester tester, int question) async {
    await tap(tester, find.byTooltip('1~7번 문항 이동'));
    final tile = find.byWidgetPredicate(
      (widget) =>
          widget is ListTile &&
          widget.title is Text &&
          (((widget.title as Text).data?.startsWith('$question번 ·')) ?? false),
    );
    await tap(tester, tile);
    expect(
      find.byType(
        question == 2 ? LifeDiaryQuestion2Page : LifeDiaryQuestion3Page,
      ),
      findsOneWidget,
    );
  }

  Future<void> writeRecord(WidgetTester tester) async {
    // Dispose the page before the next test resets the shared draft: dispose
    // saves its local fields and must not overwrite the next test's fixture.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
    await tester.pumpWidget(
      MaterialApp(home: LifeDiaryQuestion3Page(diaryDate: date)),
    );
    await tester.pumpAndSettle();
    await tap(tester, find.text('내 안의 하나님 나라'));
    await tap(tester, find.text('구체적으로 기록하기'));
    await tester.enterText(find.byType(TextField).at(0), event);
    await tester.enterText(find.byType(TextField).at(1), declaration);
    await tester.pumpAndSettle();
  }

  LifeDiaryQuestionCompletion status() => const LifeDiaryCompletionValidator()
      .status(currentLifeDiaryDraft.toJson(), 3);

  testWidgets('LD01 in-progress Q3 survives Q2 round trip', (tester) async {
    await writeRecord(tester);
    await navigate(tester, 2);
    expect(currentLifeDiaryDraft.q3Event, event);
    expect(currentLifeDiaryDraft.q3Declaration, declaration);
    expect(currentLifeDiaryDraft.q3SelectedRealms, {'내 안'});
    expect(status(), LifeDiaryQuestionCompletion.inProgress);
    await navigate(tester, 3);
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, event);
    expect(fields[1].controller!.text, declaration);
    expect(find.text('1/1  내 안의 하나님 나라'), findsOneWidget);
    expect(currentLifeDiaryDraft.q3Stage, 1);
    expect(status(), LifeDiaryQuestionCompletion.inProgress);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LD01 completed Q3 survives Q2 round trip', (tester) async {
    await writeRecord(tester);
    await tap(tester, find.text('성령의 열매 확인하기'));
    for (final fruit in fruits) {
      await tap(tester, find.text(fruit));
    }
    await tap(tester, find.text('선택하지 않은 열매 확인'));
    await navigate(tester, 2);
    expect(status(), LifeDiaryQuestionCompletion.complete);
    final before = currentLifeDiaryDraft.toJson();
    await tap(tester, find.byTooltip('1~7번 문항 이동'));
    expect(find.text('3번 · 완료'), findsOneWidget);
    await tap(tester, find.text('3번 · 완료'));
    expect(find.byType(LifeDiaryQuestion3Page), findsOneWidget);
    expect(find.text('오늘 이루어진 하나님 나라를 확인합니다.'), findsOneWidget);
    expect(find.text('상황과 하나님 나라 발견\n$event'), findsOneWidget);
    expect(find.text('고백·선포·선언과 누림\n$declaration'), findsOneWidget);
    for (final fruit in fruits) {
      expect(find.text('$fruit · 누림 기록'), findsOneWidget);
    }
    expect(currentLifeDiaryDraft.q3SelectedRealms, {'내 안'});
    expect(currentLifeDiaryDraft.q3SelectedFruits, fruits.toSet());
    expect(currentLifeDiaryDraft.q3EnjoymentRecords, hasLength(1));
    expect(currentLifeDiaryDraft.q3Stage, 4);
    expect(status(), LifeDiaryQuestionCompletion.complete);
    final after = currentLifeDiaryDraft.toJson();
    for (final key in before.keys.where((key) => key.startsWith('q3_'))) {
      expect(after[key], before[key], reason: key);
    }
    expect(tester.takeException(), isNull);
  });
}
