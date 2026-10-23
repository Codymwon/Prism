import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../../core/services/analytics_service.dart';
import 'note_model.dart';
import '../../../core/services/note_ingestion_service.dart';
import 'vault_storage.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref);
});

/// Splits sanitized user input into whitespace-separated tokens, strips any
/// embedded `"` characters, and wraps each token in double quotes with a prefix
/// wildcard outside the quotes (e.g. `rawQuery = "to be or not"` -> `"to"* AND "be"* AND "or"* AND "not"*`).
/// This completely prevents FTS5 syntax errors from reserved boolean operators
/// ("AND", "OR", "NOT", "NEAR") or unbalanced punctuation.
String buildSafeFts5Query(String rawQuery) {
  final sanitized = rawQuery
      .replaceAll('"', '')
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\s\-]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (sanitized.isEmpty) return '';

  final tokens = sanitized
      .split(' ')
      .map((t) => t.replaceAll('"', '').replaceAll('*', '').trim())
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.isEmpty) return '';
  return tokens.map((t) => '"$t"*').join(' AND ');
}

// ─── Repository ───────────────────────────────────────────────────────────────

class NoteRepository {
  final Ref _ref;

  NoteRepository(this._ref);

  Future<Database> get _db => _ref.read(databaseProvider.future);

  NoteIngestionService get _vaultService => _ref.read(noteIngestionServiceProvider);




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
    AnalyticsService.logEvent('create_note', parameters: {
      'is_daily': isDaily,
      'content_length': initialContent.length,
    });
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

  Future<List<Note>> getAllNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async {
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
      limit: limit,
      offset: offset,
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Note>> getAllNonDailyNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final orderBy = switch (sort) {
      NoteSort.updated => 'updated_at DESC',
      NoteSort.created => 'created_at DESC',
      NoteSort.title => 'title ASC',
    };
    final maps = await db.query(
      'notes',
      where: 'is_ghost = 0 AND is_daily = 0',
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Note>> getDailyNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final orderBy = switch (sort) {
      NoteSort.updated => 'updated_at DESC',
      NoteSort.created => 'created_at DESC',
      NoteSort.title => 'title ASC',
    };
    final maps = await db.query(
      'notes',
      where: 'is_ghost = 0 AND is_daily = 1',
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map(Note.fromMap).toList();
  }

  Future<List<Note>> getUncategorizedNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final orderBy = switch (sort) {
      NoteSort.updated => 'updated_at DESC',
      NoteSort.created => 'created_at DESC',
      NoteSort.title => 'title ASC',
    };
    final maps = await db.query(
      'notes',
      where: 'is_ghost = 0 AND is_daily = 0 AND id NOT IN (SELECT note_id FROM note_folders)',
      orderBy: orderBy,
      limit: limit,
      offset: offset,
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
      where: 'title = ? COLLATE NOCASE',
      whereArgs: [title],
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

  Future<String> readNoteContent(String noteId) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      final storage = _ref.read(vaultStorageProvider);
      if (await storage.exists(note.filePath)) {
        return storage.readContent(note.filePath);
      }
    }
    throw ArgumentError('Note not found or file does not exist for ID: $noteId');
  }

  Future<List<Note>> searchNotes(String query) async {
    final safeQuery = buildSafeFts5Query(query);
    if (safeQuery.isEmpty) return [];

    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT n.* FROM notes n
      JOIN notes_fts f ON f.id = n.id
      WHERE notes_fts MATCH ? AND n.is_ghost = 0
      ORDER BY bm25(notes_fts)
      LIMIT 50
      ''',
      [safeQuery],
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
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final db = await _db;
    final safeQuery = buildSafeFts5Query(trimmed);
    if (safeQuery.isNotEmpty) {
      try {
        final ftsTitleQuery = safeQuery
            .split(' AND ')
            .map((t) => 'title : $t')
            .join(' AND ');
        final maps = await db.rawQuery(
          '''
          SELECT n.* FROM notes n
          JOIN notes_fts f ON f.id = n.id
          WHERE notes_fts MATCH ? AND n.is_ghost = 0
          ORDER BY bm25(notes_fts)
          LIMIT 8
          ''',
          [ftsTitleQuery],
        );
        if (maps.isNotEmpty) {
          return maps.map(Note.fromMap).toList();
        }
      } catch (_) {
        // Fall back to indexed LIKE query if FTS prefix match encounters any error
      }
    }

    final maps = await db.query(
      'notes',
      where: 'title LIKE ? COLLATE NOCASE',
      whereArgs: ['%$trimmed%'],
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


  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> saveNote(String id, String content) async {
    await _vaultService.saveNote(id, content);
    _ref.read(notesVersionProvider.notifier).state++;
  }

  // ── DELETE & RESTORE ──────────────────────────────────────────────────────

  Future<void> deleteNote(String id) async {
    await _vaultService.deleteNote(id);
    AnalyticsService.logEvent('delete_note');
    _ref.read(notesVersionProvider.notifier).state++;
  }

  Future<Note> restoreNote(Note note, String content) async {
    final restored = await _vaultService.createNote(
      title: note.title,
      initialContent: content,
      isDaily: note.isDaily,
      dailyDate: note.dailyDate,
    );
    AnalyticsService.logEvent('restore_note');
    _ref.read(notesVersionProvider.notifier).state++;
    return restored;
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

  Future<Map<String, List<String>>> batchGetTagsForAllNotes() async {
    final db = await _db;
    final maps = await db.query('note_tags', columns: ['note_id', 'tag']);
    final result = <String, List<String>>{};
    for (final row in maps) {
      final noteId = row['note_id'] as String;
      final tag = row['tag'] as String;
      result.putIfAbsent(noteId, () => []).add(tag);
    }
    return result;
  }

  Future<Map<String, List<Backlink>>> batchGetBacklinksForAllNotes() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT l.target_id, l.source_id, n.title, l.context_snippet
      FROM note_links l
      JOIN notes n ON n.id = l.source_id
      ORDER BY n.updated_at DESC
    ''');
    final result = <String, List<Backlink>>{};
    for (final row in maps) {
      final targetId = row['target_id'] as String;
      final backlink = Backlink(
        sourceId: row['source_id'] as String,
        sourceTitle: row['title'] as String,
        contextSnippet: row['context_snippet'] as String?,
      );
      result.putIfAbsent(targetId, () => []).add(backlink);
    }
    return result;
  }
}
