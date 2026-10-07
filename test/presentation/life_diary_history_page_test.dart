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

  testWidgets('shows deleted entries by filter and restores one', (
    tester,
  ) async {
    final deleted = _entry(status: LifeDiaryEntryStatus.deleted);
    final repository = _FakeRepository([deleted]);
    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryHistoryPage(
          repository: repository,
          ownerUserId: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제됨'));
    await tester.pumpAndSettle();
    expect(find.text('복구'), findsOneWidget);

    await tester.tap(find.text('복구'));
    await tester.pumpAndSettle();
    expect(repository.restoredEntryId, 'entry-1');
  });

  testWidgets('selects and deletes multiple entries from the history list', (
    tester,
  ) async {
    final repository = _FakeRepository([
      _entry(),
      _entry(
        entryId: 'entry-2',
        sessionNumber: 2,
        entryDate: DateTime(2026, 10, 7),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: LifeDiaryHistoryPage(
          repository: repository,
          ownerUserId: 'owner',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await tester.pumpAndSettle();
    expect(find.text('삭제할 기록을 선택하세요'), findsOneWidget);

    await tester.tap(find.text('2026년 10월 6일'));
    await tester.tap(find.text('2026년 10월 7일'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 2개 삭제'), findsOneWidget);

    await tester.tap(find.text('선택한 2개 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 생명일기 2개를 삭제할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(repository.deletedEntryIds, containsAll(['entry-1', 'entry-2']));
    expect(find.text('아직 완성된 생명일기가 없습니다.'), findsOneWidget);
  });
}

class _FakeRepository implements LifeDiaryRepository {
  _FakeRepository(this.entries);

  final List<LifeDiaryEntry> entries;
  final List<String> deletedEntryIds = <String>[];
  String? get deletedEntryId =>
      deletedEntryIds.isEmpty ? null : deletedEntryIds.last;
  String? restoredEntryId;

  @override
  Future<List<LifeDiaryEntry>> findByOwner(String ownerUserId) async => entries;

  @override
  Future<LifeDiaryEntry?> findById(String entryId) async => null;

  @override
  Future<void> save(LifeDiaryEntry entry) async {}

  @override
  Future<void> tombstone(String entryId) async {
    deletedEntryIds.add(entryId);
    entries.removeWhere((entry) => entry.entryId == entryId);
  }

  @override
  Future<void> restore(String entryId) async {
    restoredEntryId = entryId;
    final index = entries.indexWhere((entry) => entry.entryId == entryId);
    if (index < 0) return;
    final entry = entries[index];
    entries[index] = _entry(status: LifeDiaryEntryStatus.completed);
    assert(entry.entryId == entries[index].entryId);
  }

  @override
  Future<void> close() async {}
}

LifeDiaryEntry _entry({
  String entryId = 'entry-1',
  int sessionNumber = 1,
  DateTime? entryDate,
  LifeDiaryEntryStatus status = LifeDiaryEntryStatus.completed,
}) => LifeDiaryEntry(
  entryId: entryId,
  ownerUserId: 'owner',
  seasonNumber: 1,
  sessionNumber: sessionNumber,
  entryDate: entryDate ?? DateTime(2026, 10, 6),
  status: status,
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
