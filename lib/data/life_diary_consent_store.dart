import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../application/life_diary_privacy.dart';

class LifeDiaryConsentStore implements LifeDiaryConsentReader {
  LifeDiaryConsentStore(this.database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Database database;
  final DateTime Function() _clock;
  int _eventSequence = 0;

  Future<void> grant(LifeDiaryConsentGrant grant) async {
    await database.transaction((transaction) async {
      await transaction.insert('life_diary_consent_grant', {
        'grant_id': grant.grantId,
        'entry_id': grant.entryId,
        'recipient_type': grant.recipientType,
        'recipient_id': grant.recipientId,
        'scope': grant.scope.wireValue,
        'purpose': grant.purpose,
        'granted_at': grant.grantedAt.toUtc().toIso8601String(),
        'expires_at': grant.expiresAt?.toUtc().toIso8601String(),
        'revoked_at': grant.revokedAt?.toUtc().toIso8601String(),
      });
      await _appendSharedEvent(transaction, grant);
    });
  }

  Future<void> revoke(String grantId, {DateTime? at}) async {
    await database.update(
      'life_diary_consent_grant',
      {'revoked_at': (at ?? _clock()).toUtc().toIso8601String()},
      where: 'grant_id = ? AND revoked_at IS NULL',
      whereArgs: [grantId],
    );
  }

  @override
  Future<List<LifeDiaryConsentGrant>> activeGrantsFor(
    String entryId,
    String recipientId,
    DateTime at,
  ) async {
    final instant = at.toUtc().toIso8601String();
    final rows = await database.query(
      'life_diary_consent_grant',
      where: '''
entry_id = ? AND recipient_id = ? AND revoked_at IS NULL
AND (expires_at IS NULL OR expires_at > ?)
''',
      whereArgs: [entryId, recipientId, instant],
      orderBy: 'granted_at DESC',
    );
    return rows.map(_decode).toList(growable: false);
  }

  Future<void> _appendSharedEvent(
    DatabaseExecutor executor,
    LifeDiaryConsentGrant grant,
  ) async {
    _eventSequence++;
    final occurredAt = grant.grantedAt.toUtc().toIso8601String();
    await executor.insert('life_diary_revision_event', {
      'event_id': '${grant.entryId}-SHARED-$occurredAt-$_eventSequence',
      'entry_id': grant.entryId,
      'event_type': 'SHARED',
      'occurred_at': occurredAt,
      'metadata_json': jsonEncode({'scope': grant.scope.wireValue}),
    });
  }
}

LifeDiaryConsentGrant _decode(Map<String, Object?> row) =>
    LifeDiaryConsentGrant(
      grantId: row['grant_id'] as String,
      entryId: row['entry_id'] as String,
      recipientType: row['recipient_type'] as String,
      recipientId: row['recipient_id'] as String,
      scope: LifeDiaryShareScopeCodec.fromWire(row['scope'] as String),
      purpose: row['purpose'] as String,
      grantedAt: DateTime.parse(row['granted_at'] as String),
      expiresAt: row['expires_at'] == null
          ? null
          : DateTime.parse(row['expires_at'] as String),
      revokedAt: row['revoked_at'] == null
          ? null
          : DateTime.parse(row['revoked_at'] as String),
    );
