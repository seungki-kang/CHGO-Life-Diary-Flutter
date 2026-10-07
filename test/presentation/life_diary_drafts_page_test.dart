import 'package:chgo_life_diary/data/life_diary_draft_store.dart';
import 'package:chgo_life_diary/presentation/life_diary_drafts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the resume question and deletes a draft', (tester) async {
    final drafts = <LifeDiaryDraftRecord>[
      LifeDiaryDraftRecord(
        date: DateTime(2026, 10, 7),
        payload: const {'q5_stage': 2},
        updatedAt: DateTime.utc(2026, 10, 7),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryDraftsPage(
          loadDrafts: () async => List.unmodifiable(drafts),
          deleteDraft: (date) async {
            drafts.removeWhere((draft) => draft.date == date);
          },
          onResume: (_, _, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5번 문항부터 이어쓰기'), findsOneWidget);
    await tester.tap(find.byTooltip('임시저장 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(find.text('작성 중인 생명일기가 없습니다.'), findsOneWidget);
  });
}
