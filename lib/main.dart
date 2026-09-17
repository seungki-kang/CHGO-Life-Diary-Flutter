import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final TextInputFormatter keepMyRighteousnessWording =
    TextInputFormatter.withFunction((oldValue, newValue) {
  if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
    return newValue;
  }
  final corrected = newValue.text.replaceAll('나의 이는', '나의 의는');
  if (corrected == newValue.text) return newValue;
  return newValue.copyWith(
    text: corrected,
    selection: newValue.selection,
    composing: TextRange.empty,
  );
});

String normalizeDiarySentence(String text) => text
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(RegExp(r'[.。]+$'), '');

String characterDifferenceGuidance(String typedText, String expectedText) {
  final typed = normalizeDiarySentence(typedText);
  final expected = normalizeDiarySentence(expectedText);
  final rows = typed.length + 1;
  final columns = expected.length + 1;
  final matrix = List.generate(rows, (_) => List<int>.filled(columns, 0));

  for (var i = 0; i < rows; i++) matrix[i][0] = i;
  for (var j = 0; j < columns; j++) matrix[0][j] = j;
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      final cost = typed.codeUnitAt(i - 1) == expected.codeUnitAt(j - 1)
          ? 0
          : 1;
      final deletion = matrix[i - 1][j] + 1;
      final insertion = matrix[i][j - 1] + 1;
      final replacement = matrix[i - 1][j - 1] + cost;
      matrix[i][j] = [deletion, insertion, replacement]
          .reduce((a, b) => a < b ? a : b);
    }
  }

  var i = typed.length;
  var j = expected.length;
  final differences = <String>[];
  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        typed.codeUnitAt(i - 1) == expected.codeUnitAt(j - 1)) {
      i--;
      j--;
      continue;
    }
    if (i > 0 &&
        j > 0 &&
        matrix[i][j] == matrix[i - 1][j - 1] + 1) {
      differences.add(
        '${j}번째 글자 “${typed[i - 1]}”를 “${expected[j - 1]}”로 수정해 주세요.',
      );
      i--;
      j--;
    } else if (i > 0 && matrix[i][j] == matrix[i - 1][j] + 1) {
      differences.add(
        '${i}번째에 입력한 “${typed[i - 1]}”는 더 들어간 글자입니다. 삭제해 주세요.',
      );
      i--;
    } else if (j > 0) {
      differences.add(
        '${j}번째에 “${expected[j - 1]}”가 빠졌습니다. 넣어 주세요.',
      );
      j--;
    }
  }

  if (differences.isEmpty) return '위 문장을 다시 확인해 주세요.';
  final ordered = differences.reversed.toList();
  final visible = ordered.take(5).map((message) => '• $message').join('\n');
  final remainder = ordered.length > 5
      ? '\n• 이 밖에도 ${ordered.length - 5}곳을 더 확인해 주세요.'
      : '';
  return '다음 글자를 확인해 주세요.\n$visible$remainder';
}

class LifeDiarySessionDraft {
  DateTime? diaryDate;
  String q1Detail = '';
  final Set<String> q1OldSelves = {};
  bool q1NoOldSelf = false;
  String? q1Awareness;
  double q1AwarenessPercent = 50;
  int q1Step = 1;
  final List<String> q2CompletedOldSelves = [];
  String q2PartialText = '';
  int q2CurrentIndex = 0;

  int q3Stage = 0;
  final Set<String> q3SelectedRealms = {};
  final Set<String> q3SelectedFruits = {};
  final List<Map<String, String>> q3EnjoymentRecords = [];
  final List<String> q3RealmQueue = [];
  final List<String> q3MissingFruits = [];
  String q3Event = '';
  String q3Discovery = '';
  String q3Declaration = '';
  String q3Enjoyment = '';
  String q3Identity = '';
  int q3RealmIndex = 0;
  int q3MissingIndex = 0;
  bool q3NoEnjoyment = false;
  bool q3NoSpecificFruit = false;
  int? q3EditingRecordIndex;

  int q4Stage = 0;
  String q4Person = '';
  String q4Event = '';
  String q4Response = '';
  String q4Love = '';
  String q4Declaration = '';
  String q4AdditionalConfession = '';
  bool q4NoRecord = false;
  bool q4Judged = false;
  bool q4Resisted = false;
  bool q4ViewedWithLove = false;
  bool q4ViewedWithCompassion = false;
  String? q4NewDiscoveryChoice;
  final Set<String> q4AdditionalOldSelves = {};
  bool q4OwnershipRealized = false;
  int q4DeclarationIndex = 0;
  int q4AdditionalIndex = 0;
  final List<String> q4AdditionalQueue = [];

  int q5Stage = 0;
  String? q5Selection;
  String q5DailyRecord = '';
  String q5WordRecord = '';
  String q5NoRecordDeclaration = '';

  int q6Stage = 0;
  final List<Map<String, String>> q6Gratitudes = [];
  String q6Person = '';
  String q6What = '';
  String q6Why = '';
  String? q6SituationType;
  int? q6EditingIndex;

  int q7Stage = 0;
  String q7Action = '';
  String q7Reason = '';
  bool q7CoachingRequested = false;
  String q7CoachingNote = '';
  bool q7FinalCompleted = false;

  void reset(DateTime date) {
    diaryDate = date;
    q1Detail = '';
    q1OldSelves.clear();
    q1NoOldSelf = false;
    q1Awareness = null;
    q1AwarenessPercent = 50;
    q1Step = 1;
    q2CompletedOldSelves.clear();
    q2PartialText = '';
    q2CurrentIndex = 0;
    q3Stage = 0;
    q3SelectedRealms.clear();
    q3SelectedFruits.clear();
    q3EnjoymentRecords.clear();
    q3RealmQueue.clear();
    q3MissingFruits.clear();
    q3Event = '';
    q3Discovery = '';
    q3Declaration = '';
    q3Enjoyment = '';
    q3Identity = '';
    q3RealmIndex = 0;
    q3MissingIndex = 0;
    q3NoEnjoyment = false;
    q3NoSpecificFruit = false;
    q3EditingRecordIndex = null;
    q4Stage = 0;
    q4Person = '';
    q4Event = '';
    q4Response = '';
    q4Love = '';
    q4Declaration = '';
    q4AdditionalConfession = '';
    q4NoRecord = false;
    q4Judged = false;
    q4Resisted = false;
    q4ViewedWithLove = false;
    q4ViewedWithCompassion = false;
    q4NewDiscoveryChoice = null;
    q4AdditionalOldSelves.clear();
    q4OwnershipRealized = false;
    q4DeclarationIndex = 0;
    q4AdditionalIndex = 0;
    q4AdditionalQueue.clear();
    q5Stage = 0;
    q5Selection = null;
    q5DailyRecord = '';
    q5WordRecord = '';
    q5NoRecordDeclaration = '';
    q6Stage = 0;
    q6Gratitudes.clear();
    q6Person = '';
    q6What = '';
    q6Why = '';
    q6SituationType = null;
    q6EditingIndex = null;
    q7Stage = 0;
    q7Action = '';
    q7Reason = '';
    q7CoachingRequested = false;
    q7CoachingNote = '';
    q7FinalCompleted = false;
  }
}

// ============================================================
// V0.17a
// Life Diary Question 7
// ============================================================

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
    final draft = currentLifeDiaryDraft;
    draft.q7Stage = stage;
    draft.q7Action = actionController.text;
    draft.q7Reason = reasonController.text;
    draft.q7CoachingRequested = coachingRequested;
    draft.q7CoachingNote = coachingNoteController.text;
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

  Future<void> completeLifeDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('생명일기를 완성하시겠습니까?'),
        content: const Text(
          '최종 완성하기 전에 1~7번 기록을 다시 확인하고 자유롭게 수정할 수 있습니다.',
        ),
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
    setState(() {
      stage = 3;
      currentLifeDiaryDraft.q7FinalCompleted = true;
    });
    saveQ7Draft();
  }

  @override
  void dispose() {
    saveQ7Draft();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('생명일기'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '1~7번 문항 이동',
            onPressed: () => showLifeDiaryQuestionNavigator(
              context, widget.diaryDate, 7, saveCurrent: saveQ7Draft),
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
              Text(formatDate(widget.diaryDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('시즌 1 · 1/50회',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('질문 7/7', textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
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

  Widget _title() => const Text('7. 무엇을 할 것인가?',
      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold));

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
        child: const Column(children: [
          Icon(Icons.pause_circle_outline, size: 48),
          SizedBox(height: 14),
          Text('잠시 모든 것을 멈춥니다.', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 14),
          Text('1~6번의 기록을 천천히 돌아보며\n'
              '“나는 이제 무엇을 할 것인가?”를 묵상해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, height: 1.6)),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('7번은 생명일기의 열매입니다.\n\n'
          '성령님이 주시는 통찰과 하나님의 뜻, 응답, 아이디어와 지혜를 따라 '
          '실제로 행할 일을 구체적으로 기록합니다. 사소한 일부터 큰 일까지 '
          '기록할 수 있고, 매일 반복하며 발전시켜도 좋습니다.',
          style: TextStyle(fontSize: 16, height: 1.65)),
      const SizedBox(height: 28),
      SizedBox(height: 58, child: FilledButton(
        onPressed: () => changeStage(1),
        child: const Text('묵상하고 기록하기', style: TextStyle(fontSize: 18)),
      )),
    ],
  );

  Widget _buildEntry() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _title(),
      const SizedBox(height: 10),
      const Text('묵상하며 깨달은 구체적인 실행을 기록해 주세요.',
          style: TextStyle(fontSize: 16, height: 1.5)),
      const SizedBox(height: 22),
      TextField(
        controller: actionController, minLines: 4, maxLines: 7,
        onChanged: (_) { setState(() {}); saveQ7Draft(); },
        decoration: const InputDecoration(
          border: OutlineInputBorder(), labelText: '무엇을 할 것인가?',
          hintText: '내가 실제로 실행할 일을 구체적으로 기록해 주세요.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: reasonController, minLines: 4, maxLines: 7,
        onChanged: (_) { setState(() {}); saveQ7Draft(); },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '왜 이것을 실행하려고 합니까?',
          hintText: '이 실행이 필요한 이유와 받은 통찰을 기록해 주세요.',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(height: 56, child: FilledButton(
        onPressed: entryComplete ? () => changeStage(2) : null,
        child: const Text('실행 내용 확인', style: TextStyle(fontSize: 18)),
      )),
    ],
  );

  Widget _recordCard(String label, String value) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 17, height: 1.55)),
      ],
    )),
  );

  Widget _buildReview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('나의 실행', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
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
          controller: coachingNoteController, minLines: 3, maxLines: 5,
          onChanged: (_) => saveQ7Draft(),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '코칭에서 함께 나누고 싶은 내용 · 선택 사항',
            alignLabelWithHint: true,
          ),
        ),
      ],
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: () => changeStage(1),
          icon: const Icon(Icons.edit_outlined), label: const Text('7번 기록 수정하기')),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => showLifeDiaryQuestionNavigator(
            context, widget.diaryDate, 7, saveCurrent: saveQ7Draft),
        icon: const Icon(Icons.grid_view_outlined),
        label: const Text('1~7번 기록 다시 확인하기'),
      ),
      const SizedBox(height: 22),
      SizedBox(height: 58, child: FilledButton(
        onPressed: completeLifeDiary,
        child: const Text('생명일기 최종 완성', style: TextStyle(fontSize: 18)),
      )),
    ],
  );

  Widget _buildCompletion() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(Icons.check_circle, size: 70, color: Colors.indigo),
      const SizedBox(height: 18),
      const Text('오늘의 생명일기를 완성했습니다.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const Text('묵상에서 얻은 통찰을 삶에서 실행해 보세요.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5)),
      const SizedBox(height: 26),
      _recordCard('나의 실행', actionController.text.trim()),
      _recordCard('실행하는 이유', reasonController.text.trim()),
      if (coachingRequested)
        const Chip(label: Text('코칭 희망 · 선택 완료')),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () {
          currentLifeDiaryDraft.q7FinalCompleted = false;
          changeStage(2);
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('최종 기록 다시 확인하기'),
      ),
    ],
  );
}

// ============================================================
// V0.17a
// Life Diary Question 6
// ============================================================

class LifeDiaryQuestion6Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion6Page({
    super.key,
    required this.diaryDate,
  });

  @override
  State<LifeDiaryQuestion6Page> createState() =>
      _LifeDiaryQuestion6PageState();
}

class _LifeDiaryQuestion6PageState extends State<LifeDiaryQuestion6Page> {
  final TextEditingController personController = TextEditingController();
  final TextEditingController whatController = TextEditingController();
  final TextEditingController whyController = TextEditingController();

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
    personController.text = draft.q6Person;
    whatController.text = draft.q6What;
    whyController.text = draft.q6Why;
    situationType = draft.q6SituationType;
    editingIndex = draft.q6EditingIndex;
  }

  void saveQ6Draft() {
    final draft = currentLifeDiaryDraft;
    draft.q6Stage = stage;
    draft.q6Gratitudes
      ..clear()
      ..addAll(gratitudes.map((item) => Map<String, String>.from(item)));
    draft.q6Person = personController.text;
    draft.q6What = whatController.text;
    draft.q6Why = whyController.text;
    draft.q6SituationType = situationType;
    draft.q6EditingIndex = editingIndex;
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  bool get entryComplete =>
      personController.text.trim().isNotEmpty &&
      whatController.text.trim().isNotEmpty &&
      whyController.text.trim().isNotEmpty;

  void startRecording() {
    setState(() => stage = 1);
    saveQ6Draft();
  }

  void saveGratitude() {
    if (!entryComplete) return;
    final item = <String, String>{
      'person': personController.text.trim(),
      'what': whatController.text.trim(),
      'why': whyController.text.trim(),
      'type': situationType ?? '',
    };
    final index = editingIndex;
    if (index != null && index < gratitudes.length) {
      gratitudes[index] = item;
    } else {
      gratitudes.add(item);
    }

    personController.clear();
    whatController.clear();
    whyController.clear();
    setState(() {
      situationType = null;
      editingIndex = null;
      stage = gratitudes.length >= 3 ? 2 : 1;
    });
    saveQ6Draft();
  }

  void addAnotherGratitude() {
    personController.clear();
    whatController.clear();
    whyController.clear();
    setState(() {
      editingIndex = null;
      situationType = null;
      stage = 1;
    });
    saveQ6Draft();
  }

  void editGratitude(int index) {
    final item = gratitudes[index];
    setState(() {
      editingIndex = index;
      personController.text = item['person'] ?? '';
      whatController.text = item['what'] ?? '';
      whyController.text = item['why'] ?? '';
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

  void finishQuestion6() {
    if (gratitudes.length < 3) return;
    setState(() => stage = 3);
    saveQ6Draft();
  }

  @override
  void dispose() {
    saveQ6Draft();
    personController.dispose();
    whatController.dispose();
    whyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                '시즌 1 · 1/50회',
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
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
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
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '“범사에 감사하라”\n'
            '(데살로니가전서 5장 18절)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, height: 1.6, fontWeight: FontWeight.w600),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          '구체적인 감사는 “누구에게, 무엇을, 왜 감사하는가”를 기록하는 것입니다.',
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
            labelText: '무엇을 감사합니까?',
            hintText: '감사하는 사건이나 내용을 구체적으로 기록해 주세요.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: whyController,
          minLines: 3,
          maxLines: 5,
          onChanged: (_) {
            setState(() {});
            saveQ6Draft();
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '왜 감사합니까?',
            hintText: '감사하는 이유를 구체적으로 기록해 주세요.',
          ),
        ),
        const SizedBox(height: 18),
        const Text('감사의 상황 · 선택 사항',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if ((item['type'] ?? '').isNotEmpty)
                  Chip(label: Text(item['type']!)),
              ],
            ),
            const SizedBox(height: 8),
            Text('누구에게\n${item['person'] ?? ''}'),
            const SizedBox(height: 8),
            Text('무엇을\n${item['what'] ?? ''}'),
            const SizedBox(height: 8),
            Text('왜\n${item['why'] ?? ''}'),
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
        const Text('감사를 3가지 이상 기록했습니다.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('현재 ${gratitudes.length}가지 감사를 기록했습니다.',
            style: const TextStyle(fontSize: 16)),
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
            label: const Text('감사를 더 기록합니다',
                style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: finishQuestion6,
            child: const Text('생명일기 6번을 마칩니다',
                style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('생명일기 6번을 마쳤습니다.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('오늘 ${gratitudes.length}가지 감사를 기록했습니다.',
            style: const TextStyle(fontSize: 16)),
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
              saveQ6Draft();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LifeDiaryQuestion7Page(
                    diaryDate: widget.diaryDate,
                  ),
                ),
              );
            },
            child: const Text('생명일기 7번으로',
                style: TextStyle(fontSize: 18)),
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

class LifeDiaryQuestion5Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion5Page({
    super.key,
    required this.diaryDate,
  });

  @override
  State<LifeDiaryQuestion5Page> createState() =>
      _LifeDiaryQuestion5PageState();
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
    final draft = currentLifeDiaryDraft;
    draft.q5Stage = stage;
    draft.q5Selection = selection;
    draft.q5DailyRecord = dailyController.text;
    draft.q5WordRecord = wordController.text;
    draft.q5NoRecordDeclaration = noRecordController.text;
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  String normalized(String text) => text
      .replaceAll(RegExp(r'\s+'), '')
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
    if (normalized(noRecordController.text) ==
        normalized(noRecordSentence)) {
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
                '시즌 1 · 1/50회',
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
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
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
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
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
        _selectionTile(
          value: 'daily',
          title: '일상에서 성령님과 나눈 교제(경험)를 기록합니다.',
        ),
        _selectionTile(
          value: 'word',
          title: '말씀을 읽다가 성령께서 깨닫게 하신 것을 기록합니다.',
        ),
        _selectionTile(
          value: 'both',
          title: '두 가지 모두 기록합니다.',
        ),
        _selectionTile(
          value: 'none',
          title: '오늘 5번에 구체적으로 기록할 것이 없습니다.',
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
      groupValue: selection,
      title: Text(title),
      onChanged: (newValue) {
        setState(() => selection = newValue);
        saveQ5Draft();
      },
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
            child: Text(
              selection == 'both' ? '말씀을 통한 교제 기록하기' : '일상 교제 기록 완료',
              style: const TextStyle(fontSize: 18),
            ),
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
            child: const Text('말씀 교제 기록 완료',
                style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _fadedSentence(String sentence) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.48),
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
            child: const Text('감사 고백 완료',
                style: TextStyle(fontSize: 18)),
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
                  const Text('일상에서 성령님과 나눈 교제',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
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
                  const Text('말씀을 통해 깨닫게 하신 내용',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
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
              child: Text(noRecordController.text,
                  style: const TextStyle(height: 1.5)),
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
              saveQ5Draft();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LifeDiaryQuestion6Page(
                    diaryDate: widget.diaryDate,
                  ),
                ),
              );
            },
            child: const Text('6번으로 이동',
                style: TextStyle(fontSize: 18)),
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

class LifeDiaryQuestion4Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion4Page({
    super.key,
    required this.diaryDate,
  });

  @override
  State<LifeDiaryQuestion4Page> createState() =>
      _LifeDiaryQuestion4PageState();
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
  }

  String formatDate(DateTime date) =>
      '${date.year}년 ${date.month}월 ${date.day}일';

  String normalized(String text) => text
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[.。]+$'), '');

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
              const Text('기록 보기·수정',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(child: Text('1')),
                title: const Text('오늘 발견한 옛사람'),
                subtitle: Text(currentLifeDiaryDraft.q1NoOldSelf
                    ? '구체적으로 발견한 옛사람 없음'
                    : currentLifeDiaryDraft.q1OldSelves.join(', ')),
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
                    currentLifeDiaryDraft.q2CompletedOldSelves.join(', ')),
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
              Text(formatDate(widget.diaryDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('시즌 1 · 1/50회',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('질문 4/7',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(child: _buildStage()),
              ),
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
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, height: 1.4),
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
            child: Text(noRecordToday ? '세 문장 기록하기' : '4번 사건 기록 완료',
                style: const TextStyle(fontSize: 18)),
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
        const Text('4번을 통해 내 안의 옛사람을 새롭게 발견했나요?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4)),
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
            onPressed: newDiscoveryChoice == null ? null : continueAfterReflection,
            child: Text(newDiscoveryChoice == 'different'
                ? '추가 1·2번 처리 선택'
                : '4번 마치기', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _fadedSentence(String sentence) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(sentence,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.48))),
      );

  Widget _buildNoRecordDeclarations() {
    final expected = noRecordDeclarations[declarationIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('생명일기 4번에 기록할 것이 없다면',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('세 문장을 처음부터 끝까지 직접 기록해 주세요.',
            style: TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 20),
        Text('생명 고백 ${declarationIndex + 1}/3',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
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
              hintText: '위 문장 전체를 직접 기록해 주세요.'),
        ),
        if (guidance != null) ...[
          const SizedBox(height: 10),
          Text(guidance!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: declarationController.text.trim().isEmpty
                ? null
                : checkNoRecordDeclaration,
            child: Text(declarationIndex == 2 ? '4번 기록 완료' : '다음 문장',
                style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDiscovery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('4번에서 새롭게 발견한 옛사람을 추가로 처리합니다.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4)),
        const SizedBox(height: 12),
        const Text('기존 1번 기록은 그대로 보존됩니다. 새롭게 발견한 것만 모두 선택해 주세요.',
            style: TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 16),
        ...allOldSelves.map((oldSelf) => CheckboxListTile(
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
            )),
        const Divider(height: 28),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: acceptsOwnership,
          title: const Text('이 옛사람은 100% 내 안에 있음을 깨달았습니다.'),
          onChanged: (value) => setState(() => acceptsOwnership = value ?? false),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: additionalOldSelves.isNotEmpty && acceptsOwnership
                ? beginAdditionalProcessing
                : null,
            child: const Text('추가 2번으로 처리하기',
                style: TextStyle(fontSize: 18)),
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
        const Text('새롭게 발견한 옛사람을 십자가에서 처리합니다.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4)),
        const SizedBox(height: 10),
        Text('추가 십자가 고백 ${additionalIndex + 1}/${additionalQueue.length}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
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
              hintText: '위 문장 전체를 직접 기록해 주세요.'),
        ),
        if (guidance != null) ...[
          const SizedBox(height: 10),
          Text(guidance!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 22),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: additionalConfessionController.text.trim().isEmpty
                ? null
                : checkAdditionalConfession,
            child: Text(additionalIndex == additionalQueue.length - 1
                ? '추가 1·2번 처리 완료'
                : '다음 문장', style: const TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('생명일기 4번을 마쳤습니다.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  builder: (_) => LifeDiaryQuestion5Page(
                    diaryDate: widget.diaryDate,
                  ),
                ),
              );
            },
            child: const Text('5번으로 이동',
                style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}

final LifeDiarySessionDraft currentLifeDiaryDraft =
    LifeDiarySessionDraft();

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
            const Text('생명일기 문항 이동',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('최종 완성 전까지 작성한 내용은 지워지지 않습니다.'),
            const SizedBox(height: 14),
            ...List.generate(7, (index) {
              final number = index + 1;
              final q1Ready = currentLifeDiaryDraft.q1NoOldSelf ||
                  currentLifeDiaryDraft.q1OldSelves.isNotEmpty;
              final available = number <= 7 && (number != 2 || q1Ready);
              return ListTile(
                leading: CircleAvatar(child: Text('$number')),
                title: Text(number == currentQuestion
                    ? '$number번 · 현재 문항'
                    : available
                        ? '$number번으로 이동'
                        : number == 2
                            ? '2번 · 먼저 1번을 기록해 주세요'
                            : '$number번 · 준비 중'),
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
                        late final Widget page;
                        if (number == 1) {
                          page = LifeDiaryReadyPage(diaryDate: diaryDate);
                        } else if (number == 2) {
                          page = LifeDiaryQuestion2Page(
                            diaryDate: diaryDate,
                            selectedOldSelves:
                                currentLifeDiaryDraft.q1OldSelves.toList(),
                            noOldSelfToday:
                                currentLifeDiaryDraft.q1NoOldSelf,
                          );
                        } else if (number == 3) {
                          page = LifeDiaryQuestion3Page(diaryDate: diaryDate);
                        } else if (number == 4) {
                          page = LifeDiaryQuestion4Page(diaryDate: diaryDate);
                        } else if (number == 5) {
                          page = LifeDiaryQuestion5Page(diaryDate: diaryDate);
                        } else if (number == 6) {
                          page = LifeDiaryQuestion6Page(diaryDate: diaryDate);
                        } else {
                          page = LifeDiaryQuestion7Page(diaryDate: diaryDate);
                        }
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

void main() {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
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
      appBar: AppBar(
        title: const Text('CHGO Life Diary'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                ),
                const SizedBox(height: 24),

                const Text(
                  '생명일기',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  '생명일기의 모든 과정은\n'
                  '성령의 역사입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '성령을 의지하며\n'
                  '자신의 내면과 삶을 바라봅니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
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
                          builder: (context) =>
                              const LifeDiaryDatePage(),
                        ),
                      );
                    },
                    child: const Text(
                      '생명일기 시작',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Flutter V0.17a',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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
  State<LifeDiaryDatePage> createState() =>
      _LifeDiaryDatePageState();
}

class _LifeDiaryDatePageState extends State<LifeDiaryDatePage> {
  DateTime selectedDate = DateTime.now();

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
      lastDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),

      helpText: '생명일기 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('생명일기'),
        centerTitle: true,
      ),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '시즌 1 · 1/50회',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
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
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 48,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '선택한 날짜',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
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
                  onPressed: () {
                    final savedDate = currentLifeDiaryDraft.diaryDate;
                    final sameDiary = savedDate != null &&
                        savedDate.year == selectedDate.year &&
                        savedDate.month == selectedDate.month &&
                        savedDate.day == selectedDate.day;
                    if (!sameDiary) {
                      currentLifeDiaryDraft.reset(selectedDate);
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LifeDiaryReadyPage(
                          diaryDate: selectedDate,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '이 날짜로 시작',
                    style: TextStyle(fontSize: 18),
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
// Temporary Ready Page
// Q1 will be connected in the next version.
// ============================================================

// ============================================================
// V0.03c
// Life Diary Question 1
// ============================================================

class LifeDiaryReadyPage extends StatefulWidget {
  final DateTime diaryDate;
  final bool editMode;

  const LifeDiaryReadyPage({
    super.key,
    required this.diaryDate,
    this.editMode = false,
  });

  @override
  State<LifeDiaryReadyPage> createState() =>
      _LifeDiaryReadyPageState();
}

class _LifeDiaryReadyPageState
    extends State<LifeDiaryReadyPage> {
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

  final TextEditingController detailController =
      TextEditingController();

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
    final previousRoots = Set<String>.from(
      currentLifeDiaryDraft.q1OldSelves,
    );
    final selectionChanged = previousRoots.length != selectedRoots.length ||
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

  void previousStep() {
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
      Navigator.pop(context);
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '질문 1/7',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStep(),
                ),
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
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        ...oldSelfRoots.map(
          (root) => CheckboxListTile(
            value: selectedRoots.contains(root),
            title: Text(root),
            controlAffinity:
                ListTileControlAffinity.leading,
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
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 18),
            ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          '어떤 상황에서 발견했나요?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          '외부의 사람이나 상황을 판단하기보다 '
          '그때 내 안에서 무엇이 일어났는지 돌아봅니다.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
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
            hintText:
                '그 상황에서 내 안에 어떤 생각, 감정, 반응이 있었는지 기록해 주세요.',
          ),
        ),

        const SizedBox(height: 24),

        const Divider(),

        CheckboxListTile(
          value: noOldSelfToday,
          title: const Text(
            '오늘 구체적으로 발견한 옛사람이 없습니다.',
          ),
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
            onPressed:
                (detailController.text.trim().isEmpty &&
                        !noOldSelfToday)
                    ? null
                    : nextStep,
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 18),
            ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
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
            onPressed:
                awareness == null ? null : nextStep,
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 18),
            ),
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
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 32),
      ],

      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant,
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
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
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

class LifeDiaryQuestion3Page extends StatefulWidget {
  final DateTime diaryDate;

  const LifeDiaryQuestion3Page({
    super.key,
    required this.diaryDate,
  });

  @override
  State<LifeDiaryQuestion3Page> createState() =>
      _LifeDiaryQuestion3PageState();
}

class _LifeDiaryQuestion3PageState
    extends State<LifeDiaryQuestion3Page> {
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

  final TextEditingController eventController =
      TextEditingController();
  final TextEditingController discoveryController =
      TextEditingController();
  final TextEditingController declarationController =
      TextEditingController();
  final TextEditingController enjoymentController =
      TextEditingController();
  final TextEditingController identityController =
      TextEditingController();

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
      draft.q3EnjoymentRecords.map((record) => Map<String, String>.from(record)),
    );
    realmQueue.addAll(draft.q3RealmQueue);
    missingFruits.addAll(draft.q3MissingFruits);
    eventController.text = draft.q3Event;
    discoveryController.text = draft.q3Discovery;
    declarationController.text = draft.q3Declaration;
    enjoymentController.text = draft.q3Enjoyment;
    identityController.text = draft.q3Identity;
    realmIndex = draft.q3RealmIndex;
    missingIndex = draft.q3MissingIndex;
    noKingdomEnjoymentToday = draft.q3NoEnjoyment;
    noSpecificFruit = draft.q3NoSpecificFruit;
    editingRecordIndex = draft.q3EditingRecordIndex;
  }

  void saveQ3Draft() {
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
      ..addAll(enjoymentRecords.map((record) => Map<String, String>.from(record)));
    draft.q3RealmQueue
      ..clear()
      ..addAll(realmQueue);
    draft.q3MissingFruits
      ..clear()
      ..addAll(missingFruits);
    draft.q3Event = eventController.text;
    draft.q3Discovery = discoveryController.text;
    draft.q3Declaration = declarationController.text;
    draft.q3Enjoyment = enjoymentController.text;
    draft.q3Identity = identityController.text;
    draft.q3RealmIndex = realmIndex;
    draft.q3MissingIndex = missingIndex;
    draft.q3NoEnjoyment = noKingdomEnjoymentToday;
    draft.q3NoSpecificFruit = noSpecificFruit;
    draft.q3EditingRecordIndex = editingRecordIndex;
  }

  String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String declarationFruitName(String fruit) {
    return fruit == '평안(화평)' ? '평안' : fruit;
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
        discoveryController.text.trim().isNotEmpty &&
        declarationController.text.trim().isNotEmpty &&
        enjoymentController.text.trim().isNotEmpty;
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
      'discovery': discoveryController.text.trim(),
      'declaration': declarationController.text.trim(),
      'enjoyment': enjoymentController.text.trim(),
    };
    final editedIndex = editingRecordIndex;
    if (editedIndex != null && editedIndex < enjoymentRecords.length) {
      enjoymentRecords[editedIndex] = record;
    } else {
      enjoymentRecords.add(record);
    }

    eventController.clear();
    discoveryController.clear();
    declarationController.clear();
    enjoymentController.clear();

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
      eventController.text = record['event'] ?? '';
      discoveryController.text = record['discovery'] ?? '';
      declarationController.text = record['declaration'] ?? '';
      enjoymentController.text = record['enjoyment'] ?? '';
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
    discoveryController.dispose();
    declarationController.dispose();
    enjoymentController.dispose();
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
                '질문 3/7',
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
                  child: _buildStage(),
                ),
              ),
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
          title: const Text(
            '생명일기 3번에 기록할 것이 없다면',
          ),
          subtitle: const Text(
            '아홉 가지 성령의 열매를 모두 기록합니다.',
          ),
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
            onPressed: selectedRealms.isEmpty &&
                    !noKingdomEnjoymentToday
                ? null
                : beginRecords,
            child: Text(
              noKingdomEnjoymentToday
                  ? '아홉 가지 열매 기록하기'
                  : '구체적으로 기록하기',
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
          title: '1. 실제 사건·상황',
          hint: '언제, 어디에서, 누구와 어떤 일이 있었는지 기록해 주세요.',
          controller: eventController,
        ),
        _recordField(
          title: '2. 하나님 나라 발견',
          hint: '그 사건에서 어떤 하나님 나라를 발견했는지 기록해 주세요.',
          controller: discoveryController,
        ),
        _recordField(
          title: '3. 고백·선포·선언',
          hint: '그 순간 무엇이라고 고백하고 선포하고 선언했는지 기록해 주세요.',
          controller: declarationController,
        ),
        _recordField(
          title: '4. 누림',
          hint: '무엇을 느끼고 어떻게 하나님 나라를 누렸는지 기록해 주세요.',
          controller: enjoymentController,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: entryIsComplete ? saveCurrentRecord : null,
            child: Text(
              realmIndex < realmQueue.length - 1
                  ? '다음 영역 기록하기'
                  : '성령의 열매 확인하기',
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
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
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
              fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
        ),
        const SizedBox(height: 12),
        const Text(
          '사건과 발견, 고백·선포·선언, 누림의 과정을 돌아보며 '
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
            child: const Text('선택하지 않은 열매 확인',
                style: TextStyle(fontSize: 18)),
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
              fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
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
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            expected,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
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
              fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
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
                    Text(record['realm'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('사건·상황\n${record['event'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('하나님 나라 발견\n${record['discovery'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('고백·선포·선언\n${record['declaration'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('누림\n${record['enjoyment'] ?? ''}'),
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
              label: Text(
                experienced ? '$fruit · 누림 기록' : '$fruit · 고백·선언',
              ),
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
          label: Text(noKingdomEnjoymentToday
              ? '3번 기록 방법 다시 선택하기'
              : '성령의 열매 선택 수정하기'),
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
                  builder: (context) => LifeDiaryQuestion4Page(
                    diaryDate: widget.diaryDate,
                  ),
                ),
              );
            },
            child: const Text('4번으로 이동',
                style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }
}
