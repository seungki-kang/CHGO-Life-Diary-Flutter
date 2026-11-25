import 'package:chgo_life_diary/main.dart';
import 'package:chgo_life_diary/main_dev_auth.dart' show DevAuthPage;
import 'package:chgo_life_diary/application/life_diary_dev_login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/life_diary_dev_login_test.dart' show FakeAuth;

void main() {
  const channel = MethodChannel('life_diary/dev_auth');
  const loginLabel = DevAuthPage.oneApi ? '로그인' : 'Test Login';
  const logoutLabel = DevAuthPage.oneApi ? '로그아웃' : 'Logout';
  testWidgets('normal home gates synthetic login and preserves diary actions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = FakeAuth();
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'pkce') {
        return {'verifier': 'v' * 43, 'challenge': 'c' * 43};
      }
      return null;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    await tester.pumpWidget(
      MaterialApp(home: LifeDiaryStartPage(devLoginClient: client)),
    );
    await tester.pumpAndSettle();
    for (final label in ['생명일기 시작', '지난 생명일기 보기', '작성 중인 생명일기']) {
      // Existing diary buttons stay enabled independently of auth state.
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      );
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull);
    }
    if (!LifeDiaryDevLogin.enabled) {
      expect(find.text(loginLabel), findsNothing);
      expect(find.text(logoutLabel), findsNothing);
      expect(calls, isEmpty);
      expect(client.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
      return;
    }
    if (!DevAuthPage.configurationValid) {
      expect(find.text('생명일기 공개 Client ID 설정 필요'), findsOneWidget);
      expect(calls, isEmpty);
      expect(client.calls, isEmpty);
      expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, loginLabel)).onPressed, isNull);
      return;
    }
    if (DevAuthPage.oneApi) {
      expect(find.text('내 계정 · 개발 시험'), findsOneWidget);
      expect(find.textContaining('현재 단계:'), findsNothing);
    }
    expect(find.textContaining('로그인 필요'), findsOneWidget);
    await tester.tap(find.text(loginLabel));
    await tester.pumpAndSettle();
    expect(calls, ['ready', 'pkce', 'openBrowser']);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(
          'callback',
          '${LifeDiaryDevLogin.returnUri}?transaction=synthetic-transaction&code=${'b' * 43}',
        ),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    const success = DevAuthPage.oneApi
        ? '개발 로그인 성공 · 업로드 없음'
        : '합성 로그인 성공 · 업로드 없음';
    expect(find.text(success), findsOneWidget);
    // Cover route lifetime without touching actual journals or repositories.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<void>(builder: (_) => Scaffold(
      appBar: AppBar(), body: const Text('로컬 화면 왕복 시험'),
    )));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(success), findsOneWidget);
    await tester.tap(find.text(logoutLabel));
    await tester.pumpAndSettle();
    expect(find.text('브라우저 인증 대기 또는 새 로그인 필요'), findsOneWidget);
    expect(client.calls, ['start', 'exchange', 'session', 'logout']);
    // Invalid callbacks expose only a fixed safe message.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('callback', 'invalid:secret'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(find.text('실패 또는 시간 초과 · 버튼을 눌러 다시 시도하세요.'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(
      MaterialApp(home: LifeDiaryStartPage(devLoginClient: client)),
    );
    expect(find.text(loginLabel), findsNothing);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
