import 'package:flutter/material.dart';

import '../data/life_diary_repository.dart';
import '../domain/life_diary_models.dart';

class LifeDiaryHistoryPage extends StatefulWidget {
  const LifeDiaryHistoryPage({
    super.key,
    required this.repository,
    required this.ownerUserId,
  });

  final LifeDiaryRepository repository;
  final String ownerUserId;

  @override
  State<LifeDiaryHistoryPage> createState() => _LifeDiaryHistoryPageState();
}

class _LifeDiaryHistoryPageState extends State<LifeDiaryHistoryPage> {
  late Future<List<LifeDiaryEntry>> _entries;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 생명일기'), centerTitle: true),
      body: FutureBuilder<List<LifeDiaryEntry>>(
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
          final entries = (snapshot.data ?? const <LifeDiaryEntry>[])
              .where((entry) => entry.status != LifeDiaryEntryStatus.deleted)
              .toList(growable: false);
          if (entries.isEmpty) {
            return const _MessageView(
              icon: Icons.menu_book_outlined,
              title: '아직 완성된 생명일기가 없습니다.',
              description: '생명일기 1~7번을 완성하면 이곳에서 다시 볼 수 있습니다.',
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
                    leading: CircleAvatar(child: Text('${entry.sessionNumber}')),
                    title: Text(
                      _formatDate(entry.entryDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '시즌 ${entry.seasonNumber} · ${entry.sessionNumber}/50회 · '
                      '${_statusLabel(entry.status)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LifeDiaryDetailPage(entry: entry),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class LifeDiaryDetailPage extends StatelessWidget {
  const LifeDiaryDetailPage({super.key, required this.entry});

  final LifeDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final q = entry.questions;
    return Scaffold(
      appBar: AppBar(title: const Text('생명일기 상세'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            _formatDate(entry.entryDate),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          _QuestionCard(
            number: 5,
            title: '성령님과의 교제',
            body: q.q5.narrative,
          ),
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

String _parts(Iterable<String> values) =>
    values.map((value) => value.trim()).where((value) => value.isNotEmpty).join('\n\n');

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
