import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chgo_life_diary/main_dev_auth.dart';
import 'package:chgo_life_diary/application/life_diary_dev_login.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('life_diary/dev_auth');

  testWidgets('cold callback requires new login; default flag stays off', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: DevAuthPage()));
    await tester.pump();
    if (!LifeDiaryDevLogin.enabled) {
      expect(calls, isEmpty);
      expect(find.text('개발 로그인 비활성화'), findsOneWidget);
    } else {
      expect(calls, ['ready']);
      // Simulates the initial Intent delivered after Dart's ready handshake.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(
          'callback',
          '${LifeDiaryDevLogin.returnUri}?transaction=lost&code=${'a' * 43}',
        )),
        (_) {},
      );
      await tester.pump();
      expect(find.text('실패 또는 시간 초과 · 버튼을 눌러 다시 시도하세요.'), findsOneWidget);
      expect(calls, ['ready']); // No exchange or PKCE/browser work.
    }
    await tester.pumpWidget(const SizedBox());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
}
