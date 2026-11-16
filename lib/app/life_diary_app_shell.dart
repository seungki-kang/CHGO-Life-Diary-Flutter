part of '../main.dart';

final LifeDiarySessionDraft currentLifeDiaryDraft = LifeDiarySessionDraft();
late final LifeDiaryDraftStore lifeDiaryDraftStore;
late final LifeDiaryRepository lifeDiaryRepository;
final LifeDiaryEntryFactory lifeDiaryEntryFactory = LifeDiaryEntryFactory();
final AppLogger lifeDiaryLogger = AppLogger();
final _draftPersistence = LifeDiaryDraftPersistence(
  save: (date, payload) => lifeDiaryDraftStore.save(date, payload),
  onRetry: (attempt, error) =>
      lifeDiaryLogger.warn('life_diary.draft_save_retry', {
        'operation': 'UPSERT',
        'source': 'LOCAL_SQLITE',
        'retry_count': attempt,
        'error_code': error.runtimeType.toString(),
      }),
);
Future<void> get _draftWrite => _draftPersistence.settled;
final LifeDiaryDraftLifecycle _draftLifecycle = LifeDiaryDraftLifecycle();
typedef LifeDiaryDraftSaveCallback = Future<bool> Function();

Future<bool>? _latestDraftSave;

Future<bool> persistCurrentLifeDiaryDraft() {
  final date = currentLifeDiaryDraft.diaryDate;
  if (!_draftLifecycle.shouldPersist || date == null) return Future.value(true);
  return _latestDraftSave = _persistDraft(date, currentLifeDiaryDraft.toJson());
}

Future<bool> _persistDraft(DateTime date, Map<String, Object?> payload) async {
  try {
    await _draftPersistence.enqueue(date, payload);
    lifeDiaryLogger.debug('life_diary.draft_saved', {
      'operation': 'UPSERT',
      'source': 'LOCAL_SQLITE',
    });
    return true;
  } catch (error) {
    lifeDiaryLogger.error('life_diary.draft_save_failed', {
      'operation': 'UPSERT',
      'source': 'LOCAL_SQLITE',
      'error_code': error.runtimeType.toString(),
    });
    return false;
  }
}

Future<bool> restoreLifeDiaryDraft(DateTime date) async {
  await _draftWrite;
  final payload = await lifeDiaryDraftStore.load(date);
  if (payload == null) {
    lifeDiaryLogger.debug('life_diary.draft_not_found', {
      'operation': 'LOAD',
      'source': 'LOCAL_SQLITE',
    });
    return false;
  }
  if (!await _loadRecoverableDraft(date, payload)) return false;
  lifeDiaryLogger.info('life_diary.draft_restored', {
    'operation': 'LOAD',
    'source': 'LOCAL_SQLITE',
  });
  return true;
}

// Older releases marked the draft before the final entry committed.
Future<bool> _loadRecoverableDraft(
  DateTime date,
  Map<String, Object?> payload,
) async {
  final draft = currentLifeDiaryDraft..loadJson(date, payload);
  if (!draft.q7FinalCompleted) return true;
  final entryId = lifeDiaryEntryFactory.entryIdFor(
    date,
    draft.seasonNumber,
    draft.sessionNumber,
  );
  final entry = await lifeDiaryRepository.findById(entryId);
  if (entry != null && entry.status != LifeDiaryEntryStatus.draft) {
    await lifeDiaryDraftStore.delete(date);
    return false;
  }
  draft.q7FinalCompleted = false;
  if (draft.q7Stage == 3) draft.q7Stage = 2;
  return true;
}

Widget buildLifeDiaryQuestionPage(DateTime diaryDate, int number) {
  if (number == 1) return LifeDiaryReadyPage(diaryDate: diaryDate);
  if (number == 2) {
    return LifeDiaryQuestion2Page(
      diaryDate: diaryDate,
      selectedOldSelves: currentLifeDiaryDraft.q1OldSelves.toList(),
      noOldSelfToday: currentLifeDiaryDraft.q1NoOldSelf,
    );
  }
  if (number == 3) return LifeDiaryQuestion3Page(diaryDate: diaryDate);
  if (number == 4) return LifeDiaryQuestion4Page(diaryDate: diaryDate);
  if (number == 5) return LifeDiaryQuestion5Page(diaryDate: diaryDate);
  if (number == 6) return LifeDiaryQuestion6Page(diaryDate: diaryDate);
  return LifeDiaryQuestion7Page(diaryDate: diaryDate);
}

Future<void> resumeLifeDiaryDraft(
  BuildContext context,
  LifeDiaryDraftRecord record,
  int questionNumber,
) async {
  if (!await restoreLifeDiaryDraft(record.date) || !context.mounted) return;
  // Completing a diary turns persistence off until a new draft begins. Without
  // this, a draft resumed later in the same app run was never saved again.
  _draftLifecycle.beginDraft();
  lifeDiaryLogger.info('life_diary.draft_resumed', {
    'question_id': 'JL-LD-Q${questionNumber.toString().padLeft(2, '0')}',
    'operation': 'LOAD',
    'source': 'LOCAL_SQLITE',
  });
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => buildLifeDiaryQuestionPage(record.date, questionNumber),
    ),
  );
}

final _pendingDraftNavigation = <BuildContext>{};

Future<bool> _saveBeforeNavigation(
  BuildContext context,
  LifeDiaryDraftSaveCallback saveCurrent,
) async {
  if (!_pendingDraftNavigation.add(context)) return false;
  try {
    final previousSave = _latestDraftSave;
    var pending = saveCurrent();
    var saved = await pending;
    // An onChanged autosave can queue newer input while the route waits.
    while (saved) {
      final latest = _latestDraftSave;
      if (latest == null ||
          identical(latest, previousSave) ||
          identical(latest, pending)) {
        break;
      }
      pending = latest;
      saved = await pending;
    }
    if (!context.mounted || ModalRoute.of(context)?.isCurrent == false) {
      return false;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('임시저장에 실패했습니다. 같은 버튼을 눌러 다시 시도해 주세요.')),
      );
    }
    return saved;
  } finally {
    _pendingDraftNavigation.remove(context);
  }
}

Widget _guardDraftBack(
  BuildContext context,
  LifeDiaryDraftSaveCallback saveCurrent,
  Widget child,
) => PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) confirmDraftExit(context, saveCurrent);
  },
  child: child,
);

Future<void> confirmDraftExit(
  BuildContext context,
  LifeDiaryDraftSaveCallback saveCurrent, {
  Object? result,
}) async {
  if (await _saveBeforeNavigation(context, saveCurrent) && context.mounted) {
    Navigator.pop(context, result);
  }
}

/// Moves between diary questions by canonical question order, not route history.
///
/// Replacing the current question route prevents grid jumps (for example Q2
/// -> Q4) from leaving a stale Q2 route underneath Q4. Every transition first
/// saves the visible question and waits for that write to finish.
Future<void> replaceLifeDiaryQuestion(
  BuildContext context,
  DateTime diaryDate,
  int targetQuestion, {
  LifeDiaryDraftSaveCallback? saveCurrent,
}) async {
  if (targetQuestion < 1 || targetQuestion > 7) {
    throw RangeError.range(targetQuestion, 1, 7, 'targetQuestion');
  }
  if (!await _saveBeforeNavigation(
    context,
    saveCurrent ?? persistCurrentLifeDiaryDraft,
  )) {
    return;
  }
  if (!context.mounted) return;
  await Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => buildLifeDiaryQuestionPage(diaryDate, targetQuestion),
    ),
  );
}

Future<void> goToPreviousLifeDiaryQuestion(
  BuildContext context,
  DateTime diaryDate,
  int currentQuestion, {
  required LifeDiaryDraftSaveCallback saveCurrent,
}) async {
  if (currentQuestion <= 1) {
    await confirmDraftExit(context, saveCurrent);
    return;
  }
  await replaceLifeDiaryQuestion(
    context,
    diaryDate,
    previousLifeDiaryLocation(currentQuestion),
    saveCurrent: saveCurrent,
  );
}

Future<void> goToNextLifeDiaryQuestion(
  BuildContext context,
  DateTime diaryDate,
  int currentQuestion, {
  required LifeDiaryDraftSaveCallback saveCurrent,
}) async {
  if (currentQuestion >= 7) return;
  await replaceLifeDiaryQuestion(
    context,
    diaryDate,
    nextLifeDiaryLocation(currentQuestion),
    saveCurrent: saveCurrent,
  );
}

Future<void> showLifeDiaryQuestionNavigator(
  BuildContext context,
  DateTime diaryDate,
  int currentQuestion, {
  LifeDiaryDraftSaveCallback? saveCurrent,
}) async {
  final completionValidator = const LifeDiaryCompletionValidator();
  final draftJson = currentLifeDiaryDraft.toJson();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '생명일기 문항 이동',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('최종 완성 전까지 작성한 내용은 지워지지 않습니다.'),
            const SizedBox(height: 14),
            ...List.generate(7, (index) {
              final number = index + 1;
              final q1Ready =
                  currentLifeDiaryDraft.q1NoOldSelf ||
                  currentLifeDiaryDraft.q1OldSelves.isNotEmpty;
              final available = number <= 7 && (number != 2 || q1Ready);
              final completion = completionValidator.status(draftJson, number);
              final statusLabel = switch (completion) {
                LifeDiaryQuestionCompletion.complete => '완료',
                LifeDiaryQuestionCompletion.inProgress => '작성 중',
                LifeDiaryQuestionCompletion.notStarted => '미작성',
              };
              return ListTile(
                leading: CircleAvatar(child: Text('$number')),
                title: Text(
                  number == currentQuestion
                      ? '$number번 · 현재 문항 · $statusLabel'
                      : available
                      ? '$number번 · $statusLabel'
                      : number == 2
                      ? '2번 · 먼저 1번을 기록해 주세요'
                      : '$number번 · 준비 중',
                ),
                trailing: completion == LifeDiaryQuestionCompletion.complete
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : number == currentQuestion
                    ? const Icon(Icons.edit_outlined)
                    : available
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_outline),
                enabled: available && number != currentQuestion,
                onTap: !available || number == currentQuestion
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        replaceLifeDiaryQuestion(
                          context,
                          diaryDate,
                          number,
                          saveCurrent: saveCurrent,
                        );
                      },
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await LifeDiaryDatabase.open();
  lifeDiaryLogger.info('life_diary.database_opened', {
    'operation': 'OPEN',
    'source': 'LOCAL_SQLITE',
    'database_version': lifeDiaryDatabaseVersion,
  });
  lifeDiaryDraftStore = LifeDiaryDraftStore(database);
  lifeDiaryRepository = SqliteLifeDiaryRepository(database);
  runApp(const ChgoLifeDiaryApp());
}

class ChgoLifeDiaryApp extends StatelessWidget {
  const ChgoLifeDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CHGO Life Diary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6759A8)),
        useMaterial3: true,
      ),
      home: const LifeDiaryStartPage(),
    );
  }
}

// ============================================================
// V0.16a
// Start Page
// ============================================================

class LifeDiaryStartPage extends StatelessWidget {
  const LifeDiaryStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHGO Life Diary'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRect(
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: Transform.scale(
                      scale: 2.1,
                      child: Image.asset(
                        'assets/branding/jesuslife_logo_light.jpg',
                        fit: BoxFit.cover,
                        semanticLabel: 'JesusLife',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  '생명일기',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 32),

                const Text(
                  '생명일기의 모든 과정은\n'
                  '성령의 역사입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, height: 1.6),
                ),

                const SizedBox(height: 16),

                const Text(
                  '성령을 의지하며\n'
                  '자신의 내면과 삶을 바라봅니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LifeDiaryDatePage(),
                        ),
                      );
                    },
                    child: const Text(
                      '생명일기 시작',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LifeDiaryHistoryPage(
                            repository: lifeDiaryRepository,
                            ownerUserId: lifeDiaryEntryFactory.ownerUserId,
                            logger: lifeDiaryLogger,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text(
                      '지난 생명일기 보기',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LifeDiaryDraftsPage(
                            store: lifeDiaryDraftStore,
                            onResume: resumeLifeDiaryDraft,
                            logger: lifeDiaryLogger,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text(
                      '작성 중인 생명일기',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Flutter V0.18a',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Date Selection Page
// ============================================================

class LifeDiaryDatePage extends StatefulWidget {
  const LifeDiaryDatePage({super.key});

  @override
  State<LifeDiaryDatePage> createState() => _LifeDiaryDatePageState();
}

class _LifeDiaryDatePageState extends State<LifeDiaryDatePage> {
  DateTime selectedDate = DateTime.now();
  LifeDiaryProgress _progress = const LifeDiaryProgress(
    seasonNumber: 1,
    sessionNumber: 1,
  );

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final entries = await lifeDiaryRepository.findByOwner(
      lifeDiaryEntryFactory.ownerUserId,
    );
    final progress = resolveLifeDiaryProgress(entries, selectedDate);
    if (mounted) setState(() => _progress = progress);
  }

  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000, 1, 1),

      // 미래 날짜 선택 금지
      lastDate: DateTime(now.year, now.month, now.day),

      helpText: '생명일기 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
      await _loadProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생명일기'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _progress.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              '생명일기를 기록할 날짜를\n선택해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 48),

                  const SizedBox(height: 16),

                  const Text(
                    '선택한 날짜',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    formatDate(selectedDate),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              onPressed: selectDate,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('다른 날짜 선택'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () async {
                  final restored = await restoreLifeDiaryDraft(selectedDate);
                  final action = _draftLifecycle.restoredDraftAction(
                    restored: restored,
                    draftSeason: currentLifeDiaryDraft.seasonNumber,
                    draftSession: currentLifeDiaryDraft.sessionNumber,
                    nextSeason: _progress.seasonNumber,
                    nextSession: _progress.sessionNumber,
                  );
                  switch (action) {
                    case RestoredDraftAction.startFresh:
                      currentLifeDiaryDraft.reset(
                        selectedDate,
                        season: _progress.seasonNumber,
                        session: _progress.sessionNumber,
                      );
                    case RestoredDraftAction.keepRenumbered:
                      // Keep the written reflections; only the number moves.
                      currentLifeDiaryDraft
                        ..seasonNumber = _progress.seasonNumber
                        ..sessionNumber = _progress.sessionNumber;
                    case RestoredDraftAction.keepAsIs:
                      break;
                  }
                  _draftLifecycle.beginDraft();
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LifeDiaryReadyPage(diaryDate: selectedDate),
                    ),
                  );
                },
                child: const Text('이 날짜로 시작', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Temporary Ready Page
// Q1 will be connected in the next version.
// ============================================================

// ============================================================
// V0.03c
// Life Diary Question 1
// ============================================================
