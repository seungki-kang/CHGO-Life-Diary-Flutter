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

  test('only a draft for the next session can be restored', () {
    final lifecycle = LifeDiaryDraftLifecycle();

    expect(
      lifecycle.matchesNextSession(
        draftSeason: 1,
        draftSession: 1,
        nextSeason: 1,
        nextSession: 2,
      ),
      isFalse,
    );
    expect(
      lifecycle.matchesNextSession(
        draftSeason: 1,
        draftSession: 2,
        nextSeason: 1,
        nextSession: 2,
      ),
      isTrue,
    );
  });

  group('restoredDraftAction', () {
    final lifecycle = LifeDiaryDraftLifecycle();
    RestoredDraftAction decide({
      bool restored = true,
      bool finalCompleted = false,
      int draftSession = 5,
      int nextSession = 5,
    }) => lifecycle.restoredDraftAction(
      restored: restored,
      finalCompleted: finalCompleted,
      draftSeason: 1,
      draftSession: draftSession,
      nextSeason: 1,
      nextSession: nextSession,
    );

    test('no saved draft starts fresh', () {
      expect(decide(restored: false), RestoredDraftAction.startFresh);
    });

    test('a draft for the next session is kept as is', () {
      expect(decide(), RestoredDraftAction.keepAsIs);
    });

    test('an unfinished draft with a stale number keeps its content', () {
      // Regression: this case used to delete the draft and every reflection
      // written in it.
      expect(decide(nextSession: 6), RestoredDraftAction.keepRenumbered);
    });

    test('a draft whose final save already happened is discarded', () {
      expect(
        decide(finalCompleted: true, nextSession: 6),
        RestoredDraftAction.startFresh,
      );
    });
  });
}
