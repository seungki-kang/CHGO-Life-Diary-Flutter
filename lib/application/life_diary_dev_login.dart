import 'package:flutter/foundation.dart';

/// Offline-testable preparation only. No production composition or storage I/O.
abstract interface class LifeDiaryAuthClient {
  Future<({String transaction, Uri authorizeUrl})> start(String challenge);
  Future<LifeDiaryAuthSession> exchange({
    required String transaction,
    required String code,
    required String verifier,
  });
  Future<String> session(String credential);
  Future<void> logout(String credential);
}

class LifeDiaryAuthSession {
  const LifeDiaryAuthSession(this.credential, this.accountId, this.expiresAt);
  final String credential;
  final String accountId;
  final DateTime expiresAt;

  @override
  String toString() => 'LifeDiaryAuthSession(redacted)';
}

class LifeDiaryDevLogin {
  LifeDiaryDevLogin({
    required this.client,
    required this.openBrowser,
    required this.createPkce,
    DateTime Function()? now,
    this.onStage,
    this.operationTimeout = const Duration(seconds: 15),
  }) : _now = now ?? DateTime.now;

  static const enabled =
      kDebugMode &&
      bool.fromEnvironment('LIFE_DIARY_DEV_LOGIN', defaultValue: false);
  static final returnUri = Uri.parse(
    'jesuslife-life-diary-poc://auth/complete/android',
  );
  final void Function(String stage)? onStage;
  final Duration operationTimeout;
  final LifeDiaryAuthClient client;
  final Future<void> Function(Uri) openBrowser;
  // Future Android adapter must supply random verifier + S256 challenge.
  final ({String verifier, String challenge}) Function() createPkce;
  final DateTime Function() _now;
  String? _transaction;
  String? _verifier;
  bool _busy = false;
  LifeDiaryAuthSession? _session;

  bool get signedIn {
    if (_session != null && !_session!.expiresAt.isAfter(_now())) {
      _session = null;
    }
    return _session != null;
  }

  LifeDiaryAuthSession? get activeSession => signedIn ? _session : null;

  Future<void> login() async {
    if (!enabled) throw StateError('Development login disabled');
    if (_busy || signedIn) throw StateError('Login unavailable');
    _busy = true;
    _clearPending();
    try {
      final pkce = createPkce();
      onStage?.call('Login request');
      final start = await client
          .start(pkce.challenge)
          .timeout(operationTimeout);
      onStage?.call('Authorization URL validation');
      final url = start.authorizeUrl;
      if (url.scheme != 'http' ||
          url.host != '127.0.0.1' ||
          url.port != 8000 ||
          url.userInfo.isNotEmpty ||
          url.path != '/api/v1/mobile/life-diary/authorize' ||
          url.fragment.isNotEmpty ||
          url.queryParametersAll.length != 1 ||
          url.queryParametersAll['state']?.length != 1 ||
          !RegExp(r'^[A-Za-z0-9_-]{43}$')
              .hasMatch(url.queryParameters['state'] ?? '')) {
        throw StateError('Invalid authorization response');
      }
      _transaction = start.transaction;
      _verifier = pkce.verifier;
      onStage?.call('Browser launch');
      await openBrowser(url).timeout(operationTimeout);
      onStage?.call('Callback wait');
    } catch (_) {
      _clearPending();
      throw StateError('Login failed; start a new login');
    } finally {
      _busy = false;
    }
  }

  /// Receives the Android handoff, never an Auth0 token or server callback.
  Future<void> handleCallback(Uri uri) async {
    if (!enabled) throw StateError('Development login disabled');
    if (_busy) throw StateError('Login busy');
    onStage?.call('Callback validation');
    final transaction = _transaction;
    final verifier = _verifier;
    _clearPending(); // Every attempt is single use, including failed exchange.
    final query = uri.queryParametersAll;
    if (transaction == null ||
        verifier == null ||
        // Null preserves URI components; normalize both sides for comparison.
        uri.replace(query: '', fragment: '') !=
            returnUri.replace(query: '', fragment: '') ||
        uri.fragment.isNotEmpty ||
        query.length != 2 ||
        query['transaction']?.length != 1 ||
        query['code']?.length != 1 ||
        query['transaction']!.single != transaction ||
        !RegExp(r'^[A-Za-z0-9_-]{43,128}$').hasMatch(query['code']!.single)) {
      throw StateError('Invalid login callback; start a new login');
    }
    _busy = true;
    try {
      onStage?.call('One-time exchange');
      final session = await client
          .exchange(
            transaction: transaction,
            code: query['code']!.single,
            verifier: verifier,
          )
          .timeout(operationTimeout);
      onStage?.call('Session validation');
      if (session.credential.isEmpty ||
          session.accountId.isEmpty ||
          !session.expiresAt.isAfter(_now()) ||
          await client.session(session.credential).timeout(operationTimeout) !=
              session.accountId) {
        throw StateError('Invalid session');
      }
      _session = session;
    } catch (_) {
      _session = null;
      throw StateError('Login failed; start a new login');
    } finally {
      _busy = false;
    }
  }

  Future<void> logout() async {
    if (_busy) throw StateError('Login busy');
    _clearPending();
    final session = _session;
    if (session == null) return;
    _busy = true;
    try {
      // Keep the credential on failure so revocation can be retried explicitly.
      onStage?.call('Logout request');
      await client.logout(session.credential).timeout(operationTimeout);
      _session = null;
    } catch (_) {
      throw StateError('Logout failed; retry logout');
    } finally {
      _busy = false;
    }
  }

  void _clearPending() {
    _transaction = null;
    _verifier = null;
  }
}
