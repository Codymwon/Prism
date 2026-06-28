import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../database/vault_providers.dart';
import 'two_way_sync_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

final vaultManagementServiceProvider = Provider<VaultManagementService>((ref) {
  return VaultManagementService();
});

final availableVaultsProvider = FutureProvider<List<String>>((ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  return ref.read(vaultManagementServiceProvider).getAvailableVaults(baseDir, activeVault);
});

class VaultManagementService {
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

    // 4. If sync is enabled for this vault, trigger auto-sync in the background
    try {
      final syncedVaults = await ref.read(syncedVaultsProvider.future);
      if (syncedVaults.contains(vaultName)) {
        ref.read(twoWaySyncServiceProvider).runSync().then((result) {
          result.fold(
            (fail) => debugPrint('Auto-sync failed on vault switch: ${fail.message}'),
            (res) => debugPrint('Auto-sync succeeded on vault switch: ${res.uploaded} uploaded, ${res.downloaded} downloaded'),
          );
        });
      }
    } catch (e) {
      debugPrint('Failed to trigger auto-sync on vault switch: $e');
    }
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
    // Determine the current hub name (defaults to 'Prism Hub' if not found or empty)
    final currentBaseDir = ref.read(baseVaultsDirectoryProvider).valueOrNull ?? '';
    final hubName = currentBaseDir.isNotEmpty ? p.basename(currentBaseDir) : 'Prism Hub';

    // Align the target path (append hubName if not already the last segment)
    final String targetBaseDir;
    if (p.basename(newPath) == hubName) {
      targetBaseDir = newPath;
    } else {
      targetBaseDir = p.join(newPath, hubName);
    }

    // Ensure the target base directory exists
    final dir = Directory(targetBaseDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Find the most recently modified vault if any exist, or create a default one
    final activeVault = await _findMostRecentVault(targetBaseDir) ?? 'My Vault';

    if (activeVault == 'My Vault') {
      final newVaultPath = p.join(targetBaseDir, activeVault);
      final vaultDir = Directory(newVaultPath);
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
    }

    // Update SharedPreferences directly for both values to ensure atomicity
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseVaultsDirectory', targetBaseDir);
    await prefs.setString('activeVaultName', activeVault);

    // Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;

    // Invalidate and reload the providers.
    // Invalidating both simultaneously ensures they reload from SharedPreferences
    // without an intermediate inconsistent state (preventing database_closed race).
    ref.invalidate(baseVaultsDirectoryProvider);
    ref.invalidate(activeVaultNameProvider);
    ref.invalidate(availableVaultsProvider);
  }

  /// Private helper to find the most recently modified vault based on file/db timestamps
  Future<String?> _findMostRecentVault(String baseDir) async {
    final dir = Directory(baseDir);
    if (!await dir.exists()) return null;

    List<Directory> subDirs = [];
    try {
      final list = await dir.list().toList();
      for (final entity in list) {
        if (entity is Directory && !p.basename(entity.path).startsWith('.')) {
          subDirs.add(entity);
        }
      }
    } catch (e) {
      debugPrint('Error scanning existing hub: $e');
    }

    if (subDirs.isEmpty) return null;

    Directory? mostRecentDir;
    DateTime? latestTime;
    for (final subDir in subDirs) {
      DateTime? subDirLatest;
      try {
        final stat = await subDir.stat();
        subDirLatest = stat.modified;
        final dbFile = File(p.join(subDir.path, '.prism.db'));
        if (await dbFile.exists()) {
          final dbTime = await dbFile.lastModified();
          if (subDirLatest != null && dbTime.isAfter(subDirLatest)) {
            subDirLatest = dbTime;
          }
        }
      } catch (e) {
        // Ignore
      }
      if (subDirLatest != null) {
        if (latestTime == null || subDirLatest.isAfter(latestTime)) {
          latestTime = subDirLatest;
          mostRecentDir = subDir;
        }
      }
    }

    return mostRecentDir != null
        ? p.basename(mostRecentDir.path)
        : p.basename(subDirs.first.path);
  }
}
