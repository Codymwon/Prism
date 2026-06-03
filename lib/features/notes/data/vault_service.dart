import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/utils/utils.dart';
import 'adapters/vault_service_impl.dart';
import 'adapters/local_vault_storage.dart';
import 'adapters/markdown_content_parser.dart';
import 'adapters/sqlite_metadata_indexer.dart';
import 'note_model.dart';

abstract class VaultService {
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

  Future<void> saveNote(String id, String content);
  Future<void> deleteNote(String id);

  Future<void> syncVault(String vaultPath);
}

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultServiceImpl(
    getDb: () => ref.read(databaseProvider.future),
    storage: LocalVaultStorage(),
    parser: MarkdownContentParser(),
    indexer: SqliteMetadataIndexer(),
    getVaultPath: () => getVaultPath(),
  );
});
