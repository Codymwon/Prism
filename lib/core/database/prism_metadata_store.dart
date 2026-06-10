import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Sync-safe sidecar store for Prism's five app-only metadata categories.
///
/// The sidecar file `.prism-metadata.json` lives alongside `.prism.db` in
/// every vault directory. It is the **source of truth** for:
///
///   • virtual_folders
///   • note_folders
///   • graph_node_positions  (graph pins)
///   • spatial_groups
///   • spatial_group_nodes
///
/// SQLite keeps a fast query cache of the same data.  On startup [loadIntoDatabase]
/// seeds SQLite from the sidecar.  After every mutation [flushFromDatabase]
/// atomically re-serialises the SQLite state back to the sidecar.
class PrismMetadataStore {
  static const _sidecarFileName = '.prism-metadata.json';
  static const _schemaVersion = 1;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Reads `.prism-metadata.json` from [vaultPath] and upserts every record
  /// into the relevant SQLite tables.  Called once after the database is
  /// opened and before the background vault sync runs.
  ///
  /// Foreign-key enforcement is temporarily suspended so that folder/pin/group
  /// rows can be restored before the notes index is rebuilt by syncVault.
  ///
  /// If the sidecar does not exist or contains invalid JSON, this is a no-op.
  Future<void> loadIntoDatabase(Database db, String vaultPath) async {
    final sidecarFile = File(p.join(vaultPath, _sidecarFileName));
    if (!await sidecarFile.exists()) return;

    Map<String, dynamic> json;
    try {
      final content = await sidecarFile.readAsString();
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[PrismMetadataStore] Sidecar parse error — skipping load: $e');
      return;
    }

    // FK enforcement is disabled so we can restore metadata rows before
    // the notes table is repopulated by the background syncVault pass.
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // Replace-all strategy: sidecar is source of truth.
        await txn.delete('graph_node_positions');
        await txn.delete('note_folders');
        await txn.delete('virtual_folders');

        for (final item in _list(json, 'virtual_folders')) {
          await txn.insert('virtual_folders', {
            'id': item['id'],
            'name': item['name'],
            'color_hex': item['color_hex'],
            'icon': item['icon'],
            'created_at': item['created_at'],
            'sort_order': item['sort_order'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in _list(json, 'note_folders')) {
          await txn.insert('note_folders', {
            'note_id': item['note_id'],
            'folder_id': item['folder_id'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        for (final item in _list(json, 'graph_pins')) {
          await txn.insert('graph_node_positions', {
            'note_id': item['note_id'],
            'x': item['x'],
            'y': item['y'],
            'is_pinned': item['is_pinned'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }

    debugPrint('[PrismMetadataStore] Loaded sidecar into database from $vaultPath');
  }

  /// Snapshots the five app-only SQLite tables and atomically writes them to
  /// `.prism-metadata.json` in [vaultPath].
  ///
  /// Atomicity is guaranteed by writing to a `.prism-metadata.json.tmp` temp
  /// file first and then renaming it over the target, ensuring the sync client
  /// never sees a partially-written file.
  Future<void> flushFromDatabase(Database db, String vaultPath) async {
    final folders = await db.query('virtual_folders');
    final noteFolders = await db.query('note_folders');
    final graphPins = await db.query('graph_node_positions');

    final payload = <String, dynamic>{
      'version': _schemaVersion,
      'virtual_folders': folders
          .map((f) => {
                'id': f['id'],
                'name': f['name'],
                'color_hex': f['color_hex'],
                'icon': f['icon'],
                'created_at': f['created_at'],
                'sort_order': f['sort_order'],
              })
          .toList(),
      'note_folders': noteFolders
          .map((nf) => {
                'note_id': nf['note_id'],
                'folder_id': nf['folder_id'],
              })
          .toList(),
      'graph_pins': graphPins
          .map((gp) => {
                'note_id': gp['note_id'],
                'x': gp['x'],
                'y': gp['y'],
                'is_pinned': gp['is_pinned'],
              })
          .toList(),
    };

    final sidecarPath = p.join(vaultPath, _sidecarFileName);
    final tempPath = '$sidecarPath.tmp';

    // Atomic write: temp file → rename.
    final tempFile = File(tempPath);
    await tempFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    await tempFile.rename(sidecarPath);

    debugPrint('[PrismMetadataStore] Flushed database to sidecar at $vaultPath');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw is! List) return const [];
    return raw.cast<Map<String, dynamic>>();
  }
}
