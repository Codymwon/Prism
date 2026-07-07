import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/features/editor/data/audio_bookmark_repository.dart';
import 'package:prism/features/editor/data/audio_bookmark_model.dart';

// ---------------------------------------------------------------------------
// Helper: create and migrate the schema to version 4 in-memory
// ---------------------------------------------------------------------------
Future<Database> _openTestDb() {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
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

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_audio_bookmarks_note ON audio_bookmarks(note_id)',
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Helper: insert a dummy note so FK constraints are satisfied
// ---------------------------------------------------------------------------
Future<void> _insertNote(Database db, String noteId) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  await db.insert('notes', {
    'id': noteId,
    'title': 'Test Note',
    'file_path': '/vault/$noteId.md',
    'word_count': 0,
    'created_at': now,
    'updated_at': now,
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AudioBookmarkRepository repo;

  setUp(() async {
    db = await _openTestDb();
    // Use the default constructor with the factory callback
    repo = AudioBookmarkRepository(() async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AudioBookmarkRepository', () {
    const noteId = 'note-001';
    const attachmentPath = 'attachments/recording.m4a';

    AudioBookmark makeBookmark({
      String id = 'bm-1',
      int timestampMs = 5000,
      String annotation = 'My first bookmark',
    }) {
      return AudioBookmark(
        id: id,
        noteId: noteId,
        attachmentPath: attachmentPath,
        timestampMs: timestampMs,
        annotationText: annotation,
        createdAt: DateTime.fromMillisecondsSinceEpoch(1000000),
      );
    }

    test('returns empty list when no bookmarks exist for attachment', () async {
      await _insertNote(db, noteId);

      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(bookmarks, isEmpty);
    });

    test('addBookmark persists a bookmark that can be retrieved', () async {
      await _insertNote(db, noteId);
      final bookmark = makeBookmark();

      await repo.addBookmark(bookmark);
      final result =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(result, hasLength(1));
      expect(result.first.id, equals('bm-1'));
      expect(result.first.timestampMs, equals(5000));
      expect(result.first.annotationText, equals('My first bookmark'));
    });

    test('getBookmarksForAttachment returns bookmarks sorted by timestampMs ascending', () async {
      await _insertNote(db, noteId);

      await repo.addBookmark(makeBookmark(id: 'bm-late', timestampMs: 30000, annotation: 'Late'));
      await repo.addBookmark(makeBookmark(id: 'bm-early', timestampMs: 2000, annotation: 'Early'));
      await repo.addBookmark(makeBookmark(id: 'bm-mid', timestampMs: 15000, annotation: 'Mid'));

      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(bookmarks, hasLength(3));
      expect(bookmarks[0].id, equals('bm-early'));
      expect(bookmarks[1].id, equals('bm-mid'));
      expect(bookmarks[2].id, equals('bm-late'));
    });

    test('getBookmarksForAttachment only returns bookmarks for the specified attachment', () async {
      await _insertNote(db, noteId);

      const otherPath = 'attachments/other.m4a';
      await repo.addBookmark(makeBookmark(id: 'bm-match'));
      await repo.addBookmark(AudioBookmark(
        id: 'bm-other',
        noteId: noteId,
        attachmentPath: otherPath,
        timestampMs: 1000,
        annotationText: 'Other attachment',
        createdAt: DateTime.now(),
      ));

      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(bookmarks, hasLength(1));
      expect(bookmarks.first.id, equals('bm-match'));
    });

    test('deleteBookmark removes the specified bookmark', () async {
      await _insertNote(db, noteId);
      await repo.addBookmark(makeBookmark(id: 'bm-delete'));
      await repo.addBookmark(makeBookmark(id: 'bm-keep', timestampMs: 10000));

      // Verify both exist
      var bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);
      expect(bookmarks, hasLength(2));

      // Delete one
      await repo.deleteBookmark('bm-delete');
      bookmarks = await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(bookmarks, hasLength(1));
      expect(bookmarks.first.id, equals('bm-keep'));
    });

    test('deleteBookmark is a no-op for a non-existent id', () async {
      await _insertNote(db, noteId);
      await repo.addBookmark(makeBookmark());

      // Deleting a non-existent ID must not throw
      await expectLater(
        repo.deleteBookmark('non-existent-id'),
        completes,
      );

      // Original bookmark must still be there
      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);
      expect(bookmarks, hasLength(1));
    });

    test('addBookmark with REPLACE semantics updates an existing bookmark when id collides', () async {
      await _insertNote(db, noteId);
      final original =
          makeBookmark(id: 'bm-replace', timestampMs: 1000, annotation: 'Original');
      await repo.addBookmark(original);

      final updated =
          makeBookmark(id: 'bm-replace', timestampMs: 9999, annotation: 'Updated');
      await repo.addBookmark(updated);

      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      // Should still be only 1 (REPLACE updated the row)
      expect(bookmarks, hasLength(1));
      expect(bookmarks.first.timestampMs, equals(9999));
      expect(bookmarks.first.annotationText, equals('Updated'));
    });

    test('getBookmarksForAttachment does not return bookmarks for a different noteId', () async {
      await _insertNote(db, noteId);
      await _insertNote(db, 'note-002');

      await repo.addBookmark(makeBookmark(id: 'bm-note1'));
      await repo.addBookmark(AudioBookmark(
        id: 'bm-note2',
        noteId: 'note-002',
        attachmentPath: attachmentPath,
        timestampMs: 1000,
        annotationText: 'Different note',
        createdAt: DateTime.now(),
      ));

      final bookmarks =
          await repo.getBookmarksForAttachment(noteId, attachmentPath);

      expect(bookmarks, hasLength(1));
      expect(bookmarks.first.id, equals('bm-note1'));
    });
  });
}
