import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/data/note_repository.dart';
import 'settings_provider.dart';

part 'startup_actions.g.dart';

@Riverpod(keepAlive: true)
class StartupActionsEvaluated extends _$StartupActionsEvaluated {
  @override
  bool build() => false;

  @override
  bool get state => super.state;

  @override
  set state(bool value) => super.state = value;
}

Future<String?> checkAndRunStartupActions(T Function<T>(ProviderListenable<T>) read) async {
  final evaluated = read(startupActionsEvaluatedProvider);
  if (evaluated) return null;
  
  // Set evaluated to true immediately
  read(startupActionsEvaluatedProvider.notifier).state = true;

  final autoCreate = await read(autoCreateDailyNoteOnLaunchProvider.future);
  if (autoCreate) {
    final dateStr = formatDailyDate(DateTime.now());
    final repo = read(noteRepositoryProvider);
    final existingNote = await repo.getDailyNote(dateStr);
    if (existingNote == null) {
      final note = await repo.createNote(
        title: dateStr,
        isDaily: true,
        dailyDate: dateStr,
      );
      return '/editor/${note.id}?date=$dateStr&new=true';
    }
  }
  return null;
}
