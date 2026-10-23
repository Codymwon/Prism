import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import '../utils/utils.dart';

class DatabaseHelper {
  static const _dbName = '.prism.db';
  static const _dbVersion = 8; // Upgraded to v8: FTS5 body indexing, covering indexes, query optimizations

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;
  String? _activeVaultPath;
  Future<Database>? _initFuture;

  // A strictly sequential queue for all database open & close operations
  // to prevent race conditions during rapid vault switching.
  Future<void> _dbQueue = Future.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _dbQueue = _dbQueue.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, stack) {
        completer.completeError(e, stack);
      }
    });
    return completer.future;
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _initFuture ??= _initDb();
    try {
      return await _initFuture!;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> closeDatabase() {
    return _enqueue(() async {
      if (_db != null) {
        await _db!.close();
        _db = null;
        _activeVaultPath = null;
      }
    });
  }

  Future<String?> _getDbPassword() async {
    if (kIsWeb) return null;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return null;
    }
    // Check if databaseFactory is FFI (i.e. we are running in desktop unit tests)
    if (databaseFactory.runtimeType.toString().contains('Ffi')) {
      return null;
    }

    const secureStorage = FlutterSecureStorage();
    const key = 'prism_db_encryption_key';
    const delays = [
      Duration(milliseconds: 100),
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
    ];

    Object? lastError;
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        String? password = await secureStorage.read(key: key);
        if (password == null) {
          password = const Uuid().v4();
          await secureStorage.write(key: key, value: password);
        }
        return password;
      } catch (e) {
        lastError = e;
        debugPrint('[DB] Error accessing secure storage for database key (attempt ${attempt + 1}/3): $e');
        if (attempt < 2) {
          await Future<void>.delayed(delays[attempt]);
        }
      }
    }
    throw StateError('Failed to access secure storage for database encryption key: $lastError');
  }

  Future<Database> openDatabaseForPath(String vaultPath) {
    return _enqueue(() async {
      if (_db != null && _db!.isOpen && _activeVaultPath == vaultPath) {
        return _db!;
      }
      if (_db != null && _activeVaultPath != vaultPath) {
        await _db!.close();
        _db = null;
        _activeVaultPath = null;
      }

      // Ensure the parent vault directory exists to prevent native openOrCreate failures
      final dir = Directory(vaultPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final path = join(vaultPath, _dbName);
      final password = await _getDbPassword();
      Database db;
      final isFfi = kIsWeb ||
          Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS ||
          databaseFactory.runtimeType.toString().contains('Ffi') ||
          ffi.databaseFactoryFfi.runtimeType.toString().contains('Ffi');
      try {
        if (isFfi) {
          db = await ffi.databaseFactoryFfi.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: _dbVersion,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              onDowngrade: _onDowngrade,
              onConfigure: (db) async {
                await db.rawQuery('PRAGMA journal_mode = WAL;');
                await db.rawQuery('PRAGMA foreign_keys = ON;');
                await db.rawQuery('PRAGMA cache_size = -2000;');
                await db.rawQuery('PRAGMA mmap_size = 268435456;');
                await db.rawQuery('PRAGMA synchronous = NORMAL;');
                await db.rawQuery('PRAGMA busy_timeout = 5000;');
              },
            ),
          );
        } else {
          db = await openDatabase(
            path,
            password: password,
            version: _dbVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onDowngrade: _onDowngrade,
            onConfigure: (db) async {
              await db.rawQuery('PRAGMA journal_mode = WAL;');
              await db.rawQuery('PRAGMA foreign_keys = ON;');
              await db.rawQuery('PRAGMA cache_size = -2000;');
              await db.rawQuery('PRAGMA mmap_size = 268435456;');
              await db.rawQuery('PRAGMA synchronous = NORMAL;');
              await db.rawQuery('PRAGMA busy_timeout = 5000;');
            },
          );
        }
      } catch (e, stack) {
        debugPrint('[DB] Unreadable database at $path — attempting recovery.\n$e\n$stack');
        try {
          final corruptFile = File(path);
          if (await corruptFile.exists()) {
            await corruptFile.rename('$path.corrupt');
            debugPrint('[DB] Corrupt file renamed to $path.corrupt');
          }
          final walFile = File('$path-wal');
          if (await walFile.exists()) {
            try {
              await walFile.rename('$path-wal.corrupt');
            } catch (_) {
              await walFile.delete();
            }
            debugPrint('[DB] Corrupt WAL file renamed/deleted');
          }
          final shmFile = File('$path-shm');
          if (await shmFile.exists()) {
            try {
              await shmFile.rename('$path-shm.corrupt');
            } catch (_) {
              await shmFile.delete();
            }
            debugPrint('[DB] Corrupt SHM file renamed/deleted');
          }
        } catch (renameErr) {
          debugPrint('[DB] Could not clean up corrupt files: $renameErr');
        }
        // Open a fresh empty database; background syncVault will rebuild
        // the notes index from the .md files on disk.
        if (isFfi) {
          db = await ffi.databaseFactoryFfi.openDatabase(
            path,
            options: OpenDatabaseOptions(
              version: _dbVersion,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              onDowngrade: _onDowngrade,
              onConfigure: (db) async {
                await db.rawQuery('PRAGMA journal_mode = WAL;');
                await db.rawQuery('PRAGMA foreign_keys = ON;');
                await db.rawQuery('PRAGMA cache_size = -2000;');
                await db.rawQuery('PRAGMA mmap_size = 268435456;');
                await db.rawQuery('PRAGMA synchronous = NORMAL;');
                await db.rawQuery('PRAGMA busy_timeout = 5000;');
              },
            ),
          );
        } else {
          db = await openDatabase(
            path,
            password: password,
            version: _dbVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onDowngrade: _onDowngrade,
            onConfigure: (db) async {
              await db.rawQuery('PRAGMA journal_mode = WAL;');
              await db.rawQuery('PRAGMA foreign_keys = ON;');
              await db.rawQuery('PRAGMA cache_size = -2000;');
              await db.rawQuery('PRAGMA mmap_size = 268435456;');
              await db.rawQuery('PRAGMA synchronous = NORMAL;');
              await db.rawQuery('PRAGMA busy_timeout = 5000;');
            },
          );
        }
      }
      _db = db;
      _activeVaultPath = vaultPath;
      return db;
    });
  }

  Future<void> closeDatabaseConnection(Database db) {
    return _enqueue(() async {
      if (db.isOpen) {
        await db.close();
      }
      if (_db == db) {
        _db = null;
        _activeVaultPath = null;
      }
    });
  }

  Future<Database> _initDb() async {
    final vaultPath = await getVaultPath();
    return openDatabaseForPath(vaultPath);
  }



  Future<void> _onCreate(Database db, int version) async {
    // Core notes index (updated in v2 with is_conflicted and original_note_id)
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

    // Full-text search virtual table (FTS5) with note body
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        id UNINDEXED,
        title,
        body,
        tokenize = 'porter'
      )
    ''');

    // FTS delete trigger to keep the index clean when notes are removed
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE id = old.id;
      END
    ''');

    // Relational wikilink graph
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_links (
        source_id TEXT NOT NULL,
        target_id TEXT NOT NULL,
        context_snippet TEXT,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (source_id, target_id),
        FOREIGN KEY(source_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY(target_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Virtual folder system
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

    // Note <-> Folder mapping (many-to-many)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_folders (
        note_id TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        PRIMARY KEY (note_id, folder_id),
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY(folder_id) REFERENCES virtual_folders(id) ON DELETE CASCADE
      )
    ''');

    // Tag index (extracted from inline #tags in note content)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_tags (
        note_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        PRIMARY KEY (note_id, tag),
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_note_links_target ON note_links(target_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_note_tags_tag ON note_tags(tag)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_daily ON notes(is_daily, daily_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_ghost_updated ON notes(is_ghost, updated_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_ghost_daily ON notes(is_ghost, is_daily, daily_date)');
    
    // Folder indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_note ON note_folders(note_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_folder ON note_folders(folder_id)');

    // Version 4 Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS graph_node_positions (
        note_id TEXT PRIMARY KEY,
        x REAL NOT NULL,
        y REAL NOT NULL,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
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

    // Version 4 Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audio_bookmarks_note ON audio_bookmarks(note_id)');

    // Version 8 Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_non_daily_updated ON notes(is_ghost, is_daily, updated_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audio_bookmarks_note_attachment ON audio_bookmarks(note_id, attachment_path, timestamp_ms ASC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add conflict columns
      await db.execute('ALTER TABLE notes ADD COLUMN is_conflicted INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN original_note_id TEXT');

      // Add folder indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_note ON note_folders(note_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_folder ON note_folders(folder_id)');
    }

    if (oldVersion < 3) {
      // Drop old FTS4 table and triggers
      await db.execute('DROP TABLE IF EXISTS notes_fts');
      await db.execute('DROP TRIGGER IF EXISTS notes_ai');
      await db.execute('DROP TRIGGER IF EXISTS notes_au');
      await db.execute('DROP TRIGGER IF EXISTS notes_ad');
      
      // Recreate FTS5 table
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
          id,
          title,
          tokenize = 'porter'
        )
      ''');
      
      // Populate FTS5 table with existing note data
      await db.execute('INSERT INTO notes_fts(id, title) SELECT id, title FROM notes WHERE is_ghost = 0');
      
      // Recreate triggers (ghost notes excluded)
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes
        WHEN new.is_ghost = 0 BEGIN
          INSERT INTO notes_fts(id, title) VALUES (new.id, new.title);
        END
      ''');
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
          DELETE FROM notes_fts WHERE id = old.id;
          INSERT OR IGNORE INTO notes_fts(id, title)
            SELECT new.id, new.title WHERE new.is_ghost = 0;
        END
      ''');
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
          DELETE FROM notes_fts WHERE id = old.id;
        END
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS graph_node_positions (
          note_id TEXT PRIMARY KEY,
          x REAL NOT NULL,
          y REAL NOT NULL,
          is_pinned INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS spatial_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color_hex TEXT NOT NULL DEFAULT '#7C6FF7',
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS spatial_group_nodes (
          group_id TEXT NOT NULL,
          note_id TEXT NOT NULL,
          PRIMARY KEY (group_id, note_id),
          FOREIGN KEY(group_id) REFERENCES spatial_groups(id) ON DELETE CASCADE,
          FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
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

      // Version 4 Indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_spatial_group_nodes_note ON spatial_group_nodes(note_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_audio_bookmarks_note ON audio_bookmarks(note_id)');
    }

    if (oldVersion < 5) {
      await db.execute("ALTER TABLE notes ADD COLUMN snippet TEXT DEFAULT ''");
    }

    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS spatial_group_nodes');
      await db.execute('DROP TABLE IF EXISTS spatial_groups');
    }

    if (oldVersion < 7) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_ghost_updated ON notes(is_ghost, updated_at DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_ghost_daily ON notes(is_ghost, is_daily, daily_date)');
    }

    if (oldVersion < 8) {
      // Drop old FTS triggers and table
      await db.execute('DROP TRIGGER IF EXISTS notes_ai');
      await db.execute('DROP TRIGGER IF EXISTS notes_au');
      await db.execute('DROP TRIGGER IF EXISTS notes_ad');
      await db.execute('DROP TABLE IF EXISTS notes_fts');

      // Recreate FTS5 table with body
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
          id UNINDEXED,
          title,
          body,
          tokenize = 'porter'
        )
      ''');

      // Populate FTS5 table with existing note data (body initialized from snippet)
      await db.execute('''
        INSERT INTO notes_fts(id, title, body)
        SELECT id, title, COALESCE(snippet, '') FROM notes WHERE is_ghost = 0
      ''');

      // FTS delete trigger
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
          DELETE FROM notes_fts WHERE id = old.id;
        END
      ''');

      // Add covering indexes for v8
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_non_daily_updated ON notes(is_ghost, is_daily, updated_at DESC)');
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
      await db.execute('CREATE INDEX IF NOT EXISTS idx_audio_bookmarks_note_attachment ON audio_bookmarks(note_id, attachment_path, timestamp_ms ASC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title COLLATE NOCASE)');
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('[DB] Schema downgrade detected ($oldVersion → $newVersion). Dropping and rebuilding schema.');
    await _dropAllTables(db);
    await _onCreate(db, newVersion);
  }

  Future<void> _dropAllTables(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    for (final table in [
      'audio_bookmarks',
      'spatial_group_nodes',
      'spatial_groups',
      'graph_node_positions',
      'note_tags',
      'note_folders',
      'virtual_folders',
      'note_links',
      'notes_fts',
      'notes',
    ]) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    for (final trigger in ['notes_ai', 'notes_au', 'notes_ad']) {
      await db.execute('DROP TRIGGER IF EXISTS $trigger');
    }
    await db.execute('PRAGMA foreign_keys = ON');
  }
}

