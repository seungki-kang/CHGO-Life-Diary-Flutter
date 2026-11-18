import 'dart:async';

import 'package:chgo_life_diary/main_dev_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PKCE timeout shows stage and restores explicit retry', (
    tester,
  ) async {
    const channel = MethodChannel('life_diary/dev_auth');
    var attempts = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'pkce') {
        attempts++;
        return Completer<Object?>().future;
      }
      return null;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    await tester.pumpWidget(const MaterialApp(home: DevAuthPage()));
    await tester.tap(find.text('합성 로그인'));
    await tester.pump();
    expect(find.text('현재 단계: PKCE generation'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 6));
    expect(find.textContaining('실패 또는 시간 초과'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    expect(attempts, 1);
    await tester.tap(find.text('합성 로그인'));
    await tester.pump();
    expect(attempts, 2);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox());
  }, skip: !const bool.fromEnvironment('LIFE_DIARY_DEV_LOGIN'));
}
