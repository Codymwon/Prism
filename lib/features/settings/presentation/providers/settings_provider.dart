import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

export '../../../../core/database/vault_providers.dart';


// ─── Font Family Provider ────────────────────────────────────────────────────
class FontFamilyNotifier extends StateNotifier<String> {
  FontFamilyNotifier() : super('Inter (Sans)') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('fontFamily');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setFontFamily(String family) async {
    state = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
  }
}

final fontFamilyProvider = StateNotifierProvider<FontFamilyNotifier, String>((ref) {
  return FontFamilyNotifier();
});

// ─── Font Size Provider ──────────────────────────────────────────────────────
class FontSizeNotifier extends StateNotifier<String> {
  FontSizeNotifier() : super('16pt') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('fontSize');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setFontSize(String size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', size);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, String>((ref) {
  return FontSizeNotifier();
});

// ─── Line Width Provider ─────────────────────────────────────────────────────
class LineWidthNotifier extends StateNotifier<String> {
  LineWidthNotifier() : super('Comfortable') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('lineWidth');
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLineWidth(String width) async {
    state = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lineWidth', width);
  }
}

final lineWidthProvider = StateNotifierProvider<LineWidthNotifier, String>((ref) {
  return LineWidthNotifier();
});

// ─── Haptics Enabled Provider ────────────────────────────────────────────────
final hapticsEnabledProvider =
    AsyncNotifierProvider<HapticsEnabledNotifier, bool>(
        HapticsEnabledNotifier.new);

class HapticsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hapticsEnabled') ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dragToPinEnabled') ?? false;
  }

  Future<void> setDragToPinEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoCreateDailyNoteOnLaunch') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('startOfWeek') ?? 'Sunday';
  }

  Future<void> setStartOfWeek(String startDay) async {
    state = AsyncData(startDay);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lineNumbersGutter') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoPairBrackets') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showBacklinks') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('analyticsEnabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analyticsEnabled', enabled);
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Error toggling Firebase collections: $e');
    }
  }
}




