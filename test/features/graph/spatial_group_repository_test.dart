import 'dart:io';
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
import 'package:meridian/features/settings/presentation/providers/settings_provider.dart';
import 'package:meridian/features/graph/data/spatial_group_repository.dart';


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
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('prism_test_vault');
    final vaultPath = tempDir.path;

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
            CREATE TABLE IF NOT EXISTS audio_bookmarks (
              id TEXT PRIMARY KEY,
              note_id TEXT NOT NULL,
              attachment_path TEXT NOT NULL,
              timestamp_ms INTEGER NOT NULL,
              annotation_text TEXT NOT NULL,
              created_at INTEGER NOT NULL,
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
            getVaultPath: () async => vaultPath,
          );
        }),
        activeVaultPathProvider.overrideWith((ref) async => vaultPath),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('SpatialGroupRepository Tests', () {
    test('createSpatialGroup correctly creates a spatial group and registers members', () async {
      final noteRepository = container.read(noteRepositoryProvider);
      final groupRepository = container.read(spatialGroupRepositoryProvider);

      // 1. Create two notes to be used as member nodes
      final note1 = await noteRepository.createNote(title: 'Node 1', initialContent: 'Content 1');
      final note2 = await noteRepository.createNote(title: 'Node 2', initialContent: 'Content 2');

      // 2. Create the spatial group
      final group = await groupRepository.createSpatialGroup(
        name: 'Design Patterns',
        colorHex: '#FF5733',
        memberNodeIds: [note1.id, note2.id],
      );

      expect(group.id, isNotEmpty);
      expect(group.name, equals('Design Patterns'));
      expect(group.colorHex, equals('#FF5733'));

      // 3. Verify mappings and groups are saved in DB
      final groups = await groupRepository.getAllSpatialGroups();
      expect(groups.length, equals(1));
      expect(groups.first.id, equals(group.id));

      final mappings = await groupRepository.getSpatialGroupNodeMappings();
      expect(mappings.containsKey(group.id), isTrue);
      expect(mappings[group.id], containsAll([note1.id, note2.id]));
    });

    test('updateSpatialGroup updates name, color, and completely synchronizes member node list', () async {
      final noteRepository = container.read(noteRepositoryProvider);
      final groupRepository = container.read(spatialGroupRepositoryProvider);

      final note1 = await noteRepository.createNote(title: 'Node 1');
      final note2 = await noteRepository.createNote(title: 'Node 2');
      final note3 = await noteRepository.createNote(title: 'Node 3');

      // Create group with [note1, note2]
      final group = await groupRepository.createSpatialGroup(
        name: 'Initial Group',
        colorHex: '#111111',
        memberNodeIds: [note1.id, note2.id],
      );

      // Update group: change name, color, and change members to [note2, note3] (remove note1, add note3)
      await groupRepository.updateSpatialGroup(
        id: group.id,
        name: 'Updated Group',
        colorHex: '#222222',
        memberNodeIds: [note2.id, note3.id],
      );

      // Verify basic attributes updated
      final groups = await groupRepository.getAllSpatialGroups();
      expect(groups.first.name, equals('Updated Group'));
      expect(groups.first.colorHex, equals('#222222'));

      // Verify member mappings synchronized
      final mappings = await groupRepository.getSpatialGroupNodeMappings();
      expect(mappings[group.id], isNot(contains(note1.id)));
      expect(mappings[group.id], containsAll([note2.id, note3.id]));
    });

    test('deleteSpatialGroup removes the group and automatically cascade deletes member mappings', () async {
      final noteRepository = container.read(noteRepositoryProvider);
      final groupRepository = container.read(spatialGroupRepositoryProvider);

      final note1 = await noteRepository.createNote(title: 'Node 1');
      
      final group = await groupRepository.createSpatialGroup(
        name: 'Ephemeral Group',
        colorHex: '#7C6FF7',
        memberNodeIds: [note1.id],
      );

      // Check they exist
      var groups = await groupRepository.getAllSpatialGroups();
      expect(groups.length, equals(1));
      var mappings = await groupRepository.getSpatialGroupNodeMappings();
      expect(mappings[group.id], contains(note1.id));

      // Delete group
      await groupRepository.deleteSpatialGroup(group.id);

      // Verify deletion
      groups = await groupRepository.getAllSpatialGroups();
      expect(groups, isEmpty);

      // Verify mappings are cascade deleted
      mappings = await groupRepository.getSpatialGroupNodeMappings();
      expect(mappings.containsKey(group.id), isFalse);
    });

    test('deleting a note cascade deletes its node mappings in spatial group nodes', () async {
      final noteRepository = container.read(noteRepositoryProvider);
      final groupRepository = container.read(spatialGroupRepositoryProvider);

      final note1 = await noteRepository.createNote(title: 'Note to Delete');
      final note2 = await noteRepository.createNote(title: 'Survivor Note');

      final group = await groupRepository.createSpatialGroup(
        name: 'Test Cascade Delete Note',
        colorHex: '#EEEEEE',
        memberNodeIds: [note1.id, note2.id],
      );

      // Delete the note via NoteRepository
      await noteRepository.deleteNote(note1.id);

      // Verify that the note itself is gone from the mapping, but group and note2 mapping remain
      final mappings = await groupRepository.getSpatialGroupNodeMappings();
      expect(mappings[group.id], isNot(contains(note1.id)));
      expect(mappings[group.id], contains(note2.id));
    });

    test('get1HopConnections correctly retrieves 1-hop connected notes', () async {
      final noteRepository = container.read(noteRepositoryProvider);
      final groupRepository = container.read(spatialGroupRepositoryProvider);

      final noteRoot = await noteRepository.createNote(title: 'Root Node');
      final noteA = await noteRepository.createNote(title: 'Node A');
      final noteB = await noteRepository.createNote(title: 'Node B');
      final noteUnrelated = await noteRepository.createNote(title: 'Unrelated');

      // Insert link relationships manually into note_links
      await db.insert('note_links', {
        'source_id': noteRoot.id,
        'target_id': noteA.id,
        'context_snippet': 'root connects to A',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      await db.insert('note_links', {
        'source_id': noteB.id,
        'target_id': noteRoot.id,
        'context_snippet': 'B connects to root',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final connections = await groupRepository.get1HopConnections(noteRoot.id);
      expect(connections.length, equals(2));
      expect(connections, containsAll([noteA.id, noteB.id]));
      expect(connections, isNot(contains(noteUnrelated.id)));
    });
  });
}
