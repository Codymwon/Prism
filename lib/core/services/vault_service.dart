import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

final availableVaultsProvider = FutureProvider<List<String>>((ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  return ref.read(vaultServiceProvider).getAvailableVaults(baseDir, activeVault);
});

class VaultService {
  /// Scans subdirectories in base directory to list available vaults asynchronously
  Future<List<String>> getAvailableVaults(String baseDir, String activeVault) async {
    List<String> vaults = [];
    try {
      final dir = Directory(baseDir);
      if (await dir.exists()) {
        final list = await dir.list().toList();
        vaults = list
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .where((name) => !name.startsWith('.'))
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading vaults: $e');
    }

    if (vaults.isEmpty) {
      vaults.add(activeVault);
    }
    
    vaults.sort();
    return vaults;
  }

  /// Switches active vault name and reconnects SQLite instance
  Future<void> switchVault({
    required String vaultName,
    required WidgetRef ref,
  }) async {
    // 1. Set new active vault name provider (saves to SharedPreferences)
    await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);

    // 2. Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;

    // 3. Invalidate vaults list cache
    ref.invalidate(availableVaultsProvider);
  }

  /// Creates a physical directory for a vault and initializes it with a welcome note asynchronously
  Future<void> createVault({
    required String vaultName,
    required String baseDir,
    required WidgetRef ref,
  }) async {
    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(vaultName)) {
      throw ArgumentError('Invalid vault name: only letters, numbers, spaces, hyphens, and underscores are allowed.');
    }
    final newVaultPath = p.join(baseDir, vaultName);
    final dir = Directory(newVaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Set new active vault (saves to SharedPreferences)
    await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);

    // Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;

    // Invalidate vaults list cache
    ref.invalidate(availableVaultsProvider);
  }

  /// Safely relocates base vaults directory path and loads/creates active vaults inside asynchronously
  Future<void> changeBaseDirectory({
    required String newPath,
    required WidgetRef ref,
  }) async {
    // Update base vaults directory provider (saves to SharedPreferences)
    await ref.read(baseVaultsDirectoryProvider.notifier).setDirectory(newPath);

    // Find if there are existing vaults asynchronously
    final dir = Directory(newPath);
    List<String> vaults = [];
    if (await dir.exists()) {
      final list = await dir.list().toList();
      vaults = list
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .where((name) => !name.startsWith('.'))
          .toList();
    }

    String activeVault = 'My Vault';
    if (vaults.isNotEmpty) {
      activeVault = vaults.first;
    } else {
      // Create a default vault folder inside the new directory asynchronously
      final newVaultPath = p.join(newPath, activeVault);
      final vaultDir = Directory(newVaultPath);
      if (!await vaultDir.exists()) await vaultDir.create(recursive: true);
    }

    // Update active vault name provider
    await ref.read(activeVaultNameProvider.notifier).setVaultName(activeVault);

    // Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;

    // Invalidate vaults list cache
    ref.invalidate(availableVaultsProvider);
  }
}
