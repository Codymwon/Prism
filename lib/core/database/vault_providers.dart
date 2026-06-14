import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'vault_providers.g.dart';

// ─── Base Vaults Directory Provider ──────────────────────────────────────────
// Uses AsyncNotifier so consumers can await the initial SharedPreferences load
// instead of receiving an empty string during the async gap.
@riverpod
class BaseVaultsDirectory extends _$BaseVaultsDirectory {
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
@riverpod
class ActiveVaultName extends _$ActiveVaultName {
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
@riverpod
Future<String> activeVaultPath(ActiveVaultPathRef ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  if (baseDir.isEmpty) return '';
  return p.join(baseDir, activeVault);
}

