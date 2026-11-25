import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chgo_life_diary/main_dev_auth.dart';
import 'package:chgo_life_diary/application/life_diary_dev_login.dart';

void main() {
  test('explicit public client configuration preserves fixture default', () {
    const enabled = bool.fromEnvironment('LIFE_DIARY_ONE_API_LOGIN');
    const id = String.fromEnvironment('LIFE_DIARY_AUTH0_CLIENT_ID');
    expect(DevAuthPage.oneApi, enabled);
    expect(
      DevAuthPage.configuredClientId,
      enabled ? id : 'synthetic-life-diary-debug',
    );
    expect(
      DevAuthPage.configurationValid,
      !enabled ||
          (id.isNotEmpty && id.trim() == id && !RegExp(r'\s').hasMatch(id)),
    );
  });
  testWidgets('missing public ID prevents channel and browser initialization', (
    tester,
  ) async {
    final calls = <String>[];
    const channel = MethodChannel('life_diary/dev_auth');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: DevAuthPage()));
    await tester.pump();
    if (LifeDiaryDevLogin.enabled && !DevAuthPage.configurationValid) {
      expect(calls, isEmpty);
      expect(find.text('생명일기 공개 Client ID 설정 필요'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    }
    await tester.pumpWidget(const SizedBox());
  });
}
