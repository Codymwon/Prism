import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_helper.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/note_content_parser.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory tempDir;
  final indexer = SqliteMetadataIndexer();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_fts_test_vault');
    db = await DatabaseHelper.instance.openDatabaseForPath(tempDir.path);
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabaseConnection(db);
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('FTS5 Database Triggers & Synchronization Tests', () {
    test('should index real notes in notes_fts but exclude ghost notes', () async {
      // 1. Insert a real note (is_ghost = 0) with body
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'real-note-1',
        title: 'Real Note Title One',
        filePath: '/vault/real-1.md',
        wordCount: 120,
        updatedAt: DateTime.now(),
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Real Note Title One',
          wordCount: 120,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: 'Snippet one',
          body: 'This is the searchable body content of note one',
        ),
      );

      // Verify it is indexed in notes_fts with body
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['real-note-1']);
      expect(ftsMatches.length, equals(1));
      expect(ftsMatches.first['title'], equals('Real Note Title One'));
      expect(ftsMatches.first['body'], equals('This is the searchable body content of note one'));

      // 2. Insert a ghost note (is_ghost = 1)
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'ghost-note-1',
        title: 'Ghost Note Title One',
        filePath: '/vault/ghost-1.md',
        wordCount: 0,
        updatedAt: DateTime.now(),
        isGhost: true,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Ghost Note Title One',
          wordCount: 0,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: '',
          body: '',
        ),
      );

      // Verify that the ghost note is NOT in the FTS index
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-1']);
      expect(ftsMatches, isEmpty);
    });

    test('should index ghost note in notes_fts when it is materialized (updated to is_ghost = 0)', () async {
      // 1. Insert a ghost note (is_ghost = 1)
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'ghost-note-2',
        title: 'Ghost Note Title Two',
        filePath: '/vault/ghost-2.md',
        wordCount: 0,
        updatedAt: DateTime.now(),
        isGhost: true,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Ghost Note Title Two',
          wordCount: 0,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: '',
          body: '',
        ),
      );

      // Verify it is not indexed
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-2']);
      expect(ftsMatches, isEmpty);

      // 2. Materialize the ghost note (update is_ghost to 0)
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'ghost-note-2',
        title: 'Ghost Note Title Two',
        filePath: '/vault/ghost-2.md',
        wordCount: 50,
        updatedAt: DateTime.now(),
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Ghost Note Title Two',
          wordCount: 50,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: 'Materialized snippet',
          body: 'Materialized full body content',
        ),
      );

      // Verify it is now indexed in notes_fts
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-2']);
      expect(ftsMatches.length, equals(1));
      expect(ftsMatches.first['title'], equals('Ghost Note Title Two'));
      expect(ftsMatches.first['body'], equals('Materialized full body content'));
    });

    test('should remove note from notes_fts when note is deleted from notes table', () async {
      // 1. Insert real note
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'note-to-delete',
        title: 'Note To Delete',
        filePath: '/vault/delete-me.md',
        wordCount: 10,
        updatedAt: DateTime.now(),
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Note To Delete',
          wordCount: 10,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: '',
          body: 'Note body to be deleted',
        ),
      );

      // Verify indexed
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['note-to-delete']);
      expect(ftsMatches.length, equals(1));

      // 2. Delete the note from notes table
      await db.delete('notes', where: 'id = ?', whereArgs: ['note-to-delete']);

      // Verify removed from FTS via notes_ad trigger
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['note-to-delete']);
      expect(ftsMatches, isEmpty);
    });

    test('notes_fts supports full-text search across body content', () async {
      await indexer.indexNote(
        SqfliteExecutorWrapper(db),
        id: 'note-body-search',
        title: 'Quantum Physics',
        filePath: '/vault/quantum.md',
        wordCount: 100,
        updatedAt: DateTime.now(),
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: tempDir.path,
        metadata: NoteMetadata(
          title: 'Quantum Physics',
          wordCount: 100,
          tags: const [],
          wikilinks: const [],
          wikilinkContexts: const {},
          snippet: 'Snippet about physics',
          body: 'Schrodinger cat superposition entanglement experiment',
        ),
      );

      // Match on a word only present in body, not title
      final results = await db.rawQuery(
        'SELECT id, title FROM notes_fts WHERE notes_fts MATCH ?',
        ['"superposition"*'],
      );
      expect(results.length, equals(1));
      expect(results.first['id'], equals('note-body-search'));
    });
  });
}
