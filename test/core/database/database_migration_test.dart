import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_migration_test');
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabase();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Database migration from v3 to v4 preserves notes and creates new tables', () async {
    final dbPath = p.join(tempDir.path, '.prism.db');

    // 1. Initialize a Version 3 Database manually
    final v3Db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          // Create v3 notes table
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

          // Create v3 virtual_folders table
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
        },
      ),
    );

    // Insert dummy note in v3 database
    await v3Db.insert('notes', {
      'id': 'note-v3-1',
      'title': 'V3 Saved Note',
      'file_path': 'note-v3-1.md',
      'word_count': 15,
      'created_at': 100000,
      'updated_at': 200000,
      'is_ghost': 0,
      'is_daily': 0,
      'is_conflicted': 0,
    });

    // Close the v3 connection
    await v3Db.close();

    // 2. Open via DatabaseHelper (which uses version 4 and onUpgrade sequential logic)
    final helper = DatabaseHelper.instance;
    final upgradedDb = await helper.openDatabaseForPath(tempDir.path);

    // 3. Verify note data is preserved
    final notes = await upgradedDb.query('notes', where: 'id = ?', whereArgs: ['note-v3-1']);
    expect(notes, isNotEmpty);
    expect(notes.first['title'], equals('V3 Saved Note'));

    // 4. Verify version 4 tables are created and accept inserts/queries
    
    // graph_node_positions
    await upgradedDb.insert('graph_node_positions', {
      'note_id': 'note-v3-1',
      'x': 100.5,
      'y': -200.5,
      'is_pinned': 1,
    });
    final positions = await upgradedDb.query('graph_node_positions');
    expect(positions.length, equals(1));
    expect(positions.first['note_id'], equals('note-v3-1'));
    expect(positions.first['x'], equals(100.5));
    expect(positions.first['y'], equals(-200.5));
    expect(positions.first['is_pinned'], equals(1));

    // Verify spatial groups tables are dropped on upgrade to version 6
    final spatialGroupsTableExists = Sqflite.firstIntValue(await upgradedDb.rawQuery(
      "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='spatial_groups'"
    ));
    expect(spatialGroupsTableExists, equals(0));

    final spatialGroupNodesTableExists = Sqflite.firstIntValue(await upgradedDb.rawQuery(
      "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='spatial_group_nodes'"
    ));
    expect(spatialGroupNodesTableExists, equals(0));

    // audio_bookmarks
    await upgradedDb.insert('audio_bookmarks', {
      'id': 'bookmark-1',
      'note_id': 'note-v3-1',
      'attachment_path': 'attachments/audio_1.m4a',
      'timestamp_ms': 5000,
      'annotation_text': 'Important insight',
      'created_at': 400000,
    });
    final bookmarks = await upgradedDb.query('audio_bookmarks');
    expect(bookmarks.length, equals(1));
    expect(bookmarks.first['id'], equals('bookmark-1'));
    expect(bookmarks.first['note_id'], equals('note-v3-1'));
    expect(bookmarks.first['attachment_path'], equals('attachments/audio_1.m4a'));
    expect(bookmarks.first['timestamp_ms'], equals(5000));
    expect(bookmarks.first['annotation_text'], equals('Important insight'));

    // Close database connection
    await helper.closeDatabaseConnection(upgradedDb);
  });

  test('Database migration from v4 to v5 preserves notes and adds snippet column', () async {
    final dbPath = p.join(tempDir.path, '.prism.db');

    // 1. Initialize a Version 4 Database manually
    final v4Db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          // Create v4 notes table (no snippet column)
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
        },
      ),
    );

    // Insert dummy note in v4 database
    await v4Db.insert('notes', {
      'id': 'note-v4-1',
      'title': 'V4 Saved Note',
      'file_path': 'note-v4-1.md',
      'word_count': 15,
      'created_at': 100000,
      'updated_at': 200000,
      'is_ghost': 0,
      'is_daily': 0,
      'is_conflicted': 0,
    });

    await v4Db.close();

    // 2. Open via DatabaseHelper (which upgrades to version 5)
    final helper = DatabaseHelper.instance;
    final upgradedDb = await helper.openDatabaseForPath(tempDir.path);

    // 3. Verify note data is preserved and snippet column exists with default value
    final notes = await upgradedDb.query('notes', where: 'id = ?', whereArgs: ['note-v4-1']);
    expect(notes, isNotEmpty);
    expect(notes.first['title'], equals('V4 Saved Note'));
    expect(notes.first['snippet'], equals(''));

    // Close database connection
    await helper.closeDatabaseConnection(upgradedDb);
  });

  test('Database migration from v7 to v8 creates notes_fts with body, covering indexes, and populates existing notes', () async {
    final dbPath = p.join(tempDir.path, '.prism.db');

    // 1. Initialize a Version 7 Database manually
    final v7Db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 7,
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
            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
              id,
              title,
              tokenize = 'porter'
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS audio_bookmarks (
              id TEXT PRIMARY KEY,
              note_id TEXT NOT NULL,
              attachment_path TEXT NOT NULL,
              timestamp_ms INTEGER NOT NULL,
              annotation_text TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    // Insert note in v7 database
    await v7Db.insert('notes', {
      'id': 'note-v7-1',
      'title': 'V7 Saved Note',
      'file_path': 'note-v7-1.md',
      'word_count': 25,
      'created_at': 100000,
      'updated_at': 200000,
      'is_ghost': 0,
      'is_daily': 0,
      'is_conflicted': 0,
      'snippet': 'Snippet of v7 note',
    });

    await v7Db.close();

    // 2. Open via DatabaseHelper (which upgrades to v8)
    final helper = DatabaseHelper.instance;
    final upgradedDb = await helper.openDatabaseForPath(tempDir.path);

    // 3. Verify notes_fts has body column and was populated from notes snippet
    final ftsMatches = await upgradedDb.rawQuery(
      'SELECT id, title, body FROM notes_fts WHERE notes_fts MATCH ?',
      ['"Snippet"*'],
    );
    expect(ftsMatches, isNotEmpty);
    expect(ftsMatches.first['id'], equals('note-v7-1'));

    // 4. Verify v8 covering indexes exist
    final indexList = await upgradedDb.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name IN ('idx_notes_created_at', 'idx_notes_non_daily_updated', 'idx_audio_bookmarks_note_attachment')",
    );
    final indexNames = indexList.map((row) => row['name'] as String).toSet();
    expect(indexNames, containsAll([
      'idx_notes_created_at',
      'idx_notes_non_daily_updated',
      'idx_audio_bookmarks_note_attachment',
    ]));

    await helper.closeDatabaseConnection(upgradedDb);
  });
}
