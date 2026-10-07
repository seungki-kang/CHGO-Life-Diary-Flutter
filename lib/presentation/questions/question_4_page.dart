part of '../../main.dart';

class LifeDiaryQuestion4Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion4Page({super.key, required this.diaryDate});

  @override
  State<LifeDiaryQuestion4Page> createState() => _LifeDiaryQuestion4PageState();
}

class _LifeDiaryQuestion4PageState extends State<LifeDiaryQuestion4Page> {
  static const List<String> allOldSelves = [
    '수치심',
    '죄책감',
    '두려움',
    '자기의(신념·고정관념)',
    '과거의 상처',
    '인정받고 싶은 욕구',
    '죽음의 공포',
  ];

  static const List<String> noRecordDeclarations = [
    '나는 다른 사람을 판단하지 않습니다.',
    '나는 다른 사람의 옛사람에 저항하지 않습니다.',
    '나는 다른 사람의 옛사람을 하나님의 사랑과 긍휼하심으로 바라봅니다.',
  ];

  final TextEditingController personController = TextEditingController();
  final TextEditingController eventController = TextEditingController();
  final TextEditingController responseController = TextEditingController();
  final TextEditingController loveController = TextEditingController();
  final TextEditingController declarationController = TextEditingController();
  final TextEditingController additionalConfessionController =
      TextEditingController();

  int stage = 0;
  bool noRecordToday = false;
  bool judged = false;
  bool resisted = false;
  bool viewedWithLove = false;
  bool viewedWithCompassion = false;
  String? newDiscoveryChoice;
  final Set<String> additionalOldSelves = {};
  bool acceptsOwnership = false;
  int declarationIndex = 0;
  int additionalIndex = 0;
  List<String> additionalQueue = [];
  String? guidance;

  @override
  void initState() {
    super.initState();
    final draft = currentLifeDiaryDraft;
    stage = draft.q4Stage;
    personController.text = draft.q4Person;
    eventController.text = draft.q4Event;
    responseController.text = draft.q4Response;
    loveController.text = draft.q4Love;
    declarationController.text = draft.q4Declaration;
    additionalConfessionController.text = draft.q4AdditionalConfession;
    noRecordToday = draft.q4NoRecord;
    judged = draft.q4Judged;
    resisted = draft.q4Resisted;
    viewedWithLove = draft.q4ViewedWithLove;
    viewedWithCompassion = draft.q4ViewedWithCompassion;
    newDiscoveryChoice = draft.q4NewDiscoveryChoice;
    additionalOldSelves.addAll(draft.q4AdditionalOldSelves);
    acceptsOwnership = draft.q4OwnershipRealized;
    declarationIndex = draft.q4DeclarationIndex;
    additionalIndex = draft.q4AdditionalIndex;
    additionalQueue = List<String>.from(draft.q4AdditionalQueue);
  }

  void saveQ4Draft() {
    final draft = currentLifeDiaryDraft;
    draft.q4Stage = stage;
    draft.q4Person = personController.text;
    draft.q4Event = eventController.text;
    draft.q4Response = responseController.text;
    draft.q4Love = loveController.text;
    draft.q4Declaration = declarationController.text;
    draft.q4AdditionalConfession = additionalConfessionController.text;
    draft.q4NoRecord = noRecordToday;
    draft.q4Judged = judged;
    draft.q4Resisted = resisted;
    draft.q4ViewedWithLove = viewedWithLove;
    draft.q4ViewedWithCompassion = viewedWithCompassion;
    draft.q4NewDiscoveryChoice = newDiscoveryChoice;
    draft.q4AdditionalOldSelves
      ..clear()
      ..addAll(additionalOldSelves);
    draft.q4OwnershipRealized = acceptsOwnership;
    draft.q4DeclarationIndex = declarationIndex;
    draft.q4AdditionalIndex = additionalIndex;
    draft.q4AdditionalQueue
      ..clear()
      ..addAll(additionalQueue);
    persistCurrentLifeDiaryDraft();
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  String normalized(String text) =>
      text.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'[.。]+$'), '');

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
    return subjects[oldSelf] ?? '$oldSelf은';
  }

  String confessionSentence(String oldSelf) =>
      '나의 ${confessionSubject(oldSelf)} 예수님과 함께 '
      '십자가에 못 박혀 죽었습니다.';

  bool get eventComplete =>
      personController.text.trim().isNotEmpty &&
      eventController.text.trim().isNotEmpty &&
      responseController.text.trim().isNotEmpty &&
      loveController.text.trim().isNotEmpty &&
      (judged || resisted || viewedWithLove || viewedWithCompassion);

  void beginQuestion4() {
    if (noRecordToday) {
      setState(() {
        stage = 2;
        declarationIndex = 0;
        declarationController.clear();
        guidance = null;
      });
      return;
    }
    if (!eventComplete) return;
    FocusScope.of(context).unfocus();
    setState(() {
      stage = 1;
      guidance = null;
    });
  }

  void checkNoRecordDeclaration() {
    final expected = noRecordDeclarations[declarationIndex];
    if (normalized(declarationController.text) != normalized(expected)) {
      setState(() {
        guidance =
            '${characterDifferenceGuidance(declarationController.text, expected)}\n'
            '띄어쓰기와 마지막 마침표는 달라도 괜찮습니다.';
      });
      return;
    }
    if (declarationIndex < noRecordDeclarations.length - 1) {
      setState(() {
        declarationIndex++;
        declarationController.clear();
        guidance = null;
      });
    } else {
      setState(() {
        declarationController.clear();
        guidance = null;
        stage = 5;
      });
    }
  }

  void continueAfterReflection() {
    if (newDiscoveryChoice == 'different') {
      setState(() => stage = 3);
    } else if (newDiscoveryChoice != null) {
      setState(() => stage = 5);
    }
  }

  void beginAdditionalProcessing() {
    if (additionalOldSelves.isEmpty || !acceptsOwnership) return;
    additionalQueue = additionalOldSelves.toList();
    setState(() {
      stage = 4;
      additionalIndex = 0;
      additionalConfessionController.clear();
      guidance = null;
    });
  }

  void checkAdditionalConfession() {
    final expected = confessionSentence(additionalQueue[additionalIndex]);
    if (normalized(additionalConfessionController.text) !=
        normalized(expected)) {
      setState(() {
        guidance =
            '${characterDifferenceGuidance(additionalConfessionController.text, expected)}\n'
            '“예수님과 함께 십자가에 못 박혀 죽었습니다”는 바꾸지 않습니다. '
            '띄어쓰기와 마지막 마침표는 달라도 괜찮습니다.';
      });
      return;
    }
    if (additionalIndex < additionalQueue.length - 1) {
      setState(() {
        additionalIndex++;
        additionalConfessionController.clear();
        guidance = null;
      });
    } else {
      setState(() {
        additionalConfessionController.clear();
        guidance = null;
        stage = 5;
      });
    }
  }

  Future<void> showSavedRecords() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '기록 보기·수정',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Text('1')),
                title: const Text('오늘 발견한 옛사람'),
                subtitle: Text(
                  currentLifeDiaryDraft.q1NoOldSelf
                      ? '구체적으로 발견한 옛사람 없음'
                      : currentLifeDiaryDraft.q1OldSelves.join(', '),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LifeDiaryReadyPage(
                        diaryDate: widget.diaryDate,
                        editMode: true,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
              ListTile(
                leading: const CircleAvatar(child: Text('2')),
                title: const Text('십자가 처리 기록'),
                subtitle: Text(
                  currentLifeDiaryDraft.q2CompletedOldSelves.join(', '),
                ),
              ),
              const ListTile(
                leading: CircleAvatar(child: Text('3')),
                title: Text('오늘 이루어진 하나님 나라'),
                subtitle: Text('3번 기록 완료'),
              ),
              const ListTile(
                leading: CircleAvatar(child: Text('4')),
                title: Text('다른 사람의 옛사람 바라보기'),
                subtitle: Text('현재 작성 중 · 입력 내용 유지'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('작성 화면으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    saveQ4Draft();
    personController.dispose();
    eventController.dispose();
    responseController.dispose();
    loveController.dispose();
    declarationController.dispose();
    additionalConfessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => confirmDraftExit(context, saveQ4Draft),
        ),
        title: const Text('생명일기'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '1~7번 문항 이동',
            onPressed: () => showLifeDiaryQuestionNavigator(
              context,
              widget.diaryDate,
              4,
              saveCurrent: saveQ4Draft,
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
                '질문 4/7',
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
        return _buildReflection();
      case 2:
        return _buildNoRecordDeclarations();
      case 3:
        return _buildAdditionalDiscovery();
      case 4:
        return _buildAdditionalConfession();
      case 5:
        return _buildCompletion();
      default:
        return _buildEventEntry();
    }
  }

  Widget _buildEventEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '4. 다른 사람의 옛사람을 하나님의 사랑과 긍휼하심으로 바라본 적이 있는가? (저항, 판단 없이)',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '다른 사람을 대했던 실제 사건과 내 반응, 예수님의 마음으로 바라본 과정을 자세히 기록해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: noRecordToday,
          title: const Text('생명일기 4번에 기록할 것이 없다면'),
          subtitle: const Text('세 문장을 모두 직접 기록합니다.'),
          onChanged: (value) => setState(() => noRecordToday = value ?? false),
        ),
        if (!noRecordToday) ...[
          const SizedBox(height: 12),
          TextField(
            controller: personController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '관계',
              hintText: '예: 배우자, 자녀, 가족, 교회 구성원, 직장 동료',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: eventController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '어떤 사건이 있었나요?',
              hintText: '다른 사람의 옛사람이 드러난 상황을 자세히 기록해 주세요.',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: responseController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '그때 내 안에서는 무엇이 일어났나요?',
              hintText: '생각, 감정, 판단이나 저항을 구체적으로 기록해 주세요.',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: loveController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '예수님의 마음으로 어떻게 바라보았나요?',
              hintText: '하나님의 사랑과 긍휼하심으로 바라본 과정을 기록해 주세요.',
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: judged,
            title: const Text('판단이 일어났습니다.'),
            onChanged: (value) => setState(() => judged = value ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: resisted,
            title: const Text('저항이 일어났습니다.'),
            onChanged: (value) => setState(() => resisted = value ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: viewedWithLove,
            title: const Text('하나님의 사랑으로 바라보았습니다.'),
            onChanged: (value) =>
                setState(() => viewedWithLove = value ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: viewedWithCompassion,
            title: const Text('하나님의 긍휼하심으로 바라보았습니다.'),
            onChanged: (value) =>
                setState(() => viewedWithCompassion = value ?? false),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: noRecordToday || eventComplete ? beginQuestion4 : null,
            child: Text(
              noRecordToday ? '세 문장 기록하기' : '4번 사건 기록 완료',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReflection() {
    final q1Summary = currentLifeDiaryDraft.q1NoOldSelf
        ? '1번에서 구체적으로 발견한 옛사람이 없습니다.'
        : '1번 기록: ${currentLifeDiaryDraft.q1OldSelves.join(', ')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '4번을 통해 내 안의 옛사람을 새롭게 발견했나요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(q1Summary, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 18),
        RadioListTile<String>(
          value: 'none',
          groupValue: newDiscoveryChoice,
          title: const Text('새롭게 발견한 옛사람이 없습니다.'),
          onChanged: (value) => setState(() => newDiscoveryChoice = value),
        ),
        RadioListTile<String>(
          value: 'same',
          groupValue: newDiscoveryChoice,
          title: const Text('1번에서 발견한 옛사람과 같습니다.'),
          subtitle: const Text('1·2번을 다시 기록하지 않습니다.'),
          onChanged: (value) => setState(() => newDiscoveryChoice = value),
        ),
        RadioListTile<String>(
          value: 'different',
          groupValue: newDiscoveryChoice,
          title: const Text('1번과 다른 옛사람을 새롭게 발견했습니다.'),
          subtitle: const Text('추가 1·2번으로 처리할 수 있습니다.'),
          onChanged: (value) => setState(() => newDiscoveryChoice = value),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: newDiscoveryChoice == null
                ? null
                : continueAfterReflection,
            child: Text(
              newDiscoveryChoice == 'different' ? '추가 1·2번 처리 선택' : '4번 마치기',
              style: const TextStyle(fontSize: 18),
            ),
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
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.48),
      ),
    ),
  );

  Widget _buildNoRecordDeclarations() {
    final expected = noRecordDeclarations[declarationIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '생명일기 4번에 기록할 것이 없다면',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          '세 문장을 처음부터 끝까지 직접 기록해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 20),
        Text(
          '생명 고백 ${declarationIndex + 1}/3',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _fadedSentence(expected),
        const SizedBox(height: 16),
        TextField(
          controller: declarationController,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => setState(() => guidance = null),
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
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: declarationController.text.trim().isEmpty
                ? null
                : checkNoRecordDeclaration,
            child: Text(
              declarationIndex == 2 ? '4번 기록 완료' : '다음 문장',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDiscovery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '4번에서 새롭게 발견한 옛사람을 추가로 처리합니다.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '기존 1번 기록은 그대로 보존됩니다. 새롭게 발견한 것만 모두 선택해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        ...allOldSelves.map(
          (oldSelf) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: additionalOldSelves.contains(oldSelf),
            title: Text(oldSelf),
            onChanged: (value) => setState(() {
              if (value == true) {
                additionalOldSelves.add(oldSelf);
              } else {
                additionalOldSelves.remove(oldSelf);
              }
            }),
          ),
        ),
        const Divider(height: 28),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: acceptsOwnership,
          title: const Text('이 옛사람은 100% 내 안에 있음을 깨달았습니다.'),
          onChanged: (value) =>
              setState(() => acceptsOwnership = value ?? false),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: additionalOldSelves.isNotEmpty && acceptsOwnership
                ? beginAdditionalProcessing
                : null,
            child: const Text('추가 2번으로 처리하기', style: TextStyle(fontSize: 18)),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => stage = 5),
          child: const Text('지금은 추가 처리하지 않고 4번을 마칩니다'),
        ),
      ],
    );
  }

  Widget _buildAdditionalConfession() {
    final expected = confessionSentence(additionalQueue[additionalIndex]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '새롭게 발견한 옛사람을 십자가에서 처리합니다.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '추가 십자가 고백 ${additionalIndex + 1}/${additionalQueue.length}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _fadedSentence(expected),
        const SizedBox(height: 16),
        TextField(
          controller: additionalConfessionController,
          inputFormatters: [keepMyRighteousnessWording],
          minLines: 3,
          maxLines: 5,
          onChanged: (_) => setState(() => guidance = null),
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
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: additionalConfessionController.text.trim().isEmpty
                ? null
                : checkAdditionalConfession,
            child: Text(
              additionalIndex == additionalQueue.length - 1
                  ? '추가 1·2번 처리 완료'
                  : '다음 문장',
              style: const TextStyle(fontSize: 18),
            ),
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
          '생명일기 4번을 마쳤습니다.',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          noRecordToday
              ? '다른 사람을 판단하거나 저항하지 않고, 하나님의 사랑과 긍휼하심으로 바라보는 세 문장을 기록했습니다.'
              : additionalQueue.isNotEmpty
              ? '4번에서 새롭게 발견한 옛사람까지 십자가에서 처리했습니다.'
              : '다른 사람의 옛사람과 관련된 사건과 내 반응을 기록했습니다.',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 18),
        if (noRecordToday)
          ...noRecordDeclarations.map(
            (sentence) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(sentence, style: const TextStyle(height: 1.5)),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('관계\n${personController.text}'),
                  const SizedBox(height: 10),
                  Text('사건\n${eventController.text}'),
                  const SizedBox(height: 10),
                  Text('내 안의 반응\n${responseController.text}'),
                  const SizedBox(height: 10),
                  Text('예수님의 마음으로 바라본 과정\n${loveController.text}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (judged) const Chip(label: Text('판단이 일어남')),
                      if (resisted) const Chip(label: Text('저항이 일어남')),
                      if (viewedWithLove)
                        const Chip(label: Text('하나님의 사랑으로 바라봄')),
                      if (viewedWithCompassion)
                        const Chip(label: Text('하나님의 긍휼로 바라봄')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (additionalQueue.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('추가로 처리한 옛사람: ${additionalQueue.join(', ')}'),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              stage = noRecordToday ? 2 : 0;
            });
            saveQ4Draft();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('4번 기록 수정하기'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              saveQ4Draft();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LifeDiaryQuestion5Page(diaryDate: widget.diaryDate),
                ),
              );
            },
            child: const Text('5번으로 이동', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}
