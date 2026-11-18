import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../application/life_diary_completed_backup.dart';
import '../application/life_diary_dev_login.dart';
import '../data/life_diary_database.dart';
import '../data/life_diary_entry_factory.dart';
import '../data/sqlite_life_diary_repository.dart';
import 'life_diary_history_page.dart';

/// Isolated debug flow using the real entry model, repository and history page.
class LifeDiaryDevBackupPage extends StatefulWidget {
  const LifeDiaryDevBackupPage({super.key, required this.session});

  final LifeDiaryAuthSession? Function() session;

  @override
  State<LifeDiaryDevBackupPage> createState() => _LifeDiaryDevBackupPageState();
}

class _LifeDiaryDevBackupPageState extends State<LifeDiaryDevBackupPage> {
  static const _base = 'http://127.0.0.1:8000/api/v1/mobile/life-diary/backup';
  static const _timeout = Duration(seconds: 10);
  static const _owner = 'synthetic-diary-owner';
  final _client = HttpClient()..connectionTimeout = _timeout;
  final _code = TextEditingController();
  final _factory = LifeDiaryEntryFactory(ownerUserId: _owner);
  late final Future<SqliteLifeDiaryRepository> _repository = _open();
  late final String _account = widget.session()?.accountId ?? '';
  bool _busy = false;
  int? _generation;
  PreparedLifeDiaryBackup? _prepared;
  String _status = '합성 일기를 백업하거나 복구 코드를 입력하세요.';

  Future<SqliteLifeDiaryRepository> _open() async {
    final accountPath = base64UrlEncode(utf8.encode(_account));
    final root = await getDatabasesPath();
    final db = await openDatabase(
      '$root/life_diary_completed_backup_dev_$accountPath.db',
      version: lifeDiaryDatabaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await LifeDiaryDatabase.createV001(db);
        await LifeDiaryDatabase.createV002(db);
        await LifeDiaryDatabase.createV003(db);
      },
    );
    return SqliteLifeDiaryRepository(db);
  }

  Future<Map<String, Object?>> _request(
    String method,
    String path,
    Set<int> expected, {
    Map<String, Object>? body,
  }) async {
    final session = widget.session();
    if (session == null || session.accountId != _account) {
      throw StateError('Session unavailable');
    }
    final request = await _client.openUrl(method, Uri.parse('$_base$path'))
        .timeout(_timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader,
        'Bearer ${session.credential}');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(_timeout);
    final text = await response.transform(utf8.decoder).join().timeout(_timeout);
    if (!expected.contains(response.statusCode)) {
      throw HttpException('HTTP ${response.statusCode}');
    }
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
    final prepared = _prepared ?? await LifeDiaryCompletedBackup(repository).prepare(
      entryId: entry.entryId,
      localOwnerId: _owner,
      accountId: _account,
      generation: generation,
    );
    _prepared = prepared;
    await _request(
      'PUT',
      '/entries/$generation/${prepared.backupId}',
      {200, 201},
      body: prepared.toRequestBody(),
    );
    return '완료 일기 백업 성공 · 복구 코드를 보관하세요.';
  }

  Future<String> _restore() async {
    final reference = LifeDiaryBackupReference.parse(_code.text);
    final payload = await _request(
      'GET', '/entries/${reference.generation}/${reference.backupId}', {200},
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
    setState(() => _busy = true);
    try {
      _status = await operation();
    } on HttpException catch (error) {
      _status = '요청 실패 · ${error.message}';
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
    _repository.then<void>((repository) => repository.close(),
        onError: (Object _) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('완료 일기 백업 검증')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('합성 기록 · 개발 계정 · 임시 PostgreSQL'),
          const Text('복구 코드를 잃으면 이 백업을 열 수 없습니다.'),
          Text(_status),
          FilledButton(
            onPressed: _busy ? null : () => _run(_backup),
            child: const Text('동의하고 합성 일기 백업'),
          ),
          if (_prepared case final prepared?) SelectableText(prepared.recoveryCode),
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
            onPressed: _busy ? null : () async {
              await _run(() async {
                final repository = await _repository;
                if (!context.mounted) return '';
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => LifeDiaryHistoryPage(
                    repository: repository,
                    ownerUserId: _owner,
                  ),
                ));
                return _status;
              });
            },
            child: const Text('검증 일기 목록'),
          ),
          TextButton(
            onPressed: _busy || _generation == null ? null : () => _run(() async {
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
