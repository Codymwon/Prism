import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/core/services/note_ingestion_service.dart';
import 'package:prism/features/notes/data/adapters/vault_service_impl.dart';
import 'package:prism/features/notes/data/adapters/sqlite_metadata_indexer.dart';
import 'package:prism/features/notes/data/adapters/markdown_content_parser.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/vault_storage.dart';
import 'package:prism/features/graph/data/graph_node_repository.dart';

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

          await db.execute('''
            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
              id UNINDEXED,
              title,
              body,
              tokenize = 'porter'
            )
          ''');

          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title COLLATE NOCASE)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_non_daily_updated ON notes(is_ghost, is_daily, updated_at DESC)');
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

  group('NoteRepository getGraphData tests with temporal nodes', () {
    test('should generate virtual temporal nodes and hierarchical connecting edges for daily notes', () async {
      final repository = container.read(noteRepositoryProvider);
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

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

      final graphData = await graphNodeRepository.getGraphData();

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
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

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

      final graphData = await graphNodeRepository.getGraphData();

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
      final graphNodeRepository = container.read(graphNodeRepositoryProvider);

      // Create a ghost note and a real note that wikilinks to it so it has an
      // edge and is not pruned as an unreferenced orphan.
      final ghostNote = await repository.createGhostNote('Future Topic');
      await repository.createNote(
        title: 'Linking Note',
        initialContent: '---\ntitle: "Linking Note"\n---\n\nSee [[Future Topic]] for details.',
      );

      final graphData = await graphNodeRepository.getGraphData();

      // Find the ghost note node
      final ghostNodeRef = graphData.nodes.firstWhere((n) => n.id == ghostNote.id);
      expect(ghostNodeRef.isGhost, isTrue);
      expect(ghostNodeRef.title, equals('Future Topic'));
    });

   group('ISO Week Number calculation edge cases', () {
      test('ISO week calculations for boundary dates', () async {
        final repository = container.read(noteRepositoryProvider);
        final graphNodeRepository = container.read(graphNodeRepositoryProvider);

        // Jan 1, 2026 is a Thursday, so it should be week 1
        await repository.createNote(
          title: 'Daily Reflection',
          initialContent: '---\ntitle: "Daily Reflection"\ndate: 2026-01-01\n---\n\nJan 1',
          isDaily: true,
          dailyDate: '2026-01-01',
        );

        final graphData = await graphNodeRepository.getGraphData();
        final weekNode = graphData.nodes.firstWhere((n) => n.temporalType == 'week');
        expect(weekNode.id, equals('week-2026-01'));
      });
    });
  });

  group('NoteRepository readNoteContent tests', () {
    test('readNoteContent reads content strictly via the VaultStorage provider seam', () async {
      final fakeStorage = FakeVaultStorage();
      await fakeStorage.writeContent('some_path.md', 'hello from fake storage');

      final overrideContainer = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
          vaultStorageProvider.overrideWith((ref) => fakeStorage),
        ],
      );
      addTearDown(overrideContainer.dispose);

      // We need to insert a note to DB so getNoteById works
      await db.insert('notes', {
        'id': 'test-note-id',
        'title': 'Test Note',
        'file_path': 'some_path.md',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final repo = overrideContainer.read(noteRepositoryProvider);
      final content = await repo.readNoteContent('test-note-id');

      expect(content, equals('hello from fake storage'));
    });
  });

  group('NoteRepository virtual folders optimized queries', () {
    test('getAllNonDailyNotes, getDailyNotes, and getUncategorizedNotes work correctly', () async {
      final repository = container.read(noteRepositoryProvider);

      // Create a daily note
      await repository.createNote(
        title: 'Daily Reflection 1',
        initialContent: 'Reflection.',
        isDaily: true,
        dailyDate: '2026-06-04',
      );

      // Create a non-daily note
      final nonDaily = await repository.createNote(
        title: 'Project Ideas',
        initialContent: 'This is a normal note.',
      );

      // Create another non-daily note that will be categorized
      final categorized = await repository.createNote(
        title: 'Categorized Note',
        initialContent: 'This note is in a folder.',
      );

      // Insert folder mapping for the categorized note
      await db.insert('note_folders', {
        'note_id': categorized.id,
        'folder_id': 'folder-1',
      });

      // Verify getDailyNotes returns only the daily note
      final dailyNotes = await repository.getDailyNotes();
      expect(dailyNotes.length, equals(1));
      expect(dailyNotes.first.title, equals('Daily Reflection 1'));

      // Verify getAllNonDailyNotes returns both non-daily notes
      final nonDailyNotes = await repository.getAllNonDailyNotes();
      expect(nonDailyNotes.length, equals(2));
      expect(nonDailyNotes.any((n) => n.id == nonDaily.id), isTrue);
      expect(nonDailyNotes.any((n) => n.id == categorized.id), isTrue);

      // Verify getUncategorizedNotes returns only the uncategorized non-daily note
      final uncategorizedNotes = await repository.getUncategorizedNotes();
      expect(uncategorizedNotes.length, equals(1));
      expect(uncategorizedNotes.first.id, equals(nonDaily.id));
    });
  });

  group('FTS5 Query Sanitizer (buildSafeFts5Query)', () {
    test('splits whitespace-separated tokens and formats each with double quotes and prefix wildcard', () {
      expect(buildSafeFts5Query('to be or not'), equals('"to"* AND "be"* AND "or"* AND "not"*'));
      expect(buildSafeFts5Query('flutter dart'), equals('"flutter"* AND "dart"*'));
    });

    test('strips embedded double quotes safely', () {
      expect(buildSafeFts5Query('"hello" "world"'), equals('"hello"* AND "world"*'));
      expect(buildSafeFts5Query('apple "banana" cherry'), equals('"apple"* AND "banana"* AND "cherry"*'));
    });

    test('safely handles reserved FTS5 boolean keywords and operators without syntax error', () {
      expect(buildSafeFts5Query('AND'), equals('"AND"*'));
      expect(buildSafeFts5Query('OR'), equals('"OR"*'));
      expect(buildSafeFts5Query('NOT'), equals('"NOT"*'));
      expect(buildSafeFts5Query('NEAR'), equals('"NEAR"*'));
      expect(buildSafeFts5Query('to and or not near'), equals('"to"* AND "and"* AND "or"* AND "not"* AND "near"*'));
    });

    test('returns empty string for empty, whitespace, or punctuation-only queries', () {
      expect(buildSafeFts5Query(''), equals(''));
      expect(buildSafeFts5Query('   '), equals(''));
      expect(buildSafeFts5Query('"""'), equals(''));
      expect(buildSafeFts5Query('***'), equals(''));
      expect(buildSafeFts5Query('()'), equals(''));
    });

    test('preserves non-Latin Unicode scripts (Devanagari, Japanese, accented characters)', () {
      expect(buildSafeFts5Query('नमस्ते भारत'), equals('"नमस्ते"* AND "भारत"*'));
      expect(buildSafeFts5Query('ノート メモ'), equals('"ノート"* AND "メモ"*'));
      expect(buildSafeFts5Query('café résumé'), equals('"café"* AND "résumé"*'));
    });
  });

  group('True Full-Text Search (Body Indexing & Search)', () {
    test('searches and finds notes when keyword exists strictly inside the markdown body', () async {
      final repository = container.read(noteRepositoryProvider);

      await repository.createNote(
        title: 'Physics Lab',
        initialContent: '# Physics Lab\n\nToday we investigated quantum superposition in subatomic particles.',
      );

      await repository.createNote(
        title: 'Biology Field Work',
        initialContent: '# Biology Field Work\n\nObserved photosynthesis in local flora.',
      );

      // Search for "superposition" which ONLY appears in the body of Physics Lab
      final results = await repository.searchNotes('superposition');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Physics Lab'));

      // Search for "photosynthesis" which ONLY appears in the body of Biology Field Work
      final bioResults = await repository.searchNotes('photosynthesis');
      expect(bioResults.length, equals(1));
      expect(bioResults.first.title, equals('Biology Field Work'));
    });

    test('searches and finds notes when keyword is in the title or both title and body', () async {
      final repository = container.read(noteRepositoryProvider);

      await repository.createNote(
        title: 'Quantum Computing Fundamentals',
        initialContent: '# Quantum Computing Fundamentals\n\nIntroduction to qubits and entanglement.',
      );

      // Search matching title
      final titleMatches = await repository.searchNotes('Fundamentals');
      expect(titleMatches.length, equals(1));
      expect(titleMatches.first.title, equals('Quantum Computing Fundamentals'));

      // Search matching both
      final bothMatches = await repository.searchNotes('Quantum');
      expect(bothMatches.isNotEmpty, isTrue);
      expect(bothMatches.any((n) => n.title == 'Quantum Computing Fundamentals'), isTrue);
    });

    test('executes FTS queries containing reserved operators without SQLite syntax error crashes', () async {
      final repository = container.read(noteRepositoryProvider);

      await repository.createNote(
        title: 'Literature Review',
        initialContent: '# Literature Review\n\nTo be or not to be, that is the question.',
      );

      // Searching for boolean operators "to be or not" must NOT crash SQLite with syntax error
      final results = await repository.searchNotes('to be or not');
      expect(results.length, equals(1));
      expect(results.first.title, equals('Literature Review'));

      // Searching for "NOT" alone
      final notResults = await repository.searchNotes('NOT');
      expect(notResults.length, equals(1));
    });

    test('searchNotes excludes ghost notes from results', () async {
      final repository = container.read(noteRepositoryProvider);

      await repository.createGhostNote('Ghostly Apparition');

      final results = await repository.searchNotes('Ghostly');
      expect(results, isEmpty);
    });
  });

  group('Wikilink Autocomplete Optimization (getTitleSuggestions)', () {
    test('returns title suggestions using FTS prefix matching with fallback to indexed LIKE', () async {
      final repository = container.read(noteRepositoryProvider);

      await repository.createNote(
        title: 'Artificial Intelligence Overview',
        initialContent: 'Overview content.',
      );
      await repository.createNote(
        title: 'Art History',
        initialContent: 'Renaissance era.',
      );
      await repository.createNote(
        title: 'Machine Learning',
        initialContent: 'Supervised learning.',
      );

      final suggestions = await repository.getTitleSuggestions('Art');
      expect(suggestions.length, equals(2));
      expect(suggestions.any((n) => n.title == 'Artificial Intelligence Overview'), isTrue);
      expect(suggestions.any((n) => n.title == 'Art History'), isTrue);

      final mlSuggestions = await repository.getTitleSuggestions('Machine');
      expect(mlSuggestions.length, equals(1));
      expect(mlSuggestions.first.title, equals('Machine Learning'));
    });

    test('returns empty list for whitespace or non-matching query', () async {
      final repository = container.read(noteRepositoryProvider);
      expect(await repository.getTitleSuggestions(''), isEmpty);
      expect(await repository.getTitleSuggestions('   '), isEmpty);
      expect(await repository.getTitleSuggestions('NonExistentTitle'), isEmpty);
    });
  });

  group('Pagination Support (limit & offset)', () {
    test('getAllNotes supports limit and offset parameters', () async {
      final repository = container.read(noteRepositoryProvider);

      // Insert 5 notes
      for (int i = 1; i <= 5; i++) {
        await repository.createNote(
          title: 'Note $i',
          initialContent: 'Content $i',
        );
      }

      // Query with limit 2, offset 0
      final page1 = await repository.getAllNotes(sort: NoteSort.title, limit: 2, offset: 0);
      expect(page1.length, equals(2));
      expect(page1[0].title, equals('Note 1'));
      expect(page1[1].title, equals('Note 2'));

      // Query with limit 2, offset 2
      final page2 = await repository.getAllNotes(sort: NoteSort.title, limit: 2, offset: 2);
      expect(page2.length, equals(2));
      expect(page2[0].title, equals('Note 3'));
      expect(page2[1].title, equals('Note 4'));

      // Query with limit 2, offset 4
      final page3 = await repository.getAllNotes(sort: NoteSort.title, limit: 2, offset: 4);
      expect(page3.length, equals(1));
      expect(page3[0].title, equals('Note 5'));
    });

    test('getAllNonDailyNotes and getDailyNotes support limit and offset', () async {
      final repository = container.read(noteRepositoryProvider);

      // 2 daily notes
      await repository.createNote(
        title: 'Daily 1',
        isDaily: true,
        dailyDate: '2026-06-01',
      );
      await repository.createNote(
        title: 'Daily 2',
        isDaily: true,
        dailyDate: '2026-06-02',
      );

      // 2 non-daily notes
      await repository.createNote(
        title: 'Standard 1',
        isDaily: false,
      );
      await repository.createNote(
        title: 'Standard 2',
        isDaily: false,
      );

      final dailyPaged = await repository.getDailyNotes(sort: NoteSort.title, limit: 1, offset: 1);
      expect(dailyPaged.length, equals(1));
      expect(dailyPaged.first.title, equals('Daily 2'));

      final nonDailyPaged = await repository.getAllNonDailyNotes(sort: NoteSort.title, limit: 1, offset: 0);
      expect(nonDailyPaged.length, equals(1));
      expect(nonDailyPaged.first.title, equals('Standard 1'));
    });
  });

  group('Batched Tag Loading (batchGetTagsForAllNotes)', () {
    test('returns all tags grouped by note ID in a single query', () async {
      final repository = container.read(noteRepositoryProvider);

      final noteA = await repository.createNote(
        title: 'Note A',
        initialContent: 'Content with #flutter and #dart tags.',
      );
      final noteB = await repository.createNote(
        title: 'Note B',
        initialContent: 'Content with #architecture and #flutter tags.',
      );
      final noteC = await repository.createNote(
        title: 'Note C',
        initialContent: 'Content without tags.',
      );

      final tagsMap = await repository.batchGetTagsForAllNotes();

      expect(tagsMap[noteA.id], containsAll(['flutter', 'dart']));
      expect(tagsMap[noteB.id], containsAll(['architecture', 'flutter']));
      expect(tagsMap[noteC.id], isNull);
    });
  });
}
