import 'dart:async';

import 'package:chgo_life_diary/application/life_diary_draft_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 10, 23);

  test('slow earlier write finishes before the newer checkpoint', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    final saved = <int>[];
    final queue = LifeDiaryDraftPersistence(
      save: (_, payload) async {
        if (payload['revision'] == 1) {
          started.complete();
          await gate.future;
        }
        saved.add(payload['revision'] as int);
      },
    );
    final first = queue.enqueue(date, {'revision': 1});
    await started.future;
    final second = queue.enqueue(date, {'revision': 2});
    expect(saved, isEmpty);
    gate.complete();
    await Future.wait([first, second]);
    expect(saved, [1, 2]);
  });

  test('queued payload keeps its nested snapshot', () async {
    Map<String, Object?>? saved;
    final queue = LifeDiaryDraftPersistence(
      save: (_, payload) async {
        saved = payload;
      },
    );
    final items = [
      {'person': '가족', 'what': '함께함'},
    ];
    final write = queue.enqueue(date, {'q6_gratitudes': items});
    items.first['what'] = '변경';
    items.clear();
    await write;
    expect(saved!['q6_gratitudes'], [
      {'person': '가족', 'what': '함께함'},
    ]);
  });

  test('temporary failure retries and then succeeds', () async {
    var attempts = 0;
    final waits = <Duration>[];
    final retries = <int>[];
    final queue = LifeDiaryDraftPersistence(
      save: (_, _) async {
        if (++attempts < 3) throw StateError('busy');
      },
      delay: (duration) async => waits.add(duration),
      onRetry: (attempt, _) => retries.add(attempt),
    );
    await queue.enqueue(date, {});
    expect(attempts, 3);
    expect(retries, [1, 2]);
    expect(waits, [
      const Duration(milliseconds: 50),
      const Duration(milliseconds: 100),
    ]);
  });

  test(
    'permanent failure is observable and does not poison later saves',
    () async {
      var failedAttempts = 0;
      var recovered = false;
      final queue = LifeDiaryDraftPersistence(
        save: (_, payload) async {
          if (payload['fail'] == true) {
            failedAttempts++;
            throw StateError('disk full');
          }
          recovered = true;
        },
        delay: (_) async {},
      );
      await expectLater(queue.enqueue(date, {'fail': true}), throwsStateError);
      await queue.enqueue(date, {'fail': false});
      await queue.settled;
      expect(failedAttempts, 3);
      expect(recovered, isTrue);
    },
  );
}
