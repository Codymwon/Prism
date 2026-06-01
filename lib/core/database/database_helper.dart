import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/utils.dart';

class DatabaseHelper {
  static const _dbName = '.meridian.db';
  static const _dbVersion = 2; // Upgraded to v2 for conflict columns and indexes

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> openDatabaseForPath(String vaultPath) async {
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

    // Sync physical files inside the vault with the SQLite DB
    await _syncVaultFiles(db, vaultPath);

    return db;
  }

  Future<Database> _initDb() async {
    final vaultPath = await getVaultPath();
    return openDatabaseForPath(vaultPath);
  }

  Future<void> _syncVaultFiles(Database db, String vaultPath) async {
    try {
      final dir = Directory(vaultPath);
      if (!dir.existsSync()) return;

      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      for (final file in files) {
        final filePath = file.path;
        final existing = await db.query(
          'notes',
          columns: ['id'],
          where: 'file_path = ?',
          whereArgs: [filePath],
        );
        if (existing.isEmpty) {
          final content = await file.readAsString();
          final title = extractTitle(content);
          final wordCount = countWords(content);
          final now = file.lastModifiedSync();
          final noteId = generateId();

          await db.insert('notes', {
            'id': noteId,
            'title': title,
            'file_path': filePath,
            'word_count': wordCount,
            'created_at': now.millisecondsSinceEpoch,
            'updated_at': now.millisecondsSinceEpoch,
            'is_ghost': 0,
            'is_daily': 0,
            'daily_date': null,
            'is_conflicted': 0,
            'original_note_id': null,
          });
        }
      }
    } catch (e) {
      // Safely ignore errors during scan so the app doesn't crash
      debugPrint('Error scanning vault files: $e');
    }
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

    // Full-text search virtual table (FTS4)
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts4(
        id,
        title,
        tokenize=porter
      )
    ''');

    // FTS triggers to keep the index in sync
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(id, title) VALUES (new.id, new.title);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
        DELETE FROM notes_fts WHERE id = old.id;
        INSERT INTO notes_fts(id, title) VALUES (new.id, new.title);
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add conflict columns
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN is_conflicted INTEGER DEFAULT 0');
      } catch (e) {
        // Safe check if column already exists
      }
      try {
        await db.execute('ALTER TABLE notes ADD COLUMN original_note_id TEXT');
      } catch (e) {
        // Safe check if column already exists
      }

      // Add folder indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_note ON note_folders(note_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_note_folders_folder ON note_folders(folder_id)');
    }
  }
}

