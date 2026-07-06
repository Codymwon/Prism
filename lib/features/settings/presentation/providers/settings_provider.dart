import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../../../onboarding/data/onboarding_provider.dart';

export '../../../../core/database/vault_providers.dart';

// ─── Font Family Provider ────────────────────────────────────────────────────
class FontFamilyNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  FontFamilyNotifier(this._prefs) : super('Inter (Sans)') {
    _load();
  }

  void _load() {
    final saved = _prefs.getString('fontFamily');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setFontFamily(String family) async {
    state = family;
    await _prefs.setString('fontFamily', family);
  }
}

final fontFamilyProvider = StateNotifierProvider<FontFamilyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FontFamilyNotifier(prefs);
});

// ─── Font Size Provider ──────────────────────────────────────────────────────
class FontSizeNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  FontSizeNotifier(this._prefs) : super('16pt') {
    _load();
  }

  void _load() {
    final saved = _prefs.getString('fontSize');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setFontSize(String size) async {
    state = size;
    await _prefs.setString('fontSize', size);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FontSizeNotifier(prefs);
});

// ─── Line Width Provider ─────────────────────────────────────────────────────
class LineWidthNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  LineWidthNotifier(this._prefs) : super('Comfortable') {
    _load();
  }

  void _load() {
    final saved = _prefs.getString('lineWidth');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLineWidth(String width) async {
    state = width;
    await _prefs.setString('lineWidth', width);
  }
}

final lineWidthProvider = StateNotifierProvider<LineWidthNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LineWidthNotifier(prefs);
});

// ─── Haptics Enabled Provider ────────────────────────────────────────────────
final hapticsEnabledProvider =
    AsyncNotifierProvider<HapticsEnabledNotifier, bool>(
        HapticsEnabledNotifier.new);

class HapticsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('hapticsEnabled') ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('hapticsEnabled', enabled);
  }
}

// ─── Drag to Pin Enabled Provider ──────────────────────────────────────────
final dragToPinEnabledProvider =
    AsyncNotifierProvider<DragToPinEnabledNotifier, bool>(
        DragToPinEnabledNotifier.new);

class DragToPinEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('dragToPinEnabled') ?? false;
  }

  Future<void> setDragToPinEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('dragToPinEnabled', enabled);
  }
}

// ─── Auto-create Daily Note on Launch Provider ─────────────────────────────
final autoCreateDailyNoteOnLaunchProvider =
    AsyncNotifierProvider<AutoCreateDailyNoteOnLaunchNotifier, bool>(
        AutoCreateDailyNoteOnLaunchNotifier.new);

class AutoCreateDailyNoteOnLaunchNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('autoCreateDailyNoteOnLaunch') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('autoCreateDailyNoteOnLaunch', enabled);
  }
}

// ─── Start of Week Provider ────────────────────────────────────────────────
final startOfWeekProvider =
    AsyncNotifierProvider<StartOfWeekNotifier, String>(
        StartOfWeekNotifier.new);

class StartOfWeekNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('startOfWeek') ?? 'Sunday';
  }

  Future<void> setStartOfWeek(String startDay) async {
    state = AsyncData(startDay);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('startOfWeek', startDay);
  }
}

// ─── Line Numbers Gutter Provider ──────────────────────────────────────────
final lineNumbersGutterProvider =
    AsyncNotifierProvider<LineNumbersGutterNotifier, bool>(
        LineNumbersGutterNotifier.new);

class LineNumbersGutterNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('lineNumbersGutter') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('lineNumbersGutter', enabled);
  }
}

// ─── Auto-pair Brackets Provider ───────────────────────────────────────────
final autoPairBracketsProvider =
    AsyncNotifierProvider<AutoPairBracketsNotifier, bool>(
        AutoPairBracketsNotifier.new);

class AutoPairBracketsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('autoPairBrackets') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('autoPairBrackets', enabled);
  }
}

// ─── Show Backlinks Provider ────────────────────────────────────────────────
final showBacklinksDefaultProvider =
    AsyncNotifierProvider<ShowBacklinksDefaultNotifier, bool>(
        ShowBacklinksDefaultNotifier.new);

class ShowBacklinksDefaultNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('showBacklinks') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('showBacklinks', enabled);
  }
}

// ─── Analytics Enabled Provider ──────────────────────────────────────────────
final analyticsEnabledProvider =
    AsyncNotifierProvider<AnalyticsEnabledNotifier, bool>(
        AnalyticsEnabledNotifier.new);

class AnalyticsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('analyticsEnabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('analyticsEnabled', enabled);
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Error toggling Firebase collections: $e');
    }
  }
}
