import 'package:chgo_life_diary/application/life_diary_step_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
