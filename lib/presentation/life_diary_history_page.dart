import 'package:flutter/material.dart';

import '../data/life_diary_repository.dart';
import '../domain/life_diary_models.dart';
import '../core/observability/app_logger.dart';
import 'life_diary_entry_editor_page.dart';

class LifeDiaryHistoryPage extends StatefulWidget {
  const LifeDiaryHistoryPage({
    super.key,
    required this.repository,
    required this.ownerUserId,
    this.logger,
  });

  final LifeDiaryRepository repository;
  final String ownerUserId;
  final AppLogger? logger;

  @override
  State<LifeDiaryHistoryPage> createState() => _LifeDiaryHistoryPageState();
}

class _LifeDiaryHistoryPageState extends State<LifeDiaryHistoryPage> {
  late Future<List<LifeDiaryEntry>> _entries;
  String _query = '';
  LifeDiaryEntryStatus? _status;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _entries = widget.repository.findByOwner(widget.ownerUserId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _entries;
  }

  List<LifeDiaryEntry> _visibleEntries(List<LifeDiaryEntry> source) {
    final query = _query.trim().toLowerCase();
    final entries = source.where((entry) {
      if (_status == null && entry.status == LifeDiaryEntryStatus.deleted) {
        return false;
      }
      if (_status != null && entry.status != _status) return false;
      if (query.isEmpty) return true;
      final searchable =
          '${_formatDate(entry.entryDate)} '
          '${entry.entryDate.toIso8601String().substring(0, 10)} '
          '시즌 ${entry.seasonNumber} ${entry.sessionNumber}회 '
          '${_statusLabel(entry.status)}';
      return searchable.toLowerCase().contains(query);
    }).toList();
    entries.sort((a, b) {
      final comparison = a.entryDate.compareTo(b.entryDate);
      return _newestFirst ? -comparison : comparison;
    });
    return entries;
  }

  Future<void> _restore(LifeDiaryEntry entry) async {
    await widget.repository.restore(entry.entryId);
    widget.logger?.audit('life_diary.entry_restored', {
      'entry_id': entry.entryId,
      'status': 'COMPLETED',
      'operation': 'RESTORE',
      'source': 'LOCAL_SQLITE',
    });
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 생명일기'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '날짜, 시즌, 회차, 상태 검색',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('활성 전체'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                const SizedBox(width: 6),
                for (final status in LifeDiaryEntryStatus.values) ...[
                  ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                  const SizedBox(width: 6),
                ],
                ActionChip(
                  avatar: Icon(
                    _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  label: Text(_newestFirst ? '최신순' : '오래된순'),
                  onPressed: () => setState(() => _newestFirst = !_newestFirst),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LifeDiaryEntry>>(
              future: _entries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageView(
                    icon: Icons.error_outline,
                    title: '기록을 불러오지 못했습니다.',
                    actionLabel: '다시 시도',
                    onAction: () => setState(_reload),
                  );
                }
                final entries = _visibleEntries(
                  snapshot.data ?? const <LifeDiaryEntry>[],
                );
                if (entries.isEmpty) {
                  return _MessageView(
                    icon: Icons.menu_book_outlined,
                    title: _query.isEmpty && _status == null
                        ? '아직 완성된 생명일기가 없습니다.'
                        : '조건에 맞는 생명일기가 없습니다.',
                    description: '검색어나 상태 필터를 변경해 보세요.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            child: Text('${entry.sessionNumber}'),
                          ),
                          title: Text(
                            _formatDate(entry.entryDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '시즌 ${entry.seasonNumber} · ${entry.sessionNumber}/50회 · '
                            '${_statusLabel(entry.status)}',
                          ),
                          trailing: entry.status == LifeDiaryEntryStatus.deleted
                              ? TextButton(
                                  onPressed: () => _restore(entry),
                                  child: const Text('복구'),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: entry.status == LifeDiaryEntryStatus.deleted
                              ? null
                              : () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LifeDiaryDetailPage(
                                        entry: entry,
                                        repository: widget.repository,
                                        logger: widget.logger,
                                      ),
                                    ),
                                  );
                                  if (changed == true && mounted)
                                    await _refresh();
                                },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LifeDiaryDetailPage extends StatefulWidget {
  const LifeDiaryDetailPage({
    super.key,
    required this.entry,
    required this.repository,
    this.logger,
  });

  final LifeDiaryEntry entry;
  final LifeDiaryRepository repository;
  final AppLogger? logger;

  @override
  State<LifeDiaryDetailPage> createState() => _LifeDiaryDetailPageState();
}

class _LifeDiaryDetailPageState extends State<LifeDiaryDetailPage> {
  late LifeDiaryEntry entry;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
  }

  Future<void> _edit() async {
    final reopened = LifeDiaryEntry(
      entryId: entry.entryId,
      ownerUserId: entry.ownerUserId,
      seasonNumber: entry.seasonNumber,
      sessionNumber: entry.sessionNumber,
      entryDate: entry.entryDate,
      status: LifeDiaryEntryStatus.reopened,
      schemaVersion: entry.schemaVersion,
      canonicalVersion: entry.canonicalVersion,
      questions: entry.questions,
    );
    final updated = await Navigator.push<LifeDiaryEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => LifeDiaryEntryEditorPage(
          entry: reopened,
          repository: widget.repository,
        ),
      ),
    );
    if (updated != null && mounted) {
      widget.logger?.audit('life_diary.entry_reopened', {
        'entry_id': entry.entryId,
        'operation': 'REOPEN',
        'source': 'LOCAL_SQLITE',
      });
      widget.logger?.audit('life_diary.entry_recompleted', {
        'entry_id': updated.entryId,
        'status': 'COMPLETED',
        'operation': 'UPDATE',
        'source': 'LOCAL_SQLITE',
      });
      setState(() {
        entry = updated;
        _changed = true;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('생명일기를 삭제하시겠습니까?'),
        content: const Text('삭제한 기록은 목록에서 보이지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.tombstone(entry.entryId);
    widget.logger?.audit('life_diary.entry_deleted', {
      'entry_id': entry.entryId,
      'operation': 'DELETE',
      'source': 'LOCAL_SQLITE',
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final q = entry.questions;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context, _changed),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('생명일기 상세'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '수정',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            _formatDate(entry.entryDate),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '시즌 ${entry.seasonNumber} · ${entry.sessionNumber}/50회 · '
            '${_statusLabel(entry.status)}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          _QuestionCard(
            number: 1,
            title: '오늘 발견한 옛사람',
            body: _parts([
              q.q1.narrative,
              _labels(q.q1.oldPersonIds, _oldPersonLabels),
            ]),
          ),
          _QuestionCard(
            number: 2,
            title: '십자가에서 처리합니다',
            body: _parts([
              q.q2.confession,
              _labels(q.q2.appliedOldPersonIds, _oldPersonLabels),
            ]),
          ),
          _QuestionCard(
            number: 3,
            title: '오늘 나에게 이루어진 하나님 나라',
            body: _parts([
              q.q3.contexts.map(_contextLabel).join(', '),
              q.q3.narrative,
              q.q3.declaration,
              _labels(q.q3.fruitIds, _fruitLabels),
            ]),
          ),
          _QuestionCard(
            number: 4,
            title: '타인의 옛사람을 긍휼히 바라봅니다',
            body: q.q4.narrative,
          ),
          _QuestionCard(number: 5, title: '성령님과의 교제', body: q.q5.narrative),
          _QuestionCard(
            number: 6,
            title: '감사',
            body: q.q6.items.isEmpty
                ? ''
                : q.q6.items
                      .map((item) => _parts([item.who, item.what, item.why]))
                      .join('\n\n'),
          ),
          _QuestionCard(
            number: 7,
            title: '무엇을 할 것인가?',
            body: q.q7.actions.join('\n\n'),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$number. $title',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              body.isEmpty ? '기록 없음' : body,
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: body.isEmpty ? Colors.grey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(description!, textAlign: TextAlign.center),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일';

String _statusLabel(LifeDiaryEntryStatus status) => switch (status) {
  LifeDiaryEntryStatus.draft => '작성 중',
  LifeDiaryEntryStatus.completed => '완성',
  LifeDiaryEntryStatus.reopened => '다시 작성 중',
  LifeDiaryEntryStatus.deleted => '삭제됨',
};

String _contextLabel(KingdomContext context) => switch (context) {
  KingdomContext.inner => '내 안',
  KingdomContext.community => '공동체·관계 안',
};

String _labels(Iterable<String> ids, Map<String, String> labels) =>
    ids.map((id) => labels[id] ?? id).join(', ');

String _parts(Iterable<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .join('\n\n');

const _oldPersonLabels = <String, String>{
  'JL-OLD-01': '수치심',
  'JL-OLD-02': '죄책감',
  'JL-OLD-03': '두려움',
  'JL-OLD-04': '나의 의(신념·고정관념)',
  'JL-OLD-05': '과거의 상처',
  'JL-OLD-06': '인정욕구',
  'JL-OLD-07': '죽음의 공포',
};

const _fruitLabels = <String, String>{
  'JL-FRUIT-01': '사랑',
  'JL-FRUIT-02': '희락',
  'JL-FRUIT-03': '화평',
  'JL-FRUIT-04': '오래참음',
  'JL-FRUIT-05': '자비',
  'JL-FRUIT-06': '양선',
  'JL-FRUIT-07': '충성',
  'JL-FRUIT-08': '온유',
  'JL-FRUIT-09': '절제',
};
