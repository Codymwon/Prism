import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as p;
import '../database/vault_providers.dart';
import 'two_way_sync_service.dart';
import 'analytics_service.dart';
import '../providers/shared_preferences_provider.dart';
import '../database/database_helper.dart';

part 'vault_service.g.dart';

@riverpod
VaultManagementService vaultManagementService(VaultManagementServiceRef ref) {
  return VaultManagementService(ref);
}

final availableVaultsProvider = FutureProvider<List<String>>((ref) async {
  final baseDir = await ref.watch(baseVaultsDirectoryProvider.future);
  final activeVault = await ref.watch(activeVaultNameProvider.future);
  return ref.read(vaultManagementServiceProvider).getAvailableVaults(baseDir, activeVault);
});

class VaultManagementService {
  final Ref ref;
  VaultManagementService(this.ref);

  /// Closes the active vault's database.
  Future<void> closeDatabase() => DatabaseHelper.instance.closeDatabase();

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
  }) async {
    // 1. Set new active vault name provider (saves to SharedPreferences)
    await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);
    AnalyticsService.logEvent('switch_vault');

    // 2. Invalidate vaults list cache
    ref.invalidate(availableVaultsProvider);

    // 3. If sync is enabled for this vault, trigger auto-sync in the background
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
    AnalyticsService.logEvent('create_vault');

    // Invalidate vaults list cache
    ref.invalidate(availableVaultsProvider);
  }

  /// Renames a physical vault directory and updates providers/databases
  Future<void> renameVault({
    required String oldName,
    required String newName,
    required String baseDir,
  }) async {
    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(newName)) {
      throw ArgumentError('Invalid vault name: only letters, numbers, spaces, hyphens, and underscores are allowed.');
    }

    final oldPath = p.join(baseDir, oldName);
    final newPath = p.join(baseDir, newName);

    if (Directory(newPath).existsSync()) {
      throw ArgumentError('A vault named "$newName" already exists.');
    }

    // Rename the directory
    await Directory(oldPath).rename(newPath);

    // If the renamed vault was the active vault, update the active name
    final activeVault = ref.read(activeVaultNameProvider).valueOrNull ?? '';
    if (activeVault == oldName) {
      await ref.read(activeVaultNameProvider.notifier).setVaultName(newName);
    }

    // Invalidate available vaults list
    ref.invalidate(availableVaultsProvider);
  }

  /// Deletes a physical vault directory
  Future<void> deleteVault({
    required String vaultName,
    required String baseDir,
  }) async {
    final path = p.join(baseDir, vaultName);
    final dir = Directory(path);

    if (await dir.exists()) {
      // Reconnect/close db if active vault is deleted
      final activeVault = ref.read(activeVaultNameProvider).valueOrNull ?? '';
      if (activeVault == vaultName) {
        // Find another vault to switch to
        final allVaults = ref.read(availableVaultsProvider).valueOrNull ?? [];
        final remainingVaults = allVaults.where((v) => v != vaultName).toList();
        if (remainingVaults.isEmpty) {
          throw StateError('Cannot delete the last remaining vault.');
        }
        // Switch to the first remaining vault
        await switchVault(vaultName: remainingVaults.first);
      }

      await dir.delete(recursive: true);
    }

    // Invalidate available vaults list
    ref.invalidate(availableVaultsProvider);
  }

  /// Safely relocates base vaults directory path and loads/creates active vaults inside asynchronously
  Future<void> changeBaseDirectory({
    required String newPath,
  }) async {
    await changeStorageLocation(
      newPath: newPath,
      vaultType: 'custom',
      migrateData: false,
    );
  }

  /// Safely changes storage location path, vault type, and handles optional directory migration
  Future<void> changeStorageLocation({
    required String newPath,
    required String vaultType,
    required bool migrateData,
  }) async {
    // Determine the current hub name (defaults to 'Prism Hub' if transitioning from sandbox or empty)
    final currentBaseDir = await ref.read(baseVaultsDirectoryProvider.future);
    final String hubName;
    if (currentBaseDir.isEmpty || currentBaseDir.contains('prism_vaults')) {
      hubName = 'Prism Hub';
    } else {
      hubName = p.basename(currentBaseDir);
    }

    // Align the target path (append hubName if not already the last segment, and not in sandbox)
    final String targetBaseDir;
    if (vaultType == 'sandbox') {
      targetBaseDir = newPath;
    } else {
      if (p.basename(newPath) == hubName) {
        targetBaseDir = newPath;
      } else {
        targetBaseDir = p.join(newPath, hubName);
      }
    }

    // Perform directory migration if requested, and the current base directory is different
    if (migrateData && currentBaseDir.isNotEmpty && currentBaseDir != targetBaseDir) {
      final currentDir = Directory(currentBaseDir);
      if (await currentDir.exists()) {
        try {
          await _migrateDirectory(currentBaseDir, targetBaseDir);
        } catch (e, stack) {
          debugPrint('Error migrating directories: $e');
          AnalyticsService.logError(e, stack, fatal: false);
          // Rollback: delete target base directory to clean up partially copied files
          try {
            final targetDir = Directory(targetBaseDir);
            if (await targetDir.exists()) {
              await targetDir.delete(recursive: true);
            }
          } catch (_) {
            // Ignore cleanup failures
          }
          rethrow;
        }
      }
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

    // Update SharedPreferences directly to ensure atomicity
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('baseVaultsDirectory', targetBaseDir);
    await prefs.setString('vaultType', vaultType);
    await prefs.setString('activeVaultName', activeVault);

    // Invalidate and reload the providers.
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
          if (dbTime.isAfter(subDirLatest)) {
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

  Future<void> _migrateDirectory(String sourcePath, String destinationPath) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) return;

    await Directory(destinationPath).create(recursive: true);

    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: sourcePath);
      final destPath = p.join(destinationPath, relativePath);

      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        // Ensure target parent directory exists
        await Directory(p.dirname(destPath)).create(recursive: true);
        
        // Copy file (merging/overwriting duplicates natively)
        await entity.copy(destPath);
      }
    }
  }
}
