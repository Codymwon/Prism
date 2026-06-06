import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/prism_metadata_store.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../graph/data/graph_models.dart';
import 'note_model.dart';
import 'vault_service.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref);
});

// ─── Repository ───────────────────────────────────────────────────────────────

class NoteRepository {
  final Ref _ref;

  NoteRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  NoteIngestionService get _vaultService => _ref.read(noteIngestionServiceProvider);

  /// Atomically re-serialises app-only SQLite tables to the sidecar.
  Future<void> _flush(Database db) async {
    final vaultPath = await _ref.read(activeVaultPathProvider.future);
    if (vaultPath.isNotEmpty) {
      await PrismMetadataStore().flushFromDatabase(db, vaultPath);
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final note = await _vaultService.createNote(
      title: title,
      initialContent: initialContent,
      isDaily: isDaily,
      dailyDate: dailyDate,
    );
    _ref.read(notesVersionProvider.notifier).state++;
    return note;
  }

  /// Creates a "ghost note" — a placeholder note from a wikilink before actual content.
  Future<Note> createGhostNote(String title) async {
    final note = await _vaultService.createGhostNote(title);
    _ref.read(notesVersionProvider.notifier).state++;
    return note;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async {
    final db = await _db;
    final orderBy = switch (sort) {
      NoteSort.updated => 'updated_at DESC',
      NoteSort.created => 'created_at DESC',
      NoteSort.title => 'title ASC',
    };
    final maps = await db.query(
      'notes',
      where: 'is_ghost = 0',
      orderBy: orderBy,
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<Note?> getNoteById(String id) async {
    final db = await _db;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  Future<Note?> getNoteByTitle(String title) async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'LOWER(title) = ?',
      whereArgs: [title.toLowerCase()],
    );
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  Future<Note?> getDailyNote(String date) async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'is_daily = 1 AND daily_date = ?',
      whereArgs: [date],
    );
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  Future<List<Note>> searchNotes(String query) async {
    // Strip FTS special control characters to avoid syntax error crashes
    final sanitizedQuery = query.replaceAll(RegExp(r'[^\w\s\-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sanitizedQuery.isEmpty) return [];

    final db = await _db;
    // Use FTS4 for full-text search
    final maps = await db.rawQuery(
      '''
      SELECT n.* FROM notes n
      JOIN notes_fts f ON f.id = n.id
      WHERE f.title MATCH ? AND n.is_ghost = 0
      ORDER BY n.updated_at DESC
      LIMIT 50
      ''',
      ['$sanitizedQuery*'],
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT n.* FROM notes n
      JOIN note_tags t ON t.note_id = n.id
      WHERE t.tag = ?
      ORDER BY n.updated_at DESC
      ''',
      [tag.toLowerCase()],
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Note>> getTitleSuggestions(String query) async {
    final db = await _db;
    final maps = await db.query(
      'notes',
      where: 'LOWER(title) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'updated_at DESC',
      limit: 8,
    );
    return maps.map(Note.fromMap).toList();
  }

  // ── BACKLINKS & GRAPH ─────────────────────────────────────────────────────

  Future<List<Backlink>> getBacklinks(String noteId) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT l.source_id, n.title, l.context_snippet
      FROM note_links l
      JOIN notes n ON n.id = l.source_id
      WHERE l.target_id = ?
      ORDER BY n.updated_at DESC
      ''',
      [noteId],
    );
    return maps
        .map((m) => Backlink(
              sourceId: m['source_id'] as String,
              sourceTitle: m['title'] as String,
              contextSnippet: m['context_snippet'] as String?,
            ))
        .toList();
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
        (SELECT COUNT(*) FROM note_links WHERE source_id = n.id OR target_id = n.id) as link_count,
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
    final noteExists = await getNoteById(nodeId) != null;
    if (!noteExists) {
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

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> saveNote(String id, String content) async {
    await _vaultService.saveNote(id, content);
    _ref.read(notesVersionProvider.notifier).state++;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteNote(String id) async {
    await _vaultService.deleteNote(id);
    _ref.read(notesVersionProvider.notifier).state++;
  }

  Future<List<String>> getTagsForNote(String noteId) async {
    final db = await _db;
    final maps = await db.query(
      'note_tags',
      columns: ['tag'],
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'tag ASC',
    );
    return maps.map((m) => m['tag'] as String).toList();
  }

  Future<List<String>> getUniqueTags() async {
    final db = await _db;
    final maps = await db.rawQuery('SELECT DISTINCT tag FROM note_tags ORDER BY tag ASC');
    return maps.map((m) => m['tag'] as String).toList();
  }

  Future<({int totalNotes, int totalWords, int totalLinks})> getVaultStats() async {
    final db = await _db;
    final noteRes = await db.rawQuery('SELECT COUNT(*), SUM(word_count) FROM notes WHERE is_ghost = 0');
    final linkRes = await db.rawQuery('SELECT COUNT(*) FROM note_links');

    // sqflite on Android can return COUNT/SUM as int, double, or even bool —
    // use a safe helper that handles all variants.
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is bool) return v ? 1 : 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    final notes = toInt(noteRes.first['COUNT(*)']);
    final words = toInt(noteRes.first['SUM(word_count)']);
    final links = toInt(linkRes.first['COUNT(*)']);

    return (totalNotes: notes, totalWords: words, totalLinks: links);
  }
}
