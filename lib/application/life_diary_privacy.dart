import '../domain/life_diary_models.dart';

enum LifeDiaryShareScope { summary, rawEntry }

extension LifeDiaryShareScopeCodec on LifeDiaryShareScope {
  String get wireValue => switch (this) {
    LifeDiaryShareScope.summary => 'SUMMARY',
    LifeDiaryShareScope.rawEntry => 'RAW_ENTRY',
  };

  static LifeDiaryShareScope fromWire(String value) => switch (value) {
    'SUMMARY' => LifeDiaryShareScope.summary,
    'RAW_ENTRY' => LifeDiaryShareScope.rawEntry,
    _ => throw FormatException('Unknown Life Diary share scope: $value'),
  };
}

class LifeDiaryConsentGrant {
  LifeDiaryConsentGrant({
    required this.grantId,
    required this.entryId,
    required this.recipientType,
    required this.recipientId,
    required this.scope,
    required this.purpose,
    required this.grantedAt,
    this.expiresAt,
    this.revokedAt,
  }) {
    if (grantId.isEmpty || entryId.isEmpty || recipientId.isEmpty) {
      throw const FormatException(
        'Grant, entry, and recipient IDs are required',
      );
    }
    if (recipientType.isEmpty || purpose.trim().isEmpty) {
      throw const FormatException('Recipient type and purpose are required');
    }
    if (expiresAt != null && !expiresAt!.isAfter(grantedAt)) {
      throw const FormatException('Grant expiry must be after grant time');
    }
  }

  final String grantId;
  final String entryId;
  final String recipientType;
  final String recipientId;
  final LifeDiaryShareScope scope;
  final String purpose;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  bool isActiveAt(DateTime instant) =>
      revokedAt == null && (expiresAt == null || instant.isBefore(expiresAt!));
}

abstract interface class LifeDiaryConsentReader {
  Future<List<LifeDiaryConsentGrant>> activeGrantsFor(
    String entryId,
    String recipientId,
    DateTime at,
  );
}

class LifeDiaryPrivacyService {
  const LifeDiaryPrivacyService(this.consentReader);

  final LifeDiaryConsentReader consentReader;

  Future<bool> canReadRaw({
    required String ownerUserId,
    required String requesterUserId,
    required String entryId,
    required DateTime at,
  }) async {
    if (ownerUserId == requesterUserId) return true;
    final grants = await consentReader.activeGrantsFor(
      entryId,
      requesterUserId,
      at,
    );
    return grants.any((grant) => grant.scope == LifeDiaryShareScope.rawEntry);
  }
}

abstract final class LifeDiaryAnalyticsExporter {
  static Map<String, Object?> growthEvent(LifeDiaryEntry entry) => {
    'entry_id': entry.entryId,
    'status': entry.status.wireValue,
    'schema_version': entry.schemaVersion,
    'canonical_version': entry.canonicalVersion,
    'season_number': entry.seasonNumber,
    'session_number': entry.sessionNumber,
    'entry_date': _dateOnly(entry.entryDate),
    'old_person_ids': entry.questions.q1.oldPersonIds,
    'kingdom_contexts': entry.questions.q3.contexts
        .map((context) => context.wireValue)
        .toList(growable: false),
    'fruit_ids': entry.questions.q3.fruitIds,
    'revisited_q1_q2': entry.questions.q4.revisitedQ1Q2,
    'communion_type': entry.questions.q5.communionType.wireValue,
    'gratitude_count': entry.questions.q6.items.length,
    'action_count': entry.questions.q7.actions.length,
  };
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
