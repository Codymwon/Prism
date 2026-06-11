import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/note_content_parser.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqliteMetadataIndexer indexer;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notes (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              file_path TEXT NOT NULL UNIQUE,
              word_count INTEGER DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_ghost INTEGER DEFAULT 0,
              is_daily INTEGER DEFAULT 0,
              daily_date TEXT,
              is_conflicted INTEGER DEFAULT 0,
              original_note_id TEXT,
              snippet TEXT DEFAULT ''
            )
          ''');

          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title COLLATE NOCASE)');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_links (
              source_id TEXT NOT NULL,
              target_id TEXT NOT NULL,
              context_snippet TEXT,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (source_id, target_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_tags (
              note_id TEXT NOT NULL,
              tag TEXT NOT NULL,
              PRIMARY KEY (note_id, tag)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS virtual_folders (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_hex TEXT NOT NULL DEFAULT '#7C6FF7',
              icon TEXT DEFAULT 'folder',
              created_at INTEGER NOT NULL,
              sort_order INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_folders (
              note_id TEXT NOT NULL,
              folder_id TEXT NOT NULL,
              PRIMARY KEY (note_id, folder_id)
            )
          ''');
        },
      ),
    );
    indexer = SqliteMetadataIndexer();
  });

  tearDown(() async {
    await db.close();
  });

  group('SqliteMetadataIndexer Tests', () {
    test('should index a note with tags and links', () async {
      final now = DateTime.now();
      final metadata = NoteMetadata(
        title: 'Note Title',
        wordCount: 150,
        tags: ['productivity', 'work'],
        wikilinks: ['Target Note'],
        wikilinkContexts: {'Target Note': '...linking to [[Target Note]]...'},
        snippet: 'Note snippet',
      );

      // Index the note
      await indexer.indexNote(
        db,
        id: 'note-1',
        title: 'Note Title',
        filePath: '/vault/note-1.md',
        wordCount: 150,
        updatedAt: now,
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: '/vault',
        metadata: metadata,
      );

      // Verify note inserted
      final notes = await db.query('notes', where: 'id = ?', whereArgs: ['note-1']);
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('Note Title'));
      expect(notes.first['is_ghost'], equals(0));

      // Verify tags inserted
      final tags = await db.query('note_tags', where: 'note_id = ?', whereArgs: ['note-1']);
      expect(tags.length, equals(2));
      final tagNames = tags.map((t) => t['tag'] as String).toList();
      expect(tagNames, containsAll(['productivity', 'work']));

      // Verify ghost note automatically created for the target
      final targetNotes = await db.query('notes', where: 'LOWER(title) = ?', whereArgs: ['target note']);
      expect(targetNotes.length, equals(1));
      expect(targetNotes.first['is_ghost'], equals(1));
      final targetId = targetNotes.first['id'] as String;

      // Verify note_link inserted
      final links = await db.query('note_links', where: 'source_id = ?', whereArgs: ['note-1']);
      expect(links.length, equals(1));
      expect(links.first['target_id'], equals(targetId));
    });

    test('should link to existing target note case-insensitively using COLLATE NOCASE', () async {
      final now = DateTime.now();
      
      // Insert an existing target note with mixed casing
      await db.insert('notes', {
        'id': 'target-id',
        'title': 'Target Note',
        'file_path': '/vault/target-note.md',
        'word_count': 100,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
        'is_ghost': 0,
      });

      // Index a source note with a wikilink using different casing
      final metadata = NoteMetadata(
        title: 'Source Note',
        wordCount: 50,
        tags: [],
        wikilinks: ['tArGeT nOtE'],
        wikilinkContexts: {'tArGeT nOtE': 'linking to [[tArGeT nOtE]]'},
        snippet: '',
      );

      await indexer.indexNote(
        db,
        id: 'source-1',
        title: 'Source Note',
        filePath: '/vault/source-1.md',
        wordCount: 50,
        updatedAt: now,
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: '/vault',
        metadata: metadata,
      );

      // Verify no new ghost note was created (meaning it matched case-insensitively)
      final notesCount = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM notes WHERE is_ghost = 1")
      );
      expect(notesCount, equals(0));

      // Verify the link targets the existing note
      final links = await db.query('note_links', where: 'source_id = ?', whereArgs: ['source-1']);
      expect(links.length, equals(1));
      expect(links.first['target_id'], equals('target-id'));
    });

    test('should rebuild tags and links on re-index', () async {
      final now = DateTime.now();
      
      // Index first time
      await indexer.indexNote(
        db,
        id: 'note-1',
        title: 'Note Title',
        filePath: '/vault/note-1.md',
        wordCount: 50,
        updatedAt: now,
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: '/vault',
        metadata: NoteMetadata(
          title: 'Note Title',
          wordCount: 50,
          tags: ['old-tag'],
          wikilinks: [],
          wikilinkContexts: {},
          snippet: '',
        ),
      );

      // Re-index with new tags
      await indexer.indexNote(
        db,
        id: 'note-1',
        title: 'Note Title',
        filePath: '/vault/note-1.md',
        wordCount: 60,
        updatedAt: now.add(const Duration(seconds: 10)),
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: '/vault',
        metadata: NoteMetadata(
          title: 'Note Title',
          wordCount: 60,
          tags: ['new-tag'],
          wikilinks: [],
          wikilinkContexts: {},
          snippet: '',
        ),
      );

      // Verify old tag is deleted, new tag exists
      final tags = await db.query('note_tags', where: 'note_id = ?', whereArgs: ['note-1']);
      expect(tags.length, equals(1));
      expect(tags.first['tag'], equals('new-tag'));
    });

    test('should remove note index', () async {
      final now = DateTime.now();
      await indexer.indexNote(
        db,
        id: 'note-1',
        title: 'Note Title',
        filePath: '/vault/note-1.md',
        wordCount: 50,
        updatedAt: now,
        isGhost: false,
        isDaily: false,
        dailyDate: null,
        vaultPath: '/vault',
        metadata: NoteMetadata(
          title: 'Note Title',
          wordCount: 50,
          tags: ['tag1'],
          wikilinks: [],
          wikilinkContexts: {},
          snippet: '',
        ),
      );

      await indexer.removeNoteIndex(db, 'note-1');

      final notes = await db.query('notes', where: 'id = ?', whereArgs: ['note-1']);
      expect(notes, isEmpty);

      // Note: in unit tests, cascade delete triggers are not setup since we did not define the foreign keys in onCreate.
      // But we can check that it removed the note itself.
    });
  });
}
