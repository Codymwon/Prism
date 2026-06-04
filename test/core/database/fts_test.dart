import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meridian/core/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('meridian_fts_test_vault');
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
      // 1. Insert a real note (is_ghost = 0)
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('notes', {
        'id': 'real-note-1',
        'title': 'Real Note Title One',
        'file_path': '/vault/real-1.md',
        'word_count': 120,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 0,
        'is_daily': 0,
      });

      // Verify it is indexed in notes_fts
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['real-note-1']);
      expect(ftsMatches.length, equals(1));
      expect(ftsMatches.first['title'], equals('Real Note Title One'));

      // 2. Insert a ghost note (is_ghost = 1)
      await db.insert('notes', {
        'id': 'ghost-note-1',
        'title': 'Ghost Note Title One',
        'file_path': '/vault/ghost-1.md',
        'word_count': 0,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 1,
        'is_daily': 0,
      });

      // Verify that the ghost note is NOT in the FTS index
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-1']);
      expect(ftsMatches, isEmpty);
    });

    test('should index ghost note in notes_fts when it is materialized (updated to is_ghost = 0)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 1. Insert a ghost note (is_ghost = 1)
      await db.insert('notes', {
        'id': 'ghost-note-2',
        'title': 'Ghost Note Title Two',
        'file_path': '/vault/ghost-2.md',
        'word_count': 0,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 1,
        'is_daily': 0,
      });

      // Verify it is not indexed
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-2']);
      expect(ftsMatches, isEmpty);

      // 2. Materialize the ghost note (update is_ghost to 0)
      await db.update('notes', {
        'is_ghost': 0,
        'word_count': 50,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, where: 'id = ?', whereArgs: ['ghost-note-2']);

      // Verify it is now indexed in notes_fts
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['ghost-note-2']);
      expect(ftsMatches.length, equals(1));
      expect(ftsMatches.first['title'], equals('Ghost Note Title Two'));
    });

    test('should remove note from notes_fts when note is deleted from notes table', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert real note
      await db.insert('notes', {
        'id': 'note-to-delete',
        'title': 'Note To Delete',
        'file_path': '/vault/delete-me.md',
        'word_count': 10,
        'created_at': now,
        'updated_at': now,
        'is_ghost': 0,
        'is_daily': 0,
      });

      // Verify indexed
      var ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['note-to-delete']);
      expect(ftsMatches.length, equals(1));

      // 2. Delete the note
      await db.delete('notes', where: 'id = ?', whereArgs: ['note-to-delete']);

      // Verify removed from FTS
      ftsMatches = await db.query('notes_fts', where: 'id = ?', whereArgs: ['note-to-delete']);
      expect(ftsMatches, isEmpty);
    });
  });
}
