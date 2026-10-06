import '../domain/life_diary_models.dart';

class LifeDiaryProgress {
  const LifeDiaryProgress({
    required this.seasonNumber,
    required this.sessionNumber,
    this.existingEntry,
  });

  final int seasonNumber;
  final int sessionNumber;
  final LifeDiaryEntry? existingEntry;

  String get label => '시즌 $seasonNumber · $sessionNumber/50회';
}

LifeDiaryProgress resolveLifeDiaryProgress(
  Iterable<LifeDiaryEntry> entries,
  DateTime date,
) {
  final normalized = DateTime(date.year, date.month, date.day);
  for (final entry in entries) {
    final entryDate = entry.entryDate;
    if (entryDate.year == normalized.year &&
        entryDate.month == normalized.month &&
        entryDate.day == normalized.day) {
      return LifeDiaryProgress(
        seasonNumber: entry.seasonNumber,
        sessionNumber: entry.sessionNumber,
        existingEntry: entry,
      );
    }
  }

  var greatestAbsoluteSession = 0;
  for (final entry in entries) {
    final absolute = (entry.seasonNumber - 1) * 50 + entry.sessionNumber;
    if (absolute > greatestAbsoluteSession) greatestAbsoluteSession = absolute;
  }
  final next = greatestAbsoluteSession + 1;
  return LifeDiaryProgress(
    seasonNumber: ((next - 1) ~/ 50) + 1,
    sessionNumber: ((next - 1) % 50) + 1,
  );
}
