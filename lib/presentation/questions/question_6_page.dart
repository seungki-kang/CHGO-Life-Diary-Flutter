part of '../../main.dart';

class LifeDiaryQuestion6Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion6Page({super.key, required this.diaryDate});

  @override
  State<LifeDiaryQuestion6Page> createState() => _LifeDiaryQuestion6PageState();
}

class _LifeDiaryQuestion6PageState extends State<LifeDiaryQuestion6Page> {
  final TextEditingController personController = TextEditingController();
  final TextEditingController whatController = TextEditingController();
  final FocusNode personFocusNode = FocusNode();

  final List<Map<String, String>> gratitudes = [];
  int stage = 0;
  String? situationType;
  int? editingIndex;

  @override
  void initState() {
    super.initState();
    final draft = currentLifeDiaryDraft;
    stage = draft.q6Stage;
    gratitudes.addAll(
      draft.q6Gratitudes.map((item) => Map<String, String>.from(item)),
    );
    _removeDuplicateGratitudes();
    personController.text = draft.q6Person;
    whatController.text = _combinedGratitude(draft.q6What, draft.q6Why);
    situationType = draft.q6SituationType;
    editingIndex = draft.q6EditingIndex;
    // Stage 3 used to be a second completion summary.  Collapse older drafts
    // to the single three-or-more summary so Q7 -> Q6 never shows duplicates.
    if (stage == 3) stage = 2;
    if (editingIndex != null &&
        (editingIndex! < 0 || editingIndex! >= gratitudes.length)) {
      editingIndex = null;
    }
    // A saved list of three or more gratitudes is the authoritative complete
    // state. Empty transient fields must not reopen an accidental next entry.
    if (gratitudes.length < 3 && stage >= 2) {
      stage = 1;
    }
    if (gratitudes.length >= 3 &&
        editingIndex == null &&
        personController.text.trim().isEmpty &&
        whatController.text.trim().isEmpty) {
      stage = 2;
    }
  }

  void saveQ6Draft() {
    if (!_draftLifecycle.shouldPersist) return;
    _removeDuplicateGratitudes();
    final draft = currentLifeDiaryDraft;
    draft.q6Stage = stage;
    draft.q6Gratitudes
      ..clear()
      ..addAll(gratitudes.map((item) => Map<String, String>.from(item)));
    draft.q6Person = personController.text;
    draft.q6What = whatController.text;
    // Keep the canonical `why` field for backward compatibility. New UI
    // records the overlapping what/why response in the `what` field.
    draft.q6Why = '';
    draft.q6SituationType = situationType;
    draft.q6EditingIndex = editingIndex;
    persistCurrentLifeDiaryDraft();
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  bool get entryComplete =>
      personController.text.trim().isNotEmpty &&
      whatController.text.trim().isNotEmpty;

  String _gratitudeKey(Map<String, String> item) => [
    item['person']?.trim() ?? '',
    item['what']?.trim() ?? '',
    item['why']?.trim() ?? '',
    item['type']?.trim() ?? '',
  ].join('\u0000');

  void _removeDuplicateGratitudes() {
    final seen = <String>{};
    final unique = <Map<String, String>>[];
    for (final item in gratitudes) {
      if (seen.add(_gratitudeKey(item))) {
        unique.add(Map<String, String>.from(item));
      }
    }
    if (unique.length != gratitudes.length) {
      gratitudes
        ..clear()
        ..addAll(unique);
    }
  }

  String _combinedGratitude(String what, String why) {
    final normalizedWhat = what.trim();
    final normalizedWhy = why.trim();
    if (normalizedWhat.isEmpty) return normalizedWhy;
    if (normalizedWhy.isEmpty || normalizedWhy == normalizedWhat) {
      return normalizedWhat;
    }
    return '$normalizedWhat\n$normalizedWhy';
  }

  void startRecording() {
    setState(() {
      editingIndex = null;
      situationType = null;
      if (gratitudes.length >= 3) {
        personController.clear();
        whatController.clear();
        stage = 2;
      } else {
        stage = 1;
      }
    });
    saveQ6Draft();
  }

  void saveGratitude() {
    if (!entryComplete) return;
    final item = <String, String>{
      'person': personController.text.trim(),
      'what': whatController.text.trim(),
      'why': '',
      'type': situationType ?? '',
    };
    final index = editingIndex;
    if (index != null && index < gratitudes.length) {
      gratitudes[index] = item;
    } else {
      // Reopening Q6 can restore the last text fields. Never append the same
      // saved gratitude again as a new record.
      final duplicateIndex = gratitudes.indexWhere(
        (saved) => _gratitudeKey(saved) == _gratitudeKey(item),
      );
      if (duplicateIndex < 0) gratitudes.add(item);
    }

    personController.clear();
    whatController.clear();
    setState(() {
      situationType = null;
      editingIndex = null;
      stage = gratitudes.length >= 3 ? 2 : 1;
    });
    saveQ6Draft();
    if (stage == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) personFocusNode.requestFocus();
      });
    }
  }

  void addAnotherGratitude() {
    personController.clear();
    whatController.clear();
    setState(() {
      editingIndex = null;
      situationType = null;
      stage = 1;
    });
    saveQ6Draft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) personFocusNode.requestFocus();
    });
  }

  void editGratitude(int index) {
    final item = gratitudes[index];
    setState(() {
      editingIndex = index;
      personController.text = item['person'] ?? '';
      whatController.text = _combinedGratitude(
        item['what'] ?? '',
        item['why'] ?? '',
      );
      final savedType = item['type'];
      situationType = savedType == null || savedType.isEmpty ? null : savedType;
      stage = 1;
    });
    saveQ6Draft();
  }

  void deleteGratitude(int index) {
    if (gratitudes.length <= 3) return;
    setState(() => gratitudes.removeAt(index));
    saveQ6Draft();
  }

  Future<void> finishQuestion6() async {
    if (gratitudes.length < 3) return;
    // Keep one canonical summary state. Going back from Q7 now returns to
    // stage 2 instead of an additional, nearly identical completion screen.
    setState(() => stage = 2);
    saveQ6Draft();
    await goToNextLifeDiaryQuestion(
      context,
      widget.diaryDate,
      6,
      saveCurrent: saveQ6Draft,
    );
  }

  Future<void> handleBack() async {
    if (stage == 0) {
      await goToPreviousLifeDiaryQuestion(
        context,
        widget.diaryDate,
        6,
        saveCurrent: saveQ6Draft,
      );
      return;
    }
    if (stage == 1 && editingIndex == null && gratitudes.length >= 3) {
      setState(() => stage = 2);
      saveQ6Draft();
      return;
    }
    if (stage == 1 && editingIndex != null) {
      final previousIndex = editingIndex! - 1;
      if (previousIndex >= 0) {
        editGratitude(previousIndex);
      } else {
        setState(() {
          stage = 0;
          editingIndex = null;
        });
        saveQ6Draft();
      }
      return;
    }
    if (stage == 2) {
      // Editing is available through each card's explicit edit button.
      // The app-bar back button always continues to the previous question.
      await goToPreviousLifeDiaryQuestion(
        context,
        widget.diaryDate,
        6,
        saveCurrent: saveQ6Draft,
      );
      return;
    }
    setState(() {
      stage = previousQuestion6Stage(stage);
      editingIndex = null;
    });
    saveQ6Draft();
  }

  @override
  void dispose() {
    saveQ6Draft();
    personController.dispose();
    whatController.dispose();
    personFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: handleBack,
        ),
        title: const Text('생명일기'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '1~7번 문항 이동',
            onPressed: () => showLifeDiaryQuestionNavigator(
              context,
              widget.diaryDate,
              6,
              saveCurrent: saveQ6Draft,
            ),
            icon: const Icon(Icons.grid_view_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatDate(widget.diaryDate),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                currentLifeDiaryDraft.progressLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '질문 6/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: SingleChildScrollView(child: _buildStage())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (stage) {
      case 1:
        return _buildGratitudeEntry();
      case 2:
        return _buildThreeOrMoreCheck();
      case 3:
        return _buildCompletion();
      default:
        return _buildIntroduction();
    }
  }

  Widget _questionTitle() => const Text(
    '6. 감사할 것은 무엇인가?',
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
  );

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '“범사에 감사하라”\n'
            '(데살로니가전서 5장 18절)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '범사는 좋은 일뿐 아니라 힘든 일을 포함한 모든 일을 말합니다.\n\n'
          '좋은 일에는 받은 은혜를 기억하며 감사하고, 힘든 일 가운데서도 '
          '하나님께서 이루실 것을 믿으며 감사합니다.\n\n'
          '감사는 기적을 낳습니다.',
          style: TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 22),
        const Text(
          '오늘 구체적으로 감사할 내용을 3가지 이상 기록해 주세요.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '구체적인 감사는 “누구에게, 무엇을 또는 왜 감사하는가”를 기록하는 것입니다.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: startRecording,
            child: const Text('감사 기록 시작', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildGratitudeEntry() {
    final displayNumber = editingIndex == null
        ? gratitudes.length + 1
        : editingIndex! + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 12),
        Text(
          editingIndex == null
              ? '감사 $displayNumber번째 · 최소 3가지'
              : '감사 $displayNumber번째 수정',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: personController,
          focusNode: personFocusNode,
          onChanged: (_) {
            setState(() {});
            saveQ6Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '누구에게 감사합니까?',
            hintText: '예: 하나님, 배우자, 자녀, 가족, 교회 공동체',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: whatController,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) {
            setState(() {});
            saveQ6Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '무엇을 또는 왜 감사합니까?',
            hintText: '감사하는 내용이나 이유를 편하게 기록해 주세요.',
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '감사의 상황 · 선택 사항',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('좋은 일 가운데 드리는 감사'),
              selected: situationType == '좋은 일',
              onSelected: (selected) {
                setState(() => situationType = selected ? '좋은 일' : null);
                saveQ6Draft();
              },
            ),
            ChoiceChip(
              label: const Text('힘든 일 가운데 믿음으로 드리는 감사'),
              selected: situationType == '힘든 일',
              onSelected: (selected) {
                setState(() => situationType = selected ? '힘든 일' : null);
                saveQ6Draft();
              },
            ),
          ],
        ),
        const SizedBox(height: 26),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: entryComplete ? saveGratitude : null,
            child: Text(
              editingIndex != null
                  ? '수정 내용 저장'
                  : gratitudes.length < 2
                  ? '저장하고 다음 감사 기록'
                  : '감사 기록 저장',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gratitudeCard(int index, {required bool allowDelete}) {
    final item = gratitudes[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '감사 ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if ((item['type'] ?? '').isNotEmpty)
                  Chip(label: Text(item['type']!)),
              ],
            ),
            const SizedBox(height: 8),
            Text('누구에게\n${item['person'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              '무엇을 또는 왜\n'
              '${_combinedGratitude(item['what'] ?? '', item['why'] ?? '')}',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => editGratitude(index),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('수정'),
                ),
                if (allowDelete)
                  TextButton.icon(
                    onPressed: () => deleteGratitude(index),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('삭제'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeOrMoreCheck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '감사를 3가지 이상 기록했습니다.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '현재 ${gratitudes.length}가지 감사를 기록했습니다.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          gratitudes.length,
          (index) => _gratitudeCard(index, allowDelete: gratitudes.length > 3),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: addAnotherGratitude,
            icon: const Icon(Icons.add),
            label: const Text('감사를 더 기록합니다', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: finishQuestion6,
            child: const Text('생명일기 6번을 마칩니다', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '생명일기 6번을 마쳤습니다.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '오늘 ${gratitudes.length}가지 감사를 기록했습니다.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        ...List.generate(
          gratitudes.length,
          (index) => _gratitudeCard(index, allowDelete: gratitudes.length > 3),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: addAnotherGratitude,
          icon: const Icon(Icons.add),
          label: const Text('감사 추가하기'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              goToNextLifeDiaryQuestion(
                context,
                widget.diaryDate,
                6,
                saveCurrent: saveQ6Draft,
              );
            },
            child: const Text('생명일기 7번으로', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// V0.16a
// Life Diary Question 5
// ============================================================
