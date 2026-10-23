import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/database/prism_metadata_store.dart';

// ─── Shared schema helpers ─────────────────────────────────────────────────────
// Foreign keys are intentionally omitted here so tests are self-contained
// and do not depend on the notes table being populated.
Future<void> _createSchema(Database db) async {
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
    CREATE TABLE IF NOT EXISTS graph_node_positions (
      note_id TEXT PRIMARY KEY,
      x REAL NOT NULL,
      y REAL NOT NULL,
      is_pinned INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS audio_bookmarks (
      id TEXT PRIMARY KEY,
      note_id TEXT NOT NULL,
      attachment_path TEXT NOT NULL,
      timestamp_ms INTEGER NOT NULL,
      annotation_text TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory tempDir;
  late PrismMetadataStore store;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => _createSchema(db),
      ),
    );
    tempDir = await Directory.systemTemp.createTemp('prism_sidecar_test_');
    store = PrismMetadataStore();
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 1 — Tracer Bullet
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 1 — Virtual Folder round-trip', () {
    test('flushFromDatabase writes sidecar and loadIntoDatabase restores it', () async {
      // Arrange: insert one virtual folder
      await db.insert('virtual_folders', {
        'id': 'folder-1',
        'name': 'Inbox',
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': 1_000_000,
        'sort_order': 0,
      });

      // Act: flush to sidecar
      await store.flushFromDatabase(db, tempDir.path);

      // Assert sidecar file was created
      final sidecar = File(p.join(tempDir.path, '.prism-metadata.json'));
      expect(await sidecar.exists(), isTrue, reason: 'Sidecar file must be written');

      // Wipe the DB table to simulate a rebuild/recovery scenario
      await db.delete('virtual_folders');
      expect((await db.query('virtual_folders')).length, 0);

      // Act: reload from sidecar
      await store.loadIntoDatabase(db, tempDir.path);

      // Assert folder was restored
      final folders = await db.query('virtual_folders');
      expect(folders.length, 1);
      expect(folders.first['id'], 'folder-1');
      expect(folders.first['name'], 'Inbox');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 2 — Missing sidecar is a no-op
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 2 — Missing sidecar', () {
    test('loadIntoDatabase does not throw and leaves DB unchanged when sidecar absent', () async {
      await db.insert('virtual_folders', {
        'id': 'folder-existing',
        'name': 'Existing',
        'color_hex': '#FFFFFF',
        'icon': 'folder',
        'created_at': 500,
        'sort_order': 0,
      });

      // No sidecar has been written — call loadIntoDatabase on a fresh directory
      await expectLater(
        store.loadIntoDatabase(db, tempDir.path),
        completes,
        reason: 'loadIntoDatabase must not throw when sidecar is absent',
      );

      // DB must be untouched
      final folders = await db.query('virtual_folders');
      expect(folders.length, 1, reason: 'Existing row must survive a no-op load');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 3 — All Virtual Folder fields are preserved
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 3 — Virtual Folder field fidelity', () {
    test('all folder fields survive a flush → load round-trip', () async {
      await db.insert('virtual_folders', {
        'id': 'folder-full',
        'name': 'Projects',
        'color_hex': '#FF5733',
        'icon': 'star',
        'created_at': 9_999_999,
        'sort_order': 42,
      });

      await store.flushFromDatabase(db, tempDir.path);
      await db.delete('virtual_folders');
      await store.loadIntoDatabase(db, tempDir.path);

      final row = (await db.query('virtual_folders')).first;
      expect(row['id'], 'folder-full');
      expect(row['name'], 'Projects');
      expect(row['color_hex'], '#FF5733');
      expect(row['icon'], 'star');
      expect(row['created_at'], 9_999_999);
      expect(row['sort_order'], 42);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 4 — Note-folder mappings round-trip
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 4 — Note-folder mappings', () {
    test('note_folders are flushed and restored correctly', () async {
      await db.insert('virtual_folders', {
        'id': 'f1',
        'name': 'Work',
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': 1,
        'sort_order': 0,
      });
      await db.insert('note_folders', {'note_id': 'note-a', 'folder_id': 'f1'});
      await db.insert('note_folders', {'note_id': 'note-b', 'folder_id': 'f1'});

      await store.flushFromDatabase(db, tempDir.path);
      await db.delete('note_folders');
      await db.delete('virtual_folders');

      await store.loadIntoDatabase(db, tempDir.path);

      final mappings = await db.query('note_folders', orderBy: 'note_id ASC');
      expect(mappings.length, 2);
      expect(mappings[0]['note_id'], 'note-a');
      expect(mappings[0]['folder_id'], 'f1');
      expect(mappings[1]['note_id'], 'note-b');
      expect(mappings[1]['folder_id'], 'f1');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 5 — Graph pins round-trip
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 5 — Graph pins', () {
    test('graph_node_positions (x, y, is_pinned) survive a round-trip', () async {
      await db.insert('graph_node_positions', {
        'note_id': 'note-pinned',
        'x': 123.45,
        'y': -67.89,
        'is_pinned': 1,
      });

      await store.flushFromDatabase(db, tempDir.path);
      await db.delete('graph_node_positions');
      await store.loadIntoDatabase(db, tempDir.path);

      final pins = await db.query('graph_node_positions');
      expect(pins.length, 1);
      expect(pins.first['note_id'], 'note-pinned');
      expect((pins.first['x'] as num).toDouble(), closeTo(123.45, 0.001));
      expect((pins.first['y'] as num).toDouble(), closeTo(-67.89, 0.001));
      expect(pins.first['is_pinned'], 1);
    });
  });



  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 8 — Sidecar is source of truth (replaces stale SQLite rows)
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 8 — Sidecar overwrites stale SQLite state', () {
    test('loadIntoDatabase replaces existing rows with sidecar content', () async {
      // Flush a known good state to sidecar
      await db.insert('virtual_folders', {
        'id': 'folder-canon',
        'name': 'Canonical',
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': 1,
        'sort_order': 0,
      });
      await store.flushFromDatabase(db, tempDir.path);

      // Manually corrupt the DB (simulates divergence after a DB rebuild)
      await db.delete('virtual_folders');
      await db.insert('virtual_folders', {
        'id': 'folder-stale',
        'name': 'Stale Row',
        'color_hex': '#000000',
        'icon': 'bug',
        'created_at': 9,
        'sort_order': 99,
      });

      // Load sidecar — it should win
      await store.loadIntoDatabase(db, tempDir.path);

      final folders = await db.query('virtual_folders');
      expect(folders.length, 1, reason: 'Only sidecar row should survive');
      expect(folders.first['id'], 'folder-canon');
      expect(folders.first['name'], 'Canonical');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 9 — Atomic writes (temp file then rename)
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 9 — Atomic write', () {
    test('no .tmp file is left behind after a successful flush', () async {
      await db.insert('virtual_folders', {
        'id': 'f1',
        'name': 'Test',
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': 1,
        'sort_order': 0,
      });

      await store.flushFromDatabase(db, tempDir.path);

      final tmpFile = File(p.join(tempDir.path, '.prism-metadata.json.tmp'));
      expect(
        await tmpFile.exists(),
        isFalse,
        reason: 'Temp file must be cleaned up (renamed to final path)',
      );

      final sidecar = File(p.join(tempDir.path, '.prism-metadata.json'));
      expect(await sidecar.exists(), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 10 — Corrupt / invalid JSON is handled gracefully
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 10 — Corrupt sidecar', () {
    test('loadIntoDatabase does not throw and leaves DB unchanged on invalid JSON', () async {
      // Write a corrupt sidecar
      final sidecar = File(p.join(tempDir.path, '.prism-metadata.json'));
      await sidecar.writeAsString('{ this is not valid json !!!');

      await db.insert('virtual_folders', {
        'id': 'f-safe',
        'name': 'Safe',
        'color_hex': '#7C6FF7',
        'icon': 'folder',
        'created_at': 1,
        'sort_order': 0,
      });

      // Must not throw
      await expectLater(
        store.loadIntoDatabase(db, tempDir.path),
        completes,
        reason: 'Corrupt sidecar must be handled gracefully',
      );

      // DB must be untouched
      final folders = await db.query('virtual_folders');
      expect(folders.length, 1, reason: 'DB must be unchanged after corrupt sidecar load');
      expect(folders.first['id'], 'f-safe');
    });

    test('loadIntoDatabase handles an empty sidecar file gracefully', () async {
      final sidecar = File(p.join(tempDir.path, '.prism-metadata.json'));
      await sidecar.writeAsString('');

      await expectLater(
        store.loadIntoDatabase(db, tempDir.path),
        completes,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cycle 11 — Audio bookmarks round-trip
  // ══════════════════════════════════════════════════════════════════════════
  group('Cycle 11 — Audio bookmarks round-trip', () {
    test('audio_bookmarks survive a flush → load round-trip', () async {
      await db.insert('audio_bookmarks', {
        'id': 'bm-001',
        'note_id': 'note-123',
        'attachment_path': 'attachments/memo_2026.m4a',
        'timestamp_ms': 42000,
        'annotation_text': 'Key discussion on architecture',
        'created_at': 1700000000000,
      });

      await store.flushFromDatabase(db, tempDir.path);
      await db.delete('audio_bookmarks');
      expect((await db.query('audio_bookmarks')).length, 0);

      await store.loadIntoDatabase(db, tempDir.path);

      final bookmarks = await db.query('audio_bookmarks');
      expect(bookmarks.length, 1);
      final bm = bookmarks.first;
      expect(bm['id'], 'bm-001');
      expect(bm['note_id'], 'note-123');
      expect(bm['attachment_path'], 'attachments/memo_2026.m4a');
      expect(bm['timestamp_ms'], 42000);
      expect(bm['annotation_text'], 'Key discussion on architecture');
      expect(bm['created_at'], 1700000000000);
    });
  });
}
