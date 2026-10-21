part of '../../main.dart';

class LifeDiaryQuestion5Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion5Page({super.key, required this.diaryDate});

  @override
  State<LifeDiaryQuestion5Page> createState() => _LifeDiaryQuestion5PageState();
}

class _LifeDiaryQuestion5PageState extends State<LifeDiaryQuestion5Page> {
  static const String noRecordSentence =
      '말할 수 없는 탄식으로 나를 위해 친히 간구하시는 성령님, 감사합니다.';

  final TextEditingController dailyController = TextEditingController();
  final TextEditingController wordController = TextEditingController();
  final TextEditingController noRecordController = TextEditingController();

  int stage = 0;
  String? selection;
  String? guidance;

  @override
  void initState() {
    super.initState();
    final draft = currentLifeDiaryDraft;
    stage = draft.q5Stage;
    selection = draft.q5Selection;
    dailyController.text = draft.q5DailyRecord;
    wordController.text = draft.q5WordRecord;
    noRecordController.text = draft.q5NoRecordDeclaration;
  }

  void saveQ5Draft() {
    if (!_draftLifecycle.shouldPersist) return;
    final draft = currentLifeDiaryDraft;
    draft.q5Stage = stage;
    draft.q5Selection = selection;
    draft.q5DailyRecord = dailyController.text;
    draft.q5WordRecord = wordController.text;
    draft.q5NoRecordDeclaration = noRecordController.text;
    persistCurrentLifeDiaryDraft();
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  Future<void> handleBack() async {
    if (stage == 0) {
      await goToPreviousLifeDiaryQuestion(
        context,
        widget.diaryDate,
        5,
        saveCurrent: saveQ5Draft,
      );
      return;
    }
    setState(() {
      stage = previousQuestion5Stage(stage: stage, selection: selection);
      guidance = null;
    });
    saveQ5Draft();
  }

  String normalized(String text) => text
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[,，]'), '')
      .replaceAll(RegExp(r'[,.，。]+$'), '');

  void beginSelectedRecord() {
    if (selection == null) return;
    setState(() {
      guidance = null;
      if (selection == 'daily' || selection == 'both') {
        stage = 1;
      } else if (selection == 'word') {
        stage = 2;
      } else {
        stage = 3;
      }
    });
    saveQ5Draft();
  }

  void completeDailyRecord() {
    if (dailyController.text.trim().isEmpty) return;
    setState(() {
      stage = selection == 'both' ? 2 : 4;
    });
    saveQ5Draft();
  }

  void completeWordRecord() {
    if (wordController.text.trim().isEmpty) return;
    setState(() => stage = 4);
    saveQ5Draft();
  }

  void checkNoRecordDeclaration() {
    if (normalized(noRecordController.text) == normalized(noRecordSentence)) {
      setState(() {
        guidance = null;
        stage = 4;
      });
      saveQ5Draft();
      return;
    }
    setState(() {
      guidance =
          '${characterDifferenceGuidance(noRecordController.text, noRecordSentence)}\n'
          '띄어쓰기와 마지막 마침표는 달라도 괜찮습니다.';
    });
  }

  @override
  void dispose() {
    saveQ5Draft();
    dailyController.dispose();
    wordController.dispose();
    noRecordController.dispose();
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
              5,
              saveCurrent: saveQ5Draft,
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
                '질문 5/7',
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
        return _buildDailyRecord();
      case 2:
        return _buildWordRecord();
      case 3:
        return _buildNoRecordDeclaration();
      case 4:
        return _buildCompletion();
      default:
        return _buildSelection();
    }
  }

  Widget _questionTitle() => const Text(
    '5. 성령님과 어떤 교제(경험)를 나누었는가?',
    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, height: 1.4),
  );

  Widget _buildSelection() {
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
            '성령 하나님은 우주 만물 가운데 나를 도우시려고 '
            '나에게 가장 관심이 많으신 분이신데, 나는 그분을 '
            '외면하며 살아갈 때가 있습니다.\n\n(로마서 8장 26절)',
            style: TextStyle(fontSize: 16, height: 1.55),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '오늘 성령님과의 교제와 경험을 돌아봅니다.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: selection,
          onChanged: (newValue) {
            setState(() => selection = newValue);
            saveQ5Draft();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _selectionTile(
                value: 'daily',
                title: '일상에서 성령님과 나눈 교제(경험)를 기록합니다.',
              ),
              _selectionTile(
                value: 'word',
                title: '말씀을 읽다가 성령께서 깨닫게 하신 것을 기록합니다.',
              ),
              _selectionTile(value: 'both', title: '두 가지 모두 기록합니다.'),
              _selectionTile(
                value: 'none',
                title: '오늘 5번에 구체적으로 기록할 것이 없습니다.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: selection == null ? null : beginSelectedRecord,
            child: Text(
              selection == 'none' ? '감사문 기록하기' : '선택한 내용 기록하기',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectionTile({required String value, required String title}) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
    );
  }

  Widget _buildDailyRecord() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 12),
        Text(
          selection == 'both' ? '교제 기록 1/2 · 일상' : '일상에서 나눈 교제',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '오늘 일상에서 성령님과 나눈 교제와 경험을 기록해 주세요.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        const Text(
          '• 성령님께 무엇을 물었는가?\n'
          '• 성령님께 무엇을 속삭였는가?\n'
          '• 내게 하시는 어떤 말씀을 들었는가?\n'
          '• 그 말씀에 어떻게 순종했는가?',
          style: TextStyle(fontSize: 16, height: 1.7),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: dailyController,
          minLines: 7,
          maxLines: 12,
          onChanged: (_) {
            setState(() {});
            saveQ5Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '성령님과 나눈 교제의 과정을 구체적으로 기록해 주세요.',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: dailyController.text.trim().isEmpty
                ? null
                : completeDailyRecord,
            child: Text('일상 교제 기록 완료', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildWordRecord() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 12),
        Text(
          selection == 'both' ? '교제 기록 2/2 · 말씀' : '말씀을 통한 교제',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '말씀을 읽다가 성령께서 깨닫게 하신 것을 기록해 주세요.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        const Text(
          '• 어떤 말씀을 읽었는가?\n'
          '• 성령께서 무엇을 깨닫게 하셨는가?\n'
          '• 그 깨달음에 어떻게 반응하고 순종했는가?',
          style: TextStyle(fontSize: 16, height: 1.7),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: wordController,
          minLines: 7,
          maxLines: 12,
          onChanged: (_) {
            setState(() {});
            saveQ5Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '말씀과 깨달음, 반응과 순종의 과정을 기록해 주세요.',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: wordController.text.trim().isEmpty
                ? null
                : completeWordRecord,
            child: const Text('말씀 교제 기록 완료', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _fadedSentence(String sentence) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      sentence,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        height: 1.55,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.48),
      ),
    ),
  );

  Widget _buildNoRecordDeclaration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 16),
        const Text(
          '오늘 5번에 구체적으로 기록할 것이 없다면',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('연하게 보이는 감사문 전체를 직접 기록해 주세요.'),
        const SizedBox(height: 20),
        _fadedSentence(noRecordSentence),
        const SizedBox(height: 18),
        TextField(
          controller: noRecordController,
          minLines: 4,
          maxLines: 6,
          onChanged: (_) {
            setState(() => guidance = null);
            saveQ5Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '위 문장 전체를 직접 기록해 주세요.',
          ),
        ),
        if (guidance != null) ...[
          const SizedBox(height: 10),
          Text(
            guidance!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: noRecordController.text.trim().isEmpty
                ? null
                : checkNoRecordDeclaration,
            child: const Text('감사 고백 완료', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    final summary = selection == 'both'
        ? '일상에서의 교제와 말씀을 통한 깨달음을 모두 기록했습니다.'
        : selection == 'daily'
        ? '일상에서 성령님과 나눈 교제와 경험을 기록했습니다.'
        : selection == 'word'
        ? '말씀을 읽으며 성령께서 깨닫게 하신 내용을 기록했습니다.'
        : '말할 수 없는 탄식으로 간구하시는 성령님께 감사드렸습니다.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '생명일기 5번을 마쳤습니다.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(summary, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 18),
        if ((selection == 'daily' || selection == 'both') &&
            dailyController.text.trim().isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '일상에서 성령님과 나눈 교제',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(dailyController.text),
                ],
              ),
            ),
          ),
        if ((selection == 'word' || selection == 'both') &&
            wordController.text.trim().isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '말씀을 통해 깨닫게 하신 내용',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(wordController.text),
                ],
              ),
            ),
          ),
        if (selection == 'none')
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                noRecordController.text,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => stage = 0);
            saveQ5Draft();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('5번 기록 수정하기'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              goToNextLifeDiaryQuestion(
                context,
                widget.diaryDate,
                5,
                saveCurrent: saveQ5Draft,
              );
            },
            child: const Text('6번으로 이동', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// V0.16a
// Life Diary Question 4
// ============================================================
