import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/adapters/local_vault_storage.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';

void main() {
  // Initialize FFI for local tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory tempDir;
  late NoteIngestionServiceImpl service;

  setUp(() async {
    // Open in-memory SQLite DB
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

          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_tags (
              note_id TEXT NOT NULL,
              tag TEXT NOT NULL,
              PRIMARY KEY (note_id, tag)
            )
          ''');
        },
      ),
    );

    // Create a temporary vault folder
    tempDir = await Directory.systemTemp.createTemp('prism_test_vault');
    
    // Initialize our VaultService
    service = NoteIngestionServiceImpl(
      getDb: () async => db,
      storage: LocalVaultStorage(),
      parser: MarkdownContentParser(),
      indexer: SqliteMetadataIndexer(),
      getVaultPath: () async => tempDir.path,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('NoteIngestionServiceImpl syncVault tests', () {
    test('should sync new file from disk to database', () async {
      // 1. Create a physical markdown note
      final file = File(p.join(tempDir.path, 'my-test-note.md'));
      await file.writeAsString('# My Test Title\n\nThis is a simple note #productivity');

      // 2. Trigger sync
      await service.syncVault(tempDir.path);

      // 3. Query notes from DB to assert it was inserted
      final notes = await db.query('notes');
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('My Test Title'));
      expect(notes.first['word_count'], equals(6));

      // Assert tags were synced
      final tags = await db.query('note_tags');
      expect(tags.length, equals(1));
      expect(tags.first['tag'], equals('productivity'));
    });

    test('should update existing database record when file is modified', () async {
      final file = File(p.join(tempDir.path, 'my-test-note.md'));
      await file.writeAsString('# Initial Title\n\nWord1');

      // First sync to insert the note
      await service.syncVault(tempDir.path);
      
      final notesBefore = await db.query('notes');
      expect(notesBefore.length, equals(1));
      expect(notesBefore.first['title'], equals('Initial Title'));
      expect(notesBefore.first['word_count'], equals(1));

      // Wait a moment, modify file, and update modification date
      // We explicitly set last modified to be 2 seconds in the future to ensure sync picks it up
      await file.writeAsString('# Updated Title\n\nWord1 Word2 Word3');
      final futureTime = DateTime.now().add(const Duration(seconds: 2));
      await file.setLastModified(futureTime);

      // Trigger sync again
      await service.syncVault(tempDir.path);

      final notesAfter = await db.query('notes');
      expect(notesAfter.length, equals(1));
      expect(notesAfter.first['title'], equals('Updated Title'));
      expect(notesAfter.first['word_count'], equals(3));
    });

    test('should automatically create Inbox folder and link Inbox note', () async {
      final file = File(p.join(tempDir.path, 'Inbox.md'));
      await file.writeAsString('# Inbox\n\n- [2026-06-02] Shared link');

      // Trigger sync
      await service.syncVault(tempDir.path);

      // Verify the note is in DB
      final notes = await db.query('notes');
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('Inbox'));

      // Verify Inbox virtual folder was automatically created
      final folders = await db.query('virtual_folders');
      expect(folders.length, equals(1));
      expect(folders.first['name'], equals('Inbox'));

      // Verify note is mapped to the folder
      final folderId = folders.first['id'];
      final noteId = notes.first['id'];
      final noteFolders = await db.query('note_folders');
      expect(noteFolders.length, equals(1));
      expect(noteFolders.first['note_id'], equals(noteId));
      expect(noteFolders.first['folder_id'], equals(folderId));
    });

    test('should NOT auto-categorize user-created notes named Inbox (e.g. inbox-uuid.md)', () async {
      final file = File(p.join(tempDir.path, 'inbox-530e788e-6701-4475-ac61.md'));
      await file.writeAsString('# Inbox\n\nUser custom content');

      // Trigger sync
      await service.syncVault(tempDir.path);

      // Verify note is in DB
      final notes = await db.query('notes');
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('Inbox'));

      // Verify no Inbox folder was automatically created for this note
      final folders = await db.query('virtual_folders');
      expect(folders, isEmpty);

      final noteFolders = await db.query('note_folders');
      expect(noteFolders, isEmpty);
    });

    test('should automatically create Tutorial folder and link welcome notes', () async {
      final file = File(p.join(tempDir.path, 'Welcome to Prism.md'));
      await file.writeAsString('# Welcome to Prism\n\nWelcome text');

      // Trigger sync
      await service.syncVault(tempDir.path);

      // Verify the note is in DB
      final notes = await db.query('notes');
      expect(notes.length, equals(1));
      expect(notes.first['title'], equals('Welcome to Prism'));

      // Verify Tutorial virtual folder was automatically created
      final folders = await db.query('virtual_folders');
      expect(folders.length, equals(1));
      expect(folders.first['name'], equals('Tutorial'));

      // Verify note is mapped to the folder
      final folderId = folders.first['id'];
      final noteId = notes.first['id'];
      final noteFolders = await db.query('note_folders');
      expect(noteFolders.length, equals(1));
      expect(noteFolders.first['note_id'], equals(noteId));
      expect(noteFolders.first['folder_id'], equals(folderId));
    });
  });
}
