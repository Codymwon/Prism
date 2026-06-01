import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/utils/utils.dart';
import 'note_model.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref);
});

// ─── Repository ───────────────────────────────────────────────────────────────

class NoteRepository {
  final Ref _ref;

  NoteRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final db = await _db; // Warm up DB first to prevent race condition during onboarding note creation
    final id = generateId();
    final vaultPath = await getVaultPath();
    final noteTitle = title ?? (isDaily && dailyDate != null ? dailyDate : 'Untitled');
    final slug = titleToSlug(noteTitle);
    final fileName = '$slug-$id.md';
    final filePath = p.join(vaultPath, fileName);
    final now = DateTime.now();

    final content = initialContent.isEmpty
        ? (isDaily ? '# $noteTitle\n\n' : '# $noteTitle\n\n')
        : initialContent;

    // Write the .md file to disk
    await File(filePath).writeAsString(content);

    final note = Note(
      id: id,
      title: noteTitle,
      filePath: filePath,
      wordCount: countWords(content),
      createdAt: now,
      updatedAt: now,
      isDaily: isDaily,
      dailyDate: dailyDate,
    );

    await db.insert('notes', note.toMap());
    _ref.read(notesVersionProvider.notifier).state++;
    return note;
  }

  /// Creates a "ghost note" — a placeholder note from a wikilink before actual content.
  Future<Note> createGhostNote(String title) async {
    final id = generateId();
    final vaultPath = await getVaultPath();
    final slug = titleToSlug(title);
    final fileName = '$slug-$id.md';
    final filePath = p.join(vaultPath, fileName);
    final now = DateTime.now();

    final note = Note(
      id: id,
      title: title,
      filePath: filePath,
      wordCount: 0,
      createdAt: now,
      updatedAt: now,
      isGhost: true,
    );

    final db = await _db;
    await db.insert('notes', note.toMap());
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

  Future<({List<GraphNode> nodes, List<GraphEdge> edges})> getGraphData() async {
    final db = await _db;

    final noteMaps = await db.rawQuery('''
      SELECT n.id, n.title,
        (SELECT COUNT(*) FROM note_links WHERE source_id = n.id OR target_id = n.id) as link_count,
        (SELECT f.color_hex FROM virtual_folders f JOIN note_folders nf ON nf.folder_id = f.id WHERE nf.note_id = n.id LIMIT 1) as color_hex
      FROM notes n WHERE n.is_ghost = 0
    ''');

    final edgeMaps = await db.query('note_links');

    final nodes = noteMaps
        .map((m) => GraphNode(
              id: m['id'] as String,
              title: m['title'] as String,
              linkCount: (m['link_count'] as int?) ?? 0,
              colorHex: m['color_hex'] as String?,
            ))
        .toList();

    final edges = edgeMaps
        .map((m) => GraphEdge(
              sourceId: m['source_id'] as String,
              targetId: m['target_id'] as String,
            ))
        .toList();

    return (nodes: nodes, edges: edges);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> saveNote(String id, String content) async {
    final note = await getNoteById(id);
    if (note == null) return;

    // Write content to disk
    await File(note.filePath).writeAsString(content);

    final title = extractTitle(content);
    final wordCount = countWords(content);
    final tags = extractTags(content);
    final wikilinks = extractWikilinks(content);
    final now = DateTime.now();

    final db = await _db;

    await db.transaction((txn) async {
      // Update note metadata
      await txn.update(
        'notes',
        {
          'title': title,
          'word_count': wordCount,
          'updated_at': now.millisecondsSinceEpoch,
          'is_ghost': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Rebuild tags
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
      for (final tag in tags) {
        await txn.insert(
          'note_tags',
          {'note_id': id, 'tag': tag},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      // Rebuild wikilinks
      await txn.delete('note_links', where: 'source_id = ?', whereArgs: [id]);
      for (final target in wikilinks) {
        // Find or create the target note inside the transaction
        final maps = await txn.query(
          'notes',
          where: 'LOWER(title) = ?',
          whereArgs: [target.toLowerCase()],
        );
        var targetNote = maps.isEmpty ? null : Note.fromMap(maps.first);

        if (targetNote == null) {
          final targetId = generateId();
          final vaultPath = await getVaultPath();
          final slug = titleToSlug(target);
          final fileName = '$slug-$targetId.md';
          final filePath = p.join(vaultPath, fileName);
          final targetNow = DateTime.now();

          targetNote = Note(
            id: targetId,
            title: target,
            filePath: filePath,
            wordCount: 0,
            createdAt: targetNow,
            updatedAt: targetNow,
            isGhost: true,
          );
          await txn.insert('notes', targetNote.toMap());
        }

        final snippet = getWikilinkContext(content, target);
        await txn.insert(
          'note_links',
          {
            'source_id': id,
            'target_id': targetNote.id,
            'context_snippet': snippet,
            'created_at': now.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _ref.read(notesVersionProvider.notifier).state++;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteNote(String id) async {
    final note = await getNoteById(id);
    if (note == null) return;

    // Delete file from disk asynchronously
    final file = File(note.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    final db = await _db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    _ref.read(notesVersionProvider.notifier).state++;
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
    
    final notes = (noteRes.first['COUNT(*)'] as int?) ?? 0;
    final words = (noteRes.first['SUM(word_count)'] as int?) ?? 0;
    final links = (linkRes.first['COUNT(*)'] as int?) ?? 0;
    
    return (totalNotes: notes, totalWords: words, totalLinks: links);
  }
}
