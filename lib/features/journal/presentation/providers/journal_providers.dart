import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../../data/journal_repository.dart';

part 'journal_providers.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  final DateTime? _initialDate;
  SelectedDay([this._initialDate]);

  @override
  DateTime build() => _initialDate ?? DateTime.now();

  void setDate(DateTime date) => state = date;

  @override
  DateTime get state => super.state;

  @override
  set state(DateTime value) => super.state = value;
}

@riverpod
class FocusedDay extends _$FocusedDay {
  final DateTime? _initialDate;
  FocusedDay([this._initialDate]);

  @override
  DateTime build() => _initialDate ?? DateTime.now();

  void setDate(DateTime date) => state = date;

  @override
  DateTime get state => super.state;

  @override
  set state(DateTime value) => super.state = value;
}

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
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1, checkDate.hour, checkDate.minute, checkDate.second);
    checkStr = formatDailyDate(checkDate);
  }

  while (dates.contains(checkStr)) {
    streak++;
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1, checkDate.hour, checkDate.minute, checkDate.second);
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
