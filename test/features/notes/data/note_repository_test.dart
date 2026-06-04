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
              original_note_id TEXT
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
            CREATE TABLE IF NOT EXISTS note_tags (
              note_id TEXT NOT NULL,
              tag TEXT NOT NULL,
              PRIMARY KEY (note_id, tag)
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
        },
      ),
    );

    storage = FakeVaultStorage();

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWith((ref) async => db),
        vaultServiceProvider.overrideWith((ref) {
          return VaultServiceImpl(
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

  group('NoteRepository getGraphData tests with temporal nodes', () {
    test('should generate virtual temporal nodes and hierarchical connecting edges for daily notes', () async {
      final repository = container.read(noteRepositoryProvider);

      // Create a normal general note
      final generalNote = await repository.createNote(
        title: 'Project Ideas',
        initialContent: 'This is a normal note about coding ideas.',
      );

      // Create a daily reflection note for June 4, 2026 (Thursday of Week 23, 2026)
      final dailyNote = await repository.createNote(
        title: 'Daily Reflection',
        initialContent: '---\ntitle: "Daily Reflection"\ndate: 2026-06-04\n---\n\nWorked on Flutter graph views today.',
        isDaily: true,
        dailyDate: '2026-06-04',
      );

      final graphData = await repository.getGraphData();

      // Check nodes: generalNote + dailyNote + week + year (month removed)
      expect(graphData.nodes.length, equals(4));

      // Find the normal nodes
      final generalNode = graphData.nodes.firstWhere((n) => n.id == generalNote.id);
      expect(generalNode.isTemporal, isFalse);
      expect(generalNode.temporalType, isNull);
      expect(generalNode.title, equals('Project Ideas'));

      final dailyNodeRef = graphData.nodes.firstWhere((n) => n.id == dailyNote.id);
      expect(dailyNodeRef.isTemporal, isFalse);
      expect(dailyNodeRef.temporalType, isNull);
      expect(dailyNodeRef.title, equals('Daily Reflection'));

      // Find week node
      final weekNode = graphData.nodes.firstWhere((n) => n.id == 'week-2026-23');
      expect(weekNode.isTemporal, isTrue);
      expect(weekNode.temporalType, equals('week'));
      expect(weekNode.title, equals('Week 23, 2026'));

      // Find year node (month node removed — hierarchy is now day -> week -> year)
      final yearNode = graphData.nodes.firstWhere((n) => n.id == 'year-2026');
      expect(yearNode.isTemporal, isTrue);
      expect(yearNode.temporalType, equals('year'));
      expect(yearNode.title, equals('2026'));

      // Check edges: dailyNote -> week -> year (2 edges)
      expect(graphData.edges.length, equals(2));

      final edgeDayToWeek = graphData.edges.firstWhere((e) => e.sourceId == dailyNote.id && e.targetId == 'week-2026-23');
      expect(edgeDayToWeek, isNotNull);

      final edgeWeekToYear = graphData.edges.firstWhere((e) => e.sourceId == 'week-2026-23' && e.targetId == 'year-2026');
      expect(edgeWeekToYear, isNotNull);
    });

    test('should prevent duplicate temporal nodes and duplicate connecting edges across multiple daily notes', () async {
      final repository = container.read(noteRepositoryProvider);

      // Create first daily note for June 4, 2026 (Thursday of Week 23, 2026)
      final dailyNote1 = await repository.createNote(
        title: 'Daily Reflection 1',
        initialContent: '---\ntitle: "Daily Reflection"\ndate: 2026-06-04\n---\n\nReflection 1.',
        isDaily: true,
        dailyDate: '2026-06-04',
      );

      // Create second daily note for June 5, 2026 (Friday of Week 23, 2026) - same week, month, and year!
      final dailyNote2 = await repository.createNote(
        title: 'Daily Reflection 2',
        initialContent: '---\ntitle: "Daily Reflection"\ndate: 2026-06-05\n---\n\nReflection 2.',
        isDaily: true,
        dailyDate: '2026-06-05',
      );

      final graphData = await repository.getGraphData();

      // Nodes: dailyNote1 + dailyNote2 + 1 week + 1 year = 4 nodes (month removed)
      expect(graphData.nodes.length, equals(4));

      // Edges:
      // dailyNote1 -> week-2026-23 (1)
      // dailyNote2 -> week-2026-23 (2)
      // week-2026-23 -> year-2026 (3)
      // Total edges should be 3 (no duplicate for week->year)
      expect(graphData.edges.length, equals(3));

      expect(graphData.edges.any((e) => e.sourceId == dailyNote1.id && e.targetId == 'week-2026-23'), isTrue);
      expect(graphData.edges.any((e) => e.sourceId == dailyNote2.id && e.targetId == 'week-2026-23'), isTrue);
      expect(graphData.edges.where((e) => e.sourceId == 'week-2026-23' && e.targetId == 'year-2026').length, equals(1));
    });

    test('should include ghost notes in graph data with isGhost set to true', () async {
      final repository = container.read(noteRepositoryProvider);

      // Create a ghost note and a real note that wikilinks to it so it has an
      // edge and is not pruned as an unreferenced orphan.
      final ghostNote = await repository.createGhostNote('Future Topic');
      await repository.createNote(
        title: 'Linking Note',
        initialContent: '---\ntitle: "Linking Note"\n---\n\nSee [[Future Topic]] for details.',
      );

      final graphData = await repository.getGraphData();

      // Find the ghost note node
      final ghostNodeRef = graphData.nodes.firstWhere((n) => n.id == ghostNote.id);
      expect(ghostNodeRef.isGhost, isTrue);
      expect(ghostNodeRef.title, equals('Future Topic'));
    });

   group('ISO Week Number calculation edge cases', () {
      test('ISO week calculations for boundary dates', () async {
        final repository = container.read(noteRepositoryProvider);

        // Jan 1, 2026 is a Thursday, so it should be week 1
        await repository.createNote(
          title: 'Daily Reflection',
          initialContent: '---\ntitle: "Daily Reflection"\ndate: 2026-01-01\n---\n\nJan 1',
          isDaily: true,
          dailyDate: '2026-01-01',
        );

        final graphData = await repository.getGraphData();
        final weekNode = graphData.nodes.firstWhere((n) => n.temporalType == 'week');
        expect(weekNode.id, equals('week-2026-01'));
      });
    });
  });
}
