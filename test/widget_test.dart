import 'package:flutter_test/flutter_test.dart';
import 'package:chgo_life_diary/main.dart';

void main() {
  testWidgets('Life Diary start page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ChgoLifeDiaryApp());

    expect(find.text('CHGO Life Diary'), findsOneWidget);
    expect(find.text('생명일기'), findsOneWidget);
    expect(find.textContaining('성령의 역사입니다'), findsOneWidget);
    expect(find.bySemanticsLabel('JesusLife'), findsOneWidget);
  });
}
