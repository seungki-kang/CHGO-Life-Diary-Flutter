enum LifeDiaryQuestionCompletion { notStarted, inProgress, complete }

class LifeDiaryCompletionIssue {
  final int questionNumber;
  final String message;

  const LifeDiaryCompletionIssue(this.questionNumber, this.message);
}

/// The seven old selves a believer can bring to the cross in Q1 and Q2.
const lifeDiaryOldSelves = <String>[
  '수치심',
  '죄책감',
  '두려움',
  '자기의(신념·고정관념)',
  '과거의 상처',
  '인정받고 싶은 욕구',
  '죽음의 공포',
];

class LifeDiaryCompletionValidator {
  const LifeDiaryCompletionValidator();

  static const _questionCount = 7;

  static const _q1CompleteStep = 4;
  static const _q3CompleteStage = 4;
  static const _q4CompleteStage = 5;
  static const _q5CompleteStage = 4;
  // Q6 uses stage 2 as its single canonical completion summary.
  // Older drafts that stored stage 3 remain compatible through >= 2.
  static const _q6CompleteStage = 2;
  static const _q6MinGratitudes = 3;
  static const _q7CompleteStage = 2;

  List<LifeDiaryCompletionIssue> validate(Map<String, Object?> draft) {
    final issues = <LifeDiaryCompletionIssue>[];
    for (var question = 1; question <= _questionCount; question++) {
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

  String? _incompleteReason(Map<String, Object?> draft, int question) =>
      switch (question) {
        1 => _q1Reason(draft),
        2 => _q2Reason(draft),
        3 => _q3Reason(draft),
        4 => _q4Reason(draft),
        5 => _q5Reason(draft),
        6 => _q6Reason(draft),
        7 => _q7Reason(draft),
        _ => '지원하지 않는 문항입니다.',
      };

  // Q1: discover today's old self and finish the confirmation step.
  String? _q1Reason(Map<String, Object?> draft) {
    const message = '오늘 발견한 옛사람 기록과 확인 단계를 마쳐 주세요.';
    final confirmed =
        _flag(draft, 'q1_completed') &&
        _number(draft, 'q1_step') >= _q1CompleteStep;
    if (!confirmed) return message;

    final recorded =
        _flag(draft, 'q1_no_old_self') ||
        (_text(draft, 'q1_detail').isNotEmpty &&
            _strings(draft, 'q1_old_selves').isNotEmpty &&
            draft['q1_awareness'] != null);
    return recorded ? null : message;
  }

  // Q2: confess every old self chosen in Q1 (all seven if Q1 found none).
  String? _q2Reason(Map<String, Object?> draft) {
    final required = _flag(draft, 'q1_no_old_self')
        ? lifeDiaryOldSelves
        : _strings(draft, 'q1_old_selves');
    final confessed = _strings(draft, 'q2_completed_old_selves').toSet();
    final allConfessed =
        required.isNotEmpty && required.every(confessed.contains);
    return allConfessed ? null : '1번에서 선택한 옛사람의 십자가 고백을 모두 마쳐 주세요.';
  }

  // Q3: discover and enjoy the kingdom of God.
  String? _q3Reason(Map<String, Object?> draft) =>
      _number(draft, 'q3_stage') >= _q3CompleteStage
      ? null
      : '하나님 나라 발견과 누림 기록을 완료해 주세요.';

  // Q4: look back on a relationship with love and compassion.
  String? _q4Reason(Map<String, Object?> draft) =>
      _number(draft, 'q4_stage') >= _q4CompleteStage
      ? null
      : '관계 사건을 사랑과 긍휼로 돌아보는 과정을 완료해 주세요.';

  // Q5: record fellowship with the Holy Spirit for the chosen branch.
  String? _q5Reason(Map<String, Object?> draft) {
    final selection = _text(draft, 'q5_selection');
    final hasDaily = _text(draft, 'q5_daily_record').isNotEmpty;
    final hasWord = _text(draft, 'q5_word_record').isNotEmpty;
    final hasDeclaration = _text(
      draft,
      'q5_no_record_declaration',
    ).isNotEmpty;
    final branchComplete = switch (selection) {
      'daily' => hasDaily,
      'word' => hasWord,
      'both' => hasDaily && hasWord,
      'none' => hasDeclaration,
      _ => false,
    };
    return _number(draft, 'q5_stage') >= _q5CompleteStage && branchComplete
        ? null
        : '선택한 성령님과의 교제 기록을 완료해 주세요.';
  }

  // Q6: write at least three distinct gratitudes.
  String? _q6Reason(Map<String, Object?> draft) {
    final gratitudes = _countDistinctGratitudes(draft);
    return _number(draft, 'q6_stage') >= _q6CompleteStage &&
            gratitudes >= _q6MinGratitudes
        ? null
        : '감사 기록을 3개 이상 작성하고 6번을 완료해 주세요.';
  }

  // Q7: decide one action and why, then reach the confirmation step.
  String? _q7Reason(Map<String, Object?> draft) =>
      _number(draft, 'q7_stage') >= _q7CompleteStage &&
          _text(draft, 'q7_action').isNotEmpty &&
          _text(draft, 'q7_reason').isNotEmpty
      ? null
      : '실행할 일과 그 이유를 작성하고 확인 단계로 이동해 주세요.';

  /// A gratitude counts when it names a person and says what or why.
  /// Identical entries (same person, what, why and type) count once.
  int _countDistinctGratitudes(Map<String, Object?> draft) =>
      _maps(draft, 'q6_gratitudes')
          .where(
            (item) =>
                _mapText(item, 'person').isNotEmpty &&
                (_mapText(item, 'what').isNotEmpty ||
                    _mapText(item, 'why').isNotEmpty),
          )
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

  bool _hasStarted(Map<String, Object?> draft, int question) =>
      switch (question) {
        1 =>
          _text(draft, 'q1_detail').isNotEmpty ||
              _strings(draft, 'q1_old_selves').isNotEmpty ||
              _flag(draft, 'q1_no_old_self'),
        2 =>
          _strings(draft, 'q2_completed_old_selves').isNotEmpty ||
              _text(draft, 'q2_partial_text').isNotEmpty,
        3 => _number(draft, 'q3_stage') > 0,
        4 => _number(draft, 'q4_stage') > 0,
        5 => _number(draft, 'q5_stage') > 0,
        6 =>
          _number(draft, 'q6_stage') > 0 ||
              _maps(draft, 'q6_gratitudes').isNotEmpty,
        7 =>
          _number(draft, 'q7_stage') > 0 ||
              _text(draft, 'q7_action').isNotEmpty ||
              _text(draft, 'q7_reason').isNotEmpty,
        _ => false,
      };

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