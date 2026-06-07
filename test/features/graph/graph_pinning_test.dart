import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meridian/core/database/database_providers.dart';
import 'package:meridian/features/notes/data/note_repository.dart';
import 'package:meridian/features/notes/data/vault_service.dart';
import 'package:meridian/features/notes/data/adapters/vault_service_impl.dart';
import 'package:meridian/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:meridian/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:meridian/features/notes/data/vault_storage.dart';
import 'package:meridian/features/graph/data/graph_node_repository.dart';
import 'package:meridian/features/graph/presentation/providers/graph_providers.dart';

class FakeVaultStorage implements VaultStorage {
  final Map<String, String> files = {};
  final Map<String, DateTime> modTimes = {};

  @override
  Future<String> readContent(String relativePath) async {
    return files[relativePath] ?? '';
  }

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
  Future<bool> exists(String relativePath) async {
    return files.containsKey(relativePath);
  }

  @override
  Future<List<String>> listDocumentIdentifiers(String vaultPath) async {
    return files.keys.toList();
  }

  @override
  Future<DateTime> getLastModified(String relativePath) async {
    return modTimes[relativePath] ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late FakeVaultStorage storage;
  late ProviderContainer container;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
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
              original_note_id TEXT
            )
          ''');

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

          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_tags (
              note_id TEXT NOT NULL,
              tag TEXT NOT NULL,
              PRIMARY KEY (note_id, tag),
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
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
              PRIMARY KEY (note_id, folder_id),
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
              FOREIGN KEY(folder_id) REFERENCES virtual_folders(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS graph_node_positions (
              note_id TEXT PRIMARY KEY,
              x REAL NOT NULL,
              y REAL NOT NULL,
              is_pinned INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
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
              PRIMARY KEY (group_id, note_id),
              FOREIGN KEY(group_id) REFERENCES spatial_groups(id) ON DELETE CASCADE,
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    storage = FakeVaultStorage();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
        noteIngestionServiceProvider.overrideWith((ref) {
          return NoteIngestionServiceImpl(
            getDb: () async => db,
            storage: storage,
            parser: MarkdownContentParser(),
            indexer: SqliteMetadataIndexer(),
            getVaultPath: () async => '/vault',
          );
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('Interactive Node Pinning Tests', () {
    test('pinNode correctly persists coordinates to database', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Create a test note
      final note = await repository.createNote(
        title: 'Interactive Pinning',
        initialContent: 'Testing coordinates persistence',
      );

      // Pin the note
      await graphNodeRepository.pinNode(note.id, 150.5, 300.75);

      // Retrieve pinned coordinates
      final pinnedCoords = await graphNodeRepository.getPinnedCoordinates();

      expect(pinnedCoords.containsKey(note.id), isTrue);
      final position = pinnedCoords[note.id]!;
      expect(position.noteId, equals(note.id));
      expect(position.x, equals(150.5));
      expect(position.y, equals(300.75));
      expect(position.isPinned, isTrue);
    });

    test('pinNode throws ArgumentError when target is a temporal node (week-)', () async {
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      expect(
        () => graphNodeRepository.pinNode('week-2026-23', 100.0, 200.0),
        throwsArgumentError,
      );
    });

    test('pinNode throws ArgumentError when target is a temporal node (year-)', () async {
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      expect(
        () => graphNodeRepository.pinNode('year-2026', 100.0, 200.0),
        throwsArgumentError,
      );
    });

    test('unpinNode throws ArgumentError when target is a temporal node', () async {
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      expect(
        () => graphNodeRepository.unpinNode('week-2026-23'),
        throwsArgumentError,
      );
    });

    test('unpinNode deletes coordinates from graph_node_positions table', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Create a test note
      final note = await repository.createNote(
        title: 'Interactive Unpinning',
        initialContent: 'Testing deletion of pinned coordinates',
      );

      // Pin the note
      await graphNodeRepository.pinNode(note.id, 100.0, 200.0);

      // Verify it is pinned
      var pinnedCoords = await graphNodeRepository.getPinnedCoordinates();
      expect(pinnedCoords.containsKey(note.id), isTrue);

      // Unpin the note
      await graphNodeRepository.unpinNode(note.id);

      // Verify it is unpinned
      pinnedCoords = await graphNodeRepository.getPinnedCoordinates();
      expect(pinnedCoords.containsKey(note.id), isFalse);
    });

    test('pinNode does not save if the note does not exist', () async {
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Pin a non-existent note
      await graphNodeRepository.pinNode('non-existent-id', 400.0, 500.0);

      // Verify no pinned coordinates are returned
      final pinnedCoords = await graphNodeRepository.getPinnedCoordinates();
      expect(pinnedCoords.containsKey('non-existent-id'), isFalse);
    });

    test('graphDataProvider correctly merges pinned coordinates into graph nodes list', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Create a test note
      final note = await repository.createNote(
        title: 'DataProvider Merge',
        initialContent: 'Testing merging in provider',
      );

      // Pin the note
      await graphNodeRepository.pinNode(note.id, 123.0, 456.0);

      // Read graphDataProvider
      final graphAsync = await container.read(graphDataProvider.future);
      final nodes = graphAsync.nodes;

      final noteNode = nodes.firstWhere((n) => n.id == note.id);
      expect(noteNode.isPinned, isTrue);
      expect(noteNode.pinnedX, equals(123.0));
      expect(noteNode.pinnedY, equals(456.0));
    });
  });
}
