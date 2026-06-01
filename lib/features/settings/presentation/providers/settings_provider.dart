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
    return p.join(docDir.path, 'meridian_vaults');
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
final fontFamilyProvider =
    AsyncNotifierProvider<FontFamilyNotifier, String>(FontFamilyNotifier.new);

class FontFamilyNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fontFamily') ?? 'Inter (Sans)';
  }

  Future<void> setFontFamily(String family) async {
    state = AsyncData(family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
  }
}

// ─── Font Size Provider ──────────────────────────────────────────────────────
final fontSizeProvider =
    AsyncNotifierProvider<FontSizeNotifier, String>(FontSizeNotifier.new);

class FontSizeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fontSize') ?? '16pt';
  }

  Future<void> setFontSize(String size) async {
    state = AsyncData(size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', size);
  }
}

// ─── Line Width Provider ─────────────────────────────────────────────────────
final lineWidthProvider =
    AsyncNotifierProvider<LineWidthNotifier, String>(LineWidthNotifier.new);

class LineWidthNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lineWidth') ?? 'Comfortable';
  }

  Future<void> setLineWidth(String width) async {
    state = AsyncData(width);
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hapticsEnabled') ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticsEnabled', enabled);
  }
}
