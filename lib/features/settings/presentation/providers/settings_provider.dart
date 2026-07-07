import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/shared_preferences_provider.dart';

export '../../../../core/database/vault_providers.dart';

part 'settings_provider.g.dart';

// ─── Font Family Provider ────────────────────────────────────────────────────
@riverpod
class FontFamily extends _$FontFamily {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('fontFamily') ?? 'Inter (Sans)';
  }

  Future<void> setFontFamily(String family) async {
    state = family;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('fontFamily', family);
  }
}

// ─── Font Size Provider ──────────────────────────────────────────────────────
@riverpod
class FontSize extends _$FontSize {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('fontSize') ?? '16pt';
  }

  Future<void> setFontSize(String size) async {
    state = size;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('fontSize', size);
  }
}

// ─── Line Width Provider ─────────────────────────────────────────────────────
@riverpod
class LineWidth extends _$LineWidth {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('lineWidth') ?? 'Comfortable';
  }

  Future<void> setLineWidth(String width) async {
    state = width;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('lineWidth', width);
  }
}

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
