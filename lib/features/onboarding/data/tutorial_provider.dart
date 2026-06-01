import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final tutorialStateProvider = StateNotifierProvider<TutorialNotifier, bool>((ref) {
  return TutorialNotifier();
});

class TutorialNotifier extends StateNotifier<bool> {
  TutorialNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false (tutorial not completed) on first use
    state = prefs.getBool('hasCompletedTutorial') ?? false;
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedTutorial', true);
    state = true;
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedTutorial', false);
    state = false;
  }
}
