import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/utils.dart' as utils;
import '../note_content_parser.dart';
import '../metadata_indexer.dart';
import '../vault_storage.dart';
import '../note_model.dart';
import '../vault_service.dart';

class NoteIngestionServiceImpl implements NoteIngestionService {
  final Future<Database> Function() getDb;
  final VaultStorage storage;
  final NoteContentParser parser;
  final MetadataIndexer indexer;
  final Future<String> Function() getVaultPath;

  NoteIngestionServiceImpl({
    required this.getDb,
    required this.storage,
    required this.parser,
    required this.indexer,
    required this.getVaultPath,
  });

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final database = await getDb();
    final currentVaultPath = await getVaultPath();

    final noteTitle = title ?? (isDaily && dailyDate != null ? dailyDate : 'Untitled');

    String id = utils.generateId();
    String? existingFilePath;
    if (title != null) {
      final maps = await database.query(
        'notes',
        columns: ['id', 'file_path'],
        where: 'title = ? COLLATE NOCASE AND is_ghost = 1',
        whereArgs: [title],
      );
      if (maps.isNotEmpty) {
        id = maps.first['id'] as String;
        existingFilePath = maps.first['file_path'] as String;
      }
    }

    final slug = parser.titleToSlug(noteTitle);
    final filePath = existingFilePath ?? p.join(currentVaultPath, '$slug-$id.md');
    final now = DateTime.now();

    final String content;
    if (initialContent.isNotEmpty) {
      content = initialContent;
    } else {
      final buffer = StringBuffer();
      buffer.writeln('---');
      buffer.writeln('title: "$noteTitle"');
      if (isDaily && dailyDate != null) {
        buffer.writeln('date: $dailyDate');
      }
      buffer.writeln('---');
      buffer.writeln();
      content = buffer.toString();
    }

    // Write physical file
    await storage.writeContent(filePath, content);

    final metadata = parser.parse(content);

    final note = Note(
      id: id,
      title: noteTitle,
      filePath: filePath,
      wordCount: metadata.wordCount,
      createdAt: now,
      updatedAt: now,
      isDaily: isDaily,
      dailyDate: dailyDate,
    );

    // Index relational database tables inside a transaction
    await database.transaction((txn) async {
      await indexer.indexNote(
        txn,
        id: id,
        title: noteTitle,
        filePath: filePath,
        wordCount: metadata.wordCount,
        updatedAt: now,
        isGhost: false,
        isDaily: isDaily,
        dailyDate: dailyDate,
        vaultPath: currentVaultPath,
        metadata: metadata,
      );
    });

    return note;
  }

  @override
  Future<Note> createGhostNote(String title) async {
    final database = await getDb();
    final currentVaultPath = await getVaultPath();

    final id = utils.generateId();
    final slug = parser.titleToSlug(title);
    final fileName = '$slug-$id.md';
    final filePath = p.join(currentVaultPath, fileName);
    final now = DateTime.now();

    final note = Note(
      id: id,
      title: title,
      filePath: filePath,
      wordCount: 0,
      createdAt: now,
      updatedAt: now,
      isGhost: true,
    );

    await database.transaction((txn) async {
      await indexer.indexNote(
        txn,
        id: id,
        title: title,
        filePath: filePath,
        wordCount: 0,
        updatedAt: now,
        isGhost: true,
        isDaily: false,
        dailyDate: null,
        vaultPath: currentVaultPath,
        metadata: NoteMetadata(
          title: title,
          wordCount: 0,
          tags: [],
          wikilinks: [],
          wikilinkContexts: {},
          snippet: '',
        ),
      );
    });

    return note;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final database = await getDb();
    final maps = await database.query('notes', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  @override
  Future<Note?> getNoteByTitle(String title) async {
    final database = await getDb();
    final maps = await database.query(
      'notes',
      where: 'title = ? COLLATE NOCASE',
      whereArgs: [title],
    );
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  @override
  Future<Note?> getDailyNote(String date) async {
    final database = await getDb();
    final maps = await database.query(
      'notes',
      where: 'is_daily = 1 AND daily_date = ?',
      whereArgs: [date],
    );
    return maps.isEmpty ? null : Note.fromMap(maps.first);
  }

  @override
  Future<String> readNoteContent(String noteId) async {
    final note = await getNoteById(noteId);
    if (note == null) {
      throw ArgumentError('Note not found for ID: $noteId');
    }
    return storage.readContent(note.filePath);
  }

  @override
  Future<void> saveNote(String id, String content) async {
    final database = await getDb();
    final currentVaultPath = await getVaultPath();

    final note = await getNoteById(id);
    if (note == null) return;

    // Write file to storage
    await storage.writeContent(note.filePath, content);

    final metadata = parser.parse(content);
    final now = DateTime.now();

    await database.transaction((txn) async {
      await indexer.indexNote(
        txn,
        id: id,
        title: metadata.title,
        filePath: note.filePath,
        wordCount: metadata.wordCount,
        updatedAt: now,
        isGhost: false,
        isDaily: note.isDaily,
        dailyDate: note.dailyDate,
        vaultPath: currentVaultPath,
        metadata: metadata,
      );
    });
  }

  @override
  Future<void> deleteNote(String id) async {
    final database = await getDb();
    final note = await getNoteById(id);
    if (note == null) return;

    // Delete physical file
    await storage.deleteContent(note.filePath);

    // Remove note from DB index
    await database.transaction((txn) async {
      await indexer.removeNoteIndex(txn, id);
    });
  }
  @override
  Future<bool> syncVault(String vaultPath, {Database? db}) async {
    try {
      final database = db ?? await getDb();
      if (!database.isOpen) return false;

      final files = await storage.listDocumentIdentifiers(vaultPath);
      if (files.isEmpty) return false;

      if (!database.isOpen) return false;

      // Query existing notes along with their updated_at time and ghost flag
      final existingNotes = await database.query('notes', columns: ['id', 'file_path', 'updated_at', 'is_ghost']);
      // Ghost notes have no physical file by design — exclude them from the path map
      final Map<String, ({String id, int updatedAt})> existingPathsMap = {
        for (final n in existingNotes)
          if ((n['is_ghost'] as int? ?? 0) == 0)
            n['file_path'] as String: (
              id: n['id'] as String,
              updatedAt: n['updated_at'] as int,
            )
      };

      if (!database.isOpen) return false;

      // 1. Scan files and parse metadata outside of transaction
      final List<({
        String id,
        String title,
        String filePath,
        int wordCount,
        DateTime updatedAt,
        NoteMetadata metadata,
        bool isClipperInbox,
        bool isWelcomeNote,
      })> notesToSync = [];

      for (final filePath in files) {
        if (!database.isOpen) return false;
        final lastMod = await storage.getLastModified(filePath);
        final lastModMs = lastMod.millisecondsSinceEpoch;

        final exists = existingPathsMap.containsKey(filePath);
        final existing = existingPathsMap[filePath];

        // Determine if we need to insert or update (allow 1 second discrepancy)
        final shouldInsert = !exists;
        final shouldUpdate = exists && (lastModMs > (existing!.updatedAt + 1000));

        if (shouldInsert || shouldUpdate) {
          final content = await storage.readContent(filePath);
          final metadata = parser.parse(content);
          final noteId = shouldInsert ? utils.generateId() : existing!.id;

          final isClipperInbox = filePath.toLowerCase().endsWith('${Platform.pathSeparator}inbox.md') ||
              filePath.toLowerCase().endsWith('/inbox.md');

          final isWelcomeNote = filePath.toLowerCase().endsWith('${Platform.pathSeparator}welcome to prism.md') ||
              filePath.toLowerCase().endsWith('/welcome to prism.md') ||
              filePath.toLowerCase().endsWith('${Platform.pathSeparator}productivity tools guide.md') ||
              filePath.toLowerCase().endsWith('/productivity tools guide.md');

          notesToSync.add((
            id: noteId,
            title: metadata.title,
            filePath: filePath,
            wordCount: metadata.wordCount,
            updatedAt: lastMod,
            metadata: metadata,
            isClipperInbox: isClipperInbox,
            isWelcomeNote: isWelcomeNote,
          ));
        }
      }

      if (!database.isOpen) return false;

      bool hasChanges = false;

      // 2. Perform all database modifications inside a single fast transaction
      await database.transaction((txn) async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        if (notesToSync.isNotEmpty || existingNotes.where((n) => (n['is_ghost'] as int? ?? 0) == 0 && !files.contains(n['file_path'] as String)).isNotEmpty) {
          hasChanges = true;
        }

        for (final item in notesToSync) {
          if (!database.isOpen) return;

          await indexer.indexNote(
            txn,
            id: item.id,
            title: item.title,
            filePath: item.filePath,
            wordCount: item.wordCount,
            updatedAt: item.updatedAt,
            isGhost: false,
            isDaily: false,
            dailyDate: null,
            vaultPath: vaultPath,
            metadata: item.metadata,
          );

          // If the note is the clipper's Inbox note, ensure it is in the virtual folder 'Inbox'
          if (item.isClipperInbox) {
            final folderMaps = await txn.query(
               'virtual_folders',
              columns: ['id'],
              where: 'LOWER(name) = ?',
              whereArgs: ['inbox'],
            );

            String folderId;
            if (folderMaps.isEmpty) {
              folderId = utils.generateId();
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
              {'note_id': item.id, 'folder_id': folderId},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }

          // If the note is a welcome note, ensure it is in the virtual folder 'Tutorial'
          if (item.isWelcomeNote) {
            final folderMaps = await txn.query(
              'virtual_folders',
              columns: ['id'],
              where: 'LOWER(name) = ?',
              whereArgs: ['tutorial'],
            );

            String folderId;
            if (folderMaps.isEmpty) {
              folderId = utils.generateId();
              final maxSortMap = await txn.rawQuery('SELECT MAX(sort_order) as max_sort FROM virtual_folders');
              final rawMax = maxSortMap.first['max_sort'];
              final maxSort = rawMax == null ? 0 : (rawMax is int ? rawMax : int.tryParse(rawMax.toString()) ?? 0);

              await txn.insert('virtual_folders', {
                'id': folderId,
                'name': 'Tutorial',
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
              {'note_id': item.id, 'folder_id': folderId},
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }

        // ── Orphan pruning ─────────────────────────────────────────────────
        // Remove non-ghost notes whose physical .md file no longer exists.
        final filesSet = files.toSet();
        final orphanedNotes = existingNotes
            .where((n) =>
                (n['is_ghost'] as int? ?? 0) == 0 &&
                !filesSet.contains(n['file_path'] as String))
            .toList();

        for (final orphan in orphanedNotes) {
          await indexer.removeNoteIndex(txn, orphan['id'] as String);
        }

        // After real-note deletes cascade through note_links, prune any
        // ghost notes that now have no remaining backlinks.
        final orphanedGhosts = await txn.rawQuery('''
          SELECT id FROM notes
          WHERE is_ghost = 1
            AND NOT EXISTS (
              SELECT 1 FROM note_links WHERE target_id = notes.id
            )
        ''');
        if (orphanedGhosts.isNotEmpty) {
          hasChanges = true;
        }
        for (final ghost in orphanedGhosts) {
          await indexer.removeNoteIndex(txn, ghost['id'] as String);
        }
      });

      return hasChanges;
    } catch (e) {
      // Safely ignore errors during scan
      debugPrint('Error scanning vault files: $e');
      return false;
    }
  }
}
