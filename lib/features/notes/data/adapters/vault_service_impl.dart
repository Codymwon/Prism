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

class VaultServiceImpl implements VaultService {
  final Future<Database> Function() getDb;
  final VaultStorage storage;
  final NoteContentParser parser;
  final MetadataIndexer indexer;
  final Future<String> Function() getVaultPath;

  VaultServiceImpl({
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

    final id = utils.generateId();
    final noteTitle = title ?? (isDaily && dailyDate != null ? dailyDate : 'Untitled');
    final slug = parser.titleToSlug(noteTitle);
    final fileName = '$slug-$id.md';
    final filePath = p.join(currentVaultPath, fileName);
    final now = DateTime.now();

    final content = initialContent.isEmpty
        ? '# $noteTitle\n\n'
        : initialContent;

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
      where: 'LOWER(title) = ?',
      whereArgs: [title.toLowerCase()],
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
  Future<void> syncVault(String vaultPath) async {
    try {
      final database = await getDb();
      final files = await storage.listDocumentIdentifiers(vaultPath);
      if (files.isEmpty) return;

      // Query existing notes along with their updated_at time
      final existingNotes = await database.query('notes', columns: ['id', 'file_path', 'updated_at']);
      final Map<String, ({String id, int updatedAt})> existingPathsMap = {
        for (final n in existingNotes)
          n['file_path'] as String: (
            id: n['id'] as String,
            updatedAt: n['updated_at'] as int,
          )
      };

      // Perform insertions and updates inside a single transaction
      await database.transaction((txn) async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        for (final filePath in files) {
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

            await indexer.indexNote(
              txn,
              id: noteId,
              title: metadata.title,
              filePath: filePath,
              wordCount: metadata.wordCount,
              updatedAt: lastMod,
              isGhost: false,
              isDaily: false,
              dailyDate: null,
              vaultPath: vaultPath,
              metadata: metadata,
            );

            // If the note is the clipper's Inbox note, ensure it is in the virtual folder 'Inbox'
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
                {'note_id': noteId, 'folder_id': folderId},
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
        }
      });
    } catch (e) {
      // Safely ignore errors during scan
      debugPrint('Error scanning vault files: $e');
    }
  }
}
