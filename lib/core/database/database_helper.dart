import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/utils.dart';

class DatabaseHelper {
  static const _dbName = '.meridian.db';
  static const _dbVersion = 4; // Upgraded to v4 for spatial groups and coordinates

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
      final path = join(vaultPath, _dbName);
      final db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          // Enable WAL mode for better concurrent read/write performance
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          // Enable foreign key constraints
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      );
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
        original_note_id TEXT
      )
    ''');

    // Full-text search virtual table (FTS5)
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        id,
        title,
        tokenize = 'porter'
      )
    ''');

    // FTS triggers to keep the index in sync (ghost notes excluded)
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
  }
}

