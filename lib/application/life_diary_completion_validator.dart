enum LifeDiaryQuestionCompletion { notStarted, inProgress, complete }

class LifeDiaryCompletionIssue {
  final int questionNumber;
  final String message;

  const LifeDiaryCompletionIssue(this.questionNumber, this.message);
}

class LifeDiaryCompletionValidator {
  const LifeDiaryCompletionValidator();

  List<LifeDiaryCompletionIssue> validate(Map<String, Object?> draft) {
    final issues = <LifeDiaryCompletionIssue>[];
    for (var question = 1; question <= 7; question++) {
      final message = _incompleteReason(draft, question);
      if (message != null) {
        issues.add(LifeDiaryCompletionIssue(question, message));
      }
    }
    return issues;
  }

  LifeDiaryQuestionCompletion status(Map<String, Object?> draft, int question) {
    if (_incompleteReason(draft, question) == null) {
      return LifeDiaryQuestionCompletion.complete;
    }
    return _hasStarted(draft, question)
        ? LifeDiaryQuestionCompletion.inProgress
        : LifeDiaryQuestionCompletion.notStarted;
  }

  String? _incompleteReason(Map<String, Object?> draft, int question) {
    switch (question) {
      case 1:
        if (_flag(draft, 'q1_completed') &&
            _number(draft, 'q1_step') >= 4 &&
            (_flag(draft, 'q1_no_old_self') ||
                (_text(draft, 'q1_detail').isNotEmpty &&
                    _strings(draft, 'q1_old_selves').isNotEmpty &&
                    draft['q1_awareness'] != null))) {
          return null;
        }
        return '오늘 발견한 옛사람 기록과 확인 단계를 마쳐 주세요.';
      case 2:
        const allOldSelves = [
          '수치심',
          '죄책감',
          '두려움',
          '자기의(신념·고정관념)',
          '과거의 상처',
          '인정받고 싶은 욕구',
          '죽음의 공포',
        ];
        final requiredOldSelves = _flag(draft, 'q1_no_old_self')
            ? allOldSelves
            : _strings(draft, 'q1_old_selves');
        final completedOldSelves = _strings(
          draft,
          'q2_completed_old_selves',
        ).toSet();
        if (requiredOldSelves.isNotEmpty &&
            requiredOldSelves.every(completedOldSelves.contains)) {
          return null;
        }
        return '1번에서 선택한 옛사람의 십자가 고백을 모두 마쳐 주세요.';
      case 3:
        return _number(draft, 'q3_stage') >= 4
            ? null
            : '하나님 나라 발견과 누림 기록을 완료해 주세요.';
      case 4:
        return _number(draft, 'q4_stage') >= 5
            ? null
            : '관계 사건을 사랑과 긍휼로 돌아보는 과정을 완료해 주세요.';
      case 5:
        final selection = _text(draft, 'q5_selection');
        final hasDaily = _text(draft, 'q5_daily_record').isNotEmpty;
        final hasWord = _text(draft, 'q5_word_record').isNotEmpty;
        final hasNoRecordDeclaration = _text(
          draft,
          'q5_no_record_declaration',
        ).isNotEmpty;
        final branchComplete = switch (selection) {
          'daily' => hasDaily,
          'word' => hasWord,
          'both' => hasDaily && hasWord,
          'none' => hasNoRecordDeclaration,
          _ => false,
        };
        return _number(draft, 'q5_stage') >= 4 && branchComplete
            ? null
            : '선택한 성령님과의 교제 기록을 완료해 주세요.';
      case 6:
        final completeGratitudes = _maps(draft, 'q6_gratitudes')
            .where((item) {
              return _mapText(item, 'person').isNotEmpty &&
                  (_mapText(item, 'what').isNotEmpty ||
                      _mapText(item, 'why').isNotEmpty);
            })
            .map(
              (item) => [
                _mapText(item, 'person'),
                _mapText(item, 'what'),
                _mapText(item, 'why'),
                _mapText(item, 'type'),
              ].join('\u0000'),
            )
            .toSet()
            .length;
        // Q6 uses stage 2 as its single canonical completion summary.
        // Older drafts that stored stage 3 remain compatible through >= 2.
        return _number(draft, 'q6_stage') >= 2 && completeGratitudes >= 3
            ? null
            : '감사 기록을 3개 이상 작성하고 6번을 완료해 주세요.';
      case 7:
        return _number(draft, 'q7_stage') >= 2 &&
                _text(draft, 'q7_action').isNotEmpty &&
                _text(draft, 'q7_reason').isNotEmpty
            ? null
            : '실행할 일과 그 이유를 작성하고 확인 단계로 이동해 주세요.';
      default:
        return '지원하지 않는 문항입니다.';
    }
  }

  bool _hasStarted(Map<String, Object?> draft, int question) {
    switch (question) {
      case 1:
        return _text(draft, 'q1_detail').isNotEmpty ||
            _strings(draft, 'q1_old_selves').isNotEmpty ||
            _flag(draft, 'q1_no_old_self');
      case 2:
        return _strings(draft, 'q2_completed_old_selves').isNotEmpty ||
            _text(draft, 'q2_partial_text').isNotEmpty;
      case 3:
        return _number(draft, 'q3_stage') > 0;
      case 4:
        return _number(draft, 'q4_stage') > 0;
      case 5:
        return _number(draft, 'q5_stage') > 0;
      case 6:
        return _number(draft, 'q6_stage') > 0 ||
            _maps(draft, 'q6_gratitudes').isNotEmpty;
      case 7:
        return _number(draft, 'q7_stage') > 0 ||
            _text(draft, 'q7_action').isNotEmpty ||
            _text(draft, 'q7_reason').isNotEmpty;
      default:
        return false;
    }
  }

  String _text(Map<String, Object?> draft, String key) =>
      (draft[key] as String? ?? '').trim();
  int _number(Map<String, Object?> draft, String key) =>
      (draft[key] as num?)?.toInt() ?? 0;
  bool _flag(Map<String, Object?> draft, String key) =>
      draft[key] as bool? ?? false;
  List<String> _strings(Map<String, Object?> draft, String key) =>
      (draft[key] as List? ?? const []).map((value) => '$value').toList();
  List<Map<Object?, Object?>> _maps(Map<String, Object?> draft, String key) =>
      (draft[key] as List? ?? const [])
          .whereType<Map>()
          .map((value) => Map<Object?, Object?>.from(value))
          .toList();
  String _mapText(Map<Object?, Object?> map, String key) =>
      (map[key] as String? ?? '').trim();
}
