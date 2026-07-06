import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/database/vault_providers.dart';
import 'package:prism/core/services/template_service.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/template_repository.dart';
import 'package:prism/features/notes/data/vault_service.dart';
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/notes/data/vault_storage.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FakeVaultStorage implements VaultStorage {
  final Map<String, String> files = {};
  final Map<String, DateTime> modTimes = {};

  @override
  Future<String> readContent(String relativePath) async => files[relativePath] ?? '';

  @override
  Future<void> writeContent(String relativePath, String content) async {
    files[relativePath] = content;
    modTimes[relativePath] = DateTime.now();
  }

  @override
  Future<void> deleteContent(String relativePath) async {
    files.remove(relativePath);
    modTimes.remove(relativePath);
  }

  @override
  Future<bool> exists(String relativePath) async => files.containsKey(relativePath);

  @override
  Future<List<String>> listDocumentIdentifiers(String vaultPath) async => files.keys.toList();

  @override
  Future<DateTime> getLastModified(String relativePath) async =>
      modTimes[relativePath] ?? DateTime.fromMillisecondsSinceEpoch(0);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late Directory tempVaultDir;
  late ProviderContainer container;
  late TemplateRepository templateRepository;
  late NoteRepository noteRepository;

  setUp(() async {
    tempVaultDir = Directory.systemTemp.createTempSync('prism_repo_template_test');
    SharedPreferences.setMockInitialValues({
      'welcomeNotesSeeded_${tempVaultDir.path.hashCode}': true,
    });

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
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
              original_note_id TEXT,
              snippet TEXT DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_tags (
              note_id TEXT NOT NULL,
              tag TEXT NOT NULL,
              PRIMARY KEY (note_id, tag)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_links (
              source_id TEXT NOT NULL,
              target_id TEXT NOT NULL,
              context_snippet TEXT,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (source_id, target_id)
            )
          ''');
        },
      ),
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
        activeVaultPathProvider.overrideWith((ref) => tempVaultDir.path),
        noteIngestionServiceProvider.overrideWith((ref) {
          return NoteIngestionServiceImpl(
            getDb: () async => db,
            storage: FakeVaultStorage(),
            parser: MarkdownContentParser(),
            indexer: SqliteMetadataIndexer(),
            getVaultPath: () async => tempVaultDir.path,
          );
        }),
      ],
    );
    templateRepository = container.read(templateRepositoryProvider);
    noteRepository = container.read(noteRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    try {
      if (tempVaultDir.existsSync()) tempVaultDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('TemplateRepository tests', () {
    test('getTemplateNoteById returns a synthetic Note for a template ID', () async {
      await container.read(templateServiceProvider).writeTemplate('Gratitude', 'x');

      final note = await templateRepository.getTemplateNoteById('template:Gratitude');

      expect(note, isNotNull);
      expect(note.id, 'template:Gratitude');
      expect(note.title, 'Gratitude');
    });

    test('readTemplateContent reads from TemplateService', () async {
      await container
          .read(templateServiceProvider)
          .writeTemplate('Gratitude', '---\ntitle: "Gratitude"\n---\n\nBe thankful.');

      final content = await templateRepository.readTemplateContent('template:Gratitude');

      expect(content, contains('Be thankful.'));
    });

    test('saveTemplate writes the template file via TemplateService and does NOT touch the DB', () async {
      await templateRepository.saveTemplate('template:Gratitude', '# Gratitude Log\n\nOne thing...');

      final file = File(p.join(tempVaultDir.path, '.prism', 'templates', 'gratitude.md'));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), '# Gratitude Log\n\nOne thing...');

      final rows = await db.query('notes', where: 'id = ?', whereArgs: ['template:Gratitude']);
      expect(rows, isEmpty);
    });

    test('deleteTemplate removes the template file via TemplateService', () async {
      await container.read(templateServiceProvider).writeTemplate('Gratitude', 'temp content');
      final file = File(p.join(tempVaultDir.path, '.prism', 'templates', 'gratitude.md'));
      expect(await file.exists(), isTrue);

      await templateRepository.deleteTemplate('template:Gratitude');

      expect(await file.exists(), isFalse);
    });

    test('NoteRepository.getAllNotes does NOT include template notes', () async {
      await noteRepository.createNote(title: 'Real Note', initialContent: 'A real note.');
      await templateRepository.saveTemplate('template:Gratitude', 'template body');

      final all = await noteRepository.getAllNotes();

      expect(all.any((n) => n.id.startsWith('template:')), isFalse);
      expect(all.any((n) => n.title == 'Real Note'), isTrue);
    });
  });
}
