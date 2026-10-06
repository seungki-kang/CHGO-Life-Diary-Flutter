import 'dart:convert';

import 'package:chgo_life_diary/core/observability/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes structured approved metadata', () {
    final messages = <String>[];
    final logger = AppLogger(
      minimumLevel: AppLogLevel.debug,
      sink: messages.add,
      clock: () => DateTime.utc(2026, 10, 6, 12),
    );

    logger.info('life_diary.saved', {
      'entry_id': 'JL-LD-LOCAL-20261006',
      'status': 'COMPLETED',
      'schema_version': '1.0.0',
    });

    final record = jsonDecode(messages.single) as Map<String, Object?>;
    expect(record['level'], 'INFO');
    expect(record['event'], 'life_diary.saved');
    expect(record['timestamp'], '2026-10-06T12:00:00.000Z');
  });

  test('drops raw answers and direct identity fields', () {
    final messages = <String>[];
    final logger = AppLogger(
      minimumLevel: AppLogLevel.debug,
      sink: messages.add,
    );

    logger.error('life_diary.save_failed', {
      'error_code': 'database_error',
      'narrative': 'private Q1 answer',
      'answer': 'private Q2 answer',
      'email': 'person@example.com',
      'church_name': 'private church',
      'owner_user_id': 'private-user',
    });

    final output = messages.single;
    expect(output, contains('database_error'));
    expect(output, isNot(contains('private Q1 answer')));
    expect(output, isNot(contains('private Q2 answer')));
    expect(output, isNot(contains('person@example.com')));
    expect(output, isNot(contains('private church')));
    expect(output, isNot(contains('private-user')));
    expect(output, contains('"dropped_fields":5'));
  });

  test('always writes audit events', () {
    final messages = <String>[];
    final logger = AppLogger(
      minimumLevel: AppLogLevel.error,
      sink: messages.add,
    );

    logger.info('ignored.info');
    logger.audit('consent.revoked', {'operation': 'REVOKE'});

    expect(messages, hasLength(1));
    expect(messages.single, contains('"level":"AUDIT"'));
  });

  test('does not allow raw text to be used as an event name', () {
    final messages = <String>[];
    final logger = AppLogger(sink: messages.add);

    logger.error('My private diary answer');

    expect(messages.single, contains('"event":"invalid_event"'));
    expect(messages.single, isNot(contains('My private diary answer')));
  });
}
