import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:meridian/core/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('meridian_migration_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Database migration from v3 to v4 preserves notes and creates new tables', () async {
    final dbPath = p.join(tempDir.path, '.meridian.db');

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

    // spatial_groups
    await upgradedDb.insert('spatial_groups', {
      'id': 'group-1',
      'name': 'Project Space',
      'color_hex': '#FF5733',
      'created_at': 300000,
    });
    final groups = await upgradedDb.query('spatial_groups');
    expect(groups.length, equals(1));
    expect(groups.first['id'], equals('group-1'));
    expect(groups.first['name'], equals('Project Space'));
    expect(groups.first['color_hex'], equals('#FF5733'));

    // spatial_group_nodes
    await upgradedDb.insert('spatial_group_nodes', {
      'group_id': 'group-1',
      'note_id': 'note-v3-1',
    });
    final groupNodes = await upgradedDb.query('spatial_group_nodes');
    expect(groupNodes.length, equals(1));
    expect(groupNodes.first['group_id'], equals('group-1'));
    expect(groupNodes.first['note_id'], equals('note-v3-1'));

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
}
