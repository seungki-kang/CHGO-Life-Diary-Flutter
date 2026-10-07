import 'dart:convert';

import 'package:chgo_life_diary/application/life_diary_privacy.dart';
import 'package:chgo_life_diary/data/life_diary_consent_store.dart';
import 'package:chgo_life_diary/data/life_diary_database.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Database database;
  late LifeDiaryConsentStore store;
  final now = DateTime.utc(2026, 10, 7, 1);

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await LifeDiaryDatabase.createV001(database);
    await LifeDiaryDatabase.createV002(database);
    await LifeDiaryDatabase.createV003(database);
    await database.insert('life_diary_entry', {
      'entry_id': 'entry-001',
      'owner_user_id': 'owner-001',
      'season_number': 1,
      'session_number': 1,
      'entry_date': '2026-10-07',
      'status': 'COMPLETED',
      'schema_version': '1.0.0',
      'canonical_version': '1.0.0',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'completed_at': now.toIso8601String(),
    });
    store = LifeDiaryConsentStore(database, clock: () => now);
  });

  tearDown(() => database.close());

  test('LD-007 denies pastor or coach raw access without a grant', () async {
    final privacy = LifeDiaryPrivacyService(store);

    expect(
      await privacy.canReadRaw(
        ownerUserId: 'owner-001',
        requesterUserId: 'pastor-001',
        entryId: 'entry-001',
        at: now,
      ),
      isFalse,
    );
    expect(
      await privacy.canReadRaw(
        ownerUserId: 'owner-001',
        requesterUserId: 'owner-001',
        entryId: 'entry-001',
        at: now,
      ),
      isTrue,
    );
  });

  test('LD-008 records recipient scope purpose and expiry', () async {
    await store.grant(
      LifeDiaryConsentGrant(
        grantId: 'grant-001',
        entryId: 'entry-001',
        recipientType: 'COACH',
        recipientId: 'coach-001',
        scope: LifeDiaryShareScope.summary,
        purpose: '주간 코칭 나눔',
        grantedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      ),
    );

    final rows = await database.query('life_diary_consent_grant');
    final events = await database.query('life_diary_revision_event');

    expect(rows.single['recipient_type'], 'COACH');
    expect(rows.single['recipient_id'], 'coach-001');
    expect(rows.single['scope'], 'SUMMARY');
    expect(rows.single['purpose'], '주간 코칭 나눔');
    expect(rows.single['expires_at'], isNotNull);
    expect(events.single['event_type'], 'SHARED');
    expect(events.single['metadata_json'], '{"scope":"SUMMARY"}');
  });

  test('summary grant never permits raw diary access', () async {
    await store.grant(
      LifeDiaryConsentGrant(
        grantId: 'grant-001',
        entryId: 'entry-001',
        recipientType: 'COACH',
        recipientId: 'coach-001',
        scope: LifeDiaryShareScope.summary,
        purpose: '요약 나눔',
        grantedAt: now,
        expiresAt: now.add(const Duration(days: 1)),
      ),
    );

    expect(
      await LifeDiaryPrivacyService(store).canReadRaw(
        ownerUserId: 'owner-001',
        requesterUserId: 'coach-001',
        entryId: 'entry-001',
        at: now,
      ),
      isFalse,
    );
  });

  test('LD-009 analytics event excludes every raw narrative', () {
    final encoded = jsonEncode(
      LifeDiaryAnalyticsExporter.growthEvent(_entryWithSensitiveText()),
    );

    expect(encoded, isNot(contains('Q1 민감 원문')));
    expect(encoded, isNot(contains('Q3 민감 원문')));
    expect(encoded, isNot(contains('Q4 민감 원문')));
    expect(encoded, isNot(contains('Q5 민감 원문')));
    expect(encoded, isNot(contains('감사 민감 원문')));
    expect(encoded, isNot(contains('실천 민감 원문')));
    expect(encoded, contains('JL-OLD-01'));
    expect(encoded, contains('JL-FRUIT-01'));
  });
}

LifeDiaryEntry _entryWithSensitiveText() => LifeDiaryEntry(
  entryId: 'entry-001',
  ownerUserId: 'owner-001',
  seasonNumber: 1,
  sessionNumber: 1,
  entryDate: DateTime(2026, 10, 7),
  status: LifeDiaryEntryStatus.completed,
  canonicalVersion: '1.0.0',
  questions: LifeDiaryQuestions(
    q1: Q1Payload(narrative: 'Q1 민감 원문', oldPersonIds: const ['JL-OLD-01']),
    q2: Q2Payload(
      explanationVersion: '1.0.0',
      acknowledgedAt: DateTime.utc(2026, 10, 7),
      appliedOldPersonIds: const ['JL-OLD-01'],
    ),
    q3: Q3Payload(
      contexts: const [KingdomContext.inner],
      narrative: 'Q3 민감 원문',
      fruitIds: const ['JL-FRUIT-01'],
    ),
    q4: const Q4Payload(narrative: 'Q4 민감 원문', revisitedQ1Q2: false),
    q5: const Q5Payload(
      communionType: CommunionType.asked,
      narrative: 'Q5 민감 원문',
    ),
    q6: Q6Payload(
      items: const [
        GratitudeItem(what: '감사 민감 원문', why: '개인 사유'),
        GratitudeItem(what: '둘', why: '개인 사유'),
        GratitudeItem(what: '셋', why: '개인 사유'),
      ],
    ),
    q7: Q7Payload(actions: const ['실천 민감 원문']),
  ),
);
