import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late DatabaseHelper helper;
  late Database db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('prism_cascade_test');
    helper = DatabaseHelper.instance;
    db = await helper.openDatabaseForPath(tempDir.path);
  });

  tearDown(() async {
    await helper.closeDatabaseConnection(db);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Cascade delete works correctly for version 4 tables', () async {
    // 1. Insert two notes
    await db.insert('notes', {
      'id': 'note-1',
      'title': 'Cascade Source Note',
      'file_path': 'note-1.md',
      'word_count': 100,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    await db.insert('notes', {
      'id': 'note-2',
      'title': 'Other Note',
      'file_path': 'note-2.md',
      'word_count': 200,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    // 2. Insert group and map note-1 to it
    await db.insert('spatial_groups', {
      'id': 'group-1',
      'name': 'Spatial Group 1',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    await db.insert('spatial_group_nodes', {
      'group_id': 'group-1',
      'note_id': 'note-1',
    });

    // 3. Insert coordinates for note-1 and note-2
    await db.insert('graph_node_positions', {
      'note_id': 'note-1',
      'x': 50.0,
      'y': 50.0,
      'is_pinned': 1,
    });

    await db.insert('graph_node_positions', {
      'note_id': 'note-2',
      'x': 100.0,
      'y': 100.0,
      'is_pinned': 0,
    });

    // 4. Insert audio bookmarks for note-1 and note-2
    await db.insert('audio_bookmarks', {
      'id': 'bookmark-1',
      'note_id': 'note-1',
      'attachment_path': 'attachments/audio_1.m4a',
      'timestamp_ms': 12000,
      'annotation_text': 'Key Note 1 bookmark',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    await db.insert('audio_bookmarks', {
      'id': 'bookmark-2',
      'note_id': 'note-2',
      'attachment_path': 'attachments/audio_2.m4a',
      'timestamp_ms': 24000,
      'annotation_text': 'Key Note 2 bookmark',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Verify all inserted records exist before deletion
    expect((await db.query('notes')).length, equals(2));
    expect((await db.query('spatial_group_nodes')).length, equals(1));
    expect((await db.query('graph_node_positions')).length, equals(2));
    expect((await db.query('audio_bookmarks')).length, equals(2));

    // 5. Delete note-1
    await db.delete('notes', where: 'id = ?', whereArgs: ['note-1']);

    // 6. Verify cascade delete occurred
    
    // note-1 coordinates should be deleted, note-2 coordinates should be preserved
    final coordinates = await db.query('graph_node_positions');
    expect(coordinates.length, equals(1));
    expect(coordinates.first['note_id'], equals('note-2'));

    // note-1 group mapping should be deleted
    final groupMappings = await db.query('spatial_group_nodes');
    expect(groupMappings, isEmpty);

    // spatial_group itself should still exist
    final groups = await db.query('spatial_groups');
    expect(groups.length, equals(1));

    // note-1 bookmark should be deleted, note-2 bookmark should be preserved
    final bookmarks = await db.query('audio_bookmarks');
    expect(bookmarks.length, equals(1));
    expect(bookmarks.first['note_id'], equals('note-2'));

    // 7. Test cascade delete from spatial_groups side
    // Insert spatial group 2
    await db.insert('spatial_groups', {
      'id': 'group-2',
      'name': 'Spatial Group 2',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Map note-2 to group-2
    await db.insert('spatial_group_nodes', {
      'group_id': 'group-2',
      'note_id': 'note-2',
    });

    // Verify it is there
    expect((await db.query('spatial_group_nodes')).length, equals(1));

    // Delete group-2
    await db.delete('spatial_groups', where: 'id = ?', whereArgs: ['group-2']);

    // Verify mapping is deleted automatically
    expect((await db.query('spatial_group_nodes')), isEmpty);
  });
}
