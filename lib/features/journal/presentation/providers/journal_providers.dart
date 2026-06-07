import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../../data/journal_repository.dart';

final allDailyDatesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);
  
  final repo = ref.watch(journalRepositoryProvider);
  return repo.getAllDailyDates();
});

({int streak, int totalCount}) computeStreak(Set<String> dates, [DateTime? referenceDate]) {
  if (dates.isEmpty) {
    return (streak: 0, totalCount: 0);
  }

  int streak = 0;
  DateTime checkDate = referenceDate ?? DateTime.now();
  String checkStr = formatDailyDate(checkDate);

  if (!dates.contains(checkStr)) {
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = formatDailyDate(checkDate);
  }

  while (dates.contains(checkStr)) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
    checkStr = formatDailyDate(checkDate);
  }

  return (streak: streak, totalCount: dates.length);
}

final journalStreakProvider = FutureProvider.autoDispose<({int streak, int totalCount})>((ref) async {
  final datesSet = await ref.watch(allDailyDatesProvider.future);
  return computeStreak(datesSet);
});

final dailyNoteProvider = FutureProvider.autoDispose.family<({Note note, String content})?, String>((ref, dateStr) async {
  await ref.watch(databaseProvider.future);
  ref.watch(notesVersionProvider);

  final repo = ref.watch(noteRepositoryProvider);
  final note = await repo.getDailyNote(dateStr);
  if (note == null) return null;

  String content = '';
  try {
    content = await repo.readNoteContent(note.id);
  } catch (_) {}

  return (note: note, content: content);
});
