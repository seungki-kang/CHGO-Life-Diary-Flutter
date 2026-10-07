import 'package:flutter/material.dart';

import '../application/life_diary_draft_resume.dart';
import '../core/observability/app_logger.dart';
import '../data/life_diary_draft_store.dart';

typedef DraftResumeCallback = Future<void> Function(
  BuildContext context,
  LifeDiaryDraftRecord record,
  int questionNumber,
);

typedef DraftLoader = Future<List<LifeDiaryDraftRecord>> Function();
typedef DraftDeleteCallback = Future<void> Function(DateTime date);

class LifeDiaryDraftsPage extends StatefulWidget {
  const LifeDiaryDraftsPage({
    super.key,
    this.store,
    required this.onResume,
    this.loadDrafts,
    this.deleteDraft,
    this.logger,
  }) : assert(
         store != null || (loadDrafts != null && deleteDraft != null),
         'Provide a store or both draft callbacks.',
       );

  final LifeDiaryDraftStore? store;
  final DraftResumeCallback onResume;
  final DraftLoader? loadDrafts;
  final DraftDeleteCallback? deleteDraft;
  final AppLogger? logger;

  @override
  State<LifeDiaryDraftsPage> createState() => _LifeDiaryDraftsPageState();
}

class _LifeDiaryDraftsPageState extends State<LifeDiaryDraftsPage> {
  late Future<List<LifeDiaryDraftRecord>> _drafts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _drafts = widget.loadDrafts?.call() ?? widget.store!.listAll();
  }

  Future<void> _delete(LifeDiaryDraftRecord draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('임시저장을 삭제하시겠습니까?'),
        content: const Text('완성되지 않은 작성 내용이 삭제됩니다.'),
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
    if (widget.deleteDraft != null) {
      await widget.deleteDraft!(draft.date);
    } else {
      await widget.store!.delete(draft.date);
    }
    widget.logger?.audit('life_diary.draft_deleted', {
      'operation': 'DELETE',
      'source': 'LOCAL_SQLITE',
    });
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('작성 중인 생명일기'), centerTitle: true),
      body: FutureBuilder<List<LifeDiaryDraftRecord>>(
        future: _drafts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('임시저장을 불러오지 못했습니다.'));
          }
          final drafts = snapshot.data ?? const [];
          if (drafts.isEmpty) {
            return const Center(child: Text('작성 중인 생명일기가 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final question = LifeDiaryDraftResume.questionNumber(
                draft.payload,
              );
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$question')),
                  title: Text(_formatDate(draft.date)),
                  subtitle: Text('$question번 문항부터 이어쓰기'),
                  trailing: IconButton(
                    tooltip: '임시저장 삭제',
                    onPressed: () => _delete(draft),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onTap: () => widget.onResume(context, draft, question),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}년 ${date.month}월 ${date.day}일';
