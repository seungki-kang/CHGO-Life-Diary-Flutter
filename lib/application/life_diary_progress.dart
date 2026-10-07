import '../domain/life_diary_models.dart';

class LifeDiaryProgress {
  const LifeDiaryProgress({
    required this.seasonNumber,
    required this.sessionNumber,
  });

  final int seasonNumber;
  final int sessionNumber;
  String get label => '시즌 $seasonNumber · $sessionNumber/50회';
}

LifeDiaryProgress resolveLifeDiaryProgress(
  Iterable<LifeDiaryEntry> entries,
  DateTime date,
) {
  var greatestAbsoluteSession = 0;
  for (final entry in entries) {
    if (entry.status == LifeDiaryEntryStatus.deleted) continue;
    final absolute = (entry.seasonNumber - 1) * 50 + entry.sessionNumber;
    if (absolute > greatestAbsoluteSession) greatestAbsoluteSession = absolute;
  }
  final next = greatestAbsoluteSession + 1;
  return LifeDiaryProgress(
    seasonNumber: ((next - 1) ~/ 50) + 1,
    sessionNumber: ((next - 1) % 50) + 1,
  );
}
