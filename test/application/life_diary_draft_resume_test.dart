import 'package:chgo_life_diary/application/life_diary_draft_resume.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty draft resumes at question 1', () {
    expect(LifeDiaryDraftResume.questionNumber(const {}), 1);
  });

  test('resumes at the latest question containing progress', () {
    expect(
      LifeDiaryDraftResume.questionNumber({
        'q1_detail': 'record',
        'q3_stage': 2,
        'q3_event': 'kingdom',
      }),
      3,
    );
    expect(
      LifeDiaryDraftResume.questionNumber({
        'q5_selection': 'word',
        'q6_gratitudes': [
          {'what': 'grace', 'why': 'today'},
        ],
      }),
      6,
    );
    expect(LifeDiaryDraftResume.questionNumber({'q7_action': 'serve'}), 7);
  });
}
