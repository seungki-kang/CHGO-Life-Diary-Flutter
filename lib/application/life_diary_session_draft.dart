part of '../main.dart';

final TextInputFormatter keepMyRighteousnessWording =
    TextInputFormatter.withFunction((oldValue, newValue) {
      if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
        return newValue;
      }
      final corrected = newValue.text.replaceAll('나의 이는', '나의 의는');
      if (corrected == newValue.text) return newValue;
      return newValue.copyWith(
        text: corrected,
        selection: newValue.selection,
        composing: TextRange.empty,
      );
    });

String normalizeDiarySentence(String text) =>
    text.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[.。]+$'), '');

String characterDifferenceGuidance(String typedText, String expectedText) {
  final typed = normalizeDiarySentence(typedText);
  final expected = normalizeDiarySentence(expectedText);
  final rows = typed.length + 1;
  final columns = expected.length + 1;
  final matrix = List.generate(rows, (_) => List<int>.filled(columns, 0));

  for (var i = 0; i < rows; i++) matrix[i][0] = i;
  for (var j = 0; j < columns; j++) matrix[0][j] = j;
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      final cost = typed.codeUnitAt(i - 1) == expected.codeUnitAt(j - 1)
          ? 0
          : 1;
      final deletion = matrix[i - 1][j] + 1;
      final insertion = matrix[i][j - 1] + 1;
      final replacement = matrix[i - 1][j - 1] + cost;
      matrix[i][j] = [
        deletion,
        insertion,
        replacement,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  var i = typed.length;
  var j = expected.length;
  final differences = <String>[];
  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        typed.codeUnitAt(i - 1) == expected.codeUnitAt(j - 1)) {
      i--;
      j--;
      continue;
    }
    if (i > 0 && j > 0 && matrix[i][j] == matrix[i - 1][j - 1] + 1) {
      differences.add(
        '${j}번째 글자 “${typed[i - 1]}”를 “${expected[j - 1]}”로 수정해 주세요.',
      );
      i--;
      j--;
    } else if (i > 0 && matrix[i][j] == matrix[i - 1][j] + 1) {
      differences.add('${i}번째에 입력한 “${typed[i - 1]}”는 더 들어간 글자입니다. 삭제해 주세요.');
      i--;
    } else if (j > 0) {
      differences.add('${j}번째에 “${expected[j - 1]}”가 빠졌습니다. 넣어 주세요.');
      j--;
    }
  }

  if (differences.isEmpty) return '위 문장을 다시 확인해 주세요.';
  final ordered = differences.reversed.toList();
  final visible = ordered.take(5).map((message) => '• $message').join('\n');
  final remainder = ordered.length > 5
      ? '\n• 이 밖에도 ${ordered.length - 5}곳을 더 확인해 주세요.'
      : '';
  return '다음 글자를 확인해 주세요.\n$visible$remainder';
}

class LifeDiarySessionDraft {
  DateTime? diaryDate;
  int seasonNumber = 1;
  int sessionNumber = 1;

  String get progressLabel => '시즌 $seasonNumber · $sessionNumber/50회';
  String q1Detail = '';
  final Set<String> q1OldSelves = {};
  bool q1NoOldSelf = false;
  String? q1Awareness;
  double q1AwarenessPercent = 50;
  int q1Step = 1;
  final List<String> q2CompletedOldSelves = [];
  String q2PartialText = '';
  int q2CurrentIndex = 0;

  int q3Stage = 0;
  final Set<String> q3SelectedRealms = {};
  final Set<String> q3SelectedFruits = {};
  final List<Map<String, String>> q3EnjoymentRecords = [];
  final List<String> q3RealmQueue = [];
  final List<String> q3MissingFruits = [];
  String q3Event = '';
  String q3Discovery = '';
  String q3Declaration = '';
  String q3Enjoyment = '';
  String q3Identity = '';
  int q3RealmIndex = 0;
  int q3MissingIndex = 0;
  bool q3NoEnjoyment = false;
  bool q3NoSpecificFruit = false;
  int? q3EditingRecordIndex;

  int q4Stage = 0;
  String q4Person = '';
  String q4Event = '';
  String q4Response = '';
  String q4Love = '';
  String q4Declaration = '';
  String q4AdditionalConfession = '';
  bool q4NoRecord = false;
  bool q4Judged = false;
  bool q4Resisted = false;
  bool q4ViewedWithLove = false;
  bool q4ViewedWithCompassion = false;
  String? q4NewDiscoveryChoice;
  final Set<String> q4AdditionalOldSelves = {};
  bool q4OwnershipRealized = false;
  int q4DeclarationIndex = 0;
  int q4AdditionalIndex = 0;
  final List<String> q4AdditionalQueue = [];

  int q5Stage = 0;
  String? q5Selection;
  String q5DailyRecord = '';
  String q5WordRecord = '';
  String q5NoRecordDeclaration = '';

  int q6Stage = 0;
  final List<Map<String, String>> q6Gratitudes = [];
  String q6Person = '';
  String q6What = '';
  String q6Why = '';
  String? q6SituationType;
  int? q6EditingIndex;

  int q7Stage = 0;
  String q7Action = '';
  String q7Reason = '';
  bool q7CoachingRequested = false;
  String q7CoachingNote = '';
  bool q7FinalCompleted = false;

  Map<String, Object?> toJson() => {
    'season_number': seasonNumber,
    'session_number': sessionNumber,
    'q1_detail': q1Detail,
    'q1_old_selves': q1OldSelves.toList(),
    'q1_no_old_self': q1NoOldSelf,
    'q1_awareness': q1Awareness,
    'q1_awareness_percent': q1AwarenessPercent,
    'q1_step': q1Step,
    'q2_completed_old_selves': q2CompletedOldSelves,
    'q2_partial_text': q2PartialText,
    'q2_current_index': q2CurrentIndex,
    'q3_stage': q3Stage,
    'q3_selected_realms': q3SelectedRealms.toList(),
    'q3_selected_fruits': q3SelectedFruits.toList(),
    'q3_enjoyment_records': q3EnjoymentRecords,
    'q3_realm_queue': q3RealmQueue,
    'q3_missing_fruits': q3MissingFruits,
    'q3_event': q3Event,
    'q3_discovery': q3Discovery,
    'q3_declaration': q3Declaration,
    'q3_enjoyment': q3Enjoyment,
    'q3_identity': q3Identity,
    'q3_realm_index': q3RealmIndex,
    'q3_missing_index': q3MissingIndex,
    'q3_no_enjoyment': q3NoEnjoyment,
    'q3_no_specific_fruit': q3NoSpecificFruit,
    'q3_editing_record_index': q3EditingRecordIndex,
    'q4_stage': q4Stage,
    'q4_person': q4Person,
    'q4_event': q4Event,
    'q4_response': q4Response,
    'q4_love': q4Love,
    'q4_declaration': q4Declaration,
    'q4_additional_confession': q4AdditionalConfession,
    'q4_no_record': q4NoRecord,
    'q4_judged': q4Judged,
    'q4_resisted': q4Resisted,
    'q4_viewed_with_love': q4ViewedWithLove,
    'q4_viewed_with_compassion': q4ViewedWithCompassion,
    'q4_new_discovery_choice': q4NewDiscoveryChoice,
    'q4_additional_old_selves': q4AdditionalOldSelves.toList(),
    'q4_ownership_realized': q4OwnershipRealized,
    'q4_declaration_index': q4DeclarationIndex,
    'q4_additional_index': q4AdditionalIndex,
    'q4_additional_queue': q4AdditionalQueue,
    'q5_stage': q5Stage,
    'q5_selection': q5Selection,
    'q5_daily_record': q5DailyRecord,
    'q5_word_record': q5WordRecord,
    'q5_no_record_declaration': q5NoRecordDeclaration,
    'q6_stage': q6Stage,
    'q6_gratitudes': q6Gratitudes,
    'q6_person': q6Person,
    'q6_what': q6What,
    'q6_why': q6Why,
    'q6_situation_type': q6SituationType,
    'q6_editing_index': q6EditingIndex,
    'q7_stage': q7Stage,
    'q7_action': q7Action,
    'q7_reason': q7Reason,
    'q7_coaching_requested': q7CoachingRequested,
    'q7_coaching_note': q7CoachingNote,
    'q7_final_completed': q7FinalCompleted,
  };

  void loadJson(DateTime date, Map<String, Object?> json) {
    reset(date);
    String text(String key) => json[key] as String? ?? '';
    bool flag(String key) => json[key] as bool? ?? false;
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    List<String> strings(String key) => (json[key] as List? ?? const [])
        .map((value) => value.toString())
        .toList();

    seasonNumber = json.containsKey('season_number')
        ? number('season_number')
        : 1;
    sessionNumber = json.containsKey('session_number')
        ? number('session_number')
        : 1;

    q1Detail = text('q1_detail');
    q1OldSelves.addAll(strings('q1_old_selves'));
    q1NoOldSelf = flag('q1_no_old_self');
    q1Awareness = json['q1_awareness'] as String?;
    q1AwarenessPercent =
        (json['q1_awareness_percent'] as num?)?.toDouble() ?? 50;
    q1Step = json.containsKey('q1_step') ? number('q1_step') : 1;
    q2CompletedOldSelves.addAll(strings('q2_completed_old_selves'));
    q2PartialText = text('q2_partial_text');
    q2CurrentIndex = number('q2_current_index');
    q3Stage = number('q3_stage');
    q3SelectedRealms.addAll(strings('q3_selected_realms'));
    q3SelectedFruits.addAll(strings('q3_selected_fruits'));
    q3EnjoymentRecords.addAll(
      (json['q3_enjoyment_records'] as List? ?? const []).whereType<Map>().map(
        (value) =>
            value.map((key, item) => MapEntry(key.toString(), item.toString())),
      ),
    );
    q3RealmQueue.addAll(strings('q3_realm_queue'));
    q3MissingFruits.addAll(strings('q3_missing_fruits'));
    q3Event = text('q3_event');
    q3Discovery = text('q3_discovery');
    q3Declaration = text('q3_declaration');
    q3Enjoyment = text('q3_enjoyment');
    q3Identity = text('q3_identity');
    q3RealmIndex = number('q3_realm_index');
    q3MissingIndex = number('q3_missing_index');
    q3NoEnjoyment = flag('q3_no_enjoyment');
    q3NoSpecificFruit = flag('q3_no_specific_fruit');
    q3EditingRecordIndex = (json['q3_editing_record_index'] as num?)?.toInt();
    q4Stage = number('q4_stage');
    q4Person = text('q4_person');
    q4Event = text('q4_event');
    q4Response = text('q4_response');
    q4Love = text('q4_love');
    q4Declaration = text('q4_declaration');
    q4AdditionalConfession = text('q4_additional_confession');
    q4NoRecord = flag('q4_no_record');
    q4Judged = flag('q4_judged');
    q4Resisted = flag('q4_resisted');
    q4ViewedWithLove = flag('q4_viewed_with_love');
    q4ViewedWithCompassion = flag('q4_viewed_with_compassion');
    q4NewDiscoveryChoice = json['q4_new_discovery_choice'] as String?;
    q4AdditionalOldSelves.addAll(strings('q4_additional_old_selves'));
    q4OwnershipRealized = flag('q4_ownership_realized');
    q4DeclarationIndex = number('q4_declaration_index');
    q4AdditionalIndex = number('q4_additional_index');
    q4AdditionalQueue.addAll(strings('q4_additional_queue'));
    q5Stage = number('q5_stage');
    q5Selection = json['q5_selection'] as String?;
    q5DailyRecord = text('q5_daily_record');
    q5WordRecord = text('q5_word_record');
    q5NoRecordDeclaration = text('q5_no_record_declaration');
    q6Stage = number('q6_stage');
    q6Gratitudes.addAll(
      (json['q6_gratitudes'] as List? ?? const []).whereType<Map>().map(
        (value) =>
            value.map((key, item) => MapEntry(key.toString(), item.toString())),
      ),
    );
    q6Person = text('q6_person');
    q6What = text('q6_what');
    q6Why = text('q6_why');
    q6SituationType = json['q6_situation_type'] as String?;
    q6EditingIndex = (json['q6_editing_index'] as num?)?.toInt();
    q7Stage = number('q7_stage');
    q7Action = text('q7_action');
    q7Reason = text('q7_reason');
    q7CoachingRequested = flag('q7_coaching_requested');
    q7CoachingNote = text('q7_coaching_note');
    q7FinalCompleted = flag('q7_final_completed');
  }

  void reset(DateTime date, {int season = 1, int session = 1}) {
    diaryDate = date;
    seasonNumber = season;
    sessionNumber = session;
    q1Detail = '';
    q1OldSelves.clear();
    q1NoOldSelf = false;
    q1Awareness = null;
    q1AwarenessPercent = 50;
    q1Step = 1;
    q2CompletedOldSelves.clear();
    q2PartialText = '';
    q2CurrentIndex = 0;
    q3Stage = 0;
    q3SelectedRealms.clear();
    q3SelectedFruits.clear();
    q3EnjoymentRecords.clear();
    q3RealmQueue.clear();
    q3MissingFruits.clear();
    q3Event = '';
    q3Discovery = '';
    q3Declaration = '';
    q3Enjoyment = '';
    q3Identity = '';
    q3RealmIndex = 0;
    q3MissingIndex = 0;
    q3NoEnjoyment = false;
    q3NoSpecificFruit = false;
    q3EditingRecordIndex = null;
    q4Stage = 0;
    q4Person = '';
    q4Event = '';
    q4Response = '';
    q4Love = '';
    q4Declaration = '';
    q4AdditionalConfession = '';
    q4NoRecord = false;
    q4Judged = false;
    q4Resisted = false;
    q4ViewedWithLove = false;
    q4ViewedWithCompassion = false;
    q4NewDiscoveryChoice = null;
    q4AdditionalOldSelves.clear();
    q4OwnershipRealized = false;
    q4DeclarationIndex = 0;
    q4AdditionalIndex = 0;
    q4AdditionalQueue.clear();
    q5Stage = 0;
    q5Selection = null;
    q5DailyRecord = '';
    q5WordRecord = '';
    q5NoRecordDeclaration = '';
    q6Stage = 0;
    q6Gratitudes.clear();
    q6Person = '';
    q6What = '';
    q6Why = '';
    q6SituationType = null;
    q6EditingIndex = null;
    q7Stage = 0;
    q7Action = '';
    q7Reason = '';
    q7CoachingRequested = false;
    q7CoachingNote = '';
    q7FinalCompleted = false;
  }
}

// ============================================================
// V0.17a
// Life Diary Question 7
// ============================================================
