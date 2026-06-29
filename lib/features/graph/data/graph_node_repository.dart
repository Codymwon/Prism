import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/vault_providers.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/data/note_model.dart';
import 'graph_models.dart';

final graphNodeRepositoryProvider = Provider<GraphNodeRepository>((ref) => GraphNodeRepository(ref));

class GraphNodeRepository {
  final Ref _ref;

  GraphNodeRepository(this._ref);

  Future<DatabaseService> get _db => _ref.read(databaseServiceProvider.future);

  /// Atomically re-serialises app-only SQLite tables to the sidecar.
  Future<void> _flush(DatabaseService db) async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    await db.flushMetadata(vaultPath);
  }

  int _getIsoWeekNumber(DateTime date) {
    final thurs = date.add(Duration(days: 3 - ((date.weekday - 1) % 7)));
    final firstDayOfYear = DateTime(thurs.year, 1, 1);
    final firstThurs = firstDayOfYear.add(Duration(days: (4 - firstDayOfYear.weekday) % 7));
    final diffDays = thurs.difference(firstThurs).inDays;
    return (diffDays / 7).round() + 1;
  }

  Future<({List<GraphNode> nodes, List<GraphEdge> edges})> getGraphData() async {
    final db = await _db;

    final noteMaps = await db.rawQuery('''
      SELECT n.id, n.title, n.is_daily, n.daily_date, n.is_ghost,
        (SELECT COUNT(*) FROM (
          SELECT 1 FROM note_links WHERE source_id = n.id
          UNION ALL
          SELECT 1 FROM note_links WHERE target_id = n.id
        )) as link_count
      FROM notes n
    ''');

    final edgeMaps = await db.query('note_links');

    final nodes = <GraphNode>[];
    final Set<String> createdTemporalIds = {};

    for (final m in noteMaps) {
      final rawCount = m['link_count'];
      final linkCount = rawCount == null ? 0
          : rawCount is int ? rawCount
          : rawCount is double ? rawCount.toInt()
          : rawCount is bool ? (rawCount ? 1 : 0)
          : int.tryParse(rawCount.toString()) ?? 0;
      
      nodes.add(GraphNode(
        id: m['id'] as String,
        title: m['title'] as String,
        linkCount: linkCount,
        colorHex: null,
        isTemporal: false,
        isGhost: m['is_ghost'] == 1 || m['is_ghost'] == true,
      ));
    }

    // Build the known node-ID set for edge validation
    final Set<String> nodeIds = nodes.map((n) => n.id).toSet();

    // Only keep edges where both endpoints exist in notes (prune dangling links)
    final allEdges = edgeMaps
        .map((m) => GraphEdge(
              sourceId: m['source_id'] as String,
              targetId: m['target_id'] as String,

            ))
        .where((e) => nodeIds.contains(e.sourceId) && nodeIds.contains(e.targetId))
        .toList();

    // Ghost notes that are no longer referenced by any edge should be pruned —
    // their mentioning note was deleted so they are now unreachable orphans.
    final Set<String> referencedByEdge = {};
    for (final e in allEdges) {
      referencedByEdge.add(e.sourceId);
      referencedByEdge.add(e.targetId);
    }
    nodes.removeWhere((n) => n.isGhost && !referencedByEdge.contains(n.id));

    // Re-sync nodeIds after ghost pruning
    final Set<String> prunedNodeIds = nodes.map((n) => n.id).toSet();
    final edges = allEdges
        .where((e) => prunedNodeIds.contains(e.sourceId) && prunedNodeIds.contains(e.targetId))
        .toList();

    final Set<String> createdTemporalEdges = {};

    for (final m in noteMaps) {
      final isDaily = m['is_daily'] == 1 || m['is_daily'] == true;
      if (isDaily && m['daily_date'] != null) {
        final dateStr = m['daily_date'] as String;
        final DateTime? date = DateTime.tryParse(dateStr);
        if (date != null) {
          // 1. Year Node
          final yearId = 'year-${date.year}';
          if (!createdTemporalIds.contains(yearId)) {
            createdTemporalIds.add(yearId);
            nodes.add(GraphNode(
              id: yearId,
              title: '${date.year}',
              linkCount: 0,
              colorHex: null,
              isTemporal: true,
              temporalType: 'year',
            ));
          }

          // 2. ISO Week Node
          final weekNum = _getIsoWeekNumber(date);
          final weekId = 'week-${date.year}-$weekNum';
          if (!createdTemporalIds.contains(weekId)) {
            createdTemporalIds.add(weekId);
            nodes.add(GraphNode(
              id: weekId,
              title: 'W$weekNum',
              linkCount: 0,
              colorHex: null,
              isTemporal: true,
              temporalType: 'week',
            ));
          }

          // 3. Connect Note -> Week Node
          final noteToWeekEdge = '${m['id']}->$weekId';
          if (!createdTemporalEdges.contains(noteToWeekEdge) && prunedNodeIds.contains(m['id'])) {
            createdTemporalEdges.add(noteToWeekEdge);
            edges.add(GraphEdge(
              sourceId: m['id'] as String,
              targetId: weekId,
            ));
          }

          // 4. Connect Week Node -> Year Node
          final weekToYearEdge = '$weekId->$yearId';
          if (!createdTemporalEdges.contains(weekToYearEdge)) {
            createdTemporalEdges.add(weekToYearEdge);
            edges.add(GraphEdge(
              sourceId: weekId,
              targetId: yearId,
            ));
          }
        }
      }
    }

    return (
      nodes: nodes,
      edges: edges,
    );
  }

  Future<Map<String, List<String>>> getNoteTagsMap() async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT note_id, tag FROM note_tags ORDER BY tag ASC');
    
    final result = <String, List<String>>{};
    for (final m in maps) {
      final noteId = m['note_id'] as String;
      final tag = m['tag'] as String;
      result.putIfAbsent(noteId, () => []).add(tag);
    }
    return result;
  }

  Future<Map<String, List<Map<String, String>>>> getNoteFoldersMap() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT nf.note_id, vf.name, vf.color_hex 
      FROM note_folders nf 
      JOIN virtual_folders vf ON nf.folder_id = vf.id 
      ORDER BY vf.name ASC
    ''');
    
    final result = <String, List<Map<String, String>>>{};
    for (final m in maps) {
      final noteId = m['note_id'] as String;
      final name = m['name'] as String;
      final colorHex = m['color_hex'] as String;
      result.putIfAbsent(noteId, () => []).add({
        'name': name,
        'color_hex': colorHex,
      });
    }
    return result;
  }

  Future<Map<String, GraphNodePosition>> getPinnedCoordinates() async {
    final db = await _db;
    final maps = await db.query(
      'graph_node_positions',
      where: 'is_pinned = 1',
    );
    final result = <String, GraphNodePosition>{};
    for (final m in maps) {
      final id = m['note_id'] as String;
      result[id] = GraphNodePosition(
        noteId: id,
        x: m['x'] as double,
        y: m['y'] as double,
      );
    }
    return result;
  }

  Future<void> pinNode(String nodeId, double x, double y) async {
    if (nodeId.startsWith('week-') || nodeId.startsWith('year-')) {
      throw ArgumentError('Cannot pin temporal node in database: $nodeId');
    }
    final note = await _ref.read(noteRepositoryProvider).getNoteById(nodeId);
    if (note == null || note.isGhost) {
      return;
    }
    try {
      final db = await _db;
      await db.insert(
        'graph_node_positions',
        {
          'note_id': nodeId,
          'x': x,
          'y': y,
          'is_pinned': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _ref.read(notesVersionProvider.notifier).state++;
      await _flush(db);
    } catch (e) {
      // Gracefully catch foreign key exceptions or others
    }
  }

  Future<void> unpinNode(String nodeId) async {
    if (nodeId.startsWith('week-') || nodeId.startsWith('year-')) {
      throw ArgumentError('Cannot unpin temporal node: $nodeId');
    }
    try {
      final db = await _db;
      await db.delete(
        'graph_node_positions',
        where: 'note_id = ?',
        whereArgs: [nodeId],
      );
      _ref.read(notesVersionProvider.notifier).state++;
      await _flush(db);
    } catch (e) {
      // Gracefully catch exceptions
    }
  }
}
