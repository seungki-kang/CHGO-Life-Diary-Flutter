import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/life_diary_models.dart';
import 'life_diary_repository.dart';

class SqliteLifeDiaryRepository implements LifeDiaryRepository {
  SqliteLifeDiaryRepository(this.database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Database database;
  final DateTime Function() _clock;
  int _eventSequence = 0;

  @override
  Future<void> save(LifeDiaryEntry entry) async {
    await database.transaction((transaction) async {
      final now = _clock().toUtc().toIso8601String();
      final existing = await transaction.query(
        'life_diary_entry',
        columns: const ['entry_id', 'status'],
        where: '''
entry_id = ? OR (
  owner_user_id = ? AND season_number = ? AND session_number = ?
)
''',
        whereArgs: [
          entry.entryId,
          entry.ownerUserId,
          entry.seasonNumber,
          entry.sessionNumber,
        ],
        limit: 1,
      );
      final effectiveEntryId = existing.isEmpty
          ? entry.entryId
          : existing.first['entry_id'] as String;
      final previousStatus = existing.isEmpty
          ? null
          : existing.first['status'] as String;

      if (existing.isEmpty) {
        await transaction.insert('life_diary_entry', {
          ..._entryRow(entry, entryId: effectiveEntryId),
          'created_at': now,
          'updated_at': now,
          'completed_at': _completedAt(entry, now),
        });
        await _appendEvent(transaction, effectiveEntryId, 'CREATED', now);
      } else {
        await transaction.update(
          'life_diary_entry',
          {
            ..._entryRow(entry, entryId: effectiveEntryId),
            'updated_at': now,
            'completed_at': _completedAt(entry, now),
          },
          where: 'entry_id = ?',
          whereArgs: [effectiveEntryId],
        );
      }

      final payloads = _questionPayloads(entry.questions);
      var changed = false;
      for (final questionId in LifeDiaryCanonicalIds.questionIds) {
        final payloadJson = jsonEncode(payloads[questionId]);
        final latest = await transaction.rawQuery(
          '''
SELECT payload_json, revision_number
FROM life_diary_answer
WHERE entry_id = ? AND question_id = ?
ORDER BY revision_number DESC
LIMIT 1
''',
          [effectiveEntryId, questionId],
        );
        if (latest.isNotEmpty && latest.first['payload_json'] == payloadJson) {
          continue;
        }

        final revision = latest.isEmpty
            ? 1
            : (latest.first['revision_number'] as int) + 1;
        await transaction.insert('life_diary_answer', {
          'entry_id': effectiveEntryId,
          'question_id': questionId,
          'payload_json': payloadJson,
          'privacy_class': 'PRIVATE_RAW',
          'revision_number': revision,
          'updated_at': now,
        });
        changed = true;
      }

      if (existing.isNotEmpty && changed) {
        await _appendEvent(transaction, effectiveEntryId, 'AUTOSAVED', now);
      }
      if (existing.isNotEmpty) {
        final nextStatus = entry.status.wireValue;
        if (previousStatus != nextStatus &&
            (nextStatus == 'REOPENED' || nextStatus == 'COMPLETED')) {
          await _appendEvent(transaction, effectiveEntryId, nextStatus, now);
        }
      }
    });
  }

  @override
  Future<LifeDiaryEntry?> findById(String entryId) async {
    final entries = await database.query(
      'life_diary_entry',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (entries.isEmpty) return null;
    return _decodeEntry(entries.first);
  }

  @override
  Future<List<LifeDiaryEntry>> findByOwner(String ownerUserId) async {
    final entries = await database.query(
      'life_diary_entry',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'entry_date DESC, season_number DESC, session_number DESC',
    );
    final result = <LifeDiaryEntry>[];
    for (final entry in entries) {
      result.add(await _decodeEntry(entry));
    }
    return result;
  }

  @override
  Future<void> tombstone(String entryId) async {
    await database.transaction((transaction) async {
      final now = _clock().toUtc().toIso8601String();
      final count = await transaction.update(
        'life_diary_entry',
        {'status': 'DELETED', 'updated_at': now},
        where: 'entry_id = ? AND status != ?',
        whereArgs: [entryId, 'DELETED'],
      );
      if (count > 0) {
        await _appendEvent(transaction, entryId, 'DELETED', now);
      }
    });
  }

  @override
  Future<void> restore(String entryId) async {
    await database.transaction((transaction) async {
      final now = _clock().toUtc().toIso8601String();
      final count = await transaction.update(
        'life_diary_entry',
        {'status': 'COMPLETED', 'updated_at': now, 'completed_at': now},
        where: 'entry_id = ? AND status = ?',
        whereArgs: [entryId, 'DELETED'],
      );
      if (count > 0) {
        await _appendEvent(transaction, entryId, 'RESTORED', now);
      }
    });
  }

  @override
  Future<void> close() => database.close();

  Map<String, Object?> _entryRow(
    LifeDiaryEntry entry, {
    required String entryId,
  }) => {
    'entry_id': entryId,
    'owner_user_id': entry.ownerUserId,
    'season_number': entry.seasonNumber,
    'session_number': entry.sessionNumber,
    'entry_date': _dateOnly(entry.entryDate),
    'status': entry.status.wireValue,
    'schema_version': entry.schemaVersion,
    'canonical_version': entry.canonicalVersion,
  };

  String? _completedAt(LifeDiaryEntry entry, String now) =>
      entry.status == LifeDiaryEntryStatus.completed ? now : null;

  Future<LifeDiaryEntry> _decodeEntry(Map<String, Object?> row) async {
    final answers = await database.rawQuery(
      '''
SELECT answer.question_id, answer.payload_json
FROM life_diary_answer AS answer
JOIN (
  SELECT question_id, MAX(revision_number) AS revision_number
  FROM life_diary_answer
  WHERE entry_id = ?
  GROUP BY question_id
) AS latest
ON latest.question_id = answer.question_id
AND latest.revision_number = answer.revision_number
WHERE answer.entry_id = ?
''',
      [row['entry_id'], row['entry_id']],
    );
    final payloads = <String, Object?>{};
    for (final answer in answers) {
      payloads[answer['question_id'] as String] = jsonDecode(
        answer['payload_json'] as String,
      );
    }
    if (payloads.length != LifeDiaryCanonicalIds.questionIds.length) {
      throw StateError('Entry ${row['entry_id']} does not contain Q1-Q7');
    }

    return LifeDiaryEntry(
      entryId: row['entry_id'] as String,
      ownerUserId: row['owner_user_id'] as String,
      seasonNumber: row['season_number'] as int,
      sessionNumber: row['session_number'] as int,
      entryDate: DateTime.parse(row['entry_date'] as String),
      status: LifeDiaryEntryStatusCodec.fromWire(row['status'] as String),
      schemaVersion: row['schema_version'] as String,
      canonicalVersion: row['canonical_version'] as String,
      questions: LifeDiaryQuestions.fromJson({
        'q1': payloads['JL-LD-Q01'],
        'q2': payloads['JL-LD-Q02'],
        'q3': payloads['JL-LD-Q03'],
        'q4': payloads['JL-LD-Q04'],
        'q5': payloads['JL-LD-Q05'],
        'q6': payloads['JL-LD-Q06'],
        'q7': payloads['JL-LD-Q07'],
      }),
    );
  }

  Future<void> _appendEvent(
    DatabaseExecutor executor,
    String entryId,
    String type,
    String occurredAt,
  ) async {
    _eventSequence++;
    await executor.insert('life_diary_revision_event', {
      'event_id': '$entryId-$type-${occurredAt}_$_eventSequence',
      'entry_id': entryId,
      'event_type': type,
      'occurred_at': occurredAt,
      'metadata_json': '{}',
    });
  }
}

Map<String, Object?> _questionPayloads(LifeDiaryQuestions questions) => {
  'JL-LD-Q01': questions.q1.toJson(),
  'JL-LD-Q02': questions.q2.toJson(),
  'JL-LD-Q03': questions.q3.toJson(),
  'JL-LD-Q04': questions.q4.toJson(),
  'JL-LD-Q05': questions.q5.toJson(),
  'JL-LD-Q06': questions.q6.toJson(),
  'JL-LD-Q07': questions.q7.toJson(),
};

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
