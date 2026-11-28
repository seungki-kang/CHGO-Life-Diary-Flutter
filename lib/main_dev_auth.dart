import 'package:flutter/material.dart';
import 'application/auth_session_store.dart';
import 'package:flutter/services.dart';

import 'application/life_diary_dev_login.dart';
import 'application/life_diary_one_api_auth_client.dart';
import 'presentation/life_diary_dev_backup_page.dart';

// Explicit debug authentication target. No journal imports, repositories or DB access.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: DevAuthPage()));
}

class DevAuthPage extends StatefulWidget {
  static const oneApi = bool.fromEnvironment('LIFE_DIARY_ONE_API_LOGIN');
  static const completedBackup =
      bool.fromEnvironment('LIFE_DIARY_DEV_COMPLETED_BACKUP');
  static const publicClientId = String.fromEnvironment(
    'LIFE_DIARY_AUTH0_CLIENT_ID',
  );
  static bool get configurationValid =>
      !oneApi ||
      (publicClientId.isNotEmpty &&
          publicClientId.trim() == publicClientId &&
          !RegExp(r'\s').hasMatch(publicClientId));
  static String get configuredClientId =>
      oneApi ? publicClientId : 'synthetic-life-diary-debug';

  const DevAuthPage({super.key, this.embedded = false, this.accountMode = false, this.client});

  final bool embedded;
  final bool accountMode;
  final LifeDiaryAuthClient? client;

  @override
  DevAuthPageState createState() => DevAuthPageState();
}

class DevAuthPageState extends State<DevAuthPage> {
  LifeDiaryAuthSession? get activeSession =>
      busy ? null : login?.activeSession;
  static const channel = MethodChannel('life_diary/dev_auth');
  LifeDiaryDevLogin? login;
  String status = DevAuthPage.oneApi
      ? 'One API 개발 로그인 · 로그인 필요'
      : '합성 인증 테스트 · 로그인 필요';
  bool busy = false;
  String stage = 'Ready';

  void showStage(String value) {
    if (mounted) setState(() => stage = value);
  }

  @override
  void initState() {
    super.initState();
    if (!LifeDiaryDevLogin.enabled || !DevAuthPage.configurationValid) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'callback') {
        await perform(() async {
          // A fresh controller has no transaction, so cold-start callbacks fail.
          await login!.handleCallback(Uri.parse(call.arguments as String));
        });
      }
    });
    login = LifeDiaryDevLogin(
      store: AndroidAuthSessionStore.enabled && widget.client == null && DevAuthPage.oneApi
          ? AndroidAuthSessionStore('life_diary:${DevAuthPage.configuredClientId}:loopback8000:v1')
          : null,
      client:
          widget.client ??
          LifeDiaryOneApiAuthClient(
            transport: LifeDiaryIoAuthTransport(),
            clientId: DevAuthPage.configuredClientId,
            onStage: showStage,
          ),
      onStage: showStage,
      openBrowser: (uri) => channel.invokeMethod<void>('openBrowser', '$uri'),
      createPkce: () => pendingPkce!,
    );
    if (login!.store != null) {
      perform(() => login!.restore());
    }
    channel
        .invokeMethod<void>('ready')
        .timeout(const Duration(seconds: 5))
        .catchError((Object _) {
          if (mounted) setState(() => status = 'Android debug 연결 필요');
        });
  }

  ({String verifier, String challenge})? pendingPkce;

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      status = '처리 중';
    });
    try {
      await action();
      if (mounted) {
        setState(
          () => status = login!.signedIn
              ? (DevAuthPage.oneApi
                    ? '개발 로그인 성공 · 업로드 없음'
                    : '합성 로그인 성공 · 업로드 없음')
              : '브라우저 인증 대기 또는 새 로그인 필요',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = '실패 또는 시간 초과 · 버튼을 눌러 다시 시도하세요.');
      }
    } finally {
      pendingPkce = null;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        if (widget.accountMode) ...[
          Text('내 계정 · 개발 시험', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('로그인 없이 일기를 작성할 수 있습니다. 로그인만으로 일기가 업로드되지 않습니다.'),
          const SizedBox(height: 8),
        ],
        Text(
          !LifeDiaryDevLogin.enabled
              ? '개발 로그인 비활성화'
              : !DevAuthPage.configurationValid
              ? '생명일기 공개 Client ID 설정 필요'
              : status,
        ),
        if (LifeDiaryDevLogin.enabled && !widget.accountMode)
          Text('현재 단계: $stage'),
        if (login?.store != null)
          TextButton(
            onPressed: busy ? null : () => perform(() => login!.restore()),
            child: const Text('로그인 상태 복구'),
          ),
        ElevatedButton(
          onPressed:
              !LifeDiaryDevLogin.enabled ||
                  !DevAuthPage.configurationValid ||
                  busy
              ? null
              : () => perform(() async {
                  showStage('PKCE generation');
                  final pair = await channel
                      .invokeMapMethod<String, String>('pkce')
                      .timeout(const Duration(seconds: 5));
                  pendingPkce = (
                    verifier: pair!['verifier']!,
                    challenge: pair['challenge']!,
                  );
                  await login!.login();
                }),
          child: Text(
            widget.accountMode
                ? '로그인'
                : widget.embedded
                ? 'Test Login'
                : DevAuthPage.oneApi
                ? '개발 로그인'
                : '합성 로그인',
          ),
        ),
        if (LifeDiaryDevLogin.enabled &&
            DevAuthPage.oneApi &&
            DevAuthPage.completedBackup &&
            !busy &&
            login?.signedIn == true)
          OutlinedButton(
            onPressed: () {
              final controller = login!;
              if (controller.activeSession == null) {
                setState(() => status = '다시 로그인하세요.');
                return;
              }
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => LifeDiaryDevBackupPage(
                  session: () => controller.activeSession,
                ),
              ));
            },
            child: const Text('완료 일기 백업 검증'),
          ),
        TextButton(
          onPressed:
              !LifeDiaryDevLogin.enabled ||
                  !DevAuthPage.configurationValid ||
                  busy
              ? null
              : () => perform(login!.logout),
          child: Text(widget.accountMode ? '로그아웃' : widget.embedded ? 'Logout' : '로그아웃'),
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DevAuthPage.oneApi ? 'Life Diary · 개발 인증' : 'Life Diary · 합성 인증',
        ),
      ),
      body: content,
    );
  }
}
