part of '../../main.dart';

class LifeDiaryReadyPage extends StatefulWidget {
  final DateTime diaryDate;
  final bool editMode;

  const LifeDiaryReadyPage({
    super.key,
    required this.diaryDate,
    this.editMode = false,
  });

  @override
  State<LifeDiaryReadyPage> createState() => _LifeDiaryReadyPageState();
}

class _LifeDiaryReadyPageState extends State<LifeDiaryReadyPage> {
  final List<String> oldSelfRoots = [
    '수치심',
    '죄책감',
    '두려움',
    '자기의(신념·고정관념)',
    '과거의 상처',
    '인정받고 싶은 욕구',
    '죽음의 공포',
  ];

  final Set<String> selectedRoots = {};

  bool noOldSelfToday = false;

  final TextEditingController detailController = TextEditingController();

  String? awareness;

  double awarenessPercent = 50;

  int step = 1;

  @override
  void initState() {
    super.initState();
    detailController.text = currentLifeDiaryDraft.q1Detail;
    selectedRoots.addAll(currentLifeDiaryDraft.q1OldSelves);
    noOldSelfToday = currentLifeDiaryDraft.q1NoOldSelf;
    awareness = currentLifeDiaryDraft.q1Awareness;
    awarenessPercent = currentLifeDiaryDraft.q1AwarenessPercent;
    step = currentLifeDiaryDraft.q1Step;
  }

  void saveQ1Draft() {
    if (!_draftLifecycle.shouldPersist) return;
    final previousRoots = Set<String>.from(currentLifeDiaryDraft.q1OldSelves);
    final selectionChanged =
        previousRoots.length != selectedRoots.length ||
        !previousRoots.containsAll(selectedRoots) ||
        currentLifeDiaryDraft.q1NoOldSelf != noOldSelfToday;
    currentLifeDiaryDraft.q1Detail = detailController.text.trim();
    currentLifeDiaryDraft.q1OldSelves
      ..clear()
      ..addAll(selectedRoots);
    currentLifeDiaryDraft.q1NoOldSelf = noOldSelfToday;
    currentLifeDiaryDraft.q1Awareness = awareness;
    currentLifeDiaryDraft.q1AwarenessPercent = awarenessPercent;
    currentLifeDiaryDraft.q1Step = step;
    if (selectionChanged) {
      currentLifeDiaryDraft.q2CompletedOldSelves.clear();
      currentLifeDiaryDraft.q2CurrentIndex = 0;
      currentLifeDiaryDraft.q2PartialText = '';
    }
    persistCurrentLifeDiaryDraft();
  }

  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void nextStep() {
    if (step == 1 && noOldSelfToday) {
      setState(() {
        step = 4;
      });
      return;
    }

    if (step < 4) {
      setState(() {
        step++;
      });
    }
  }

  Future<void> previousStep() async {
    if (step == 4 && noOldSelfToday) {
      setState(() {
        step = 1;
      });
      return;
    }

    if (step > 1) {
      setState(() {
        step--;
      });
    } else {
      await confirmDraftExit(context, saveQ1Draft);
    }
  }

  @override
  void dispose() {
    saveQ1Draft();
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: previousStep,
        ),
        title: const Text('생명일기'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '1~7번 문항 이동',
            onPressed: () => showLifeDiaryQuestionNavigator(
              context,
              widget.diaryDate,
              1,
              saveCurrent: saveQ1Draft,
            ),
            icon: const Icon(Icons.grid_view_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '질문 1/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(child: _buildCurrentStep()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (step) {
      case 1:
        return _buildDetailEntry();
      case 2:
        return _buildRootSelection();
      case 3:
        return _buildAwareness();
      case 4:
        return _buildCrossDeclaration();
      default:
        return const SizedBox();
    }
  }

  // ----------------------------------------------------------
  // Q1 Step 2
  // Old-self selection after reflection
  // ----------------------------------------------------------

  Widget _buildRootSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '기록한 내용에서 어떤 옛사람을 발견했나요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          '앞에서 기록한 생각과 감정, 반응을 돌아보며 '
          '해당하는 옛사람을 모두 선택해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),

        const SizedBox(height: 24),

        ...oldSelfRoots.map(
          (root) => CheckboxListTile(
            value: selectedRoots.contains(root),
            title: Text(root),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  selectedRoots.add(root);
                } else {
                  selectedRoots.remove(root);
                }
              });
            },
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: selectedRoots.isEmpty ? null : nextStep,
            child: const Text('다음', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Q1 Step 1
  // Concrete reflection before category selection
  // ----------------------------------------------------------

  Widget _buildDetailEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '1. 오늘 발견한 옛사람은 무엇인가?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        const Text(
          '어떤 상황에서 발견했나요?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        const Text(
          '외부의 사람이나 상황을 판단하기보다 '
          '그때 내 안에서 무엇이 일어났는지 돌아봅니다.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),

        const SizedBox(height: 24),

        TextField(
          controller: detailController,
          minLines: 4,
          maxLines: 7,
          onChanged: (value) {
            setState(() {
              if (value.trim().isNotEmpty) {
                noOldSelfToday = false;
              }
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '그 상황에서 내 안에 어떤 생각, 감정, 반응이 있었는지 기록해 주세요.',
          ),
        ),

        const SizedBox(height: 24),

        const Divider(),

        CheckboxListTile(
          value: noOldSelfToday,
          title: const Text('오늘 구체적으로 발견한 옛사람이 없습니다.'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (selected) {
            setState(() {
              noOldSelfToday = selected ?? false;
              if (noOldSelfToday) {
                detailController.clear();
                selectedRoots.clear();
                awareness = null;
                awarenessPercent = 50;
              }
            });
          },
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: (detailController.text.trim().isEmpty && !noOldSelfToday)
                ? null
                : nextStep,
            child: const Text('다음', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Q1 Step 3
  // 100% inner awareness
  // ----------------------------------------------------------

  Widget _buildAwareness() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '이 옛사람은 어디에서 나오는가?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: const Text(
            '“이 옛사람은 100% 내 안에 있다.”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 24),

        RadioListTile<String>(
          value: '깨달아졌다',
          groupValue: awareness,
          title: const Text('깨달아졌다'),
          onChanged: (value) {
            setState(() {
              awareness = value;
            });
          },
        ),

        RadioListTile<String>(
          value: '어느 정도 깨달아졌다',
          groupValue: awareness,
          title: const Text('어느 정도 깨달아졌다'),
          onChanged: (value) {
            setState(() {
              awareness = value;
            });
          },
        ),

        if (awareness == '어느 정도 깨달아졌다') ...[
          const SizedBox(height: 8),

          Text(
            '현재 나의 인식 정도: '
            '${awarenessPercent.round()}%',
            textAlign: TextAlign.center,
          ),

          Slider(
            value: awarenessPercent,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${awarenessPercent.round()}%',
            onChanged: (value) {
              setState(() {
                awarenessPercent = value;
              });
            },
          ),

          const Text(
            '이 숫자는 영적 성장 점수가 아니라 '
            '지금 이 순간 스스로 느끼는 인식 정도입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],

        RadioListTile<String>(
          value: '아직 모르겠다',
          groupValue: awareness,
          title: const Text('아직 모르겠다'),
          onChanged: (value) {
            setState(() {
              awareness = value;
            });
          },
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: awareness == null ? null : nextStep,
            child: const Text('다음', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // Q1 Step 4
  // Cross declaration
  // ----------------------------------------------------------

  Widget _buildCrossDeclaration() {
    final bool isNoOldSelf = noOldSelfToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isNoOldSelf) ...[
          const Text(
            '나는 새생명입니다',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 32),
        ],

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Text(
                isNoOldSelf
                    ? '나는 예수님과 함께 십자가에 못박혀 죽었고 '
                          '장사되었고 부활하여 새생명으로 살고 있다'
                    : '“십자가에서 다 끝났다.”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),

              if (!isNoOldSelf) ...[
                const SizedBox(height: 16),

                const Text(
                  '잠시 멈추어 이 사실을 바라보고 '
                  '고백해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 40),

        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              saveQ1Draft();
              if (widget.editMode) {
                Navigator.pop(context, true);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LifeDiaryQuestion2Page(
                    diaryDate: widget.diaryDate,
                    selectedOldSelves: selectedRoots.toList(),
                    noOldSelfToday: noOldSelfToday,
                  ),
                ),
              );
            },
            child: Text(
              widget.editMode ? '수정 저장 후 돌아가기' : '계속하기',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// V0.16a
// Life Diary Question 2
// ============================================================
