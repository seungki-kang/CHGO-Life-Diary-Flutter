part of '../../main.dart';

class LifeDiaryQuestion2Page extends StatefulWidget {
  final DateTime diaryDate;
  final List<String> selectedOldSelves;
  final bool noOldSelfToday;

  const LifeDiaryQuestion2Page({
    super.key,
    required this.diaryDate,
    required this.selectedOldSelves,
    required this.noOldSelfToday,
  });

  @override
  State<LifeDiaryQuestion2Page> createState() =>
      _LifeDiaryQuestion2PageState();
}

class _LifeDiaryQuestion2PageState
    extends State<LifeDiaryQuestion2Page> {
  static const List<String> allOldSelves = [
    '수치심',
    '죄책감',
    '두려움',
    '자기의(신념·고정관념)',
    '과거의 상처',
    '인정받고 싶은 욕구',
    '죽음의 공포',
  ];

  final TextEditingController confessionController =
      TextEditingController();
  late final List<String> confessionQueue;
  final List<String> completedOldSelves = [];
  int currentIndex = 0;
  String? guidanceMessage;

  bool get q2AllComplete => confessionQueue.isNotEmpty &&
      confessionQueue.every(
        (oldSelf) => currentLifeDiaryDraft.q2CompletedOldSelves.contains(oldSelf),
      );

  @override
  void initState() {
    super.initState();
    confessionQueue = widget.noOldSelfToday
        ? List<String>.from(allOldSelves)
        : List<String>.from(widget.selectedOldSelves);
    completedOldSelves.addAll(currentLifeDiaryDraft.q2CompletedOldSelves);
    if (confessionQueue.isNotEmpty) {
      currentIndex = currentLifeDiaryDraft.q2CurrentIndex;
      if (currentIndex < 0) currentIndex = 0;
      if (currentIndex >= confessionQueue.length) {
        currentIndex = confessionQueue.length - 1;
      }
    }
    confessionController.text = currentLifeDiaryDraft.q2PartialText;
  }

  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void saveQ2Draft() {
    currentLifeDiaryDraft.q2CurrentIndex = currentIndex;
    currentLifeDiaryDraft.q2PartialText = confessionController.text;
    persistCurrentLifeDiaryDraft();
  }

  @override
  void dispose() {
    saveQ2Draft();
    confessionController.dispose();
    super.dispose();
  }

  String confessionName(String oldSelf) {
    if (oldSelf.startsWith('자기의')) return '자기의';
    return oldSelf;
  }

  String confessionSubject(String oldSelf) {
    const subjects = {
      '수치심': '수치심은',
      '죄책감': '죄책감은',
      '두려움': '두려움은',
      '자기의(신념·고정관념)': '의는',
      '과거의 상처': '과거의 상처는',
      '인정받고 싶은 욕구': '인정받고 싶은 욕구는',
      '죽음의 공포': '죽음의 공포는',
    };
    return subjects[oldSelf] ?? '${confessionName(oldSelf)}은';
  }

  String confessionSentence(String oldSelf) {
    return '나의 ${confessionSubject(oldSelf)} 예수님과 함께 '
        '십자가에 못 박혀 죽었습니다.';
  }

  String normalized(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[.。]+$'), '');
  }

  int editDistance(String first, String second) {
    final previous = List<int>.generate(second.length + 1, (i) => i);
    for (var i = 1; i <= first.length; i++) {
      var diagonal = previous[0];
      previous[0] = i;
      for (var j = 1; j <= second.length; j++) {
        final above = previous[j];
        final cost = first.codeUnitAt(i - 1) == second.codeUnitAt(j - 1)
            ? 0
            : 1;
        previous[j] = [
          previous[j] + 1,
          previous[j - 1] + 1,
          diagonal + cost,
        ].reduce((a, b) => a < b ? a : b);
        diagonal = above;
      }
    }
    return previous[second.length];
  }

  String specificDifferenceGuidance(String typed, String expected) {
    var prefixLength = 0;
    while (prefixLength < typed.length &&
        prefixLength < expected.length &&
        typed.codeUnitAt(prefixLength) ==
            expected.codeUnitAt(prefixLength)) {
      prefixLength++;
    }

    var suffixLength = 0;
    while (suffixLength < typed.length - prefixLength &&
        suffixLength < expected.length - prefixLength &&
        typed.codeUnitAt(typed.length - 1 - suffixLength) ==
            expected.codeUnitAt(expected.length - 1 - suffixLength)) {
      suffixLength++;
    }

    final typedEnd = typed.length - suffixLength;
    final expectedEnd = expected.length - suffixLength;
    final typedPart = typed.substring(prefixLength, typedEnd);
    final expectedPart = expected.substring(prefixLength, expectedEnd);

    if (typedPart.isNotEmpty && expectedPart.isEmpty) {
      return '입력한 문장에서 “$typedPart”가 더 들어갔습니다. '
          '해당 글자를 삭제해 주세요.';
    }
    if (typedPart.isEmpty && expectedPart.isNotEmpty) {
      return '입력한 문장에서 “$expectedPart”가 빠졌습니다. '
          '해당 글자를 넣어 주세요.';
    }
    if (typedPart.isNotEmpty && expectedPart.isNotEmpty) {
      return '입력한 “$typedPart”를 “$expectedPart”로 고쳐 주세요.';
    }
    return '위 문장을 다시 확인해 주세요.';
  }

  String? detectedOldSelf(String text) {
    final compact = normalized(text);
    for (final oldSelf in allOldSelves) {
      final detectionText = oldSelf.startsWith('자기의')
          ? '나의의는'
          : confessionName(oldSelf).replaceAll(' ', '');
      if (compact.contains(detectionText)) {
        return oldSelf;
      }
    }
    return null;
  }

  Future<void> checkConfession() async {
    final typed = confessionController.text;
    final expectedOldSelf = confessionQueue[currentIndex];
    final expected = confessionSentence(expectedOldSelf);
    final typedNormalized = normalized(typed);
    final expectedNormalized = normalized(expected);

    if (typedNormalized == expectedNormalized) {
      completeCurrentConfession();
      return;
    }

    final detected = detectedOldSelf(typed);
    if (detected != null && detected != expectedOldSelf) {
      final detectedSentence = confessionSentence(detected);
      final isNewDiscovery = !confessionQueue.contains(detected) &&
          !completedOldSelves.contains(detected);
      if (isNewDiscovery &&
          typedNormalized == normalized(detectedSentence)) {
        final shouldAdd = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('새롭게 발견한 옛사람인가요?'),
            content: Text(
              '1번에서는 ${widget.selectedOldSelves.join('과 ')}을(를) '
              '발견했습니다. 지금 기록한 ‘${confessionName(detected)}’도 '
              '새롭게 발견한 옛사람입니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '${confessionName(expectedOldSelf)} 문장을 다시 기록합니다',
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('${confessionName(detected)}를 새로 추가합니다'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (shouldAdd == true) {
          setState(() {
            completedOldSelves.add(detected);
            confessionController.clear();
            guidanceMessage =
                '${confessionName(detected)}를 2번에서 새로 발견해 기록했습니다. '
                '이제 ${confessionName(expectedOldSelf)} 문장을 기록해 주세요.';
          });
        } else {
          setState(() {
            guidanceMessage =
                '위에 보이는 ${confessionName(expectedOldSelf)} 문장을 '
                '처음부터 끝까지 다시 기록해 주세요.';
          });
        }
        return;
      }

      setState(() {
        guidanceMessage =
            '지금은 ${confessionName(expectedOldSelf)}에 대한 문장을 '
            '기록할 차례입니다. 위 문장을 따라 다시 기록해 주세요.';
      });
      return;
    }

    setState(() {
      guidanceMessage =
          '${characterDifferenceGuidance(typed, expected)}\n'
          '띄어쓰기와 마지막 마침표는 달라도 괜찮습니다. '
          '“예수님과 함께 십자가에 못 박혀 죽었습니다”는 바꾸지 않습니다.';
    });
  }

  void completeCurrentConfession() {
    final completed = confessionQueue[currentIndex];
    completedOldSelves.add(completed);
    if (!currentLifeDiaryDraft.q2CompletedOldSelves.contains(completed)) {
      currentLifeDiaryDraft.q2CompletedOldSelves.add(completed);
    }

    if (currentIndex < confessionQueue.length - 1) {
      setState(() {
        currentIndex++;
        confessionController.clear();
        guidanceMessage = null;
      });
      currentLifeDiaryDraft.q2CurrentIndex = currentIndex;
      currentLifeDiaryDraft.q2PartialText = '';
      return;
    }

    currentLifeDiaryDraft.q2CurrentIndex = currentIndex;
    currentLifeDiaryDraft.q2PartialText = '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LifeDiaryQuestion3Page(
          diaryDate: widget.diaryDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (q2AllComplete) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('생명일기'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: '1~7번 문항 이동',
              onPressed: () => showLifeDiaryQuestionNavigator(
                context,
                widget.diaryDate,
                2,
                saveCurrent: saveQ2Draft,
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
                Text(formatDate(widget.diaryDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text('시즌 1 · 1/50회 · 질문 2/7',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 28),
                const Text('2번 기록을 완료했습니다.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('기록한 내용은 최종 완성 전까지 유지됩니다.'),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: confessionQueue
                      .map((oldSelf) => Chip(
                            avatar: const Icon(Icons.check, size: 18),
                            label: Text(confessionName(oldSelf)),
                          ))
                      .toList(),
                ),
                const Spacer(),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LifeDiaryQuestion3Page(
                          diaryDate: widget.diaryDate,
                        ),
                      ),
                    ),
                    child: const Text('3번으로 이동',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      currentLifeDiaryDraft.q2CompletedOldSelves.clear();
                      completedOldSelves.clear();
                      currentIndex = 0;
                      confessionController.clear();
                    });
                    saveQ2Draft();
                  },
                  child: const Text('2번 문장을 다시 기록하기'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('생명일기'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '1~7번 문항 이동',
            onPressed: () => showLifeDiaryQuestionNavigator(
              context,
              widget.diaryDate,
              2,
              saveCurrent: saveQ2Draft,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '시즌 1 · 1/50회',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '질문 2/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '2. 발견한 옛사람을 십자가에서 처리합니다.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        '연하게 보이는 문장을 따라 처음부터 끝까지 '
                        '직접 기록해 주세요.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        '십자가 고백 ${currentIndex + 1}/${confessionQueue.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          confessionSentence(confessionQueue[currentIndex]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.48),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: confessionController,
                        inputFormatters: [keepMyRighteousnessWording],
                        minLines: 4,
                        maxLines: 6,
                        onChanged: (_) {
                          if (guidanceMessage != null) {
                            setState(() => guidanceMessage = null);
                          } else {
                            setState(() {});
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '위 문장 전체를 직접 기록해 주세요.',
                        ),
                      ),

                      if (guidanceMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          guidanceMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: confessionController.text.trim().isEmpty
                              ? null
                              : checkConfession,
                          child: Text(
                            currentIndex == confessionQueue.length - 1
                                ? '기록 완료'
                                : '다음 문장',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
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
// V0.16a
// Life Diary Question 3
// ============================================================

