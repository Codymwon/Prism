import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/prism_metadata_store.dart';
import '../../../core/database/vault_providers.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/data/note_model.dart';
import 'graph_models.dart';

final graphNodeRepositoryProvider = Provider<GraphNodeRepository>((ref) => GraphNodeRepository(ref));

class GraphNodeRepository {
  final Ref _ref;

  GraphNodeRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  /// Atomically re-serialises app-only SQLite tables to the sidecar.
  Future<void> _flush(Database db) async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    if (vaultPath.isNotEmpty) {
      await PrismMetadataStore().flushFromDatabase(db, vaultPath);
    }
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
        )) as link_count,
        (SELECT f.color_hex FROM virtual_folders f JOIN note_folders nf ON nf.folder_id = f.id WHERE nf.note_id = n.id LIMIT 1) as color_hex
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
        colorHex: m['color_hex'] as String?,
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
      final dailyDateStr = m['daily_date'] as String?;
      if (isDaily && dailyDateStr != null && dailyDateStr.isNotEmpty) {
        final parsedDate = DateTime.tryParse(dailyDateStr);
        if (parsedDate != null) {
          final noteId = m['id'] as String;

          final thurs = parsedDate.add(Duration(days: 3 - ((parsedDate.weekday - 1) % 7)));
          final yearOfThurs = thurs.year;
          final weekNum = _getIsoWeekNumber(parsedDate);

          final weekId = 'week-$yearOfThurs-${weekNum.toString().padLeft(2, '0')}';
          final weekTitle = 'Week $weekNum, $yearOfThurs';

          final yearId = 'year-${parsedDate.year}';
          final yearTitle = '${parsedDate.year}';

          if (!createdTemporalIds.contains(weekId)) {
            nodes.add(GraphNode(
              id: weekId,
              title: weekTitle,
              linkCount: 0,
              isTemporal: true,
              temporalType: 'week',
            ));
            createdTemporalIds.add(weekId);
          }

          if (!createdTemporalIds.contains(yearId)) {
            nodes.add(GraphNode(
              id: yearId,
              title: yearTitle,
              linkCount: 0,
              isTemporal: true,
              temporalType: 'year',
            ));
            createdTemporalIds.add(yearId);
          }

          final dayToWeekKey = '$noteId->$weekId';
          if (!createdTemporalEdges.contains(dayToWeekKey)) {
            edges.add(GraphEdge(sourceId: noteId, targetId: weekId));
            createdTemporalEdges.add(dayToWeekKey);
          }

          final weekToYearKey = '$weekId->$yearId';
          if (!createdTemporalEdges.contains(weekToYearKey)) {
            edges.add(GraphEdge(sourceId: weekId, targetId: yearId));
            createdTemporalEdges.add(weekToYearKey);
          }
        }
      }
    }

    return (nodes: nodes, edges: edges);
  }

  Future<Map<String, GraphNodePosition>> getPinnedCoordinates() async {
    final db = await _db;
    final maps = await db.query('graph_node_positions');
    final result = <String, GraphNodePosition>{};
    for (final map in maps) {
      final pos = GraphNodePosition.fromMap(map);
      result[pos.noteId] = pos;
    }
    return result;
  }

  Future<void> pinNode(String nodeId, double x, double y) async {
    if (nodeId.startsWith('week-') || nodeId.startsWith('year-')) {
      throw ArgumentError('Cannot pin temporal node: $nodeId');
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
