import 'package:chgo_life_diary/data/life_diary_entry_factory.dart';
import 'package:chgo_life_diary/domain/life_diary_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final factory = LifeDiaryEntryFactory(
    clock: () => DateTime.utc(2026, 10, 6, 12),
  );

  test('maps the Q1-Q7 UI draft to a completed canonical entry', () {
    final entry = factory.fromUiDraft(DateTime(2026, 10, 6), {
      'q1_detail': 'record',
      'q1_old_selves': ['수치심', '두려움'],
      'q2_completed_old_selves': ['수치심'],
      'q3_selected_realms': ['내 안', '공동체·관계 안'],
      'q3_selected_fruits': ['사랑', '절제'],
      'q3_event': 'event',
      'q3_discovery': 'discovery',
      'q3_declaration': 'declaration',
      'q4_person': 'person',
      'q4_ownership_realized': true,
      'q5_selection': 'word',
      'q5_word_record': 'scripture insight',
      'q6_gratitudes': [
        {'person': 'friend', 'what': 'help', 'why': 'love'},
      ],
      'q7_action': 'act',
      'q7_reason': 'reason',
    }, completed: true);

    expect(entry.entryId, 'JL-LD-LOCAL-20261006-S001-N01');
    expect(entry.status, LifeDiaryEntryStatus.completed);
    expect(entry.questions.q1.oldPersonIds, ['JL-OLD-01', 'JL-OLD-03']);
    expect(entry.questions.q3.contexts, containsAll(KingdomContext.values));
    expect(entry.questions.q3.fruitIds, ['JL-FRUIT-01', 'JL-FRUIT-09']);
    expect(entry.questions.q5.communionType, CommunionType.scriptureInsight);
    expect(entry.questions.q6.items.single.what, 'help');
    expect(entry.questions.q7.actions, ['act', 'reason']);
  });

  test('stores Q3 text from the saved realm records', () {
    // Regression: the Q3 screen moves each record into q3_enjoyment_records and
    // clears q3_event/q3_declaration, so completed entries had an empty Q3.
    final entry = factory.fromUiDraft(DateTime(2026, 10, 6), {
      'q3_selected_realms': ['내 안', '공동체·관계 안'],
      'q3_enjoyment_records': [
        {
          'realm': '내 안',
          'event': '아침 묵상 중 평안을 발견',
          'discovery': '',
          'declaration': '나는 평안입니다라고 선포',
          'enjoyment': '',
        },
        {
          'realm': '공동체·관계 안',
          'event': '소그룹에서 서로 섬김',
          'discovery': '',
          'declaration': '감사로 고백',
          'enjoyment': '',
        },
      ],
      'q3_event': '',
      'q3_declaration': '',
    }, completed: true);

    expect(
      entry.questions.q3.narrative,
      '[내 안] 아침 묵상 중 평안을 발견\n\n[공동체·관계 안] 소그룹에서 서로 섬김',
    );
    expect(
      entry.questions.q3.declaration,
      '[내 안] 나는 평안입니다라고 선포\n\n[공동체·관계 안] 감사로 고백',
    );
  });

  test('older Q3 drafts without records still use the flat fields', () {
    final entry = factory.fromUiDraft(DateTime(2026, 10, 6), {
      'q3_event': 'event',
      'q3_discovery': 'discovery',
      'q3_declaration': 'declaration',
    }, completed: true);

    expect(entry.questions.q3.narrative, 'event\n\ndiscovery');
    expect(entry.questions.q3.declaration, 'declaration');
  });

  test('uses safe empty canonical payloads for unanswered fields', () {
    final entry = factory.fromUiDraft(
      DateTime(2026, 10, 7),
      const {},
      completed: false,
    );

    expect(entry.status, LifeDiaryEntryStatus.draft);
    expect(entry.questions.q1.oldPersonIds, isEmpty);
    expect(entry.questions.q5.communionType, CommunionType.noneWithThanks);
    expect(entry.questions.q7.actions, isEmpty);
  });

  test('creates distinct canonical IDs for multiple entries on one day', () {
    final first = factory.fromUiDraft(
      DateTime(2026, 10, 7),
      const {},
      completed: true,
      seasonNumber: 1,
      sessionNumber: 8,
    );
    final second = factory.fromUiDraft(
      DateTime(2026, 10, 7),
      const {},
      completed: true,
      seasonNumber: 1,
      sessionNumber: 9,
    );

    expect(first.entryId, 'JL-LD-LOCAL-20261007-S001-N08');
    expect(second.entryId, 'JL-LD-LOCAL-20261007-S001-N09');
    expect(first.entryId, isNot(second.entryId));
  });
}
