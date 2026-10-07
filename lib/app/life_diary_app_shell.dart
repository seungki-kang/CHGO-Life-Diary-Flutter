part of '../main.dart';

final LifeDiarySessionDraft currentLifeDiaryDraft = LifeDiarySessionDraft();
late final LifeDiaryDraftStore lifeDiaryDraftStore;
late final SqliteLifeDiaryRepository lifeDiaryRepository;
final LifeDiaryEntryFactory lifeDiaryEntryFactory = LifeDiaryEntryFactory();
final AppLogger lifeDiaryLogger = AppLogger();
Future<void> _draftWrite = Future.value();

void persistCurrentLifeDiaryDraft() {
  final date = currentLifeDiaryDraft.diaryDate;
  if (date == null) return;
  final payload = currentLifeDiaryDraft.toJson();
  _draftWrite = _draftWrite
      .then((_) async {
        await _saveDraftWithRetry(date, payload);
        lifeDiaryLogger.debug('life_diary.draft_saved', {
          'operation': 'UPSERT',
          'source': 'LOCAL_SQLITE',
        });
      })
      .catchError((Object error, StackTrace stackTrace) {
        lifeDiaryLogger.error('life_diary.draft_save_failed', {
          'operation': 'UPSERT',
          'source': 'LOCAL_SQLITE',
          'error_code': error.runtimeType.toString(),
        });
      });
}

Future<void> _saveDraftWithRetry(
  DateTime date,
  Map<String, Object?> payload,
) async {
  const maximumAttempts = 3;
  for (var attempt = 1; attempt <= maximumAttempts; attempt++) {
    try {
      await lifeDiaryDraftStore.save(date, payload);
      return;
    } catch (error) {
      if (attempt == maximumAttempts) rethrow;
      lifeDiaryLogger.warn('life_diary.draft_save_retry', {
        'operation': 'UPSERT',
        'source': 'LOCAL_SQLITE',
        'retry_count': attempt,
        'error_code': error.runtimeType.toString(),
      });
      await Future<void>.delayed(Duration(milliseconds: 50 * attempt));
    }
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
  currentLifeDiaryDraft.loadJson(date, payload);
  lifeDiaryLogger.info('life_diary.draft_restored', {
    'operation': 'LOAD',
    'source': 'LOCAL_SQLITE',
  });
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
  currentLifeDiaryDraft.loadJson(record.date, record.payload);
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

Future<void> confirmDraftExit(
  BuildContext context,
  VoidCallback saveCurrent,
) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('작성 내용을 저장하고 나갈까요?'),
      content: const Text('저장한 내용은 “작성 중인 생명일기”에서 이어갈 수 있습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('계속 작성'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('저장 후 나가기'),
        ),
      ],
    ),
  );
  if (leave != true) return;
  saveCurrent();
  await _draftWrite;
  if (context.mounted) Navigator.pop(context);
}

Future<void> showLifeDiaryQuestionNavigator(
  BuildContext context,
  DateTime diaryDate,
  int currentQuestion, {
  VoidCallback? saveCurrent,
}) async {
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
              return ListTile(
                leading: CircleAvatar(child: Text('$number')),
                title: Text(
                  number == currentQuestion
                      ? '$number번 · 현재 문항'
                      : available
                      ? '$number번으로 이동'
                      : number == 2
                      ? '2번 · 먼저 1번을 기록해 주세요'
                      : '$number번 · 준비 중',
                ),
                trailing: number == currentQuestion
                    ? const Icon(Icons.check_circle)
                    : available
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.lock_outline),
                enabled: available && number != currentQuestion,
                onTap: !available || number == currentQuestion
                    ? null
                    : () {
                        saveCurrent?.call();
                        Navigator.pop(sheetContext);
                        final page = buildLifeDiaryQuestionPage(
                          diaryDate,
                          number,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => page),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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
                const Icon(Icons.menu_book_rounded, size: 72),
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
                  'Flutter V0.17a',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              const Spacer(),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () async {
                    final existing = _progress.existingEntry;
                    if (existing != null) {
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('이미 기록한 날짜입니다.'),
                          content: Text(
                            existing.status == LifeDiaryEntryStatus.deleted
                                ? '삭제된 기록이 남아 있습니다. 지난 생명일기의 삭제됨 필터에서 복구해 주세요.'
                                : '같은 날짜의 생명일기는 중복 생성하지 않습니다. 지난 생명일기에서 기존 기록을 확인하거나 수정해 주세요.',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    final restored = await restoreLifeDiaryDraft(selectedDate);
                    if (!restored) {
                      currentLifeDiaryDraft.reset(
                        selectedDate,
                        season: _progress.seasonNumber,
                        session: _progress.sessionNumber,
                      );
                    }
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
