import 'package:chgo_life_diary/application/life_diary_draft_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed entry blocks stale page disposal writes', () {
    final lifecycle = LifeDiaryDraftLifecycle();

    expect(lifecycle.shouldPersist, isTrue);

    lifecycle.markCompletedEntryClosing();

    expect(lifecycle.shouldPersist, isFalse);
  });

  test('a new diary enables draft persistence again', () {
    final lifecycle = LifeDiaryDraftLifecycle()
      ..markCompletedEntryClosing()
      ..beginDraft();

    expect(lifecycle.shouldPersist, isTrue);
  });
}
