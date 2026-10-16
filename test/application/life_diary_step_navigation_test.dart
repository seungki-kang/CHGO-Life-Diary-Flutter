import 'package:chgo_life_diary/application/life_diary_step_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whole diary moves backward from Q7 to the start in strict order', () {
    var location = 7;
    final visited = <int>[location];
    while (location > lifeDiaryStartLocation) {
      location = previousLifeDiaryLocation(location);
      visited.add(location);
    }
    expect(visited, <int>[7, 6, 5, 4, 3, 2, 1, 0]);
  });

  test('whole diary moves forward from the start to Q7 in strict order', () {
    var location = lifeDiaryStartLocation;
    final visited = <int>[location];
    while (location < lastLifeDiaryQuestion) {
      location = nextLifeDiaryLocation(location);
      visited.add(location);
    }
    expect(visited, <int>[0, 1, 2, 3, 4, 5, 6, 7]);
  });

  test('question navigation rejects locations outside its boundaries', () {
    expect(() => previousLifeDiaryLocation(0), throwsRangeError);
    expect(() => previousLifeDiaryLocation(8), throwsRangeError);
    expect(() => nextLifeDiaryLocation(-1), throwsRangeError);
    expect(() => nextLifeDiaryLocation(7), throwsRangeError);
  });

  test('Q3 record screen returns to kingdom realm selection', () {
    expect(previousQuestion3Stage(stage: 1, noKingdomEnjoyment: false), 0);
  });

  test('Q3 no-enjoyment declaration returns to realm selection', () {
    expect(previousQuestion3Stage(stage: 3, noKingdomEnjoyment: true), 0);
  });

  test('Q4 internal stages return to their immediately previous stage', () {
    expect(
      previousQuestion4Stage(
        stage: 1,
        noRecord: false,
        hasAdditionalConfessions: false,
      ),
      0,
    );
    expect(
      previousQuestion4Stage(
        stage: 4,
        noRecord: false,
        hasAdditionalConfessions: true,
      ),
      3,
    );
  });

  test('Q5 respects the selected branch when moving backward', () {
    expect(previousQuestion5Stage(stage: 2, selection: 'both'), 1);
    expect(previousQuestion5Stage(stage: 2, selection: 'word'), 0);
    expect(previousQuestion5Stage(stage: 4, selection: 'none'), 3);
  });

  test('Q6 and Q7 move back one internal stage', () {
    expect(previousQuestion6Stage(3), 2);
    expect(previousQuestion6Stage(1), 0);
    expect(previousQuestion7Stage(2), 1);
    expect(previousQuestion7Stage(1), 0);
  });
}
