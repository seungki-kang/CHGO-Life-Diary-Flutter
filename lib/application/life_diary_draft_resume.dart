class LifeDiaryDraftResume {
  const LifeDiaryDraftResume._();

  static int questionNumber(Map<String, Object?> draft) {
    if (_hasQ7(draft)) return 7;
    if (_hasQ6(draft)) return 6;
    if (_hasQ5(draft)) return 5;
    if (_hasQ4(draft)) return 4;
    if (_hasQ3(draft)) return 3;
    if (_hasQ2(draft)) return 2;
    return 1;
  }

  static bool _hasQ2(Map<String, Object?> value) =>
      _strings(value['q2_completed_old_selves']).isNotEmpty ||
      _text(value['q2_partial_text']).isNotEmpty ||
      _number(value['q2_current_index']) > 0;

  static bool _hasQ3(Map<String, Object?> value) =>
      _strings(value['q3_selected_realms']).isNotEmpty ||
      _text(value['q3_event']).isNotEmpty ||
      _number(value['q3_stage']) > 0;

  static bool _hasQ4(Map<String, Object?> value) =>
      _text(value['q4_event']).isNotEmpty ||
      _text(value['q4_response']).isNotEmpty ||
      _number(value['q4_stage']) > 0;

  static bool _hasQ5(Map<String, Object?> value) =>
      value['q5_selection'] != null ||
      _text(value['q5_daily_record']).isNotEmpty ||
      _number(value['q5_stage']) > 0;

  static bool _hasQ6(Map<String, Object?> value) =>
      (value['q6_gratitudes'] as List? ?? const []).isNotEmpty ||
      _number(value['q6_stage']) > 0;

  static bool _hasQ7(Map<String, Object?> value) =>
      _text(value['q7_action']).isNotEmpty ||
      _text(value['q7_reason']).isNotEmpty ||
      _number(value['q7_stage']) > 0;
}

String _text(Object? value) => value?.toString().trim() ?? '';
int _number(Object? value) => (value as num?)?.toInt() ?? 0;
List<String> _strings(Object? value) =>
    (value as List? ?? const []).map((item) => item.toString()).toList();
