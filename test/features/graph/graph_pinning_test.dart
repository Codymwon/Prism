import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/core/services/note_ingestion_service.dart';
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/notes/data/vault_storage.dart';
import 'package:prism/features/graph/data/graph_node_repository.dart';
import 'package:prism/features/graph/presentation/providers/graph_providers.dart';
import 'package:prism/features/graph/presentation/screens/graph_screen.dart';
import 'package:prism/features/graph/data/graph_models.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';

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
            CREATE TABLE IF NOT EXISTS graph_node_positions (
              note_id TEXT PRIMARY KEY,
              x REAL NOT NULL,
              y REAL NOT NULL,
              is_pinned INTEGER NOT NULL DEFAULT 0,
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

    test('pinNode returns early if target note is a ghost note', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Create a ghost note
      final ghostNote = await repository.createGhostNote('Ghost Note');
      expect(ghostNote.isGhost, isTrue);

      // Try to pin the ghost note
      await graphNodeRepository.pinNode(ghostNote.id, 150.5, 300.75);

      // Retrieve pinned coordinates
      final pinnedCoords = await graphNodeRepository.getPinnedCoordinates();

      // Verify the ghost note was not pinned
      expect(pinnedCoords.containsKey(ghostNote.id), isFalse);
    });
  });

  group('GraphNodeRepository Link Count and Query Plan Tests', () {
    test('getGraphData correctly calculates link counts', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Add target_id index for query plan verification
      await db.execute('CREATE INDEX IF NOT EXISTS idx_note_links_target ON note_links(target_id)');

      // Create three notes
      final noteA = await repository.createNote(
        title: 'Note A',
        initialContent: 'Link to [[Note B]]',
      );
      final noteB = await repository.createNote(
        title: 'Note B',
        initialContent: 'Link to [[Note C]]',
      );
      final noteC = await repository.createNote(
        title: 'Note C',
        initialContent: 'No links',
      );

      // Add links between A->B and B->C
      final time = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'note_links',
        {
          'source_id': noteA.id,
          'target_id': noteB.id,
          'created_at': time,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'note_links',
        {
          'source_id': noteB.id,
          'target_id': noteC.id,
          'created_at': time,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Get graph data
      final data = await graphNodeRepository.getGraphData();
      final nodes = data.nodes;

      final nodeANode = nodes.firstWhere((n) => n.id == noteA.id);
      final nodeBNode = nodes.firstWhere((n) => n.id == noteB.id);
      final nodeCNode = nodes.firstWhere((n) => n.id == noteC.id);

      // Verify link counts:
      // Note A: 1 link (outgoing: A->B)
      // Note B: 2 links (incoming: A->B, outgoing: B->C)
      // Note C: 1 link (incoming: B->C)
      expect(nodeANode.linkCount, equals(1));
      expect(nodeBNode.linkCount, equals(2));
      expect(nodeCNode.linkCount, equals(1));

      // Verify query plan uses indexes
      final queryPlan = await db.rawQuery('''
        EXPLAIN QUERY PLAN
        SELECT n.id,
          (SELECT COUNT(*) FROM (
            SELECT 1 FROM note_links WHERE source_id = n.id
            UNION ALL
            SELECT 1 FROM note_links WHERE target_id = n.id
          )) as link_count
        FROM notes n
      ''');
      final planStr = queryPlan.toString();
      // Verify that query plan indicates index usage and no table scan on note_links
      expect(planStr, contains('idx_note_links_target'));
      expect(planStr, contains('sqlite_autoindex_note_links_1'));
      expect(planStr, isNot(contains('SCAN note_links')));
    });
  });

  group('Graph Dragging and Pinning Behaviors (dragToPin enabled vs disabled)', () {
    testWidgets('With dragToPin ENABLED: dragging normal note calls pinNode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2500.0, 2500.0);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(2500.0, 2500.0));
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });

      final mockRepo = FakeGraphNodeRepository();
      final nodes = [
        GraphNode(id: 'note-1', title: 'Normal Note', linkCount: 1, isTemporal: false, isPinned: false, isGhost: false, createdAt: DateTime(2026)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            graphNodeRepositoryProvider.overrideWithValue(mockRepo),
            dragToPinEnabledProvider.overrideWith(() => FakeDragToPinEnabledNotifier(true)),
          ],
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphSimulationCanvas(
                nodes: nodes,
                edges: const [],
                repulsionRate: 1.0,
                repulsionPercentage: 0.5,
                attractionRate: 0.35,
                damping: 0.85,
                transformationController: TransformationController(),
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('note-1', const Offset(100.0, 100.0));
      await tester.pump();

      final keyFinder = find.byKey(const ValueKey('drag_note-1'));
      final center = tester.getCenter(keyFinder);

      // Drag the node starting from its explicit coordinates
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(20.0, 20.0)); // win arena
      await tester.pump();
      await gesture.moveBy(const Offset(30.0, 30.0)); // drag
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Check if pinNode was called
      expect(mockRepo.pinCalls, isNotEmpty);
      expect(mockRepo.pinCalls.first.$1, equals('note-1'));

      // Clean up ticker
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('With dragToPin ENABLED: dragging ghost note does NOT call pinNode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2500.0, 2500.0);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(2500.0, 2500.0));
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });

      final mockRepo = FakeGraphNodeRepository();
      final nodes = [
        GraphNode(id: 'ghost-1', title: 'Ghost Note', linkCount: 1, isTemporal: false, isPinned: false, isGhost: true, createdAt: DateTime(2026)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            graphNodeRepositoryProvider.overrideWithValue(mockRepo),
            dragToPinEnabledProvider.overrideWith(() => FakeDragToPinEnabledNotifier(true)),
          ],
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphSimulationCanvas(
                nodes: nodes,
                edges: const [],
                repulsionRate: 1.0,
                repulsionPercentage: 0.5,
                attractionRate: 0.35,
                damping: 0.85,
                transformationController: TransformationController(),
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('ghost-1', const Offset(100.0, 100.0));
      await tester.pump();

      final keyFinder = find.byKey(const ValueKey('drag_ghost-1'));
      final center = tester.getCenter(keyFinder);

      // Drag the node
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(20.0, 20.0));
      await tester.pump();
      await gesture.moveBy(const Offset(30.0, 30.0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Check if pinNode was NOT called
      expect(mockRepo.pinCalls, isEmpty);

      // Clean up ticker
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('With dragToPin DISABLED: dragging unpinned note does NOT call pinNode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2500.0, 2500.0);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(2500.0, 2500.0));
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });

      final mockRepo = FakeGraphNodeRepository();
      final nodes = [
        GraphNode(id: 'note-1', title: 'Unpinned Note', linkCount: 1, isTemporal: false, isPinned: false, isGhost: false, createdAt: DateTime(2026)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            graphNodeRepositoryProvider.overrideWithValue(mockRepo),
            dragToPinEnabledProvider.overrideWith(() => FakeDragToPinEnabledNotifier(false)),
          ],
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphSimulationCanvas(
                nodes: nodes,
                edges: const [],
                repulsionRate: 1.0,
                repulsionPercentage: 0.5,
                attractionRate: 0.35,
                damping: 0.85,
                transformationController: TransformationController(),
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('note-1', const Offset(100.0, 100.0));
      await tester.pump();

      final keyFinder = find.byKey(const ValueKey('drag_note-1'));
      final center = tester.getCenter(keyFinder);

      // Drag the node
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(20.0, 20.0));
      await tester.pump();
      await gesture.moveBy(const Offset(30.0, 30.0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Check if pinNode was NOT called
      expect(mockRepo.pinCalls, isEmpty);

      // Clean up ticker
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('With dragToPin DISABLED: dragging pinned note calls pinNode (to update positions)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2500.0, 2500.0);
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(2500.0, 2500.0));
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.binding.setSurfaceSize(null);
      });

      final mockRepo = FakeGraphNodeRepository();
      final nodes = [
        GraphNode(id: 'note-1', title: 'Pinned Note', linkCount: 1, isTemporal: false, isPinned: true, isGhost: false, createdAt: DateTime(2026)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            graphNodeRepositoryProvider.overrideWithValue(mockRepo),
            dragToPinEnabledProvider.overrideWith(() => FakeDragToPinEnabledNotifier(false)),
          ],
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GraphSimulationCanvas(
                nodes: nodes,
                edges: const [],
                repulsionRate: 1.0,
                repulsionPercentage: 0.5,
                attractionRate: 0.35,
                damping: 0.85,
                transformationController: TransformationController(),
                disableEntranceAnimation: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<GraphSimulationCanvasState>(find.byType(GraphSimulationCanvas));
      state.setNodePositionForTesting('note-1', const Offset(2500.0, 2500.0));
      await tester.pump();

      final keyFinder = find.byKey(const ValueKey('drag_note-1'));
      final center = tester.getCenter(keyFinder);

      // Drag the node
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(20.0, 20.0));
      await tester.pump();
      await gesture.moveBy(const Offset(30.0, 30.0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Check if pinNode was called
      expect(mockRepo.pinCalls, isNotEmpty);
      expect(mockRepo.pinCalls.first.$1, equals('note-1'));

      // Clean up ticker
      await tester.pumpWidget(const SizedBox());
    });
  });
}

class FakeGraphNodeRepository implements GraphNodeRepository {
  final List<(String, double, double)> pinCalls = [];
  final List<String> unpinCalls = [];

  @override
  Future<void> pinNode(String nodeId, double x, double y) async {
    pinCalls.add((nodeId, x, y));
  }

  @override
  Future<void> unpinNode(String nodeId) async {
    unpinCalls.add(nodeId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDragToPinEnabledNotifier extends DragToPinEnabledNotifier {
  final bool initialValue;
  FakeDragToPinEnabledNotifier(this.initialValue);

  @override
  Future<bool> build() async => initialValue;
}
