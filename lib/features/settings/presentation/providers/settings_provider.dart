import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ─── Keep Voice Recordings Provider ──────────────────────────────────────────
final keepVoiceRecordingsProvider =
    AsyncNotifierProvider<KeepVoiceRecordingsNotifier, bool>(
        KeepVoiceRecordingsNotifier.new);

class KeepVoiceRecordingsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('keepVoiceRecordings') ?? false;
  }

  Future<void> setKeepVoiceRecordings(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepVoiceRecordings', enabled);
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


