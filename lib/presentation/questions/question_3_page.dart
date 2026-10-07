part of '../../main.dart';

class LifeDiaryQuestion3Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion3Page({super.key, required this.diaryDate});

  @override
  State<LifeDiaryQuestion3Page> createState() => _LifeDiaryQuestion3PageState();
}

class _LifeDiaryQuestion3PageState extends State<LifeDiaryQuestion3Page> {
  static const List<String> fruits = [
    '사랑',
    '기쁨',
    '평안(화평)',
    '오래 참음',
    '자비',
    '양선',
    '충성',
    '온유',
    '절제',
  ];

  final Set<String> selectedRealms = {};
  final Set<String> selectedFruits = {};
  final List<Map<String, String>> enjoymentRecords = [];
  final List<String> realmQueue = [];
  final List<String> missingFruits = [];

  final TextEditingController eventController = TextEditingController();
  final TextEditingController declarationController = TextEditingController();
  final TextEditingController identityController = TextEditingController();

  int stage = 0;
  int realmIndex = 0;
  int missingIndex = 0;
  bool noKingdomEnjoymentToday = false;
  bool noSpecificFruit = false;
  String? identityGuidance;
  int? editingRecordIndex;

  @override
  void initState() {
    super.initState();
    final draft = currentLifeDiaryDraft;
    stage = draft.q3Stage;
    selectedRealms.addAll(draft.q3SelectedRealms);
    selectedFruits.addAll(draft.q3SelectedFruits);
    enjoymentRecords.addAll(
      draft.q3EnjoymentRecords.map(
        (record) => Map<String, String>.from(record),
      ),
    );
    realmQueue.addAll(draft.q3RealmQueue);
    missingFruits.addAll(draft.q3MissingFruits);
    eventController.text = _combinedText(draft.q3Event, draft.q3Discovery);
    declarationController.text = _combinedText(
      draft.q3Declaration,
      draft.q3Enjoyment,
    );
    identityController.text = draft.q3Identity;
    realmIndex = draft.q3RealmIndex;
    missingIndex = draft.q3MissingIndex;
    noKingdomEnjoymentToday = draft.q3NoEnjoyment;
    noSpecificFruit = draft.q3NoSpecificFruit;
    editingRecordIndex = draft.q3EditingRecordIndex;
  }

  void saveQ3Draft() {
    if (!_draftLifecycle.shouldPersist) return;
    final draft = currentLifeDiaryDraft;
    draft.q3Stage = stage;
    draft.q3SelectedRealms
      ..clear()
      ..addAll(selectedRealms);
    draft.q3SelectedFruits
      ..clear()
      ..addAll(selectedFruits);
    draft.q3EnjoymentRecords
      ..clear()
      ..addAll(
        enjoymentRecords.map((record) => Map<String, String>.from(record)),
      );
    draft.q3RealmQueue
      ..clear()
      ..addAll(realmQueue);
    draft.q3MissingFruits
      ..clear()
      ..addAll(missingFruits);
    draft.q3Event = eventController.text;
    draft.q3Discovery = '';
    draft.q3Declaration = declarationController.text;
    draft.q3Enjoyment = '';
    draft.q3Identity = identityController.text;
    draft.q3RealmIndex = realmIndex;
    draft.q3MissingIndex = missingIndex;
    draft.q3NoEnjoyment = noKingdomEnjoymentToday;
    draft.q3NoSpecificFruit = noSpecificFruit;
    draft.q3EditingRecordIndex = editingRecordIndex;
    persistCurrentLifeDiaryDraft();
  }

  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> handleBack() async {
    if (stage == 0) {
      await confirmDraftExit(context, saveQ3Draft);
      return;
    }
    setState(() {
      stage = previousQuestion3Stage(
        stage: stage,
        noKingdomEnjoyment: noKingdomEnjoymentToday,
      );
      identityGuidance = null;
    });
    saveQ3Draft();
  }

  String declarationFruitName(String fruit) {
    return fruit == '평안(화평)' ? '평안' : fruit;
  }

  String _combinedText(String first, String second) {
    final normalizedFirst = first.trim();
    final normalizedSecond = second.trim();
    if (normalizedFirst.isEmpty) return normalizedSecond;
    if (normalizedSecond.isEmpty || normalizedSecond == normalizedFirst) {
      return normalizedFirst;
    }
    return '$normalizedFirst\n$normalizedSecond';
  }

  String identitySentence(String fruit) {
    return '나는 ${declarationFruitName(fruit)}입니다.';
  }

  String normalized(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[.。]+$'), '');
  }

  bool get entryIsComplete {
    return eventController.text.trim().isNotEmpty &&
        declarationController.text.trim().isNotEmpty;
  }

  void beginRecords() {
    if (noKingdomEnjoymentToday) {
      missingFruits
        ..clear()
        ..addAll(fruits);
      setState(() {
        missingIndex = 0;
        identityController.clear();
        identityGuidance = null;
        stage = 3;
      });
      return;
    }

    realmQueue
      ..clear()
      ..addAll(selectedRealms);
    setState(() {
      realmIndex = 0;
      stage = 1;
    });
  }

  void saveCurrentRecord() {
    final record = <String, String>{
      'realm': realmQueue[realmIndex],
      'event': eventController.text.trim(),
      'discovery': '',
      'declaration': declarationController.text.trim(),
      'enjoyment': '',
    };
    final editedIndex = editingRecordIndex;
    if (editedIndex != null && editedIndex < enjoymentRecords.length) {
      enjoymentRecords[editedIndex] = record;
    } else {
      enjoymentRecords.add(record);
    }

    eventController.clear();
    declarationController.clear();

    setState(() {
      if (editedIndex != null) {
        editingRecordIndex = null;
        stage = 4;
      } else if (realmIndex < realmQueue.length - 1) {
        realmIndex++;
      } else {
        stage = 2;
      }
    });
    saveQ3Draft();
  }

  void editEnjoymentRecord(int index) {
    final record = enjoymentRecords[index];
    setState(() {
      editingRecordIndex = index;
      realmQueue
        ..clear()
        ..add(record['realm'] ?? '내 안');
      realmIndex = 0;
      eventController.text = _combinedText(
        record['event'] ?? '',
        record['discovery'] ?? '',
      );
      declarationController.text = _combinedText(
        record['declaration'] ?? '',
        record['enjoyment'] ?? '',
      );
      stage = 1;
    });
    saveQ3Draft();
  }

  void prepareMissingFruits() {
    missingFruits
      ..clear()
      ..addAll(fruits.where((fruit) => !selectedFruits.contains(fruit)));

    setState(() {
      missingIndex = 0;
      identityController.clear();
      identityGuidance = null;
      stage = missingFruits.isEmpty ? 4 : 3;
    });
  }

  void checkIdentityDeclaration() {
    final expected = identitySentence(missingFruits[missingIndex]);
    if (normalized(identityController.text) == normalized(expected)) {
      if (missingIndex < missingFruits.length - 1) {
        setState(() {
          missingIndex++;
          identityController.clear();
          identityGuidance = null;
        });
      } else {
        setState(() {
          identityController.clear();
          identityGuidance = null;
          stage = 4;
        });
      }
      return;
    }

    setState(() {
      identityGuidance =
          '${characterDifferenceGuidance(identityController.text, expected)}\n'
          '띄어쓰기와 마지막 마침표는 달라도 괜찮습니다.';
    });
  }

  @override
  void dispose() {
    saveQ3Draft();
    eventController.dispose();
    declarationController.dispose();
    identityController.dispose();
    super.dispose();
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
              const SizedBox(height: 20),
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
                  currentLifeDiaryDraft.q2CompletedOldSelves.isEmpty
                      ? '기록 확인 전'
                      : currentLifeDiaryDraft.q2CompletedOldSelves.join(', '),
                ),
                trailing: const Icon(Icons.visibility_outlined),
              ),
              const ListTile(
                leading: CircleAvatar(child: Text('3')),
                title: Text('오늘 이루어진 하나님 나라'),
                subtitle: Text('현재 작성 중 · 입력 내용 유지'),
                trailing: Icon(Icons.edit_note),
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
              3,
              saveCurrent: saveQ3Draft,
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
                '질문 3/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: _buildStage())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (stage) {
      case 0:
        return _buildRealmSelection();
      case 1:
        return _buildEnjoymentRecord();
      case 2:
        return _buildFruitSelection();
      case 3:
        return _buildMissingFruitDeclaration();
      case 4:
        return _buildCompletion();
      default:
        return const SizedBox();
    }
  }

  Widget _questionTitle() {
    return const Text(
      '3. 오늘 나에게 이루어진\n'
      '하나님 나라를 구체적으로\n'
      '찾아본다면 무엇인가?',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.45,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildRealmSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 16),
        const Text(
          '오늘 하나님 나라를 구체적으로 발견하고 누린 영역을 '
          '선택해 주세요. 두 영역을 모두 선택할 수 있습니다.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: selectedRealms.contains('내 안'),
          title: const Text('내 안의 하나님 나라'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: noKingdomEnjoymentToday
              ? null
              : (value) {
                  setState(() {
                    value == true
                        ? selectedRealms.add('내 안')
                        : selectedRealms.remove('내 안');
                  });
                },
        ),
        CheckboxListTile(
          value: selectedRealms.contains('공동체·관계 안'),
          title: const Text('공동체·관계 안의 하나님 나라'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: noKingdomEnjoymentToday
              ? null
              : (value) {
                  setState(() {
                    value == true
                        ? selectedRealms.add('공동체·관계 안')
                        : selectedRealms.remove('공동체·관계 안');
                  });
                },
        ),
        const SizedBox(height: 12),
        const Divider(),
        CheckboxListTile(
          value: noKingdomEnjoymentToday,
          title: const Text('생명일기 3번에 기록할 것이 없다면'),
          subtitle: const Text('아홉 가지 성령의 열매를 모두 기록합니다.'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              noKingdomEnjoymentToday = value ?? false;
              if (noKingdomEnjoymentToday) {
                selectedRealms.clear();
              }
            });
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: selectedRealms.isEmpty && !noKingdomEnjoymentToday
                ? null
                : beginRecords,
            child: Text(
              noKingdomEnjoymentToday ? '아홉 가지 열매 기록하기' : '구체적으로 기록하기',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnjoymentRecord() {
    final realm = realmQueue[realmIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _questionTitle(),
        const SizedBox(height: 16),
        Text(
          '${realmIndex + 1}/${realmQueue.length}  $realm의 하나님 나라',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _recordField(
          title: '1. 어떤 상황에서 하나님 나라를 발견하였는가?',
          hint: '상황과 그 안에서 발견한 하나님 나라를 기록해 주세요.',
          controller: eventController,
        ),
        _recordField(
          title: '2. 고백·선포·선언하며 누렸는가?',
          hint: '무엇을 고백·선포·선언했고 어떻게 누렸는지 기록해 주세요.',
          controller: declarationController,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: entryIsComplete ? saveCurrentRecord : null,
            child: Text(
              realmIndex < realmQueue.length - 1 ? '다음 영역 기록하기' : '성령의 열매 확인하기',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recordField({
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '기록한 과정에서 어떤 성령의 열매가 나타났나요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '하나님 나라를 발견하고 고백·선포·선언하며 누린 과정을 돌아보며 '
          '관련된 열매를 모두 선택해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 20),
        ...fruits.map(
          (fruit) => CheckboxListTile(
            value: selectedFruits.contains(fruit),
            title: Text(fruit),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: noSpecificFruit
                ? null
                : (value) {
                    setState(() {
                      value == true
                          ? selectedFruits.add(fruit)
                          : selectedFruits.remove(fruit);
                    });
                  },
          ),
        ),
        const Divider(),
        CheckboxListTile(
          value: noSpecificFruit,
          title: const Text('오늘 관련된 열매를 구체적으로 찾지 못했습니다.'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(() {
              noSpecificFruit = value ?? false;
              if (noSpecificFruit) selectedFruits.clear();
            });
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: selectedFruits.isEmpty && !noSpecificFruit
                ? null
                : prepareMissingFruits,
            child: const Text('선택하지 않은 열매 확인', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingFruitDeclaration() {
    final fruit = missingFruits[missingIndex];
    final expected = identitySentence(fruit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          noKingdomEnjoymentToday
              ? '아홉 가지 성령의 열매를 고백합니다.'
              : '오늘 기록하지 않은 열매를 고백합니다.',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          noKingdomEnjoymentToday
              ? '오늘 구체적인 누림으로 기록할 것이 없다면 '
                    '아홉 가지 열매를 한 가지씩 모두 직접 기록합니다.'
              : '구체적인 사건으로 기록하지 않은 열매도 한 가지씩 '
                    '직접 고백하고 선언해 주세요.',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        Text(
          '열매 고백 ${missingIndex + 1}/${missingFruits.length}',
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            expected,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.48),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: identityController,
          minLines: 3,
          maxLines: 4,
          onChanged: (_) {
            setState(() => identityGuidance = null);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '위 문장 전체를 직접 기록해 주세요.',
          ),
        ),
        if (identityGuidance != null) ...[
          const SizedBox(height: 12),
          Text(
            identityGuidance!,
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
            onPressed: identityController.text.trim().isEmpty
                ? null
                : checkIdentityDeclaration,
            child: Text(
              missingIndex == missingFruits.length - 1
                  ? '아홉 가지 열매 확인'
                  : '다음 열매',
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
          '오늘 이루어진 하나님 나라를 확인합니다.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          noKingdomEnjoymentToday
              ? '오늘 구체적으로 기록할 누림은 없었지만, '
                    '아홉 가지 성령의 열매를 모두 고백하고 선언했습니다.'
              : '오늘 내 안과 공동체·관계 안에서 이루어진 하나님 나라를 '
                    '발견하고 고백하며 누렸습니다.',
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (enjoymentRecords.isNotEmpty) ...[
          ...enjoymentRecords.asMap().entries.map((entry) {
            final record = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      record['realm'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '상황과 하나님 나라 발견\n'
                      '${_combinedText(record['event'] ?? '', record['discovery'] ?? '')}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '고백·선포·선언과 누림\n'
                      '${_combinedText(record['declaration'] ?? '', record['enjoyment'] ?? '')}',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => editEnjoymentRecord(entry.key),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('이 기록 수정하기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fruits.map((fruit) {
            final experienced = selectedFruits.contains(fruit);
            return Chip(
              avatar: Icon(
                experienced ? Icons.favorite : Icons.record_voice_over,
                size: 18,
              ),
              label: Text(experienced ? '$fruit · 누림 기록' : '$fruit · 고백·선언'),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              stage = noKingdomEnjoymentToday ? 0 : 2;
            });
            saveQ3Draft();
          },
          icon: const Icon(Icons.edit_note),
          label: Text(
            noKingdomEnjoymentToday ? '3번 기록 방법 다시 선택하기' : '성령의 열매 선택 수정하기',
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              saveQ3Draft();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LifeDiaryQuestion4Page(diaryDate: widget.diaryDate),
                ),
              );
            },
            child: const Text('4번으로 이동', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}
