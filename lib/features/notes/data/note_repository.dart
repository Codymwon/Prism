import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/services/template_service.dart';
import '../../../../core/services/analytics_service.dart';
import 'note_model.dart';
import 'vault_service.dart';
import 'vault_storage.dart';

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

  TemplateService get _templates => _ref.read(templateServiceProvider);

  /// Synthetic [Note] for a virtual `template:<name>` ID. Templates have no
  /// SQLite row by design — their content lives as Markdown in
  /// `.prism/templates/` — so we fabricate a lightweight Note object for the
  /// editor/other readers that expect a Note instance.
  Note _syntheticTemplateNote(String id) => Note(
        id: id,
        title: _templates.nameFromId(id),
        filePath: '',
        wordCount: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );


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
    if (isTemplateId(id)) return _syntheticTemplateNote(id);
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

  Future<String> readNoteContent(String noteId) async {
    // Template content lives in .prism/templates/, never the DB or VaultStorage.
    if (isTemplateId(noteId)) {
      final res = await _templates.readTemplate(_templates.nameFromId(noteId));
      return res.fold(
        (f) => throw ArgumentError(f.message),
        (content) => content,
      );
    }
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


  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> saveNote(String id, String content) async {
    // Templates bypass SQLite indexing entirely — write the Markdown file only.
    if (isTemplateId(id)) {
      await _templates.writeTemplate(_templates.nameFromId(id), content);
      return;
    }
    await _vaultService.saveNote(id, content);
    _ref.read(notesVersionProvider.notifier).state++;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteNote(String id) async {
    if (isTemplateId(id)) {
      await _templates.deleteTemplate(_templates.nameFromId(id));
      AnalyticsService.logEvent('delete_template');
      return;
    }
    await _vaultService.deleteNote(id);
    AnalyticsService.logEvent('delete_note');
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
