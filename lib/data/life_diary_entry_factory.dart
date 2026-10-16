import '../domain/life_diary_models.dart';

class LifeDiaryEntryFactory {
  LifeDiaryEntryFactory({
    this.ownerUserId = 'local-device-user',
    this.canonicalVersion = '1.0.0',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String ownerUserId;
  final String canonicalVersion;
  final DateTime Function() _clock;

  LifeDiaryEntry fromUiDraft(
    DateTime date,
    Map<String, Object?> draft, {
    required bool completed,
    int seasonNumber = 1,
    int sessionNumber = 1,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final oldPersonIds = _ids(_strings(draft['q1_old_selves']), _oldPersonIds);
    final q2Ids = _ids(
      _strings(draft['q2_completed_old_selves']),
      _oldPersonIds,
    );
    final contexts = _strings(draft['q3_selected_realms'])
        .map((value) => _kingdomContexts[value])
        .whereType<KingdomContext>();
    final fruitIds = _ids(_strings(draft['q3_selected_fruits']), _fruitIds);
    final gratitudeItems = _maps(draft['q6_gratitudes'])
        .map(
          (item) => GratitudeItem(
            who: _text(item['person']),
            what: _text(item['what']),
            why: _text(item['why']),
          ),
        )
        .where(
          (item) =>
              item.who.isNotEmpty ||
              item.what.isNotEmpty ||
              item.why.isNotEmpty,
        );
    final q3Text = _q3Text(draft);

    return LifeDiaryEntry(
      entryId:
          'JL-LD-LOCAL-${_compactDate(normalizedDate)}-'
          'S${seasonNumber.toString().padLeft(3, '0')}-'
          'N${sessionNumber.toString().padLeft(2, '0')}',
      ownerUserId: ownerUserId,
      seasonNumber: seasonNumber,
      sessionNumber: sessionNumber,
      entryDate: normalizedDate,
      status: completed
          ? LifeDiaryEntryStatus.completed
          : LifeDiaryEntryStatus.draft,
      canonicalVersion: canonicalVersion,
      questions: LifeDiaryQuestions(
        q1: Q1Payload(
          narrative: _text(draft['q1_detail']),
          oldPersonIds: oldPersonIds,
        ),
        q2: Q2Payload(
          explanationVersion: '1.0.0',
          acknowledgedAt: q2Ids.isEmpty ? null : _clock().toUtc(),
          appliedOldPersonIds: q2Ids,
        ),
        q3: Q3Payload(
          contexts: contexts,
          narrative: q3Text.narrative,
          declaration: q3Text.declaration,
          fruitIds: fruitIds,
        ),
        q4: Q4Payload(
          narrative: _joined([
            _text(draft['q4_person']),
            _text(draft['q4_event']),
            _text(draft['q4_response']),
            _text(draft['q4_love']),
            _text(draft['q4_declaration']),
            _text(draft['q4_additional_confession']),
          ]),
          revisitedQ1Q2: draft['q4_ownership_realized'] == true,
        ),
        q5: Q5Payload(
          communionType: _communionType(draft['q5_selection']),
          narrative: _joined([
            _text(draft['q5_daily_record']),
            _text(draft['q5_word_record']),
            _text(draft['q5_no_record_declaration']),
          ]),
        ),
        q6: Q6Payload(items: gratitudeItems),
        q7: Q7Payload(
          actions: [
            _text(draft['q7_action']),
            _text(draft['q7_reason']),
            if (draft['q7_coaching_requested'] == true)
              _text(draft['q7_coaching_note']),
          ].where((value) => value.isNotEmpty),
        ),
      ),
    );
  }
}

const _oldPersonIds = <String, String>{
  '수치심': 'JL-OLD-01',
  '죄책감': 'JL-OLD-02',
  '두려움': 'JL-OLD-03',
  '자기의(신념·고정관념)': 'JL-OLD-04',
  '나의 의(신념·고정관념)': 'JL-OLD-04',
  '과거의 상처': 'JL-OLD-05',
  '인정받고 싶은 욕구': 'JL-OLD-06',
  '인정욕구': 'JL-OLD-06',
  '죽음의 공포': 'JL-OLD-07',
};

const _fruitIds = <String, String>{
  '사랑': 'JL-FRUIT-01',
  '기쁨': 'JL-FRUIT-02',
  '희락': 'JL-FRUIT-02',
  '평안(화평)': 'JL-FRUIT-03',
  '화평': 'JL-FRUIT-03',
  '오래 참음': 'JL-FRUIT-04',
  '오래참음': 'JL-FRUIT-04',
  '자비': 'JL-FRUIT-05',
  '양선': 'JL-FRUIT-06',
  '충성': 'JL-FRUIT-07',
  '온유': 'JL-FRUIT-08',
  '절제': 'JL-FRUIT-09',
};

const _kingdomContexts = <String, KingdomContext>{
  '내 안': KingdomContext.inner,
  '공동체·관계 안': KingdomContext.community,
};

/// Q3 text for the stored entry.
///
/// The Q3 screen saves each realm's record into `q3_enjoyment_records` and then
/// clears its input fields, so the flat `q3_event` / `q3_declaration` fields are
/// empty once records exist. Reading only the flat fields stored every completed
/// Q3 as blank. Records are the source of truth; the flat fields remain a
/// fallback for older drafts written before records existed.
({String narrative, String declaration}) _q3Text(Map<String, Object?> draft) {
  final records = _maps(draft['q3_enjoyment_records']).where(
    (record) => [
      'event',
      'discovery',
      'declaration',
      'enjoyment',
    ].any((key) => _text(record[key]).isNotEmpty),
  );
  if (records.isEmpty) {
    return (
      narrative: _joined([
        _text(draft['q3_event']),
        _text(draft['q3_discovery']),
        _text(draft['q3_enjoyment']),
        _text(draft['q3_identity']),
      ]),
      declaration: _text(draft['q3_declaration']),
    );
  }
  return (
    narrative: _joined(
      records.map(
        (record) => _withRealm(
          record,
          _joined([_text(record['event']), _text(record['discovery'])]),
        ),
      ),
    ),
    declaration: _joined(
      records.map(
        (record) => _withRealm(
          record,
          _joined([_text(record['declaration']), _text(record['enjoyment'])]),
        ),
      ),
    ),
  );
}

/// Prefixes a record's text with its realm so two realms stay distinguishable.
String _withRealm(Map<String, Object?> record, String text) {
  if (text.isEmpty) return '';
  final realm = _text(record['realm']);
  return realm.isEmpty ? text : '[$realm] $text';
}

CommunionType _communionType(Object? selection) => switch (selection) {
  'daily' => CommunionType.whisper,
  'word' => CommunionType.scriptureInsight,
  'both' => CommunionType.asked,
  _ => CommunionType.noneWithThanks,
};

List<String> _strings(Object? value) =>
    (value as List? ?? const []).map((item) => item.toString()).toList();

List<Map<String, Object?>> _maps(Object? value) =>
    (value as List? ?? const []).whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();

List<String> _ids(Iterable<String> values, Map<String, String> mapping) =>
    values.map((value) => mapping[value]).whereType<String>().toSet().toList();

String _text(Object? value) => value?.toString().trim() ?? '';

String _joined(Iterable<String> values) =>
    values.where((value) => value.isNotEmpty).join('\n\n');

String _compactDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}'
    '${value.month.toString().padLeft(2, '0')}'
    '${value.day.toString().padLeft(2, '0')}';
