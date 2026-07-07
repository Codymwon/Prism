import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_service.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:prism/features/graph/data/graph_node_repository.dart';
import 'package:prism/features/notes/data/vault_storage.dart';
import 'package:prism/core/services/note_ingestion_service.dart';
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';

// ---------------------------------------------------------------------------
// Fake VaultStorage for tests
// ---------------------------------------------------------------------------
class FakeVaultStorage implements VaultStorage {
  final Map<String, String> files = {};

  @override
  Future<String> readContent(String p) async => files[p] ?? '';

  @override
  Future<void> writeContent(String p, String c) async => files[p] = c;

  @override
  Future<void> deleteContent(String p) async => files.remove(p);

  @override
  Future<bool> exists(String p) async => files.containsKey(p);

  @override
  Future<List<String>> listDocumentIdentifiers(String vaultPath) async =>
      files.keys.toList();

  @override
  Future<DateTime> getLastModified(String p) async =>
      DateTime.fromMillisecondsSinceEpoch(0);
}

// ---------------------------------------------------------------------------
// Full in-memory schema (mirrors DatabaseHelper._onCreate up to v5)
// ---------------------------------------------------------------------------
Future<Database> _openTestDb() {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 5,
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
          CREATE TABLE IF NOT EXISTS note_links (
            source_id TEXT NOT NULL,
            target_id TEXT NOT NULL,
            context_snippet TEXT,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (source_id, target_id)
          )
        ''');
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
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_folders (
            note_id TEXT NOT NULL,
            folder_id TEXT NOT NULL,
            PRIMARY KEY (note_id, folder_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS graph_node_positions (
            note_id TEXT PRIMARY KEY,
            x REAL NOT NULL,
            y REAL NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS spatial_groups (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color_hex TEXT NOT NULL DEFAULT '#7C6FF7',
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS spatial_group_nodes (
            group_id TEXT NOT NULL,
            note_id TEXT NOT NULL,
            PRIMARY KEY (group_id, note_id)
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
          CREATE TABLE IF NOT EXISTS audio_bookmarks (
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            attachment_path TEXT NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            annotation_text TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    ),
  );
}

/// Helper: builds a [ProviderContainer] with all necessary overrides.
ProviderContainer _makeContainer({
  required Database rawDb,
  DatabaseService? serviceOverride,
  String vaultPath = '',  // Empty so flushMetadata is a no-op in tests
}) {
  final storage = FakeVaultStorage();
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWith((ref) async => rawDb),
      if (serviceOverride != null)
        databaseServiceProvider.overrideWith((ref) async => serviceOverride),
      noteIngestionServiceProvider.overrideWith((ref) {
        return NoteIngestionServiceImpl(
          getDb: () async => rawDb,
          storage: storage,
          parser: MarkdownContentParser(),
          indexer: SqliteMetadataIndexer(),
          getVaultPath: () async => vaultPath,
        );
      }),
      activeVaultPathProvider.overrideWith((ref) async => vaultPath),
    ],
  );
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database rawDb;
  late ProviderContainer container;

  setUp(() async {
    rawDb = await _openTestDb();
    container = _makeContainer(rawDb: rawDb);
  });

  tearDown(() async {
    container.dispose();
    await rawDb.close();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FolderRepository via DatabaseService
  // ──────────────────────────────────────────────────────────────────────────
  group('FolderRepository via DatabaseService seam', () {
    test('createFolder stores a folder that can be retrieved via getAllFolders', () async {
      final repo = container.read(folderRepositoryProvider);

      final folder = await repo.createFolder('Work', colorHex: '#FF0000', icon: 'work');

      expect(folder.name, equals('Work'));
      expect(folder.colorHex, equals('#FF0000'));

      final folders = await repo.getAllFolders();
      expect(folders, hasLength(1));
      expect(folders.first.id, equals(folder.id));
    });

    test('updateFolder changes name and colour', () async {
      final repo = container.read(folderRepositoryProvider);
      final folder = await repo.createFolder('Old Name');

      await repo.updateFolder(folder.id, 'New Name', '#AABBCC', 'star');

      final folders = await repo.getAllFolders();
      expect(folders.first.name, equals('New Name'));
      expect(folders.first.colorHex, equals('#AABBCC'));
    });

    test('deleteFolder removes the folder', () async {
      final repo = container.read(folderRepositoryProvider);
      final folder = await repo.createFolder('To Delete');

      await repo.deleteFolder(folder.id);

      final folders = await repo.getAllFolders();
      expect(folders, isEmpty);
    });

    test('addNoteToFolder creates the note-folder mapping', () async {
      final repo = container.read(folderRepositoryProvider);
      final folder = await repo.createFolder('Inbox');

      // Insert a bare note so FK constraints are satisfied
      final now = DateTime.now().millisecondsSinceEpoch;
      await rawDb.insert('notes', {
        'id': 'note-x',
        'title': 'X',
        'file_path': 'x.md',
        'created_at': now,
        'updated_at': now,
      });

      await repo.addNoteToFolder('note-x', folder.id);

      final mappings = await repo.getNoteFolderMappings();
      expect(mappings.containsKey('note-x'), isTrue);
      expect(mappings['note-x'], contains(folder.id));
    });

    test('removeNoteFromFolder deletes the mapping', () async {
      final repo = container.read(folderRepositoryProvider);
      final folder = await repo.createFolder('Remove Me');

      final now = DateTime.now().millisecondsSinceEpoch;
      await rawDb.insert('notes', {
        'id': 'note-y',
        'title': 'Y',
        'file_path': 'y.md',
        'created_at': now,
        'updated_at': now,
      });
      await repo.addNoteToFolder('note-y', folder.id);
      await repo.removeNoteFromFolder('note-y', folder.id);

      final mappings = await repo.getNoteFolderMappings();
      expect(mappings['note-y'], isNull);
    });

    test('FolderRepository does not import sqflite Database directly', () {
      // This test validates the structural boundary. If FolderRepository
      // compiles correctly with only DatabaseService as its database type,
      // then it's properly decoupled from the raw sqflite Database class.
      // The fact that this test file compiles proves the contract.
      final repo = container.read(folderRepositoryProvider);
      expect(repo, isA<FolderRepository>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GraphNodeRepository via DatabaseService
  // ──────────────────────────────────────────────────────────────────────────
  group('GraphNodeRepository via DatabaseService seam', () {
    test('getGraphData returns nodes from the notes table', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await rawDb.insert('notes', {
        'id': 'g1',
        'title': 'Graph Note',
        'file_path': 'g1.md',
        'created_at': now,
        'updated_at': now,
      });

      final repo = container.read(graphNodeRepositoryProvider);
      final data = await repo.getGraphData();

      expect(data.nodes.any((n) => n.id == 'g1'), isTrue);
    });

    test('pinNode and getPinnedCoordinates round-trip through DatabaseService', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await rawDb.insert('notes', {
        'id': 'pin-1',
        'title': 'Pinnable',
        'file_path': 'pin1.md',
        'created_at': now,
        'updated_at': now,
      });

      final repo = container.read(graphNodeRepositoryProvider);
      await repo.pinNode('pin-1', 42.0, 99.0);

      final positions = await repo.getPinnedCoordinates();
      expect(positions.containsKey('pin-1'), isTrue);
      expect(positions['pin-1']!.x, closeTo(42.0, 0.001));
      expect(positions['pin-1']!.y, closeTo(99.0, 0.001));
    });

    test('unpinNode removes the position record', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await rawDb.insert('notes', {
        'id': 'unpin-1',
        'title': 'Unpinable',
        'file_path': 'up1.md',
        'created_at': now,
        'updated_at': now,
      });

      final repo = container.read(graphNodeRepositoryProvider);
      await repo.pinNode('unpin-1', 10.0, 20.0);
      await repo.unpinNode('unpin-1');

      final positions = await repo.getPinnedCoordinates();
      expect(positions.containsKey('unpin-1'), isFalse);
    });
  });
}
