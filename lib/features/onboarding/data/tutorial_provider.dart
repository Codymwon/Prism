import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

part 'tutorial_provider.g.dart';

@riverpod
class TutorialState extends _$TutorialState {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasCompletedTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedTutorial', false);
    state = false;
  }
}

@riverpod
class EditorTutorialState extends _$EditorTutorialState {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasCompletedEditorTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedEditorTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedEditorTutorial', false);
    state = false;
  }
}

@riverpod
class JournalTutorialState extends _$JournalTutorialState {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasCompletedJournalTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedJournalTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasCompletedJournalTutorial', false);
    state = false;
  }
}

