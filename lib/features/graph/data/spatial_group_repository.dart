import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/prism_metadata_store.dart';
import '../../../core/utils/utils.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import 'graph_models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────
final spatialGroupRepositoryProvider = Provider<SpatialGroupRepository>((ref) {
  return SpatialGroupRepository(ref);
});

final spatialGroupsVersionProvider = StateProvider<int>((ref) => 0);

final spatialGroupsListProvider = FutureProvider<List<SpatialGroup>>((ref) async {
  ref.watch(spatialGroupsVersionProvider);
  final repo = ref.watch(spatialGroupRepositoryProvider);
  return repo.getAllSpatialGroups();
});

final spatialGroupMappingsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  ref.watch(spatialGroupsVersionProvider);
  final repo = ref.watch(spatialGroupRepositoryProvider);
  return repo.getSpatialGroupNodeMappings();
});

// ─── Repository ──────────────────────────────────────────────────────────────
class SpatialGroupRepository {
  final Ref _ref;

  SpatialGroupRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  /// Atomically re-serialises app-only SQLite tables to the sidecar.
  Future<void> _flush(Database db) async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    if (vaultPath.isNotEmpty) {
      await PrismMetadataStore().flushFromDatabase(db, vaultPath);
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  /// Creates a new spatial group and inserts its associated member note IDs.
  Future<SpatialGroup> createSpatialGroup({
    required String name,
    required String colorHex,
    List<String> memberNodeIds = const [],
  }) async {
    final db = await _db;
    final id = generateId();
    final group = SpatialGroup(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert(
        'spatial_groups',
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final noteId in memberNodeIds) {
        await txn.insert(
          'spatial_group_nodes',
          {
            'group_id': id,
            'note_id': noteId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    _ref.read(spatialGroupsVersionProvider.notifier).state++;
    _ref.read(notesVersionProvider.notifier).state++;
    await _flush(db);
    return group;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  /// Updates an existing spatial group's metadata and synchronizes its member node IDs.
  Future<void> updateSpatialGroup({
    required String id,
    required String name,
    required String colorHex,
    required List<String> memberNodeIds,
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      // 1. Update the spatial group info
      await txn.update(
        'spatial_groups',
        {
          'name': name,
          'color_hex': colorHex,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // 2. Clear out all existing member node mappings for this group
      await txn.delete(
        'spatial_group_nodes',
        where: 'group_id = ?',
        whereArgs: [id],
      );

      // 3. Insert the new/updated set of member nodes
      for (final noteId in memberNodeIds) {
        await txn.insert(
          'spatial_group_nodes',
          {
            'group_id': id,
            'note_id': noteId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    _ref.read(spatialGroupsVersionProvider.notifier).state++;
    _ref.read(notesVersionProvider.notifier).state++;
    await _flush(db);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  /// Deletes a spatial group. Foreign keys will trigger Cascade Delete on mappings.
  Future<void> deleteSpatialGroup(String id) async {
    final db = await _db;
    await db.delete(
      'spatial_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    _ref.read(spatialGroupsVersionProvider.notifier).state++;
    _ref.read(notesVersionProvider.notifier).state++;
    await _flush(db);
  }

  // ── READ ──────────────────────────────────────────────────────────────────
  /// Fetches all spatial groups from the database.
  Future<List<SpatialGroup>> getAllSpatialGroups() async {
    final db = await _db;
    final maps = await db.query(
      'spatial_groups',
      orderBy: 'created_at ASC',
    );
    return maps.map(SpatialGroup.fromMap).toList();
  }

  /// Fetches the mapping of groupId to noteIds for all spatial groups.
  Future<Map<String, List<String>>> getSpatialGroupNodeMappings() async {
    final db = await _db;
    final maps = await db.query('spatial_group_nodes');
    final Map<String, List<String>> result = {};
    for (final row in maps) {
      final groupId = row['group_id'] as String;
      final noteId = row['note_id'] as String;
      result.putIfAbsent(groupId, () => []).add(noteId);
    }
    return result;
  }

  /// Get 1-hop connected notes for group auto-selection flow.
  Future<List<String>> get1HopConnections(String noteId) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT DISTINCT 
        CASE WHEN source_id = ? THEN target_id ELSE source_id END as note_id
      FROM note_links
      WHERE source_id = ? OR target_id = ?
    ''', [noteId, noteId, noteId]);
    return maps.map((m) => m['note_id'] as String).toList();
  }

  /// Get 2-hop connected notes for group auto-selection flow.
  Future<List<String>> get2HopConnections(String noteId) async {
    final h1 = await get1HopConnections(noteId);
    final Set<String> results = Set.from(h1);
    for (final neighborId in h1) {
      final h2 = await get1HopConnections(neighborId);
      results.addAll(h2);
    }
    results.remove(noteId);
    return results.toList();
  }

  /// Get all connected notes in the component (BFS).
  Future<List<String>> getAllConnectedHops(String noteId) async {
    final db = await _db;
    final links = await db.query('note_links', columns: ['source_id', 'target_id']);
    
    final Map<String, List<String>> adjList = {};
    for (final link in links) {
      final src = link['source_id'] as String;
      final tgt = link['target_id'] as String;
      adjList.putIfAbsent(src, () => []).add(tgt);
      adjList.putIfAbsent(tgt, () => []).add(src);
    }

    final Set<String> visited = {noteId};
    final List<String> queue = [noteId];
    int head = 0;

    while (head < queue.length) {
      final current = queue[head++];
      final neighbors = adjList[current] ?? [];
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    visited.remove(noteId);
    return visited.toList();
  }
}
