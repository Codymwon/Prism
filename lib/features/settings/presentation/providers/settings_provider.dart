import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ─── Base Vaults Directory Provider ──────────────────────────────────────────
// Uses AsyncNotifier so consumers can await the initial SharedPreferences load
// instead of receiving an empty string during the async gap.
final baseVaultsDirectoryProvider =
    AsyncNotifierProvider<BaseVaultsDirectoryNotifier, String>(
        BaseVaultsDirectoryNotifier.new);

class BaseVaultsDirectoryNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('baseVaultsDirectory');
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final docDir = await getApplicationDocumentsDirectory();
    return p.join(docDir.path, 'prism_vaults');
  }

  Future<void> setDirectory(String path) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseVaultsDirectory', path);
    state = AsyncData(path);
  }
}

// ─── Active Vault Name Provider ──────────────────────────────────────────────
final activeVaultNameProvider =
    AsyncNotifierProvider<ActiveVaultNameNotifier, String>(
        ActiveVaultNameNotifier.new);

class ActiveVaultNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeVaultName') ?? 'My Vault';
  }

  Future<void> setVaultName(String name) async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeVaultName', name);
    state = AsyncData(name);
  }
}

// ─── Active Vault Path Provider (Derived) ────────────────────────────────────
// FutureProvider that waits for both async notifiers before computing the path.
final activeVaultPathProvider = FutureProvider<String>((ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  if (baseDir.isEmpty) return '';
  return p.join(baseDir, activeVault);
});

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

