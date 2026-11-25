import 'package:chgo_life_diary/application/life_diary_draft_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Like the app-level queue, this instance outlives each widget test zone.
  late LifeDiaryDraftPersistence queue;
  setUpAll(() {
    queue = LifeDiaryDraftPersistence(
      save: (_, _) async {
        fail('An idle queue must not write');
      },
    );
  });

  for (final name in ['first', 'second']) {
    testWidgets('idle shared queue settles in $name test zone', (tester) async {
      var settled = false;
      queue.settled.then((_) => settled = true);
      await tester.pump();
      expect(settled, isTrue);
    });
  }
}
