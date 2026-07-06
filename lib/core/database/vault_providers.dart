import 'dart:convert';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/onboarding/data/onboarding_provider.dart';

part 'vault_providers.g.dart';

// ─── Base Vaults Directory Provider ──────────────────────────────────────────
// Uses AsyncNotifier so consumers can await the initial SharedPreferences load
// instead of receiving an empty string during the async gap.
@riverpod
class BaseVaultsDirectory extends _$BaseVaultsDirectory {
  @override
  Future<String> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString('baseVaultsDirectory');
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    final docDir = await getApplicationDocumentsDirectory();
    return p.join(docDir.path, 'prism_vaults');
  }

  Future<void> setDirectory(String path) async {
    state = const AsyncLoading();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('baseVaultsDirectory', path);
    state = AsyncData(path);
  }
}

// ─── Active Vault Name Provider ──────────────────────────────────────────────
@riverpod
class ActiveVaultName extends _$ActiveVaultName {
  @override
  Future<String> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('activeVaultName') ?? 'My Vault';
  }

  Future<void> setVaultName(String name) async {
    state = const AsyncLoading();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('activeVaultName', name);
    state = AsyncData(name);
  }
}

// ─── Active Vault Path Provider (Derived) ────────────────────────────────────
// FutureProvider that waits for both async notifiers before computing the path.
@riverpod
Future<String> activeVaultPath(ActiveVaultPathRef ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  if (baseDir.isEmpty) return '';
  return p.join(baseDir, activeVault);
}

// ─── Synced Vaults Provider ──────────────────────────────────────────────────
@riverpod
class SyncedVaults extends _$SyncedVaults {
  @override
  Future<List<String>> build() async {
    final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
    if (baseDir.isEmpty) return [];
    
    final configFile = File(p.join(baseDir, '.prism', 'sync_config.json'));
    if (!await configFile.exists()) return [];
    
    try {
      final content = await configFile.readAsString();
      final data = jsonDecode(content);
      if (data is Map && data['syncedVaults'] is List) {
        return List<String>.from(data['syncedVaults'] as List);
      }
    } catch (_) {}
    return [];
  }

  Future<void> enableSync(String vaultName) async {
    final current = await future;
    if (current.contains(vaultName)) return;
    
    final updated = [...current, vaultName];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> disableSync(String vaultName) async {
    final current = await future;
    if (!current.contains(vaultName)) return;
    
    final updated = current.where((name) => name != vaultName).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> _save(List<String> vaults) async {
    final baseDir = await ref.read(baseVaultsDirectoryProvider.future);
    if (baseDir.isEmpty) return;
    
    final configDir = Directory(p.join(baseDir, '.prism'));
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    
    final configFile = File(p.join(configDir.path, 'sync_config.json'));
    final payload = {
      'version': 1,
      'syncedVaults': vaults,
    };
    
    // Atomic write
    final tempFile = File('${configFile.path}.tmp');
    await tempFile.writeAsString(jsonEncode(payload));
    await tempFile.rename(configFile.path);
  }
}

