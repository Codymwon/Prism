import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_provider.dart';

final tutorialStateProvider = StateNotifierProvider<TutorialNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialNotifier(prefs);
});

class TutorialNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  TutorialNotifier([this._prefs]) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    state = prefs.getBool('hasCompletedTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedTutorial', false);
    state = false;
  }
}

final editorTutorialStateProvider = StateNotifierProvider<EditorTutorialNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return EditorTutorialNotifier(prefs);
});

class EditorTutorialNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  EditorTutorialNotifier([this._prefs]) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    state = prefs.getBool('hasCompletedEditorTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedEditorTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedEditorTutorial', false);
    state = false;
  }
}

final journalTutorialStateProvider = StateNotifierProvider<JournalTutorialNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return JournalTutorialNotifier(prefs);
});

class JournalTutorialNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  JournalTutorialNotifier([this._prefs]) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    state = prefs.getBool('hasCompletedJournalTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJournalTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedJournalTutorial', false);
    state = false;
  }
}
