part of '../../main.dart';

class LifeDiaryQuestion7Page extends StatefulWidget {
  final DateTime diaryDate;
  const LifeDiaryQuestion7Page({super.key, required this.diaryDate});

  @override
  State<LifeDiaryQuestion7Page> createState() => _LifeDiaryQuestion7PageState();
}

class _LifeDiaryQuestion7PageState extends State<LifeDiaryQuestion7Page> {
  final actionController = TextEditingController();
  final reasonController = TextEditingController();
  final coachingNoteController = TextEditingController();
  int stage = 0;
  bool coachingRequested = false;
  bool _draftFinalized = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    final draft = currentLifeDiaryDraft;
    stage = draft.q7Stage;
    actionController.text = draft.q7Action;
    reasonController.text = draft.q7Reason;
    coachingRequested = draft.q7CoachingRequested;
    coachingNoteController.text = draft.q7CoachingNote;
  }

  void saveQ7Draft() {
    if (_draftFinalized) return;
    final draft = currentLifeDiaryDraft;
    draft.q7Stage = stage;
    draft.q7Action = actionController.text;
    draft.q7Reason = reasonController.text;
    draft.q7CoachingRequested = coachingRequested;
    draft.q7CoachingNote = coachingNoteController.text;
    persistCurrentLifeDiaryDraft();
  }

  bool get entryComplete =>
      actionController.text.trim().isNotEmpty &&
      reasonController.text.trim().isNotEmpty;

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  void changeStage(int value) {
    setState(() => stage = value);
    saveQ7Draft();
  }

  Future<void> handleBack() async {
    if (_draftFinalized) {
      Navigator.pop(context);
      return;
    }
    if (stage == 0) {
      await goToPreviousLifeDiaryQuestion(
        context,
        widget.diaryDate,
        7,
        saveCurrent: saveQ7Draft,
      );
      return;
    }
    setState(() => stage = previousQuestion7Stage(stage));
    saveQ7Draft();
  }

  Future<void> completeLifeDiary() async {
    if (_isCompleting) return;
    saveQ7Draft();
    final issues = const LifeDiaryCompletionValidator().validate(
      currentLifeDiaryDraft.toJson(),
    );
    if (issues.isNotEmpty) {
      await _showCompletionIssues(issues);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('생명일기를 완성하시겠습니까?'),
        content: const Text('최종 완성하기 전에 1~7번 기록을 다시 확인하고 자유롭게 수정할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('다시 확인'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('최종 완성'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isCompleting = true);
    currentLifeDiaryDraft.q7FinalCompleted = true;
    saveQ7Draft();
    try {
      var entry = lifeDiaryEntryFactory.fromUiDraft(
        widget.diaryDate,
        currentLifeDiaryDraft.toJson(),
        completed: true,
        seasonNumber: currentLifeDiaryDraft.seasonNumber,
        sessionNumber: currentLifeDiaryDraft.sessionNumber,
      );
      // The session number was assigned when this draft was started. Another
      // diary (another date's draft, or a deleted entry) may hold it by now, so
      // confirm it against the stored entries and move to the next free number
      // rather than colliding with or replacing that diary.
      final storedEntries = await lifeDiaryRepository.findByOwner(
        lifeDiaryEntryFactory.ownerUserId,
      );
      final session = resolveCompletionSession(
        entries: storedEntries,
        entryId: entry.entryId,
        draftSeason: entry.seasonNumber,
        draftSession: entry.sessionNumber,
      );
      if (session.seasonNumber != entry.seasonNumber ||
          session.sessionNumber != entry.sessionNumber) {
        currentLifeDiaryDraft
          ..seasonNumber = session.seasonNumber
          ..sessionNumber = session.sessionNumber;
        entry = lifeDiaryEntryFactory.fromUiDraft(
          widget.diaryDate,
          currentLifeDiaryDraft.toJson(),
          completed: true,
          seasonNumber: session.seasonNumber,
          sessionNumber: session.sessionNumber,
        );
      }
      await lifeDiaryRepository.save(entry);
      lifeDiaryLogger.info('life_diary.completed_entry_saved', {
        'entry_id': entry.entryId,
        'status': entry.status.name.toUpperCase(),
        'schema_version': entry.schemaVersion,
        'canonical_version': entry.canonicalVersion,
        'season_number': entry.seasonNumber,
        'session_number': entry.sessionNumber,
        'operation': 'UPSERT',
        'source': 'LOCAL_SQLITE',
      });
      if (!mounted) return;
      setState(() => stage = 3);
      saveQ7Draft();
      try {
        await _draftWrite;
        await lifeDiaryDraftStore.delete(widget.diaryDate);
        _draftFinalized = true;
        _draftLifecycle.markCompletedEntryClosing();
        lifeDiaryLogger.info('life_diary.completed_draft_removed', {
          'entry_id': entry.entryId,
          'operation': 'DELETE',
          'source': 'LOCAL_SQLITE',
        });
      } catch (error) {
        lifeDiaryLogger.warn('life_diary.completed_draft_cleanup_failed', {
          'entry_id': entry.entryId,
          'operation': 'DELETE',
          'source': 'LOCAL_SQLITE',
          'error_code': error.runtimeType.toString(),
        });
      }
    } catch (error) {
      currentLifeDiaryDraft.q7FinalCompleted = false;
      saveQ7Draft();
      lifeDiaryLogger.error('life_diary.completed_entry_save_failed', {
        'operation': 'UPSERT',
        'source': 'LOCAL_SQLITE',
        'error_code': error.runtimeType.toString(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('최종 저장에 실패했습니다: $error')));
    } finally {
      if (mounted && !_draftFinalized) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _showCompletionIssues(
    List<LifeDiaryCompletionIssue> issues,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('아직 완성하지 않은 문항이 있습니다'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: issues
                  .map(
                    (issue) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text('${issue.questionNumber}'),
                      ),
                      title: Text('${issue.questionNumber}번 확인 필요'),
                      subtitle: Text(issue.message),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        replaceLifeDiaryQuestion(
                          context,
                          widget.diaryDate,
                          issue.questionNumber,
                          saveCurrent: saveQ7Draft,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('계속 작성'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (!_draftFinalized) saveQ7Draft();
    actionController.dispose();
    reasonController.dispose();
    coachingNoteController.dispose();
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
              7,
              saveCurrent: saveQ7Draft,
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
                '질문 7/7',
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
    if (stage == 1) return _buildEntry();
    if (stage == 2) return _buildReview();
    if (stage == 3) return _buildCompletion();
    return _buildPause();
  }

  Widget _title() => const Text(
    '7. 무엇을 할 것인가?',
    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
  );

  Widget _buildPause() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(Icons.pause_circle_outline, size: 48),
            SizedBox(height: 14),
            Text(
              '잠시 모든 것을 멈춥니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14),
            Text(
              '1~6번의 기록을 천천히 돌아보며\n'
              '“나는 이제 무엇을 할 것인가?”를 묵상해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, height: 1.6),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        '7번은 생명일기의 열매입니다.\n\n'
        '성령님이 주시는 통찰과 하나님의 뜻, 응답, 아이디어와 지혜를 따라 '
        '실제로 행할 일을 구체적으로 기록합니다. 사소한 일부터 큰 일까지 '
        '기록할 수 있고, 매일 반복하며 발전시켜도 좋습니다.',
        style: TextStyle(fontSize: 16, height: 1.65),
      ),
      const SizedBox(height: 28),
      SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: () => changeStage(1),
          child: const Text('묵상하고 기록하기', style: TextStyle(fontSize: 18)),
        ),
      ),
    ],
  );

  Widget _buildEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(),
      const SizedBox(height: 10),
      const Text(
        '묵상하며 깨달은 구체적인 실행을 기록해 주세요.',
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
      const SizedBox(height: 22),
      TextField(
        controller: actionController,
        minLines: 4,
        maxLines: 7,
        onChanged: (_) {
          setState(() {});
          saveQ7Draft();
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '무엇을 할 것인가?',
          hintText: '내가 실제로 실행할 일을 구체적으로 기록해 주세요.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: reasonController,
        minLines: 4,
        maxLines: 7,
        onChanged: (_) {
          setState(() {});
          saveQ7Draft();
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '왜 이것을 실행하려고 합니까?',
          hintText: '이 실행이 필요한 이유와 받은 통찰을 기록해 주세요.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 56,
        child: FilledButton(
          onPressed: entryComplete ? () => changeStage(2) : null,
          child: const Text('실행 내용 확인', style: TextStyle(fontSize: 18)),
        ),
      ),
    ],
  );

  Widget _recordCard(String label, String value) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 17, height: 1.55)),
        ],
      ),
    ),
  );

  Widget _buildReview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        '나의 실행',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      _recordCard('무엇을 할 것인가?', actionController.text.trim()),
      _recordCard('왜 이것을 실행하려고 합니까?', reasonController.text.trim()),
      const SizedBox(height: 8),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('이 실행에 대해 코칭을 받고 싶습니다.'),
        subtitle: const Text('선택 사항이며, 선택하지 않아도 7번을 완성할 수 있습니다.'),
        value: coachingRequested,
        onChanged: (value) {
          setState(() => coachingRequested = value ?? false);
          saveQ7Draft();
        },
      ),
      if (coachingRequested) ...[
        const SizedBox(height: 10),
        TextField(
          controller: coachingNoteController,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => saveQ7Draft(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '코칭에서 함께 나누고 싶은 내용 · 선택 사항',
            alignLabelWithHint: true,
          ),
        ),
      ],
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () => changeStage(1),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('7번 기록 수정하기'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => showLifeDiaryQuestionNavigator(
          context,
          widget.diaryDate,
          7,
          saveCurrent: saveQ7Draft,
        ),
        icon: const Icon(Icons.grid_view_outlined),
        label: const Text('1~7번 기록 다시 확인하기'),
      ),
      const SizedBox(height: 22),
      SizedBox(
        height: 58,
        child: FilledButton(
          onPressed: _isCompleting ? null : completeLifeDiary,
          child: Text(
            _isCompleting ? '최종 저장 중…' : '생명일기 최종 완성',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    ],
  );

  Widget _buildCompletion() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.check_circle, size: 70, color: Colors.indigo),
      const SizedBox(height: 18),
      const Text(
        '오늘의 생명일기를 완성했습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      const Text(
        '묵상에서 얻은 통찰을 삶에서 실행해 보세요.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, height: 1.5),
      ),
      const SizedBox(height: 26),
      _recordCard('나의 실행', actionController.text.trim()),
      _recordCard('실행하는 이유', reasonController.text.trim()),
      if (coachingRequested) const Chip(label: Text('코칭 희망 · 선택 완료')),
      const SizedBox(height: 18),
      SizedBox(
        height: 58,
        child: FilledButton.icon(
          onPressed: () {
            _forceFreshDiaryDate = widget.diaryDate;
            currentLifeDiaryDraft.reset(widget.diaryDate);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.refresh),
          label: const Text(
            '처음으로 돌아가 새 생명일기 쓰기',
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
    ],
  );
}

// ============================================================
// V0.17a
// Life Diary Question 6
// ============================================================
