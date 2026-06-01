import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

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

  final db = await DatabaseHelper.instance.openDatabaseForPath(vaultPath);

  ref.onDispose(() async {
    await db.close();
    debugPrint('Database connection reactively closed for: $vaultPath');
  });

  return db;
});

// ─── Centralized Data Version State Providers ──────────────────────────────────
final notesVersionProvider = StateProvider<int>((ref) => 0);
final foldersVersionProvider = StateProvider<int>((ref) => 0);
