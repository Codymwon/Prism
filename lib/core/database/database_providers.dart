import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'prism_metadata_store.dart';
import '../utils/utils.dart';
import 'vault_providers.dart';
import '../../features/notes/data/vault_service.dart';

// ─── Database Connection Provider (Reactive Lifecycle) ────────────────────────
// Watches activeVaultPathProvider (now a FutureProvider) so it waits for the
// vault path to be fully loaded from SharedPreferences before opening the DB.
final databaseProvider = FutureProvider<Database>((ref) async {
  // Await the full path — this suspends until baseVaultsDirectory and
  // activeVaultName are both loaded from SharedPreferences.
  final vaultPath = await ref.watch(activeVaultPathProvider.future);
  if (vaultPath.isEmpty) {
    throw Exception('Active vault path is empty');
  }

  // Ensure welcome notes are seeded if the vault is new/empty before opening
  await seedWelcomeNotes(vaultPath);

  final db = await DatabaseHelper.instance.openDatabaseForPath(vaultPath);

  // Restore app-only metadata (virtual folders, pins, spatial groups) from the
  // sync-safe sidecar before the background notes-index rebuild runs.
  await PrismMetadataStore().loadIntoDatabase(db, vaultPath);

  // Sync vault physical files in the background without blocking database loading
  _triggerBackgroundSync(db, vaultPath, ref);

  ref.onDispose(() async {
    await DatabaseHelper.instance.closeDatabaseConnection(db);
    debugPrint('Database connection reactively closed for: $vaultPath');
  });

  return db;
});

/// Helper to trigger vault file synchronization asynchronously in the background.
/// Increments notesVersionProvider upon completion to reactively refresh note listings.
void _triggerBackgroundSync(Database db, String vaultPath, Ref ref) {
  ref.read(noteIngestionServiceProvider).syncVault(vaultPath).then((_) {
    ref.read(notesVersionProvider.notifier).update((state) => state + 1);
    debugPrint('Background physical files sync completed for vault: $vaultPath');
  }).catchError((e) {
    debugPrint('Error during background files sync: $e');
  });
}

// ─── Centralized Data Version State Providers ──────────────────────────────────
final notesVersionProvider = StateProvider<int>((ref) => 0);
final foldersVersionProvider = StateProvider<int>((ref) => 0);
