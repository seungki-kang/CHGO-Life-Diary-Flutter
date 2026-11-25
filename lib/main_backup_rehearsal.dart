import 'package:flutter/material.dart';

void main() => runApp(const BackupRehearsalApp());

class BackupRehearsalApp extends StatelessWidget {
  const BackupRehearsalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BackupRehearsalPage());
  }
}

class BackupRehearsalPage extends StatefulWidget {
  const BackupRehearsalPage({super.key});

  @override
  State<BackupRehearsalPage> createState() => _BackupRehearsalPageState();
}

class _BackupRehearsalPageState extends State<BackupRehearsalPage> {
  final _server = _RehearsalServer();
  bool _online = true;
  int? _consent;
  int? _queued;
  int? _pendingWithdrawal;
  int? _lastRequest;
  String _status = '';

  void _flush() {
    if (!_online) return;

    final withdrawal = _pendingWithdrawal;
    if (withdrawal != null) {
      _server.withdraw(withdrawal);
      _pendingWithdrawal = null;
      _status = '철회 전송 완료';
    }

    final queued = _queued;
    if (queued != null && queued == _consent) {
      _status = _server.save(queued) ? '테스트 업로드 완료' : '테스트 업로드 거부';
      _queued = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('백업 동의 검증')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('합성 기록 · 모의 서버'),
          SwitchListTile(
            title: const Text('온라인'),
            value: _online,
            onChanged: (value) => setState(() {
              _online = value;
              _flush();
            }),
          ),
          Text(_consent == null ? '백업 동의 없음' : '백업 동의 활성'),
          Text(_queued == null ? '업로드 대기 0건' : '업로드 대기 1건'),
          if (_pendingWithdrawal != null) const Text('철회 전송 대기'),
          Text('서버 백업 ${_server.hasEntry ? 1 : 0}건'),
          if (_status.isNotEmpty) Text(_status),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _online && _consent == null && _pendingWithdrawal == null
                ? () => setState(() {
                    _consent = _server.grant();
                    _status = '백업 동의 완료';
                  })
                : null,
            child: const Text('테스트 백업 동의'),
          ),
          OutlinedButton(
            onPressed: _consent == null
                ? null
                : () => setState(() {
                    _queued = _lastRequest = _consent;
                    _status = '업로드 대기';
                    _flush();
                  }),
            child: const Text('테스트 기록 업로드'),
          ),
          OutlinedButton(
            onPressed: _consent == null
                ? null
                : () => setState(() {
                    _pendingWithdrawal = _consent;
                    _consent = null;
                    _queued = null;
                    _status = '대기 업로드 취소';
                    _flush();
                  }),
            child: const Text('백업 동의 철회'),
          ),
          TextButton(
            onPressed: _online && _lastRequest != null
                ? () => setState(() {
                    _status = _server.save(_lastRequest!)
                        ? '이전 요청 저장'
                        : '이전 요청 거부';
                  })
                : null,
            child: const Text('이전 요청 재전송 검증'),
          ),
        ],
      ),
    );
  }
}

class _RehearsalServer {
  int _generation = 0;
  bool _active = false;
  bool hasEntry = false;

  int grant() {
    if (!_active) {
      _generation++;
      _active = true;
    }
    return _generation;
  }

  void withdraw(int generation) {
    if (!_active || generation != _generation) return;
    _active = false;
    hasEntry = false;
  }

  bool save(int generation) {
    if (!_active || generation != _generation) return false;
    hasEntry = true;
    return true;
  }
}
