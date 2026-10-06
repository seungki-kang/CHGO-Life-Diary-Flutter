import 'package:chgo_life_diary/data/life_diary_repository.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:chgo_life_diary/presentation/life_diary_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the empty history state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryHistoryPage(
          repository: _FakeRepository(const []),
          ownerUserId: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 완성된 생명일기가 없습니다.'), findsOneWidget);
  });

  testWidgets('opens a stored entry and shows Q1-Q7', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryHistoryPage(
          repository: _FakeRepository([_entry()]),
          ownerUserId: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 10월 6일'), findsOneWidget);
    await tester.tap(find.text('2026년 10월 6일'));
    await tester.pumpAndSettle();

    expect(find.text('1. 오늘 발견한 옛사람'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('7. 무엇을 할 것인가?'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('7. 무엇을 할 것인가?'), findsOneWidget);
    expect(find.text('감사 인사를 전한다'), findsOneWidget);
  });

  testWidgets('confirms deletion and refreshes the history list', (
    tester,
  ) async {
    final repository = _FakeRepository([_entry()]);
    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryHistoryPage(
          repository: repository,
          ownerUserId: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026년 10월 6일'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('생명일기를 삭제하시겠습니까?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(repository.deletedEntryId, 'entry-1');
    expect(find.text('아직 완성된 생명일기가 없습니다.'), findsOneWidget);
  });
}

class _FakeRepository implements LifeDiaryRepository {
  _FakeRepository(this.entries);

  final List<LifeDiaryEntry> entries;
  String? deletedEntryId;

  @override
  Future<List<LifeDiaryEntry>> findByOwner(String ownerUserId) async => entries;

  @override
  Future<LifeDiaryEntry?> findById(String entryId) async => null;

  @override
  Future<void> save(LifeDiaryEntry entry) async {}

  @override
  Future<void> tombstone(String entryId) async {
    deletedEntryId = entryId;
    entries.removeWhere((entry) => entry.entryId == entryId);
  }

  @override
  Future<void> close() async {}
}

LifeDiaryEntry _entry() => LifeDiaryEntry(
  entryId: 'entry-1',
  ownerUserId: 'owner',
  seasonNumber: 1,
  sessionNumber: 1,
  entryDate: DateTime(2026, 10, 6),
  status: LifeDiaryEntryStatus.completed,
  canonicalVersion: '1.0.0',
  questions: LifeDiaryQuestions(
    q1: Q1Payload(narrative: 'record', oldPersonIds: const ['JL-OLD-01']),
    q2: Q2Payload(
      explanationVersion: '1.0.0',
      appliedOldPersonIds: const ['JL-OLD-01'],
    ),
    q3: Q3Payload(
      contexts: const [KingdomContext.inner],
      narrative: 'kingdom',
      fruitIds: const ['JL-FRUIT-01'],
    ),
    q4: const Q4Payload(narrative: 'compassion', revisitedQ1Q2: false),
    q5: const Q5Payload(
      communionType: CommunionType.whisper,
      narrative: 'communion',
    ),
    q6: Q6Payload(
      items: const [GratitudeItem(who: 'friend', what: 'help', why: 'love')],
    ),
    q7: Q7Payload(actions: const ['감사 인사를 전한다']),
  ),
);
