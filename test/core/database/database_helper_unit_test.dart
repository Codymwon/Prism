import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meridian/core/database/database_helper.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir1;
  late Directory tempDir2;

  setUp(() async {
    tempDir1 = await Directory.systemTemp.createTemp('meridian_test_vault1');
    tempDir2 = await Directory.systemTemp.createTemp('meridian_test_vault2');
    
    SharedPreferences.setMockInitialValues({
      'baseVaultsDirectory': tempDir1.parent.path,
      'activeVaultName': p.basename(tempDir1.path),
    });

    await DatabaseHelper.instance.closeDatabase();
  });

  tearDown(() async {
    await DatabaseHelper.instance.closeDatabase();
    try {
      if (await tempDir1.exists()) {
        await tempDir1.delete(recursive: true);
      }
    } catch (_) {}
    try {
      if (await tempDir2.exists()) {
        await tempDir2.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('DatabaseHelper Connection Management', () {
    test('openDatabaseForPath returns same instance for same path', () async {
      final db1 = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      final db2 = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      
      expect(db1, equals(db2));
      expect(db1.isOpen, isTrue);
    });

    test('openDatabaseForPath closes old instance and returns new for different path', () async {
      final db1 = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      expect(db1.isOpen, isTrue);

      final db2 = await DatabaseHelper.instance.openDatabaseForPath(tempDir2.path);
      expect(db1.isOpen, isFalse);
      expect(db2.isOpen, isTrue);
      expect(db1, isNot(equals(db2)));
    });

    test('closeDatabase cleans up active vault references', () async {
      final db = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      expect(db.isOpen, isTrue);

      await DatabaseHelper.instance.closeDatabase();
      expect(db.isOpen, isFalse);
      
      // If we open again, it should be a new open database
      final dbNew = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      expect(dbNew.isOpen, isTrue);
      expect(dbNew, isNot(equals(db)));
    });

    test('closeDatabaseConnection cleans up references if closing the active connection', () async {
      final db = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      expect(db.isOpen, isTrue);

      await DatabaseHelper.instance.closeDatabaseConnection(db);
      expect(db.isOpen, isFalse);

      // If we open again, it should be a new open database
      final dbNew = await DatabaseHelper.instance.openDatabaseForPath(tempDir1.path);
      expect(dbNew.isOpen, isTrue);
      expect(dbNew, isNot(equals(db)));
    });
  });

  group('DatabaseHelper Concurrent Initialization', () {
    test('concurrent database getters return same database instance', () async {
      final dbFutures = await Future.wait([
        DatabaseHelper.instance.database,
        DatabaseHelper.instance.database,
        DatabaseHelper.instance.database,
      ]);

      expect(dbFutures[0], equals(dbFutures[1]));
      expect(dbFutures[0], equals(dbFutures[2]));
      expect(dbFutures[0].isOpen, isTrue);
    });
  });

  group('DatabaseHelper Upgrade Error Propagation', () {
    test('upgrade failure propagates the exception to the caller', () async {
      final dbPath = p.join(tempDir2.path, '.prism.db');

      // 1. Initialize a Version 1 Database manually without the notes table
      final v1Db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE dummy (id INTEGER PRIMARY KEY)');
          },
        ),
      );
      await v1Db.close();

      // Now we open it via DatabaseHelper to upgrade it to v4.
      // This should trigger the ALTER TABLE notes ... in version 2 upgrade,
      // which will fail because the notes table does not exist.
      // We expect DatabaseHelper to catch the error, rename to .corrupt, and return a fresh database.
      final db = await DatabaseHelper.instance.openDatabaseForPath(tempDir2.path);
      expect(db.isOpen, isTrue);

      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='notes'");
      expect(tables, isNotEmpty);

      final corruptFile = File('$dbPath.corrupt');
      expect(await corruptFile.exists(), isTrue);
    });
  });
}
