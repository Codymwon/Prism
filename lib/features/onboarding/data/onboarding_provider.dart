import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
export '../../../../core/providers/shared_preferences_provider.dart';

part 'onboarding_provider.g.dart';

@riverpod
class OnboardingState extends _$OnboardingState {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hasOnboarded') ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hasOnboarded', true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('hasOnboarded');
    state = false;
  }
}
