import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/services/template_service.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/metadata_indexer.dart';
import 'package:prism/features/notes/data/note_content_parser.dart';
import 'package:prism/features/notes/data/vault_storage.dart';

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// VaultStorage backed by the real temp dir on disk.
class OnDiskVaultStorage implements VaultStorage {
  final String vaultPath;
  OnDiskVaultStorage(this.vaultPath);

  String _abs(String relativeOrAbs) =>
      p.isAbsolute(relativeOrAbs) ? relativeOrAbs : p.join(vaultPath, relativeOrAbs);

  @override
  Future<String> readContent(String relativePath) => File(_abs(relativePath)).readAsString();

  @override
  Future<void> writeContent(String relativePath, String content) =>
      File(_abs(relativePath)).writeAsString(content, flush: true);

  @override
  Future<void> deleteContent(String relativePath) async {
    final f = File(_abs(relativePath));
    if (await f.exists()) await f.delete();
  }

  @override
  Future<bool> exists(String relativePath) => File(_abs(relativePath)).exists();

  @override
  Future<List<String>> listDocumentIdentifiers(String vp) async {
    final dir = Directory(vp);
    if (!await dir.exists()) return [];
    final out = <String>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.md')) out.add(e.path);
    }
    return out;
  }

  @override
  Future<DateTime> getLastModified(String relativePath) => File(_abs(relativePath)).lastModified();
}

/// Fake indexer that counts calls but does no real DB work.
class CallCountingIndexer implements MetadataIndexer {
  int indexCalls = 0;
  int removeCalls = 0;

  @override
  Future<void> indexNote(
    DatabaseExecutor executor, {
    required String id,
    required String title,
    required String filePath,
    required int wordCount,
    required DateTime updatedAt,
    required bool isGhost,
    required bool isDaily,
    required String? dailyDate,
    required String vaultPath,
    required NoteMetadata metadata,
  }) async {
    indexCalls++;
  }

  @override
  Future<void> removeNoteIndex(DatabaseExecutor executor, String id) async {
    removeCalls++;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempVaultDir;
  late ProviderContainer container;
  late CallCountingIndexer indexer;
  late OnDiskVaultStorage storage;
  late NoteIngestionServiceImpl service;

  setUp(() async {
    tempVaultDir = Directory.systemTemp.createTempSync('prism_ingestion_template_test');
    SharedPreferences.setMockInitialValues({
      'welcomeNotesSeeded_${tempVaultDir.path.hashCode}': true,
    });

    indexer = CallCountingIndexer();
    storage = OnDiskVaultStorage(tempVaultDir.path);

    container = ProviderContainer(
      overrides: [
        activeVaultPathProvider.overrideWith((ref) => tempVaultDir.path),
      ],
    );

    service = NoteIngestionServiceImpl(
      getDb: () async => _openEmptyDb(),
      storage: storage,
      parser: MarkdownContentParser(),
      indexer: indexer,
      getVaultPath: () async => tempVaultDir.path,
      getTemplateService: () => container.read(templateServiceProvider),
    );
  });

  tearDown(() {
    container.dispose();
    try {
      if (tempVaultDir.existsSync()) tempVaultDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('NoteIngestionServiceImpl template: interception', () {
    test('saveNote writes the template file and does NOT call the indexer (FTS5 bypass)', () async {
      await service.saveNote('template:Gratitude', '# Gratitude\n\nThree things...');

      // File landed under .prism/templates/
      final file = File(p.join(tempVaultDir.path, '.prism', 'templates', 'gratitude.md'));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), contains('Three things'));

      // Indexer was never touched.
      expect(indexer.indexCalls, 0);
    });

    test('readNoteContent reads a template via TemplateService', () async {
      await container.read(templateServiceProvider).writeTemplate('Gratitude', 'Hello template');

      final content = await service.readNoteContent('template:Gratitude');
      expect(content, 'Hello template');
    });

    test('deleteNote removes the template file and does NOT call the indexer', () async {
      await container.read(templateServiceProvider).writeTemplate('Gratitude', 'temp');

      await service.deleteNote('template:Gratitude');

      final file = File(p.join(tempVaultDir.path, '.prism', 'templates', 'gratitude.md'));
      expect(await file.exists(), isFalse);
      expect(indexer.removeCalls, 0);
    });
  });
}

/// Opens a throwaway in-memory DB so getDb never throws.
Future<Database> _openEmptyDb() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT, file_path TEXT, '
            'word_count INTEGER, created_at INTEGER, updated_at INTEGER, is_ghost INTEGER, '
            'is_daily INTEGER, daily_date TEXT, is_conflicted INTEGER, original_note_id TEXT, '
            'snippet TEXT)');
        await db.execute('CREATE TABLE note_tags (note_id TEXT, tag TEXT)');
        await db.execute('CREATE TABLE note_links (source_id TEXT, target_id TEXT, '
            'context_snippet TEXT, created_at INTEGER)');
      },
    ),
  );
}
