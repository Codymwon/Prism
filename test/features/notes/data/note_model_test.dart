import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/features/notes/data/note_model.dart';
import 'package:meridian/features/folders/data/folder_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Context
// ─────────────────────────────────────────────────────────────────────────────
//
// Bug: "type 'bool' is not a subtype of type 'double?' in type cast"
//
// Happens when:
//   1. A note is IN a folder
//   2. The note has #tags
//   3. The folder view accordion is expanded
//
// Root cause (two separate sites — both rawQuery JOINs):
//
//   1. getAllFolders() rawQuery (LEFT JOIN note_folders):
//        SELECT f.*, COUNT(nf.note_id) as note_count FROM virtual_folders f
//        LEFT JOIN note_folders nf ON nf.folder_id = f.id
//        GROUP BY f.id ...
//      → VirtualFolder.fromMap crashed on: created_at as int / sort_order as int? / note_count as int?
//        because sqflite returns 0 as bool false, timestamps as double
//
//   2. getNotesInFolder() rawQuery (JOIN note_folders):
//        SELECT n.* FROM notes n JOIN note_folders nf ON nf.note_id = n.id
//      → Note.fromMap crashed on: word_count as int? / created_at as int / updated_at as int
//        because of the same sqflite type variability
//
// Why it only crashed for TAGGED notes:
//   - Notes without tags in folder view → accordion renders without _buildTagBadge,
//     fewer providers are invoked, so the crash in VirtualFolder.fromMap was masked.
//   - When a note gets a #tag, `uniqueTagsProvider` and `noteDetailsProvider` trigger
//     a full widget tree rebuild that exercises the folder-data path more deeply,
//     finally surfacing the VirtualFolder.fromMap crash.
//   - Notes in the flat list are loaded by getAllNotes() (db.query, clean types)
//     which never hit the rawQuery JOIN type issue.
// ─────────────────────────────────────────────────────────────────────────────

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Simulates the map returned by sqflite for getAllFolders() rawQuery JOIN.
/// On Android sqflite: INTEGER 0 → bool false, timestamps → double.
Map<String, dynamic> _folderRawQueryResult({
  String id = 'folder-001',
  String name = 'My Folder',
  dynamic createdAt = 1717000000000.0, // timestamp as double (JOIN variant)
  dynamic sortOrder = false,           // 0 returned as bool
  dynamic noteCount = false,           // COUNT(*) returned as bool when 0
}) {
  return {
    'id': id,
    'name': name,
    'color_hex': '#7C6FF7',
    'icon': 'folder',
    'created_at': createdAt,
    'sort_order': sortOrder,
    'note_count': noteCount,
  };
}

/// Simulates the map returned by sqflite for getNotesInFolder() rawQuery JOIN.
/// A note WITH #tags: has non-zero word_count, all numerics may be wrong types.
Map<String, dynamic> _taggedNoteInFolderRawQueryResult({
  String id = 'note-tagged-001',
  dynamic wordCount = false,           // 0 returned as bool
  dynamic createdAt = 1717000000000.0, // timestamp as double
  dynamic updatedAt = 1717000001000.0,
}) {
  return {
    'id': id,
    'title': 'Note With #tag',
    'file_path': '/vault/note-with-tag.md',
    'word_count': wordCount,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_ghost': false,
    'is_daily': false,
    'daily_date': null,
    'is_conflicted': false,
    'original_note_id': null,
  };
}

void main() {
  // ── Folder model crash (the trigger for the #tag crash chain) ──────────────

  group('Folder view — VirtualFolder.fromMap rawQuery JOIN type safety', () {
    test(
      'CRASH SITE 1: note_count=false (COUNT(*) of 0 notes → bool) must not throw',
      () {
        // This is what sqflite returns from the LEFT JOIN when a folder has 0 notes.
        // Before the fix: false as int? → "type 'bool' is not a subtype of type 'int?'"
        final map = _folderRawQueryResult(noteCount: false);
        expect(() => VirtualFolder.fromMap(map), returnsNormally);
        expect(VirtualFolder.fromMap(map).noteCount, 0);
      },
    );

    test(
      'CRASH SITE 1: sort_order=false (INTEGER 0 → bool from JOIN) must not throw',
      () {
        final map = _folderRawQueryResult(sortOrder: false);
        expect(() => VirtualFolder.fromMap(map), returnsNormally);
        expect(VirtualFolder.fromMap(map).sortOrder, 0);
      },
    );

    test(
      'CRASH SITE 1: created_at as double (rawQuery timestamp variant) must not throw',
      () {
        final map = _folderRawQueryResult(createdAt: 1717000000000.0);
        expect(() => VirtualFolder.fromMap(map), returnsNormally);
        expect(
          VirtualFolder.fromMap(map).createdAt,
          DateTime.fromMillisecondsSinceEpoch(1717000000000),
        );
      },
    );

    test(
      'Full JOIN-style folder map — all bad types at once',
      () {
        final map = _folderRawQueryResult(
          createdAt: 1717000000000.0, // double
          sortOrder: false,           // bool
          noteCount: false,           // bool
        );
        expect(() => VirtualFolder.fromMap(map), returnsNormally);
        final folder = VirtualFolder.fromMap(map);
        expect(folder.noteCount, 0);
        expect(folder.sortOrder, 0);
      },
    );

    test('note_count as int works (clean db.query variant)', () {
      final map = _folderRawQueryResult(noteCount: 3, sortOrder: 2, createdAt: 1717000000000);
      expect(VirtualFolder.fromMap(map).noteCount, 3);
      expect(VirtualFolder.fromMap(map).sortOrder, 2);
    });

    test('note_count as double works', () {
      expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: 5.0)).noteCount, 5);
    });
  });

  // ── Note model crash (secondary crash in same folder note flow) ────────────

  group('Folder view — Note.fromMap rawQuery JOIN type safety', () {
    test(
      'CRASH SITE 2: word_count=false + timestamps as double for note with #tags',
      () {
        final map = _taggedNoteInFolderRawQueryResult(
          wordCount: false,
          createdAt: 1717000000000.0,
          updatedAt: 1717000001000.0,
        );
        expect(() => Note.fromMap(map), returnsNormally);

        final note = Note.fromMap(map);
        expect(note.wordCount, 0);
        expect(note.createdAt, DateTime.fromMillisecondsSinceEpoch(1717000000000));
      },
    );

    test(
      'Note with actual content/tags: word_count as double (rawQuery JOIN returns 285.0)',
      () {
        final map = _taggedNoteInFolderRawQueryResult(wordCount: 285.0);
        expect(Note.fromMap(map).wordCount, 285);
      },
    );
  });

  // ── Why flat-list notes with tags were fine ────────────────────────────────

  group('Flat list — getAllNotes() returns clean types, never crashes', () {
    test('Note from db.query (not rawQuery JOIN) — all int types, always fine', () {
      final map = {
        'id': 'flat-note-001',
        'title': 'Flat Note With #tag',
        'file_path': '/vault/flat.md',
        'word_count': 0,          // int — clean
        'created_at': 1717000000000, // int — clean
        'updated_at': 1717000001000,
        'is_ghost': 0,
        'is_daily': 0,
        'daily_date': null,
        'is_conflicted': 0,
        'original_note_id': null,
      };
      expect(() => Note.fromMap(map), returnsNormally);
    });
  });

  // ── Full type matrix for both models ──────────────────────────────────────

  group('Note.fromMap — complete sqflite type matrix', () {
    test('word_count: false  → 0', () => expect(Note.fromMap(_taggedNoteInFolderRawQueryResult(wordCount: false)).wordCount, 0));
    test('word_count: true   → 1', () => expect(Note.fromMap(_taggedNoteInFolderRawQueryResult(wordCount: true)).wordCount, 1));
    test('word_count: 42.0   → 42', () => expect(Note.fromMap(_taggedNoteInFolderRawQueryResult(wordCount: 42.0)).wordCount, 42));
    test('word_count: 0      → 0', () => expect(Note.fromMap(_taggedNoteInFolderRawQueryResult(wordCount: 0)).wordCount, 0));
    test('word_count: null   → 0', () => expect(Note.fromMap(_taggedNoteInFolderRawQueryResult(wordCount: null)).wordCount, 0));
    test('created_at: double → DateTime', () {
      expect(
        Note.fromMap(_taggedNoteInFolderRawQueryResult(createdAt: 1717000000000.0)).createdAt,
        DateTime.fromMillisecondsSinceEpoch(1717000000000),
      );
    });
  });

  group('VirtualFolder.fromMap — complete sqflite type matrix', () {
    test('note_count: false  → 0', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: false)).noteCount, 0));
    test('note_count: true   → 1', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: true)).noteCount, 1));
    test('note_count: 5.0    → 5', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: 5.0)).noteCount, 5));
    test('note_count: 3      → 3', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: 3)).noteCount, 3));
    test('note_count: null   → 0', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(noteCount: null)).noteCount, 0));
    test('sort_order: false  → 0', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(sortOrder: false)).sortOrder, 0));
    test('sort_order: 2.0    → 2', () => expect(VirtualFolder.fromMap(_folderRawQueryResult(sortOrder: 2.0)).sortOrder, 2));
    test('created_at: double → DateTime', () {
      expect(
        VirtualFolder.fromMap(_folderRawQueryResult(createdAt: 1717000000000.0)).createdAt,
        DateTime.fromMillisecondsSinceEpoch(1717000000000),
      );
    });
  });
}
