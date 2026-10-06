import 'package:flutter/material.dart';

import '../data/life_diary_repository.dart';
import '../domain/life_diary_models.dart';

class LifeDiaryEntryEditorPage extends StatefulWidget {
  const LifeDiaryEntryEditorPage({
    super.key,
    required this.entry,
    required this.repository,
  });

  final LifeDiaryEntry entry;
  final LifeDiaryRepository repository;

  @override
  State<LifeDiaryEntryEditorPage> createState() =>
      _LifeDiaryEntryEditorPageState();
}

class _LifeDiaryEntryEditorPageState extends State<LifeDiaryEntryEditorPage> {
  late final List<TextEditingController> _controllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.entry.questions;
    _controllers = [
      TextEditingController(text: q.q1.narrative),
      TextEditingController(text: q.q3.narrative),
      TextEditingController(text: q.q3.declaration),
      TextEditingController(text: q.q4.narrative),
      TextEditingController(text: q.q5.narrative),
      TextEditingController(
        text: q.q6.items
            .map(
              (item) => [
                item.who,
                item.what,
                item.why,
              ].where((value) => value.trim().isNotEmpty).join(' | '),
            )
            .join('\n'),
      ),
      TextEditingController(text: q.q7.actions.join('\n')),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final original = widget.entry;
    final q = original.questions;
    final updated = LifeDiaryEntry(
      entryId: original.entryId,
      ownerUserId: original.ownerUserId,
      seasonNumber: original.seasonNumber,
      sessionNumber: original.sessionNumber,
      entryDate: original.entryDate,
      status: LifeDiaryEntryStatus.completed,
      schemaVersion: original.schemaVersion,
      canonicalVersion: original.canonicalVersion,
      questions: LifeDiaryQuestions(
        q1: Q1Payload(
          narrative: _controllers[0].text.trim(),
          oldPersonIds: q.q1.oldPersonIds,
        ),
        q2: q.q2,
        q3: Q3Payload(
          contexts: q.q3.contexts,
          narrative: _controllers[1].text.trim(),
          declaration: _controllers[2].text.trim(),
          fruitIds: q.q3.fruitIds,
        ),
        q4: Q4Payload(
          narrative: _controllers[3].text.trim(),
          revisitedQ1Q2: q.q4.revisitedQ1Q2,
        ),
        q5: Q5Payload(
          communionType: q.q5.communionType,
          narrative: _controllers[4].text.trim(),
        ),
        q6: Q6Payload(items: _gratitudeItems(_controllers[5].text)),
        q7: Q7Payload(actions: _nonEmptyLines(_controllers[6].text)),
      ),
    );
    try {
      await widget.repository.save(original);
      await widget.repository.save(updated);
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('수정 내용을 저장하지 못했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생명일기 수정'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            '2번 십자가 고백과 Canonical 선택값은 그대로 유지됩니다.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _field(0, '1. 오늘 발견한 옛사람'),
          _field(1, '3. 하나님 나라 경험'),
          _field(2, '3. 고백·선포·선언'),
          _field(3, '4. 타인의 옛사람을 긍휼히 바라봄'),
          _field(4, '5. 성령님과의 교제'),
          _field(5, '6. 감사', hint: '한 줄에 하나씩: 대상 | 내용 | 이유'),
          _field(6, '7. 실천', hint: '한 줄에 하나씩 기록'),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('수정 완료'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(int index, String label, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: _controllers[index],
      minLines: 3,
      maxLines: 7,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

List<String> _nonEmptyLines(String value) => value
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);

List<GratitudeItem> _gratitudeItems(String value) =>
    _nonEmptyLines(value)
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          return GratitudeItem(
            who: parts.isNotEmpty ? parts[0] : '',
            what: parts.length > 1 ? parts[1] : '',
            why: parts.length > 2 ? parts.sublist(2).join(' | ') : '',
          );
        })
        .toList(growable: false);
