import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/vault_providers.dart';
import '../../../../core/services/template_service.dart';
import 'adapters/vault_service_impl.dart';
import 'adapters/markdown_content_parser.dart';
import 'adapters/sqlite_metadata_indexer.dart';
import 'note_model.dart';

import 'vault_storage.dart';

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
    getTemplateService: () => ref.read(templateServiceProvider),
  );
});
