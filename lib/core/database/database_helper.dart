import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/utils.dart';

class DatabaseHelper {
  static const _dbName = '.meridian.db';
  static const _dbVersion = 3; // Upgraded to v3 for FTS5 support

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

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
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> closeDatabase() {
    return _enqueue(() async {
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
    });
  }

  Future<Database> openDatabaseForPath(String vaultPath) {
    return _enqueue(() async {
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
      return db;
    });
  }

  Future<void> closeDatabaseConnection(Database db) {
    return _enqueue(() async {
      if (db.isOpen) {
        await db.close();
      }
    });
  }

  Future<Database> _initDb() async {
    final vaultPath = await getVaultPath();
    return openDatabaseForPath(vaultPath);
  }

  Future<void> syncVaultFiles(Database db, String vaultPath) async {
    try {
      final dir = Directory(vaultPath);
      if (!await dir.exists()) return;

      final fileList = await dir.list().toList();
      final files = fileList
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      if (files.isEmpty) return;

      // Query existing notes along with their updated_at time
      final existingNotes = await db.query('notes', columns: ['id', 'file_path', 'updated_at']);
      final Map<String, ({String id, int updatedAt})> existingPathsMap = {
        for (final n in existingNotes)
          n['file_path'] as String: (
            id: n['id'] as String,
            updatedAt: n['updated_at'] as int,
          )
      };

      // Perform insertions and updates inside a single transaction
      await db.transaction((txn) async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        for (final file in files) {
          final filePath = file.path;
          final lastMod = await file.lastModified();
          final lastModMs = lastMod.millisecondsSinceEpoch;

          final exists = existingPathsMap.containsKey(filePath);
          final existing = existingPathsMap[filePath];

          // Determine if we need to insert or update
          final shouldInsert = !exists;
          final shouldUpdate = exists && (lastModMs > (existing!.updatedAt + 1000));

          if (shouldInsert || shouldUpdate) {
            final content = await file.readAsString();
            final title = extractTitle(content);
            final wordCount = countWords(content);
            final tags = extractTags(content);
            final wikilinks = extractWikilinks(content);
            final noteId = shouldInsert ? generateId() : existing!.id;

            if (shouldInsert) {
              await txn.insert('notes', {
                'id': noteId,
                'title': title,
                'file_path': filePath,
                'word_count': wordCount,
                'created_at': lastModMs,
                'updated_at': lastModMs,
                'is_ghost': 0,
                'is_daily': 0,
                'daily_date': null,
                'is_conflicted': 0,
                'original_note_id': null,
              });
            } else {
              await txn.update('notes', {
                'title': title,
                'word_count': wordCount,
                'updated_at': lastModMs,
                'is_ghost': 0,
              }, where: 'id = ?', whereArgs: [noteId]);
            }

            // Sync tags
            await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [noteId]);
            for (final tag in tags) {
              await txn.insert(
                'note_tags',
                {'note_id': noteId, 'tag': tag},
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }

            // Sync wikilinks
            await txn.delete('note_links', where: 'source_id = ?', whereArgs: [noteId]);
            for (final target in wikilinks) {
              final targetMaps = await txn.query(
                'notes',
                columns: ['id'],
                where: 'LOWER(title) = ?',
                whereArgs: [target.toLowerCase()],
              );

              String targetId;
              if (targetMaps.isEmpty) {
                targetId = generateId();
                final slug = titleToSlug(target);
                final fileName = '$slug-$targetId.md';
                final targetFilePath = join(vaultPath, fileName);

                await txn.insert('notes', {
                  'id': targetId,
                  'title': target,
                  'file_path': targetFilePath,
                  'word_count': 0,
                  'created_at': lastModMs,
                  'updated_at': lastModMs,
                  'is_ghost': 1,
                  'is_daily': 0,
                  'daily_date': null,
                  'is_conflicted': 0,
                  'original_note_id': null,
                });
              } else {
                targetId = targetMaps.first['id'] as String;
              }

              final snippet = getWikilinkContext(content, target);
              await txn.insert(
                'note_links',
                {
                  'source_id': noteId,
                  'target_id': targetId,
                  'context_snippet': snippet,
                  'created_at': lastModMs,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

            // If the note is the clipper's Inbox note (file path ending with inbox.md), ensure it is in the virtual folder 'Inbox'
            final isClipperInbox = filePath.toLowerCase().endsWith('${Platform.pathSeparator}inbox.md') ||
                filePath.toLowerCase().endsWith('/inbox.md');
            if (isClipperInbox) {
              final folderMaps = await txn.query(
                'virtual_folders',
                columns: ['id'],
                where: 'LOWER(name) = ?',
                whereArgs: ['inbox'],
              );

              String folderId;
              if (folderMaps.isEmpty) {
                folderId = generateId();
                final maxSortMap = await txn.rawQuery('SELECT MAX(sort_order) as max_sort FROM virtual_folders');
                final rawMax = maxSortMap.first['max_sort'];
                final maxSort = rawMax == null ? 0 : (rawMax is int ? rawMax : int.tryParse(rawMax.toString()) ?? 0);

                await txn.insert('virtual_folders', {
                  'id': folderId,
                  'name': 'Inbox',
                  'color_hex': '#7C6FF7',
                  'icon': 'folder',
                  'created_at': nowMs,
                  'sort_order': maxSort + 1,
                });
              } else {
                folderId = folderMaps.first['id'] as String;
              }

              await txn.insert(
                'note_folders',
                {'note_id': noteId, 'folder_id': folderId},
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      });
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

    // Full-text search virtual table (FTS5)
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        id,
        title,
        tokenize = 'porter'
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

    if (oldVersion < 3) {
      // Drop old FTS4 table and triggers
      try {
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
        
        // Recreate triggers
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
      } catch (e) {
        // Safely ignore or log error
        debugPrint('Error upgrading database to FTS5: $e');
      }
    }
  }
}

