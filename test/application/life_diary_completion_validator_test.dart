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
    'q5_selection': 'both',
    'q5_daily_record': '일상 교제',
    'q5_word_record': '말씀 교제',
    'q5_no_record_declaration': '',
    'q6_stage': 2,
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

  test('accepts the single Q6 summary stage with three valid gratitudes', () {
    final draft = completeDraft()..['q6_stage'] = 2;

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      isNot(contains(6)),
    );
  });

  test('Q5 both branch requires both daily and word records', () {
    final draft = completeDraft()..['q5_word_record'] = '';

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(5),
    );
  });

  test('Q6 does not count identical duplicated gratitudes as three', () {
    final duplicate = {'person': '하나님', 'what': '오늘을 주심'};
    final draft = completeDraft()
      ..['q6_gratitudes'] = [duplicate, duplicate, duplicate];

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(6),
    );
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
    const allOldSelves = [
      '수치심',
      '죄책감',
      '두려움',
      '자기의(신념·고정관념)',
      '과거의 상처',
      '인정받고 싶은 욕구',
      '죽음의 공포',
    ];
    final draft = completeDraft()
      ..['q1_detail'] = ''
      ..['q1_old_selves'] = <String>[]
      ..['q1_no_old_self'] = true
      ..['q2_completed_old_selves'] = allOldSelves.take(6).toList();

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(2),
    );

    draft['q2_completed_old_selves'] = allOldSelves;
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

  test('Q2 review text does not invalidate completed confessions', () {
    final draft = completeDraft()
      ..['q2_partial_text'] = '나의 두려움은 예수님과 함께 십자가에 못 박혀 죽었습니다.';

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      isNot(contains(2)),
    );
  });

  test('Q2 requires the actual Q1 old selves, not only the same count', () {
    final draft = completeDraft()
      ..['q1_old_selves'] = ['두려움', '수치심']
      ..['q2_completed_old_selves'] = ['두려움', '죄책감'];

    expect(
      validator.validate(draft).map((issue) => issue.questionNumber),
      contains(2),
    );
  });
}
