import 'dart:async';

import 'package:chgo_life_diary/application/life_diary_dev_login.dart';
import 'package:chgo_life_diary/data/life_diary_entry_factory.dart';
import 'package:chgo_life_diary/data/sqlite_life_diary_repository.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:chgo_life_diary/presentation/life_diary_dev_backup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  const enabled = LifeDiaryDevBackupPage.selectedEnabled;
  final entry = LifeDiaryEntryFactory(ownerUserId: 'synthetic-owner')
      .fromUiDraft(DateTime(2026, 11, 17), {
        'q1_detail': '합성 일기',
        'q7_action': '감사 인사를 전한다.',
      }, completed: true);
  final expires = DateTime.utc(2100);
  final original = LifeDiaryAuthSession('synthetic-a', 'account', expires);
  final replacement = LifeDiaryAuthSession('synthetic-b', 'account', expires);
  final action = find.widgetWithText(FilledButton, '동의하고 이 일기 백업');

  Future<void> open(
    WidgetTester tester,
    _PendingReadRepository repository,
    LifeDiaryAuthSession? Function() session,
  ) => tester.pumpWidget(
    MaterialApp(
      home: LifeDiaryDevBackupPage.selected(
        session: session,
        selectedSession: original,
        selectedRepository: repository,
        selectedEntry: entry,
        selectedAttempt: LifeDiarySelectedBackupAttempt(),
      ),
    ),
  );

  testWidgets('opening the backup page leaves the diary untouched', (
    tester,
  ) async {
    final repository = _PendingReadRepository();
    await open(tester, repository, () => original);
    expect(find.text('개발 계정 ID account'), findsOneWidget);
    expect(tester.widget<FilledButton>(action).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(action).onPressed, isNotNull);
    expect(repository.reads, 0);
  }, skip: !enabled);

  for (final author in [null, 'another-account']) {
    testWidgets('blocks backup for a missing or different author: $author', (
      tester,
    ) async {
      final repository = _PendingReadRepository(author: author);
      repository.result.complete(entry);
      await open(tester, repository, () => original);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text('작성할 때 연결한 계정으로만 백업할 수 있습니다.'), findsOneWidget);
      expect(find.byType(SelectableText), findsNothing);
    }, skip: !enabled);
  }

  for (final (label, nextSession) in [
    ('same account signs in again', replacement),
    ('active session is missing', null),
  ]) {
    testWidgets('blocks backup during the diary read when $label', (
      tester,
    ) async {
      final repository = _PendingReadRepository();
      LifeDiaryAuthSession? active = original;
      await open(tester, repository, () => active);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(action);
      await tester.tap(action);
      // A second tap before the widget rebuilds still reaches the old handler.
      await tester.tap(action);
      expect(repository.reads, 1);

      active = nextSession;
      repository.result.complete(entry);
      await tester.pumpAndSettle();

      expect(find.text('로그인 세션이 바뀌었거나 만료되었습니다.'), findsOneWidget);
      expect(tester.widget<FilledButton>(action).onPressed, isNull);
      expect(find.byType(SelectableText), findsNothing);
    }, skip: !enabled);
  }
}

class _PendingReadRepository extends SqliteLifeDiaryRepository {
  _PendingReadRepository({this.author = 'account'}) : super(_UnusedDatabase());

  final String? author;

  @override
  Future<String?> findAuthorAccountId(String entryId) async => author;

  final result = Completer<LifeDiaryEntry?>();
  int reads = 0;

  @override
  Future<LifeDiaryEntry?> findById(String entryId) {
    reads++;
    return result.future;
  }
}

class _UnusedDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
