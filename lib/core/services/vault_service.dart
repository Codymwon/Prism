import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../features/notes/data/note_repository.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

class VaultService {
  /// Scans subdirectories in base directory to list available vaults
  List<String> getAvailableVaults(String baseDir, String activeVault) {
    List<String> vaults = [];
    try {
      final dir = Directory(baseDir);
      if (dir.existsSync()) {
        vaults = dir.listSync()
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
  }

  /// Creates a physical directory for a vault and initializes it with a welcome note
  Future<void> createVault({
    required String vaultName,
    required String baseDir,
    required WidgetRef ref,
  }) async {
    final newVaultPath = p.join(baseDir, vaultName);
    final dir = Directory(newVaultPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Set new active vault (saves to SharedPreferences)
    await ref.read(activeVaultNameProvider.notifier).setVaultName(vaultName);

    // Initialize with a welcome note inside the repository
    final repo = ref.read(noteRepositoryProvider);
    await repo.createNote(
      title: 'Welcome to your new Vault',
      initialContent: '# Welcome to $vaultName\n\nThis is a brand new workspace. Start linking notes using `[[wikilinks]]`!',
    );

    // Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;
  }

  /// Safely relocates base vaults directory path and loads/creates active vaults inside
  Future<void> changeBaseDirectory({
    required String newPath,
    required WidgetRef ref,
  }) async {
    // Update base vaults directory provider (saves to SharedPreferences)
    await ref.read(baseVaultsDirectoryProvider.notifier).setDirectory(newPath);

    // Find if there are existing vaults
    final dir = Directory(newPath);
    List<String> vaults = [];
    if (dir.existsSync()) {
      vaults = dir.listSync()
          .whereType<Directory>()
          .map((d) => p.basename(d.path))
          .where((name) => !name.startsWith('.'))
          .toList();
    }

    String activeVault = 'My Vault';
    if (vaults.isNotEmpty) {
      activeVault = vaults.first;
    } else {
      // Create a default vault folder inside the new directory
      final newVaultPath = p.join(newPath, activeVault);
      final vaultDir = Directory(newVaultPath);
      if (!vaultDir.existsSync()) vaultDir.createSync(recursive: true);

      // Initialize starter notes inside it
      final welcomeFile = File(p.join(newVaultPath, 'welcome.md'));
      await welcomeFile.writeAsString('# Welcome to Meridian\n\nNotes configured at new location.');
    }

    // Update active vault name provider
    await ref.read(activeVaultNameProvider.notifier).setVaultName(activeVault);

    // Reset selected folder filter
    ref.read(selectedFolderIdProvider.notifier).state = null;
  }
}
