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

  List<int> issueNumbers(Map<String, Object?> draft) =>
      validator.validate(draft).map((issue) => issue.questionNumber).toList();

  group('validate', () {
    test('allows final completion only when Q1 through Q7 are complete', () {
      expect(issueNumbers(completeDraft()), isEmpty);
    });

    test('empty draft reports all seven questions in order', () {
      expect(issueNumbers({}), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('reports skipped questions and preserves direct question numbers', () {
      final draft = completeDraft()
        ..['q3_stage'] = 0
        ..['q4_stage'] = 2
        ..['q6_stage'] = 1
        ..['q6_gratitudes'] = [
          {'person': '하나님', 'what': '오늘을 주심'},
        ];

      expect(issueNumbers(draft), [3, 4, 6]);
    });
  });

  group('Q1 old self discovery', () {
    test('opening Q1 final screen is not the same as completing Q1', () {
      final draft = completeDraft()..['q1_completed'] = false;

      expect(issueNumbers(draft), [1]);
    });

    test('requires reaching step 4', () {
      expect(issueNumbers(completeDraft()..['q1_step'] = 3), [1]);
    });

    test('requires an awareness answer', () {
      expect(issueNumbers(completeDraft()..['q1_awareness'] = null), [1]);
    });
  });

  group('Q2 cross confession', () {
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

      expect(issueNumbers(draft), [2], reason: '6 of 7 confessed');

      draft['q2_completed_old_selves'] = allOldSelves;
      expect(issueNumbers(draft), isEmpty, reason: 'all 7 confessed');
    });

    test('review text does not invalidate completed confessions', () {
      final draft = completeDraft()
        ..['q2_partial_text'] = '나의 두려움은 예수님과 함께 십자가에 못 박혀 죽었습니다.';

      expect(issueNumbers(draft), isEmpty);
    });

    test('requires the actual Q1 old selves, not only the same count', () {
      final draft = completeDraft()
        ..['q1_old_selves'] = ['두려움', '수치심']
        ..['q2_completed_old_selves'] = ['두려움', '죄책감'];

      expect(issueNumbers(draft), [2]);
    });
  });

  group('Q3 and Q4 stage thresholds', () {
    test('Q3 requires stage 4', () {
      expect(issueNumbers(completeDraft()..['q3_stage'] = 3), [3]);
    });

    test('Q4 requires stage 5', () {
      expect(issueNumbers(completeDraft()..['q4_stage'] = 4), [4]);
    });
  });

  group('Q5 fellowship with the Holy Spirit', () {
    test('both branch requires both daily and word records', () {
      final draft = completeDraft()..['q5_word_record'] = '';

      expect(issueNumbers(draft), [5]);
    });

    test('daily branch completes with only a daily record', () {
      final draft = completeDraft()
        ..['q5_selection'] = 'daily'
        ..['q5_word_record'] = '';

      expect(issueNumbers(draft), isEmpty);
    });

    test('word branch requires a word record', () {
      final draft = completeDraft()
        ..['q5_selection'] = 'word'
        ..['q5_word_record'] = '';

      expect(issueNumbers(draft), [5]);
    });

    test('none branch completes with a declaration', () {
      final draft = completeDraft()
        ..['q5_selection'] = 'none'
        ..['q5_no_record_declaration'] = '오늘은 기록 없이 머물렀습니다';

      expect(issueNumbers(draft), isEmpty);
    });

    test('rejects an unknown selection', () {
      expect(issueNumbers(completeDraft()..['q5_selection'] = 'etc'), [5]);
    });

    test('rejects an insufficient stage', () {
      expect(issueNumbers(completeDraft()..['q5_stage'] = 3), [5]);
    });
  });

  group('Q6 gratitude', () {
    test('accepts summary stage 2 and legacy stage 3, rejects stage 1', () {
      expect(
        issueNumbers(completeDraft()..['q6_stage'] = 3),
        isEmpty,
        reason: 'legacy stage 3 stays compatible',
      );
      expect(
        issueNumbers(completeDraft()..['q6_stage'] = 1),
        [6],
        reason: 'stage 1 is not finished',
      );
    });

    test('does not count identical duplicated gratitudes as three', () {
      final duplicate = {'person': '하나님', 'what': '오늘을 주심'};
      final draft = completeDraft()
        ..['q6_gratitudes'] = [duplicate, duplicate, duplicate];

      expect(issueNumbers(draft), [6]);
    });

    test('ignores gratitudes without a person or without content', () {
      final draft = completeDraft()
        ..['q6_gratitudes'] = [
          {'person': '', 'what': '이름 없음'},
          {'person': '가족'},
          {'person': '친구', 'what': '격려해 줌'},
        ];

      expect(issueNumbers(draft), [6]);
    });

    test('accepts a gratitude with only a reason', () {
      final draft = completeDraft()
        ..['q6_gratitudes'] = [
          {'person': '하나님', 'why': '오늘도 지켜 주셔서'},
          {'person': '가족', 'what': '함께해 줌'},
          {'person': '친구', 'what': '격려해 줌'},
        ];

      expect(issueNumbers(draft), isEmpty);
    });
  });

  group('Q7 action', () {
    test('requires action, reason and confirmation stage', () {
      expect(
        issueNumbers(completeDraft()..['q7_action'] = ''),
        [7],
        reason: 'action is empty',
      );
      expect(
        issueNumbers(completeDraft()..['q7_reason'] = '   '),
        [7],
        reason: 'reason is only whitespace',
      );
      expect(
        issueNumbers(completeDraft()..['q7_stage'] = 1),
        [7],
        reason: 'confirmation stage not reached',
      );
    });
  });

  group('status', () {
    test('every question is complete for a complete draft', () {
      for (var q = 1; q <= 7; q++) {
        expect(
          validator.status(completeDraft(), q),
          LifeDiaryQuestionCompletion.complete,
          reason: 'Q$q',
        );
      }
    });

    test('empty draft is notStarted', () {
      expect(validator.status({}, 3), LifeDiaryQuestionCompletion.notStarted);
    });

    test('partial progress is inProgress', () {
      expect(
        validator.status({'q3_stage': 2}, 3),
        LifeDiaryQuestionCompletion.inProgress,
        reason: 'Q3 stage started',
      );
      expect(
        validator.status({
          'q6_gratitudes': [
            {'person': '가족', 'what': '함께해 줌'},
          ],
        }, 6),
        LifeDiaryQuestionCompletion.inProgress,
        reason: 'Q6 has a gratitude before any stage',
      );
    });

    test('each question reports inProgress once started', () {
      final started = <int, Map<String, Object?>>{
        1: {'q1_detail': '오늘의 반응'},
        2: {'q2_partial_text': '고백 중'},
        4: {'q4_stage': 1},
        5: {'q5_stage': 1},
        7: {'q7_action': '먼저 연락하기'},
      };
      started.forEach((q, draft) {
        expect(
          validator.status(draft, q),
          LifeDiaryQuestionCompletion.inProgress,
          reason: 'Q$q',
        );
      });
    });

    test('unsupported question number is reported as notStarted', () {
      expect(validator.status({}, 8), LifeDiaryQuestionCompletion.notStarted);
    });
  });

  group('messages', () {
    // These strings are shown to users. If the copy changes on purpose,
    // update this test together with the screen text.
    test('each incomplete question has its guidance message', () {
      final messages = {
        for (final issue in validator.validate({}))
          issue.questionNumber: issue.message,
      };

      expect(messages, {
        1: '오늘 발견한 옛사람 기록과 확인 단계를 마쳐 주세요.',
        2: '1번에서 선택한 옛사람의 십자가 고백을 모두 마쳐 주세요.',
        3: '하나님 나라 발견과 누림 기록을 완료해 주세요.',
        4: '관계 사건을 사랑과 긍휼로 돌아보는 과정을 완료해 주세요.',
        5: '선택한 성령님과의 교제 기록을 완료해 주세요.',
        6: '감사 기록을 3개 이상 작성하고 6번을 완료해 주세요.',
        7: '실행할 일과 그 이유를 작성하고 확인 단계로 이동해 주세요.',
      });
    });
  });

  group('stored value types (current behavior)', () {
    // The validator expects num stages and bool flags. These tests document
    // what happens today if storage returns other types. If the validator is
    // later made tolerant (e.g. parsing '4' or 1), update these expectations.
    test('accepts a stage stored as a double, such as 4.0 from JSON', () {
      expect(issueNumbers(completeDraft()..['q3_stage'] = 4.0), isEmpty);
    });

    test('a stage stored as text throws instead of being read', () {
      expect(
        () => issueNumbers(completeDraft()..['q3_stage'] = '4'),
        throwsA(isA<TypeError>()),
      );
    });

    test('a flag stored as 1 (SQLite style) throws instead of being read', () {
      expect(
        () => issueNumbers(completeDraft()..['q1_completed'] = 1),
        throwsA(isA<TypeError>()),
      );
    });
  });
}