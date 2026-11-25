import 'package:chgo_life_diary/main_backup_rehearsal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline withdrawal clears queue and rejects delayed upload', (
    tester,
  ) async {
    await tester.pumpWidget(const BackupRehearsalApp());

    Future<void> tap(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await tap('테스트 백업 동의');
    await tap('온라인');
    await tap('테스트 기록 업로드');
    expect(find.text('업로드 대기 1건'), findsOneWidget);

    await tap('백업 동의 철회');
    expect(find.text('업로드 대기 0건'), findsOneWidget);
    expect(find.text('철회 전송 대기'), findsOneWidget);

    await tap('온라인');
    expect(find.text('철회 전송 완료'), findsOneWidget);
    expect(find.text('철회 전송 대기'), findsNothing);
    await tap('이전 요청 재전송 검증');
    expect(find.text('이전 요청 거부'), findsOneWidget);
    expect(find.text('서버 백업 0건'), findsOneWidget);

    await tap('테스트 백업 동의');
    await tap('이전 요청 재전송 검증');
    expect(find.text('이전 요청 거부'), findsOneWidget);
    expect(find.text('서버 백업 0건'), findsOneWidget);
    await tap('테스트 기록 업로드');
    expect(find.text('서버 백업 1건'), findsOneWidget);
  });
}
