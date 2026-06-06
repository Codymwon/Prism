import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meridian/features/notes/data/adapters/vault_service_impl.dart';
import 'package:meridian/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:meridian/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:meridian/features/notes/data/vault_storage.dart';

class FakeVaultStorage implements VaultStorage {
  final Map<String, String> files = {};
  final Map<String, DateTime> modTimes = {};

  @override
  Future<String> readContent(String relativePath) async {
    return files[relativePath] ?? '';
  }

  @override
  Future<void> writeContent(String relativePath, String content) async {
    files[relativePath] = content;
    modTimes[relativePath] = DateTime.now();
  }

  @override
  Future<void> deleteContent(String relativePath) async {
    files.remove(relativePath);
    modTimes.remove(relativePath);
  }

  @override
  Future<bool> exists(String relativePath) async {
    return files.containsKey(relativePath);
  }

  @override
  Future<List<String>> listDocumentIdentifiers(String vaultPath) async {
    return files.keys.toList();
  }

  @override
  Future<DateTime> getLastModified(String relativePath) async {
    return modTimes[relativePath] ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late FakeVaultStorage storage;
  late NoteIngestionServiceImpl service;

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
              original_note_id TEXT
            )
          ''');

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

    storage = FakeVaultStorage();
    // Initialize our hybrid service with adapters
    service = NoteIngestionServiceImpl(
      getDb: () async => db,
      storage: storage,
      parser: MarkdownContentParser(),
      indexer: SqliteMetadataIndexer(),
      getVaultPath: () async => '/vault',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('NoteIngestionServiceImpl Tests', () {
    test('should create and index a new note', () async {
      final note = await service.createNote(
        title: 'New Note',
        initialContent: '# New Note\n\nSome content #ideas',
      );

      expect(note.title, equals('New Note'));
      expect(note.wordCount, equals(6));

      // Verify file written to fake storage
      final fileWritten = await storage.exists(note.filePath);
      expect(fileWritten, isTrue);

      final fileContent = await storage.readContent(note.filePath);
      expect(fileContent, contains('Some content #ideas'));

      // Verify indexed in DB
      final notes = await db.query('notes', where: 'id = ?', whereArgs: [note.id]);
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('New Note'));

      final tags = await db.query('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      expect(tags.length, equals(1));
      expect(tags.first['tag'], equals('ideas'));
    });

    test('should save and re-index an existing note', () async {
      final note = await service.createNote(
        title: 'Initial Title',
        initialContent: '# Initial Title\n\nInitial content',
      );

      await service.saveNote(note.id, '# Updated Title\n\nUpdated content with #newtag');

      // Verify fake storage has updated content
      final content = await storage.readContent(note.filePath);
      expect(content, contains('Updated content with #newtag'));

      // Verify DB matches updated metadata
      final notes = await db.query('notes', where: 'id = ?', whereArgs: [note.id]);
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('Updated Title'));

      final tags = await db.query('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      expect(tags.length, equals(1));
      expect(tags.first['tag'], equals('newtag'));
    });

    test('should delete note file and database index', () async {
      final note = await service.createNote(
        title: 'To Delete',
        initialContent: 'Content',
      );

      await service.deleteNote(note.id);

      // Verify file deleted from storage
      final fileExists = await storage.exists(note.filePath);
      expect(fileExists, isFalse);

      // Verify deleted from index
      final notes = await db.query('notes', where: 'id = ?', whereArgs: [note.id]);
      expect(notes, isEmpty);
    });

    test('should materialize ghost note and reuse its ID/filePath when creating a note with the same title', () async {
      // 1. Create a ghost note
      final ghostNote = await service.createGhostNote('My Ghost Note');
      
      // Verify it is created in the db as a ghost
      final ghostDbNotes = await db.query('notes', where: 'id = ?', whereArgs: [ghostNote.id]);
      expect(ghostDbNotes.length, equals(1));
      expect(ghostDbNotes.first['is_ghost'], equals(1));
      
      // 2. Create a note with the same title
      final materializedNote = await service.createNote(
        title: 'My Ghost Note',
        initialContent: '# My Ghost Note\n\nMaterialized content',
      );
      
      // Verify ID and filePath are reused
      expect(materializedNote.id, equals(ghostNote.id));
      expect(materializedNote.filePath, equals(ghostNote.filePath));
      
      // Verify file is written to storage
      final fileWritten = await storage.exists(materializedNote.filePath);
      expect(fileWritten, isTrue);
      
      // Verify database entry is updated to is_ghost = 0
      final dbNotes = await db.query('notes', where: 'id = ?', whereArgs: [materializedNote.id]);
      expect(dbNotes.length, equals(1));
      expect(dbNotes.first['is_ghost'], equals(0));
      
      // Verify no duplicate titles exist in the db
      final allWithTitle = await db.query('notes', where: 'LOWER(title) = ?', whereArgs: ['my ghost note']);
      expect(allWithTitle.length, equals(1));
    });
  });
}
