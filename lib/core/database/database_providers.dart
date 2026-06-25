import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'prism_metadata_store.dart';
import '../utils/utils.dart';
import 'vault_providers.dart';
import '../../features/notes/data/vault_service.dart';

part 'database_providers.g.dart';

// ─── Database Connection Provider (Reactive Lifecycle) ────────────────────────
// Watches activeVaultPathProvider (now a FutureProvider) so it waits for the
// vault path to be fully loaded from SharedPreferences before opening the DB.
@riverpod
Future<Database> database(DatabaseRef ref) async {
  bool isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
  });

  // Await the full path — this suspends until baseVaultsDirectory and
  // activeVaultName are both loaded from SharedPreferences.
  final vaultPath = await ref.watch(activeVaultPathProvider.future);
  if (isDisposed) throw Exception('Provider disposed during activeVaultPathProvider load');
  if (vaultPath.isEmpty) {
    throw Exception('Active vault path is empty');
  }

  // Ensure welcome notes are seeded if the vault is new/empty before opening
  await seedWelcomeNotes(vaultPath);
  if (isDisposed) throw Exception('Provider disposed during seedWelcomeNotes');

  Database? db;
  ref.onDispose(() async {
    if (db != null) {
      await DatabaseHelper.instance.closeDatabaseConnection(db!);
      debugPrint('Database connection reactively closed for: $vaultPath');
    }
  });

  db = await DatabaseHelper.instance.openDatabaseForPath(vaultPath);
  if (isDisposed) {
    await DatabaseHelper.instance.closeDatabaseConnection(db);
    throw Exception('Provider disposed during openDatabaseForPath');
  }

  // Restore app-only metadata (virtual folders, pins, spatial groups) from the
  // sync-safe sidecar before the background notes-index rebuild runs.
  await PrismMetadataStore().loadIntoDatabase(db, vaultPath);
  if (isDisposed) throw Exception('Provider disposed during metadata restoration');

  // Sync vault physical files in the background without blocking database loading
  _triggerBackgroundSync(db, vaultPath, ref, () => isDisposed);

  return db;
}

/// Helper to trigger vault file synchronization asynchronously in the background.
/// Increments notesVersionProvider upon completion to reactively refresh note listings.
void _triggerBackgroundSync(Database db, String vaultPath, DatabaseRef ref, bool Function() isDisposedFn) {
  if (isDisposedFn()) return;
  final keepAliveLink = ref.keepAlive();
  ref.read(noteIngestionServiceProvider).syncVault(vaultPath, db: db).then((_) {
    if (!isDisposedFn()) {
      ref.read(notesVersionProvider.notifier).update((state) => state + 1);
      ref.read(foldersVersionProvider.notifier).update((state) => state + 1);
    }
    debugPrint('Background physical files sync completed for vault: $vaultPath');
  }).catchError((e) {
    debugPrint('Error during background files sync: $e');
  }).whenComplete(() {
    keepAliveLink.close();
  });
}

// ─── Centralized Data Version State Providers ──────────────────────────────────
@riverpod
class NotesVersion extends _$NotesVersion {
  @override
  int build() => 0;

  void update(int Function(int state) cb) {
    state = cb(state);
  }

  @override
  int get state => super.state;

  @override
  set state(int value) => super.state = value;
}

@riverpod
class FoldersVersion extends _$FoldersVersion {
  @override
  int build() => 0;

  void update(int Function(int state) cb) {
    state = cb(state);
  }

  @override
  int get state => super.state;

  @override
  set state(int value) => super.state = value;
}

