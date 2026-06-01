import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ─── Base Vaults Directory Provider ──────────────────────────────────────────
final baseVaultsDirectoryProvider = StateNotifierProvider<BaseVaultsDirectoryNotifier, String>((ref) {
  return BaseVaultsDirectoryNotifier();
});

class BaseVaultsDirectoryNotifier extends StateNotifier<String> {
  BaseVaultsDirectoryNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('baseVaultsDirectory');
    if (saved != null && saved.isNotEmpty) {
      state = saved;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      state = p.join(docDir.path, 'meridian_vaults');
    }
  }

  Future<void> setDirectory(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseVaultsDirectory', path);
  }
}

// ─── Active Vault Name Provider ──────────────────────────────────────────────
final activeVaultNameProvider = StateNotifierProvider<ActiveVaultNameNotifier, String>((ref) {
  return ActiveVaultNameNotifier();
});

class ActiveVaultNameNotifier extends StateNotifier<String> {
  ActiveVaultNameNotifier() : super('My Vault') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('activeVaultName') ?? 'My Vault';
  }

  Future<void> setVaultName(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activeVaultName', name);
  }
}

// ─── Active Vault Path Provider (Derived) ──────────────────────────────────
final activeVaultPathProvider = Provider<String>((ref) {
  final baseDir = ref.watch(baseVaultsDirectoryProvider);
  final activeVault = ref.watch(activeVaultNameProvider);
  if (baseDir.isEmpty) return '';
  return p.join(baseDir, activeVault);
});

// ─── Font Family Provider ────────────────────────────────────────────────────
final fontFamilyProvider = StateNotifierProvider<FontFamilyNotifier, String>((ref) {
  return FontFamilyNotifier();
});

class FontFamilyNotifier extends StateNotifier<String> {
  FontFamilyNotifier() : super('Inter (Sans)') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('fontFamily') ?? 'Inter (Sans)';
  }

  Future<void> setFontFamily(String family) async {
    state = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
  }
}

// ─── Font Size Provider ──────────────────────────────────────────────────────
final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, String>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<String> {
  FontSizeNotifier() : super('16pt') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('fontSize') ?? '16pt';
  }

  Future<void> setFontSize(String size) async {
    state = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', size);
  }
}

// ─── Line Width Provider ─────────────────────────────────────────────────────
final lineWidthProvider = StateNotifierProvider<LineWidthNotifier, String>((ref) {
  return LineWidthNotifier();
});

class LineWidthNotifier extends StateNotifier<String> {
  LineWidthNotifier() : super('Comfortable') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('lineWidth') ?? 'Comfortable';
  }

  Future<void> setLineWidth(String width) async {
    state = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lineWidth', width);
  }
}

// ─── Haptics Enabled Provider ────────────────────────────────────────────────
final hapticsEnabledProvider = StateNotifierProvider<HapticsEnabledNotifier, bool>((ref) {
  return HapticsEnabledNotifier();
});

class HapticsEnabledNotifier extends StateNotifier<bool> {
  HapticsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('hapticsEnabled') ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticsEnabled', enabled);
  }
}

