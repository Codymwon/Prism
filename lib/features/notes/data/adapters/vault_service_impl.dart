import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/utils.dart' as utils;
import '../note_content_parser.dart';
import '../metadata_indexer.dart';
import 'sqlite_metadata_indexer.dart';
import '../vault_storage.dart';
import '../note_model.dart';
import '../../../folders/data/virtual_folder_sync_helper.dart';
import '../../../../core/services/note_ingestion_service.dart';

class NoteIngestionServiceImpl implements NoteIngestionService {
  final Future<Database> Function() getDb;
  final VaultStorage storage;
  final NoteContentParser parser;
  final MetadataIndexer indexer;
  final Future<String> Function() getVaultPath;
  final Future<void> Function(String noteId, String filePath, DatabaseExecutor txn)? onNoteSynced;

  NoteIngestionServiceImpl({
    required this.getDb,
    required this.storage,
    required this.parser,
    required this.indexer,
    required this.getVaultPath,
    this.onNoteSynced = _defaultOnNoteSynced,
  });

  static Future<void> _defaultOnNoteSynced(String noteId, String filePath, DatabaseExecutor txn) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await VirtualFolderSyncHelper.handleNoteSync(
      txn: txn,
      noteId: noteId,
      filePath: filePath,
      nowMs: nowMs,
    );
  }

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

    final cleanNoteTitle = noteTitle.trim().isEmpty ? 'Untitled' : noteTitle.trim();
    final String? existingFm = initialContent.isNotEmpty ? utils.extractFrontmatterBlock(initialContent) : null;
    final String body = initialContent.isNotEmpty ? utils.stripFrontmatter(initialContent) : '';
    final String content = utils.updateOrInjectFrontmatter(
      existingFrontmatterBlock: existingFm,
      body: body,
      id: id,
      title: cleanNoteTitle,
      date: isDaily && dailyDate != null ? dailyDate : null,
    );

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
        SqfliteExecutorWrapper(txn),
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
        SqfliteExecutorWrapper(txn),
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
        SqfliteExecutorWrapper(txn),
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
      await indexer.removeNoteIndex(SqfliteExecutorWrapper(txn), id);
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

      // Query existing notes along with their updated_at time, ghost flag, and title
      final existingNotes = await database.query('notes', columns: ['id', 'title', 'file_path', 'updated_at', 'is_ghost']);
      // Ghost notes have no physical file by design — exclude them from the path map
      final Map<String, ({String id, int updatedAt})> existingPathsMap = {
        for (final n in existingNotes)
          if ((n['is_ghost'] as int? ?? 0) == 0)
            n['file_path'] as String: (
              id: n['id'] as String,
              updatedAt: n['updated_at'] as int,
            )
      };

      final Map<String, ({String id, String filePath, int updatedAt, int isGhost})> existingNotesById = {
        for (final n in existingNotes)
          n['id'] as String: (
            id: n['id'] as String,
            filePath: n['file_path'] as String,
            updatedAt: n['updated_at'] as int,
            isGhost: n['is_ghost'] as int? ?? 0,
          )
      };

      final Map<String, ({String id, int updatedAt})> ghostNotesByLowerTitle = {
        for (final n in existingNotes)
          if ((n['is_ghost'] as int? ?? 0) == 1 && n['title'] != null)
            (n['title'] as String).toLowerCase().trim(): (
              id: n['id'] as String,
              updatedAt: n['updated_at'] as int,
            )
      };

      final Set<String> claimedNoteIds = {};

      if (!database.isOpen) return false;

      // 1. Scan files and parse metadata outside of transaction
      final List<({
        String id,
        String title,
        String filePath,
        int wordCount,
        DateTime updatedAt,
        NoteMetadata metadata,
      })> notesToSync = [];

      for (final filePath in files) {
        if (!database.isOpen) return false;
        final lastMod = await storage.getLastModified(filePath);
        final lastModMs = lastMod.millisecondsSinceEpoch;

        if (existingPathsMap.containsKey(filePath)) {
          final existing = existingPathsMap[filePath]!;
          claimedNoteIds.add(existing.id);

          // Determine if we need to update (discrepancy > 1 second)
          if (lastModMs > (existing.updatedAt + 1000)) {
            final content = await storage.readContent(filePath);
            final metadata = parser.parse(content);
            notesToSync.add((
              id: existing.id,
              title: metadata.title,
              filePath: filePath,
              wordCount: metadata.wordCount,
              updatedAt: lastMod,
              metadata: metadata,
            ));
          }
        } else {
          // Exact file_path match not found
          final content = await storage.readContent(filePath);
          final metadata = parser.parse(content);

          // 1. Check if parsed frontmatter contains an id matching existing note
          final frontmatterId = utils.extractFrontmatterValue(content, 'id');
          String? matchedId;
          if (frontmatterId != null && existingNotesById.containsKey(frontmatterId)) {
            matchedId = frontmatterId;
          } else {
            // 2. Check if trailing filename matches UUID format
            final basename = p.basenameWithoutExtension(filePath);
            final uuidMatch = RegExp(r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$').firstMatch(basename);
            if (uuidMatch != null) {
              final filenameUuid = uuidMatch.group(1);
              if (filenameUuid != null && existingNotesById.containsKey(filenameUuid)) {
                matchedId = filenameUuid;
              }
            }
          }

          if (matchedId != null) {
            // Note's file_path changed (e.g. vault rename or file move). Update existing note!
            claimedNoteIds.add(matchedId);
            notesToSync.add((
              id: matchedId,
              title: metadata.title,
              filePath: filePath,
              wordCount: metadata.wordCount,
              updatedAt: lastMod,
              metadata: metadata,
            ));
          } else {
            // 3. Check Ghost Notes (promote matching title)
            final lowerTitle = metadata.title.toLowerCase().trim();
            if (ghostNotesByLowerTitle.containsKey(lowerTitle)) {
              final ghost = ghostNotesByLowerTitle[lowerTitle]!;
              claimedNoteIds.add(ghost.id);
              notesToSync.add((
                id: ghost.id,
                title: metadata.title,
                filePath: filePath,
                wordCount: metadata.wordCount,
                updatedAt: lastMod,
                metadata: metadata,
              ));
            } else {
              // Brand-new note
              final noteId = utils.generateId();
              claimedNoteIds.add(noteId);
              notesToSync.add((
                id: noteId,
                title: metadata.title,
                filePath: filePath,
                wordCount: metadata.wordCount,
                updatedAt: lastMod,
                metadata: metadata,
              ));
            }
          }
        }
      }

      if (!database.isOpen) return false;

      bool hasChanges = false;

      // 2. Perform all database modifications inside a single fast transaction
      await database.transaction((txn) async {
        // ── Orphan pruning ─────────────────────────────────────────────────
        // Remove non-ghost notes whose physical .md file no longer exists and wasn't claimed.
        final orphanedNotes = existingNotes
            .where((n) =>
                (n['is_ghost'] as int? ?? 0) == 0 &&
                !claimedNoteIds.contains(n['id'] as String))
            .toList();

        if (notesToSync.isNotEmpty || orphanedNotes.isNotEmpty) {
          hasChanges = true;
        }

        for (final item in notesToSync) {
          if (!database.isOpen) return;

          await indexer.indexNote(
            SqfliteExecutorWrapper(txn),
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

          if (onNoteSynced != null) {
            await onNoteSynced!(item.id, item.filePath, txn);
          }
        }

        for (final orphan in orphanedNotes) {
          await indexer.removeNoteIndex(SqfliteExecutorWrapper(txn), orphan['id'] as String);
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
          await indexer.removeNoteIndex(SqfliteExecutorWrapper(txn), ghost['id'] as String);
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
