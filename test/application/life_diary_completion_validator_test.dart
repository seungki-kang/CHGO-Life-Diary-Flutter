import 'package:chgo_life_diary/application/life_diary_completion_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = LifeDiaryCompletionValidator();

  Map<String, Object?> completeDraft() => {
    'q1_detail': '오늘의 반응',
    'q1_old_selves': ['두려움'],
    'q1_no_old_self': false,
    'q1_awareness': '알고 있었다',
    'q1_step': 4,
    'q1_completed': true,
    'q2_completed_old_selves': ['두려움'],
    'q2_partial_text': '',
    'q3_stage': 4,
    'q4_stage': 5,
    'q5_stage': 4,
    'q6_stage': 3,
    'q6_gratitudes': [
      {'person': '하나님', 'what': '오늘을 주심'},
      {'person': '가족', 'what': '함께해 줌'},
      {'person': '친구', 'what': '격려해 줌'},
    ],
    'q7_stage': 2,
    'q7_action': '먼저 연락하기',
    'q7_reason': '사랑을 실천하기 위해',
  };

  test('allows final completion only when Q1 through Q7 are complete', () {
    expect(validator.validate(completeDraft()), isEmpty);
  });

  test('reports skipped questions and preserves direct question numbers', () {
    final draft = completeDraft()
      ..['q3_stage'] = 0
      ..['q4_stage'] = 2
      ..['q6_stage'] = 1
      ..['q6_gratitudes'] = [
        {'person': '하나님', 'what': '오늘을 주심'},
      ];

    expect(validator.validate(draft).map((issue) => issue.questionNumber), [
      3,
      4,
      6,
    ]);
  });

  test('Q1 no-old-self path still requires all seven Q2 confessions', () {
    final draft = completeDraft()
      ..['q1_detail'] = ''
      ..['q1_old_selves'] = <String>[]
      ..['q1_no_old_self'] = true
      ..['q2_completed_old_selves'] = List.generate(6, (index) => 'old-$index');

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(2),
    );

    draft['q2_completed_old_selves'] = List.generate(
      7,
      (index) => 'old-$index',
    );
    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      isNot(contains(2)),
    );
  });

  test('opening Q1 final screen is not the same as completing Q1', () {
    final draft = completeDraft()..['q1_completed'] = false;

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(1),
    );
  });
}
