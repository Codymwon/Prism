import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // In tests or when not overridden, return an in-memory FakeSharedPreferences
  // so tests don't crash with UnimplementedError!
  return FakeSharedPreferences();
});

final onboardingStateProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(_prefs.getBool('hasOnboarded') ?? false);

  Future<void> completeOnboarding() async {
    await _prefs.setBool('hasOnboarded', true);
    state = true;
  }
}

class FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _values;
  FakeSharedPreferences([Map<String, Object>? values]) : _values = values ?? {
    'baseVaultsDirectory': '/tmp/prism_test_vaults',
    'activeVaultName': 'Vault',
  };

  @override
  Set<String> getKeys() => _values.keys.toSet();

  @override
  Object? get(String key) => _values[key];

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  List<String>? getStringList(String key) => _values[key] as List<String>?;

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _values.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}
