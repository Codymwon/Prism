import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_service.dart';
import 'package:prism/core/database/database_providers.dart';

// ---------------------------------------------------------------------------
// Helper: open an in-memory DB with the notes schema
// ---------------------------------------------------------------------------
Future<Database> _openTestDb() {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
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
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database rawDb;
  late DatabaseService service;

  setUp(() async {
    rawDb = await _openTestDb();
    service = SqliteDatabaseService(rawDb);
  });

  tearDown(() async {
    await rawDb.close();
  });

  group('DatabaseService - execute', () {
    test('execute runs arbitrary SQL without throwing', () async {
      await expectLater(
        service.execute(
          'INSERT INTO notes (id, title, file_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['id-1', 'Test', 'test.md', 1000, 1000],
        ),
        completes,
      );
    });
  });

  group('DatabaseService - query', () {
    test('query returns rows from the specified table', () async {
      await rawDb.insert('notes', {
        'id': 'q-1',
        'title': 'Query Note',
        'file_path': 'query.md',
        'created_at': 2000,
        'updated_at': 2000,
      });

      final rows = await service.query('notes', where: 'id = ?', whereArgs: ['q-1']);

      expect(rows, hasLength(1));
      expect(rows.first['title'], equals('Query Note'));
    });

    test('query returns empty list when table is empty', () async {
      final rows = await service.query('virtual_folders');
      expect(rows, isEmpty);
    });
  });

  group('DatabaseService - rawQuery', () {
    test('rawQuery executes a raw SQL SELECT and returns results', () async {
      await rawDb.insert('notes', {
        'id': 'rq-1',
        'title': 'Raw Query Note',
        'file_path': 'raw.md',
        'created_at': 3000,
        'updated_at': 3000,
      });

      final rows = await service.rawQuery(
        'SELECT id, title FROM notes WHERE id = ?',
        ['rq-1'],
      );

      expect(rows, hasLength(1));
      expect(rows.first['title'], equals('Raw Query Note'));
    });
  });

  group('DatabaseService - transaction', () {
    test('transaction commits all changes atomically', () async {
      await service.transaction((txn) async {
        await txn.execute(
          'INSERT INTO notes (id, title, file_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['txn-1', 'Txn Note 1', 'txn1.md', 4000, 4000],
        );
        await txn.execute(
          'INSERT INTO notes (id, title, file_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
          ['txn-2', 'Txn Note 2', 'txn2.md', 5000, 5000],
        );
      });

      final rows = await service.query('notes', orderBy: 'id ASC');
      final ids = rows.map((r) => r['id'] as String).toList();
      expect(ids, containsAll(['txn-1', 'txn-2']));
    });

    test('transaction rolls back on error', () async {
      try {
        await service.transaction((txn) async {
          await txn.execute(
            'INSERT INTO notes (id, title, file_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
            ['fail-1', 'Will Fail', 'fail.md', 6000, 6000],
          );
          // This will throw (PRIMARY KEY conflict)
          await txn.execute(
            'INSERT INTO notes (id, title, file_path, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
            ['fail-1', 'Duplicate', 'fail2.md', 7000, 7000],
          );
        });
      } catch (_) {
        // expected
      }

      // Neither row should be committed after rollback
      final rows = await service.query('notes', where: 'id = ?', whereArgs: ['fail-1']);
      expect(rows, isEmpty);
    });
  });

  group('DatabaseService - Provider', () {
    test('databaseServiceProvider is overridable with a fake', () async {
      final fakeDb = await _openTestDb();
      final fakeService = SqliteDatabaseService(fakeDb);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) async => rawDb),
          databaseServiceProvider.overrideWith((ref) async => fakeService),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await fakeDb.close();
      });

      final resolved = await container.read(databaseServiceProvider.future);
      expect(resolved, isA<DatabaseService>());
      expect(resolved, same(fakeService));
    });
  });
}
