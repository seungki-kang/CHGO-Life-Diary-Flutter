import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../application/life_diary_completed_backup.dart';
import '../application/life_diary_dev_login.dart';
import '../data/life_diary_database.dart';
import '../data/life_diary_entry_factory.dart';
import '../data/sqlite_life_diary_repository.dart';
import '../domain/life_diary_models.dart';
import 'life_diary_history_page.dart';

/// Keeps an ambiguous upload retry on the same ID for the app process.
class LifeDiarySelectedBackupAttempt {
  LifeDiaryAuthSession? _session;
  int? _generation;
  PreparedLifeDiaryBackup? _prepared;
  bool _uploaded = false;
}

/// Isolated debug flow using the real entry model, repository and history page.
class LifeDiaryDevBackupPage extends StatefulWidget {
  const LifeDiaryDevBackupPage({super.key, required this.session})
    : _selection = null;

  const LifeDiaryDevBackupPage.selected({
    super.key,
    required this.session,
    required LifeDiaryAuthSession selectedSession,
    required SqliteLifeDiaryRepository selectedRepository,
    required LifeDiaryEntry selectedEntry,
    required LifeDiarySelectedBackupAttempt selectedAttempt,
  }) : _selection = (
         session: selectedSession,
         repository: selectedRepository,
         entry: selectedEntry,
         attempt: selectedAttempt,
       );

  static const selectedEnabled =
      kDebugMode &&
      bool.fromEnvironment('LIFE_DIARY_DEV_SELECTED_BACKUP') &&
      !bool.fromEnvironment('LIFE_DIARY_BACKUP_RESTORE_ONLY');

  final ({
    LifeDiaryAuthSession session,
    SqliteLifeDiaryRepository repository,
    LifeDiaryEntry entry,
    LifeDiarySelectedBackupAttempt attempt,
  })? _selection;

  final LifeDiaryAuthSession? Function() session;

  @override
  State<LifeDiaryDevBackupPage> createState() => _LifeDiaryDevBackupPageState();
}

class _LifeDiaryDevBackupPageState extends State<LifeDiaryDevBackupPage> {
  static const _base = 'http://127.0.0.1:8000/api/v1/mobile/life-diary/backup';
  static const _timeout = Duration(seconds: 10);
  static const _owner = 'synthetic-diary-owner';
  static const _restoreOnly = bool.fromEnvironment(
    'LIFE_DIARY_BACKUP_RESTORE_ONLY',
  );
  static const _testNamespace = String.fromEnvironment(
    'LIFE_DIARY_BACKUP_TEST_NAMESPACE',
  );
  final _client = HttpClient()..connectionTimeout = _timeout;
  final _code = TextEditingController();
  final _factory = LifeDiaryEntryFactory(ownerUserId: _owner);
  late final Future<SqliteLifeDiaryRepository> _repository = _open();
  late final String _account = widget.session()?.accountId ?? '';
  bool _busy = false;
  bool _confirmedLocalEntry = false;
  int? _generation;
  PreparedLifeDiaryBackup? _prepared;
  static const _initialStatus = '합성 일기를 백업하거나 복구 코드를 입력하세요.';
  String _status = _initialStatus;

  Future<SqliteLifeDiaryRepository> _open() async {
    if (!kDebugMode) {
      throw StateError('Development backup requires debug mode');
    }
    if ((_restoreOnly && _testNamespace.isEmpty) ||
        (_testNamespace.isNotEmpty &&
            !RegExp(r'^[a-z0-9_-]{1,48}$').hasMatch(_testNamespace))) {
      throw StateError('Invalid development database namespace');
    }
    final accountPath = base64UrlEncode(utf8.encode(_account));
    final suffix = _testNamespace.isEmpty ? '' : '_$_testNamespace';
    final root = await getDatabasesPath();
    final db = await openDatabase(
      '$root/life_diary_completed_backup_dev_$accountPath$suffix.db',
      version: lifeDiaryDatabaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await LifeDiaryDatabase.createV001(db);
        await LifeDiaryDatabase.createV002(db);
        await LifeDiaryDatabase.createV003(db);
        await LifeDiaryDatabase.createV004(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 4) await LifeDiaryDatabase.createV004(db);
      },
    );
    return SqliteLifeDiaryRepository(db);
  }

  LifeDiaryAuthSession _requireSession() {
    final session = widget.session();
    final selection = widget._selection;
    if (!mounted ||
        session == null ||
        session.accountId != _account ||
        (selection != null &&
            (!LifeDiaryDevBackupPage.selectedEnabled ||
                !identical(session, selection.session) ||
                (selection.attempt._session != null &&
                    !identical(session, selection.attempt._session))))) {
      throw StateError('Session unavailable');
    }
    return session;
  }

  Future<void> _requireSelectedAuthor(LifeDiaryAuthSession session) async {
    final selection = widget._selection;
    if (selection == null) return;
    final author = await selection.repository.findAuthorAccountId(
      selection.entry.entryId,
    );
    if (author != session.accountId) {
      throw const _BackupAuthorMismatch();
    }
  }

  Future<Map<String, Object?>> _request(
    String method,
    String path,
    Set<int> expected, {
    Map<String, Object>? body,
  }) async {
    final session = _requireSession();
    final request = await _client
        .openUrl(method, Uri.parse('$_base$path'))
        .timeout(_timeout);
    try {
      await _requireSelectedAuthor(session);
      if (!identical(_requireSession(), session)) {
        throw StateError('Session changed');
      }
    } catch (_) {
      request.abort();
      rethrow;
    }
    request.followRedirects = false;
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${session.credential}',
    );
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(_timeout);
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    if (!expected.contains(response.statusCode)) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    if (widget._selection != null) _requireSession();
    return text.isEmpty ? {} : jsonDecode(text) as Map<String, Object?>;
  }

  Future<String> _backup() async {
    final repository = await _repository;
    final entry = _factory.fromUiDraft(DateTime(2026, 11, 17), {
      'q1_detail': '합성 일기 · 오늘 감사한 일을 기록했습니다.',
      'q7_action': '내일 만나는 사람에게 감사를 표현합니다.',
    }, completed: true);
    final importResult = await repository.importCompletedBackup(entry);
    if (importResult == LifeDiaryRestoreResult.conflict) {
      return '합성 일기와 같은 회차에 다른 기록이 있습니다.';
    }
    final consent = _generation == null
        ? await _request('POST', '/consent', {200})
        : null;
    final generation = _generation ?? (consent!['generation'] as int);
    _generation = generation;
    final prepared =
        _prepared ??
        await LifeDiaryCompletedBackup(repository).prepare(
          entryId: entry.entryId,
          localOwnerId: _owner,
          accountId: _account,
          generation: generation,
        );
    _prepared = prepared;
    await _request('PUT', '/entries/$generation/${prepared.backupId}', {
      200,
      201,
    }, body: prepared.toRequestBody());
    return '완료 일기 백업 성공 · 복구 코드를 보관하세요.';
  }

  Future<String> _backupSelected() async {
    final selection = widget._selection!;
    final attempt = selection.attempt;
    final session = _requireSession();
    if (!_confirmedLocalEntry) {
      throw StateError('Local entry confirmation required');
    }
    if (attempt._uploaded) return '이미 이 일기를 백업했습니다.';

    final entry = await selection.repository.findById(selection.entry.entryId);
    if (entry == null ||
        entry.ownerUserId != selection.entry.ownerUserId ||
        entry.status != LifeDiaryEntryStatus.completed) {
      return '선택한 완료 일기를 찾을 수 없습니다.';
    }
    _requireSession();
    await _requireSelectedAuthor(session);
    _requireSession();

    if (attempt._prepared == null) {
      attempt._session = session;
      if (attempt._generation == null) {
        final consent = await _request('POST', '/consent', {200});
        attempt._generation = consent['generation'] as int;
      }
      final prepared = await LifeDiaryCompletedBackup(selection.repository)
          .prepare(
            entryId: selection.entry.entryId,
            localOwnerId: selection.entry.ownerUserId,
            accountId: session.accountId,
            generation: attempt._generation!,
          );
      _requireSession();
      attempt._prepared = prepared;
    }

    final prepared = attempt._prepared!;
    await _request(
      'PUT',
      '/entries/${prepared.generation}/${prepared.backupId}',
      {200, 201},
      body: prepared.toRequestBody(),
    );
    attempt._uploaded = true;
    return '완료 일기 백업 성공 · 복구 코드를 보관하세요.';
  }

  Future<String> _restore() async {
    final reference = LifeDiaryBackupReference.parse(_code.text);
    final payload = await _request(
      'GET',
      '/entries/${reference.generation}/${reference.backupId}',
      {200},
    );
    final session = widget.session();
    if (session == null || session.accountId != _account) {
      throw StateError('Session unavailable');
    }
    final result = await LifeDiaryCompletedBackup(await _repository).restore(
      backup: reference,
      response: payload,
      localOwnerId: _owner,
      accountId: _account,
    );
    _generation = reference.generation;
    return switch (result) {
      LifeDiaryRestoreResult.inserted => '복구 성공 · 일기 목록에서 확인하세요.',
      LifeDiaryRestoreResult.alreadyPresent => '이미 복구된 일기입니다.',
      LifeDiaryRestoreResult.conflict => '같은 회차의 기존 일기를 보존했습니다.',
    };
  }

  Future<void> _run(Future<String> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _status = await operation();
    } on HttpException catch (error) {
      _status = '요청 실패 · ${error.message}';
    } on _BackupAuthorMismatch {
      _status = '작성할 때 연결한 계정으로만 백업할 수 있습니다.';
    } on StateError {
      _status = widget._selection == null
          ? '백업 또는 복구 실패 · 로그인 상태를 확인하세요.'
          : '백업을 완료하지 못했습니다. 로그인 세션과 완료 일기를 확인하세요.';
    } on FormatException {
      _status = '복구 코드 형식을 확인하세요.';
    } catch (_) {
      _status = '백업 또는 복구 실패 · 로그인과 복구 코드를 확인하세요.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _client.close(force: true);
    if (widget._selection == null) {
      _repository.then<void>(
        (repository) => repository.close(),
        onError: (Object _) {},
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget._selection;
    if (selection != null) {
      return _buildSelected(selection.entry, selection.attempt);
    }
    return _buildRehearsal();
  }

  Widget _buildSelected(
    LifeDiaryEntry entry,
    LifeDiarySelectedBackupAttempt attempt,
  ) {
    final session = widget.session();
    final prepared = attempt._prepared;
    final accountId = widget._selection!.session.accountId;
    final accountLabel = accountId.length <= 8
        ? accountId
        : '…${accountId.substring(accountId.length - 8)}';
    final date = MaterialLocalizations.of(context).formatFullDate(entry.entryDate);
    final active = identical(session, widget._selection!.session) &&
        (attempt._session == null || identical(session, attempt._session));
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('선택한 완료 일기 백업')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(date),
            Text('시즌 ${entry.seasonNumber} · ${entry.sessionNumber}회'),
            if (active) Text('개발 계정 ID $accountLabel'),
            const Text('개발 시험용 합성 일기만 사용하세요.'),
            const Text('동의하면 이 일기 한 건을 암호화하여 개발 서버에 보냅니다.'),
            const Text('복구 코드를 잃으면 이 백업을 열 수 없습니다.'),
            const SizedBox(height: 12),
            if (active && !attempt._uploaded)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('제가 작성한 시험 일기이며 위 계정에 백업합니다.'),
                value: _confirmedLocalEntry,
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _confirmedLocalEntry = value ?? false;
                      }),
              ),
            if (!active)
              const Text('로그인 세션이 바뀌었거나 만료되었습니다.')
            else if (attempt._uploaded)
              const Text('이 일기는 백업되었습니다. 복구 코드를 보관하세요.')
            else if (_busy)
              const Text('백업 처리 중입니다.')
            else if (_status != _initialStatus)
              Text(_status),
            if (active && prepared != null)
              SelectableText(prepared.recoveryCode),
            FilledButton(
              onPressed: !active || !_confirmedLocalEntry || _busy || attempt._uploaded
                  ? null
                  : () => _run(_backupSelected),
              child: const Text('동의하고 이 일기 백업'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRehearsal() => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('완료 일기 백업 검증')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('합성 기록 · 개발 계정 · 임시 PostgreSQL'),
          const Text('복구 코드를 잃으면 이 백업을 열 수 없습니다.'),
          Text(_status),
          if (!_restoreOnly)
            FilledButton(
              onPressed: _busy ? null : () => _run(_backup),
              child: const Text('동의하고 합성 일기 백업'),
            ),
          if (_prepared case final prepared?)
            SelectableText(prepared.recoveryCode),
          TextField(
            controller: _code,
            enabled: !_busy,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: '테스트 복구 코드'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : () => _run(_restore),
            child: const Text('완료 일기 복구'),
          ),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    await _run(() async {
                      final repository = await _repository;
                      if (!mounted) return '';
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LifeDiaryHistoryPage(
                            repository: repository,
                            ownerUserId: _owner,
                          ),
                        ),
                      );
                      return _status;
                    });
                  },
            child: const Text('검증 일기 목록'),
          ),
          TextButton(
            onPressed: _busy || _generation == null
                ? null
                : () => _run(() async {
                    await _request('DELETE', '/consent/$_generation', {204});
                    _generation = null;
                    _prepared = null;
                    return '백업 동의를 철회했습니다.';
                  }),
            child: const Text('백업 동의 철회'),
          ),
        ],
      ),
    ),
  );
}

class _BackupAuthorMismatch implements Exception {
  const _BackupAuthorMismatch();
}
