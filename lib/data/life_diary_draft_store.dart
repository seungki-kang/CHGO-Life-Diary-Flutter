import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class LifeDiaryDraftStore {
  LifeDiaryDraftStore(this.database, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Database database;
  final DateTime Function() _clock;

  Future<void> save(DateTime date, Map<String, Object?> payload) async {
    await database.insert(
      'life_diary_ui_draft',
      {
        'draft_date': _dateOnly(date),
        'payload_json': jsonEncode(payload),
        'updated_at': _clock().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> load(DateTime date) async {
    final rows = await database.query(
      'life_diary_ui_draft',
      columns: const ['payload_json'],
      where: 'draft_date = ?',
      whereArgs: [_dateOnly(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload_json'] as String);
    if (decoded is! Map) throw const FormatException('Draft must be an object');
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> delete(DateTime date) => database.delete(
        'life_diary_ui_draft',
        where: 'draft_date = ?',
        whereArgs: [_dateOnly(date)],
      );
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
