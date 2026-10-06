/// Canonical, storage-neutral domain models for the JesusLife Life Diary.
///
/// These models implement JL-LD-002 / LD-FL-001. They deliberately contain no
/// Flutter or database imports so the same contract can be tested and reused
/// by repositories, services, and widgets.
library;

const lifeDiarySchemaVersion = '1.0.0';
const q2CanonicalConfessionKo = '예수님과 함께 십자가에 못 박혀 죽었습니다';

abstract final class LifeDiaryCanonicalIds {
  static const questionIds = <String>[
    'JL-LD-Q01',
    'JL-LD-Q02',
    'JL-LD-Q03',
    'JL-LD-Q04',
    'JL-LD-Q05',
    'JL-LD-Q06',
    'JL-LD-Q07',
  ];

  static const oldPersonIds = <String>{
    'JL-OLD-01',
    'JL-OLD-02',
    'JL-OLD-03',
    'JL-OLD-04',
    'JL-OLD-05',
    'JL-OLD-06',
    'JL-OLD-07',
  };

  static const fruitIds = <String>{
    'JL-FRUIT-01',
    'JL-FRUIT-02',
    'JL-FRUIT-03',
    'JL-FRUIT-04',
    'JL-FRUIT-05',
    'JL-FRUIT-06',
    'JL-FRUIT-07',
    'JL-FRUIT-08',
    'JL-FRUIT-09',
  };
}

enum LifeDiaryEntryStatus { draft, completed, reopened, deleted }

enum KingdomContext { inner, community }

enum CommunionType { asked, whisper, scriptureInsight, noneWithThanks }

extension LifeDiaryEntryStatusCodec on LifeDiaryEntryStatus {
  String get wireValue => switch (this) {
    LifeDiaryEntryStatus.draft => 'DRAFT',
    LifeDiaryEntryStatus.completed => 'COMPLETED',
    LifeDiaryEntryStatus.reopened => 'REOPENED',
    LifeDiaryEntryStatus.deleted => 'DELETED',
  };

  static LifeDiaryEntryStatus fromWire(String value) => switch (value) {
    'DRAFT' => LifeDiaryEntryStatus.draft,
    'COMPLETED' => LifeDiaryEntryStatus.completed,
    'REOPENED' => LifeDiaryEntryStatus.reopened,
    'DELETED' => LifeDiaryEntryStatus.deleted,
    _ => throw FormatException('Unknown Life Diary status: $value'),
  };
}

extension KingdomContextCodec on KingdomContext {
  String get wireValue => switch (this) {
    KingdomContext.inner => 'INNER',
    KingdomContext.community => 'COMMUNITY',
  };

  static KingdomContext fromWire(String value) => switch (value) {
    'INNER' => KingdomContext.inner,
    'COMMUNITY' => KingdomContext.community,
    _ => throw FormatException('Unknown kingdom context: $value'),
  };
}

extension CommunionTypeCodec on CommunionType {
  String get wireValue => switch (this) {
    CommunionType.asked => 'ASKED',
    CommunionType.whisper => 'WHISPER',
    CommunionType.scriptureInsight => 'SCRIPTURE_INSIGHT',
    CommunionType.noneWithThanks => 'NONE_WITH_THANKS',
  };

  static CommunionType fromWire(String value) => switch (value) {
    'ASKED' => CommunionType.asked,
    'WHISPER' => CommunionType.whisper,
    'SCRIPTURE_INSIGHT' => CommunionType.scriptureInsight,
    'NONE_WITH_THANKS' => CommunionType.noneWithThanks,
    _ => throw FormatException('Unknown communion type: $value'),
  };
}

List<String> _canonicalIds(
  Iterable<String> values,
  Set<String> allowed,
  String fieldName,
) {
  final result = values.toSet().toList(growable: false);
  final invalid = result.where((value) => !allowed.contains(value)).toList();
  if (invalid.isNotEmpty) {
    throw FormatException(
      '$fieldName contains invalid Canonical IDs: $invalid',
    );
  }
  return result;
}

List<String> _stringList(Object? value, String fieldName) {
  if (value is! List) throw FormatException('$fieldName must be a list');
  return value
      .map((item) {
        if (item is! String)
          throw FormatException('$fieldName must contain strings');
        return item;
      })
      .toList(growable: false);
}

Map<String, Object?> _map(Object? value, String fieldName) {
  if (value is! Map) throw FormatException('$fieldName must be an object');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

class Q1Payload {
  Q1Payload({required this.narrative, required Iterable<String> oldPersonIds})
    : oldPersonIds = _canonicalIds(
        oldPersonIds,
        LifeDiaryCanonicalIds.oldPersonIds,
        'old_person_ids',
      );

  final String narrative;
  final List<String> oldPersonIds;

  Map<String, Object?> toJson() => {
    'narrative': narrative,
    'old_person_ids': oldPersonIds,
  };

  factory Q1Payload.fromJson(Map<String, Object?> json) => Q1Payload(
    narrative: json['narrative'] as String? ?? '',
    oldPersonIds: _stringList(json['old_person_ids'], 'old_person_ids'),
  );
}

class Q2Payload {
  Q2Payload({
    this.confession = q2CanonicalConfessionKo,
    required this.explanationVersion,
    this.acknowledgedAt,
    required Iterable<String> appliedOldPersonIds,
  }) : appliedOldPersonIds = _canonicalIds(
         appliedOldPersonIds,
         LifeDiaryCanonicalIds.oldPersonIds,
         'applied_old_person_ids',
       ) {
    if (confession != q2CanonicalConfessionKo) {
      throw const FormatException(
        'Q2 confession must match the Korean Canonical',
      );
    }
  }

  final String confession;
  final String explanationVersion;
  final DateTime? acknowledgedAt;
  final List<String> appliedOldPersonIds;

  Map<String, Object?> toJson() => {
    'confession': confession,
    'explanation_version': explanationVersion,
    'acknowledged_at': acknowledgedAt?.toUtc().toIso8601String(),
    'applied_old_person_ids': appliedOldPersonIds,
  };

  factory Q2Payload.fromJson(Map<String, Object?> json) => Q2Payload(
    confession: json['confession'] as String? ?? '',
    explanationVersion: json['explanation_version'] as String? ?? '',
    acknowledgedAt: json['acknowledged_at'] == null
        ? null
        : DateTime.parse(json['acknowledged_at'] as String),
    appliedOldPersonIds: _stringList(
      json['applied_old_person_ids'],
      'applied_old_person_ids',
    ),
  );
}

class Q3Payload {
  Q3Payload({
    required Iterable<KingdomContext> contexts,
    required this.narrative,
    this.declaration = '',
    required Iterable<String> fruitIds,
  }) : contexts = contexts.toSet().toList(growable: false),
       fruitIds = _canonicalIds(
         fruitIds,
         LifeDiaryCanonicalIds.fruitIds,
         'fruit_ids',
       );

  final List<KingdomContext> contexts;
  final String narrative;
  final String declaration;
  final List<String> fruitIds;

  Map<String, Object?> toJson() => {
    'contexts': contexts.map((value) => value.wireValue).toList(),
    'narrative': narrative,
    'declaration': declaration,
    'fruit_ids': fruitIds,
  };

  factory Q3Payload.fromJson(Map<String, Object?> json) => Q3Payload(
    contexts: _stringList(
      json['contexts'],
      'contexts',
    ).map(KingdomContextCodec.fromWire),
    narrative: json['narrative'] as String? ?? '',
    declaration: json['declaration'] as String? ?? '',
    fruitIds: _stringList(json['fruit_ids'], 'fruit_ids'),
  );
}

class Q4Payload {
  const Q4Payload({required this.narrative, required this.revisitedQ1Q2});

  final String narrative;
  final bool revisitedQ1Q2;

  Map<String, Object?> toJson() => {
    'narrative': narrative,
    'revisited_q1_q2': revisitedQ1Q2,
  };

  factory Q4Payload.fromJson(Map<String, Object?> json) => Q4Payload(
    narrative: json['narrative'] as String? ?? '',
    revisitedQ1Q2: json['revisited_q1_q2'] as bool? ?? false,
  );
}

class Q5Payload {
  const Q5Payload({required this.communionType, required this.narrative});

  final CommunionType communionType;
  final String narrative;

  Map<String, Object?> toJson() => {
    'communion_type': communionType.wireValue,
    'narrative': narrative,
  };

  factory Q5Payload.fromJson(Map<String, Object?> json) => Q5Payload(
    communionType: CommunionTypeCodec.fromWire(
      json['communion_type'] as String? ?? '',
    ),
    narrative: json['narrative'] as String? ?? '',
  );
}

class GratitudeItem {
  const GratitudeItem({this.who = '', required this.what, required this.why});

  final String who;
  final String what;
  final String why;

  Map<String, Object?> toJson() => {'who': who, 'what': what, 'why': why};

  factory GratitudeItem.fromJson(Map<String, Object?> json) => GratitudeItem(
    who: json['who'] as String? ?? '',
    what: json['what'] as String? ?? '',
    why: json['why'] as String? ?? '',
  );
}

class Q6Payload {
  Q6Payload({required Iterable<GratitudeItem> items})
    : items = List.unmodifiable(items);

  final List<GratitudeItem> items;

  Map<String, Object?> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory Q6Payload.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    if (items is! List) throw const FormatException('items must be a list');
    return Q6Payload(
      items: items.map((item) => GratitudeItem.fromJson(_map(item, 'item'))),
    );
  }
}

class Q7Payload {
  Q7Payload({required Iterable<String> actions})
    : actions = List.unmodifiable(actions);

  final List<String> actions;

  Map<String, Object?> toJson() => {'actions': actions};

  factory Q7Payload.fromJson(Map<String, Object?> json) =>
      Q7Payload(actions: _stringList(json['actions'], 'actions'));
}

class LifeDiaryQuestions {
  const LifeDiaryQuestions({
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
    required this.q5,
    required this.q6,
    required this.q7,
  });

  final Q1Payload q1;
  final Q2Payload q2;
  final Q3Payload q3;
  final Q4Payload q4;
  final Q5Payload q5;
  final Q6Payload q6;
  final Q7Payload q7;

  Map<String, Object?> toJson() => {
    'q1': q1.toJson(),
    'q2': q2.toJson(),
    'q3': q3.toJson(),
    'q4': q4.toJson(),
    'q5': q5.toJson(),
    'q6': q6.toJson(),
    'q7': q7.toJson(),
  };

  factory LifeDiaryQuestions.fromJson(Map<String, Object?> json) =>
      LifeDiaryQuestions(
        q1: Q1Payload.fromJson(_map(json['q1'], 'q1')),
        q2: Q2Payload.fromJson(_map(json['q2'], 'q2')),
        q3: Q3Payload.fromJson(_map(json['q3'], 'q3')),
        q4: Q4Payload.fromJson(_map(json['q4'], 'q4')),
        q5: Q5Payload.fromJson(_map(json['q5'], 'q5')),
        q6: Q6Payload.fromJson(_map(json['q6'], 'q6')),
        q7: Q7Payload.fromJson(_map(json['q7'], 'q7')),
      );
}

class LifeDiaryEntry {
  LifeDiaryEntry({
    required this.entryId,
    required this.ownerUserId,
    required this.seasonNumber,
    required this.sessionNumber,
    required this.entryDate,
    required this.status,
    this.schemaVersion = lifeDiarySchemaVersion,
    required this.canonicalVersion,
    required this.questions,
  }) {
    if (entryId.isEmpty || ownerUserId.isEmpty) {
      throw const FormatException('Entry and owner IDs must not be empty');
    }
    if (seasonNumber < 1 || sessionNumber < 1 || sessionNumber > 50) {
      throw const FormatException(
        'Season must be >= 1 and session must be 1..50',
      );
    }
    if (schemaVersion != lifeDiarySchemaVersion) {
      throw FormatException('Unsupported schema version: $schemaVersion');
    }
    if (canonicalVersion.isEmpty) {
      throw const FormatException('Canonical version must not be empty');
    }
  }

  final String entryId;
  final String ownerUserId;
  final int seasonNumber;
  final int sessionNumber;
  final DateTime entryDate;
  final LifeDiaryEntryStatus status;
  final String schemaVersion;
  final String canonicalVersion;
  final LifeDiaryQuestions questions;

  Map<String, Object?> toJson() => {
    'entry_id': entryId,
    'owner_user_id': ownerUserId,
    'season_number': seasonNumber,
    'session_number': sessionNumber,
    'entry_date': _dateOnly(entryDate),
    'status': status.wireValue,
    'schema_version': schemaVersion,
    'canonical_version': canonicalVersion,
    'questions': questions.toJson(),
  };

  factory LifeDiaryEntry.fromJson(Map<String, Object?> json) => LifeDiaryEntry(
    entryId: json['entry_id'] as String? ?? '',
    ownerUserId: json['owner_user_id'] as String? ?? '',
    seasonNumber: json['season_number'] as int? ?? 0,
    sessionNumber: json['session_number'] as int? ?? 0,
    entryDate: DateTime.parse(json['entry_date'] as String? ?? ''),
    status: LifeDiaryEntryStatusCodec.fromWire(json['status'] as String? ?? ''),
    schemaVersion: json['schema_version'] as String? ?? '',
    canonicalVersion: json['canonical_version'] as String? ?? '',
    questions: LifeDiaryQuestions.fromJson(
      _map(json['questions'], 'questions'),
    ),
  );
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
