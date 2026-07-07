import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_providers.dart';
import '../database/vault_providers.dart';
import '../../features/notes/data/note_model.dart';
import '../../features/notes/data/vault_storage.dart';
import '../../features/notes/data/adapters/vault_service_impl.dart';
import '../../features/notes/data/adapters/markdown_content_parser.dart';
import '../../features/notes/data/adapters/sqlite_metadata_indexer.dart';
import '../../features/folders/data/virtual_folder_sync_helper.dart';

abstract class NoteIngestionService {
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  });

  Future<Note> createGhostNote(String title);

  Future<Note?> getNoteById(String id);
  Future<Note?> getNoteByTitle(String title);
  Future<Note?> getDailyNote(String date);

  Future<String> readNoteContent(String noteId);

  Future<void> saveNote(String id, String content);
  Future<void> deleteNote(String id);

  Future<bool> syncVault(String vaultPath, {Database? db});
}

final noteIngestionServiceProvider = Provider<NoteIngestionService>((ref) {
  return NoteIngestionServiceImpl(
    getDb: () => ref.read(databaseProvider.future),
    storage: ref.read(vaultStorageProvider),
    parser: MarkdownContentParser(),
    indexer: SqliteMetadataIndexer(),
    getVaultPath: () => ref.read(activeVaultPathProvider.future),
    onNoteSynced: (noteId, filePath, txn) async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await VirtualFolderSyncHelper.handleNoteSync(
        txn: txn,
        noteId: noteId,
        filePath: filePath,
        nowMs: nowMs,
      );
    },
  );
});
