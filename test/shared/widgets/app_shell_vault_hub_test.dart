import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/providers/shared_preferences_provider.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/notes/presentation/widgets/notes_list_search_bar.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/shared/design_system/design_system.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/shared/widgets/prism_toast.dart';
import 'package:prism/shared/widgets/quick_capture_bottom_sheet.dart';
import 'package:prism/shared/widgets/vault_hub.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/folders/data/folder_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;
}

class FakeFolderRepository extends Fake implements FolderRepository {
  final List<VirtualFolder> createdFolders = [];

  @override
  Future<VirtualFolder> createFolder(String name,
      {String colorHex = '#7C6FF7', String icon = 'folder'}) async {
    final folder = VirtualFolder(
      id: 'f-1',
      name: name,
      colorHex: colorHex,
      icon: icon,
      createdAt: DateTime.now(),
      sortOrder: 1,
    );
    createdFolders.add(folder);
    return folder;
  }
}

class FakeNoteRepository extends Fake implements NoteRepository {
  final List<Note> notes;
  FakeNoteRepository({List<Note>? notes})
      : notes = notes ??
            [
              Note(
                id: 'serendipity-test-note-1',
                title: 'Serendipity Test Note',
                filePath: 'test.md',
                wordCount: 150,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isDaily: false,
                isGhost: false,
              ),
            ];

  @override
  Future<List<Note>> getAllNotes({
    NoteSort sort = NoteSort.updated,
    int? limit,
    int? offset,
  }) async =>
      notes;

  @override
  Future<Note?> getDailyNote(String dateStr) async => null;

  @override
  Future<Note?> getNoteById(String id) async {
    try {
      return notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<({int totalNotes, int totalWords, int totalLinks})>
      getVaultStats() async {
    return (totalNotes: notes.length, totalWords: 350, totalLinks: 4);
  }

  @override
  Future<List<String>> getUniqueTags() async => ['ideas', 'prism', 'release'];
}

class FakeTutorialState extends TutorialState {
  final bool initialValue;
  FakeTutorialState(this.initialValue);

  @override
  bool build() => initialValue;

  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

class FakeJournalTutorialState extends JournalTutorialState {
  final bool initialValue;
  FakeJournalTutorialState(this.initialValue);

  @override
  bool build() => initialValue;

  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

Widget buildTestAppWithRouter({
  required ProviderContainer container,
  String initialLocation = '/notes',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/notes',
            builder: (context, state) => const Scaffold(
              body: Column(
                children: [
                  NotesListSearchBar(),
                  Expanded(child: Text('Notes Screen')),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) =>
                const Scaffold(body: Text('Journal Screen')),
          ),
          GoRoute(
            path: '/graph',
            builder: (context, state) =>
                const Scaffold(body: Text('Graph Screen')),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Scaffold(body: Text('Settings Screen')),
          ),
        ],
      ),
      GoRoute(
        path: '/editor/:id',
        builder: (context, state) => Scaffold(
          body: Text('Editor Note Screen: ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/folders/create',
        builder: (context, state) => const Scaffold(
          body: Text('Create Folder Screen'),
        ),
      ),
      GoRoute(
        path: '/settings/vault-export',
        builder: (context, state) => const Scaffold(
          body: Text('Vault Export Screen'),
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'hasOnboarded': true,
      'hasCompletedTutorial': true,
      'hasCompletedJournalTutorial': true,
      'has_accepted_audio_recording_notice': true,
      'activeVaultName': 'Personal Workspace',
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('TASK-064: Dynamic Island Vault Hub Tests', () {
    testWidgets(
        'tapping search bar menu button opens the Vault Hub deck in AppShell',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 5, totalWords: 1200, totalLinks: 3)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      // Vault Hub is initially closed
      expect(find.byKey(const ValueKey('vault_hub_action_deck')), findsNothing);
      expect(container.read(vaultHubNotifierProvider), isFalse);

      // Tap the menu button in NotesListSearchBar
      final menuButton = find.byIcon(DesignIcons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pump();

      // VaultHubNotifier should be open
      expect(container.read(vaultHubNotifierProvider), isTrue);

      // Pump through forward spring animation
      await tester.pump(const Duration(milliseconds: 350));

      // Vault Hub deck is now visible with all elements
      expect(
          find.byKey(const ValueKey('vault_hub_action_deck')), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_note_count_badge')),
          findsOneWidget);
      expect(find.text('5 Notes'), findsOneWidget);
      expect(find.text('Serendipity'), findsOneWidget);
      expect(find.text('New Folder'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);
    });

    testWidgets(
        'monolithic capsule expands, gap collapses from 12dp to 0dp, and FAB rotates 45°',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 200, totalLinks: 1)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      final capsuleFinder = find.byKey(const ValueKey('monolithic_capsule'));
      final fabFinder = find.byKey(const ValueKey('app_shell_fab'));
      expect(capsuleFinder, findsOneWidget);
      expect(fabFinder, findsOneWidget);

      // Check resting bounds: gap is 12dp, FAB width is 56dp
      final RenderBox initialCapsuleBox = tester.renderObject(capsuleFinder);
      final RenderBox initialFabBox = tester.renderObject(fabFinder);
      final initialCapsuleRight =
          initialCapsuleBox.localToGlobal(Offset.zero).dx +
              initialCapsuleBox.size.width;
      final initialFabLeft = initialFabBox.localToGlobal(Offset.zero).dx;

      expect(initialFabLeft - initialCapsuleRight, closeTo(12.0, 0.5));
      expect(initialFabBox.size.width, closeTo(56.0, 0.5));
      expect(initialCapsuleBox.size.height, closeTo(57.6, 1.0)); // 56 + 1.6

      // Open Vault Hub
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Expanded checks
      final RenderBox expandedCapsuleBox = tester.renderObject(capsuleFinder);
      final RenderBox expandedFabBox = tester.renderObject(fabFinder);
      final expandedCapsuleLeft =
          expandedCapsuleBox.localToGlobal(Offset.zero).dx;
      final expandedCapsuleRight =
          expandedCapsuleLeft + expandedCapsuleBox.size.width;
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Assert 100% full-width symmetrical Universal Fusion (16dp left, 16dp right):
      expect(expandedCapsuleBox.size.width, closeTo(screenWidth - 32.0, 0.5));
      expect(expandedCapsuleLeft, closeTo(16.0, 0.5));
      expect(screenWidth - expandedCapsuleRight, closeTo(16.0, 0.5));
      // FAB remains 56dp
      expect(expandedFabBox.size.width, closeTo(56.0, 0.5));
      // Capsule expands by 128dp
      expect(expandedCapsuleBox.size.height, closeTo(185.6, 1.0));

      // FAB rotation check: Transform widget rotating by pi / 4
      final transformFinder = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsWidgets);
      final Transform rotateWidget = tester.widget(transformFinder.first);
      // In 2D rotation matrix: storage[0] = cos(pi/4) ≈ 0.7071
      expect(rotateWidget.transform.storage[0],
          closeTo(math.cos(math.pi / 4), 0.05));
    });

    testWidgets('tapping FAB dismisses active Vault Hub deck', (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 2, totalWords: 400, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(container.read(vaultHubNotifierProvider), isTrue);

      // Tap FAB to dismiss
      final fabFinder = find.byKey(const ValueKey('app_shell_fab'));
      await tester.tap(fabFinder);
      await tester.pump();

      expect(container.read(vaultHubNotifierProvider), isFalse);

      // Pump reverse animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('vault_hub_action_deck')), findsNothing);
    });

    testWidgets('tapping backdrop scrim dismisses active Vault Hub deck',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 2, totalWords: 400, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final scrimFinder = find.byKey(const ValueKey('island_modal_scrim'));
      expect(scrimFinder, findsOneWidget);

      await tester.tap(scrimFinder);
      await tester.pump();

      expect(container.read(vaultHubNotifierProvider), isFalse);
    });

    testWidgets('Serendipity action opens a random note in the editor',
        (tester) async {
      final testNote = Note(
        id: 'random-pick-42',
        title: 'Eureka Discovery',
        filePath: 'eureka.md',
        wordCount: 88,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDaily: false,
        isGhost: false,
      );
      final fakeRepo = FakeNoteRepository(notes: [testNote]);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 88, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      // Open Vault Hub
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Tap Serendipity tile
      final serendipityTile =
          find.byKey(const ValueKey('vault_hub_serendipity_tile'));
      expect(serendipityTile, findsOneWidget);
      await tester.tap(serendipityTile);
      await tester.pumpAndSettle();

      // Vault Hub should be dismissed
      expect(container.read(vaultHubNotifierProvider), isFalse);

      // Verify navigation to editor with the selected note ID
      expect(
          find.text('Editor Note Screen: random-pick-42'), findsOneWidget);
    });

    testWidgets(
        'New Folder and Tags tiles open in-island subdecks, Export navigates',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final fakeFolderRepo = FakeFolderRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          folderRepositoryProvider.overrideWithValue(fakeFolderRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 100, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      // 1. New Folder tile opens CreateFolderDeck subdeck in-island
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester
          .tap(find.byKey(const ValueKey('vault_hub_new_folder_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('subdeck_create_folder')), findsOneWidget);
      expect(find.byKey(const ValueKey('create_folder_name_input')), findsOneWidget);

      // Back button returns to Tools subdeck
      await tester.tap(find.byKey(const ValueKey('create_folder_back_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('subdeck_tools')), findsOneWidget);

      // 2. Tags tile opens TagCloudDeck subdeck in-island
      await tester.tap(find.byKey(const ValueKey('vault_hub_tags_tile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('subdeck_tags')), findsOneWidget);

      // Back button returns to Tools subdeck
      await tester.tap(find.byKey(const ValueKey('tag_cloud_back_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('subdeck_tools')), findsOneWidget);

      // 3. Export tile navigates to Vault Export Screen
      await tester.tap(find.byKey(const ValueKey('vault_hub_export_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Vault Export Screen'), findsOneWidget);
    });

    testWidgets('TagCloudDeck tag chip filters notes and dismisses island',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 100, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      final sub = container.listen(selectedTagProvider, (prev, next) {});
      addTearDown(sub.close);

      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const ValueKey('vault_hub_tags_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('subdeck_tags')), findsOneWidget);
      expect(find.byKey(const ValueKey('tag_chip_ideas')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tag_chip_ideas')));
      await tester.pumpAndSettle();

      // Tag filter should be activated
      expect(container.read(selectedTagProvider), equals('ideas'));
      // Vault Hub should be dismissed
      expect(container.read(vaultHubNotifierProvider), isFalse);
    });

    testWidgets('CreateFolderDeck creates folder and dismisses island',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final fakeFolderRepo = FakeFolderRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          folderRepositoryProvider.overrideWithValue(fakeFolderRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 100, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const ValueKey('vault_hub_new_folder_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('subdeck_create_folder')), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('create_folder_name_input')), 'Research Papers');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('create_folder_submit_btn')));
      await tester.pumpAndSettle();

      expect(fakeFolderRepo.createdFolders, hasLength(1));
      expect(fakeFolderRepo.createdFolders.first.name, equals('Research Papers'));
      expect(container.read(vaultHubNotifierProvider), isFalse);
    });

    testWidgets('Quick Capture deck inside AppShell has no top-right close button',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 100, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      container.read(quickCaptureNotifierProvider.notifier).open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('quick_capture_actions_deck')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick_capture_close')), findsNothing);
    });

    testWidgets(
        'mutual exclusivity: Toast, Menu, QuickCapture, and VaultHub dismiss each other',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 1, totalWords: 100, totalLinks: 0)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(
          container: container,
          initialLocation: '/notes',
        ),
      );
      await tester.pumpAndSettle();

      // Case 1: Open Vault Hub, then show Toast -> Vault Hub closes
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      expect(container.read(vaultHubNotifierProvider), isTrue);

      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Incoming Toast',
          );
      await tester.pump();
      expect(container.read(vaultHubNotifierProvider), isFalse);
      expect(container.read(islandToastNotifierProvider), isNotNull);

      // Case 2: Toast active, open Vault Hub -> Toast dismisses
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      expect(container.read(islandToastNotifierProvider), isNull);
      expect(container.read(vaultHubNotifierProvider), isTrue);

      // Case 3: Vault Hub active, open Quick Capture -> Vault Hub dismisses
      container.read(quickCaptureNotifierProvider.notifier).open();
      await tester.pump();
      expect(container.read(vaultHubNotifierProvider), isFalse);
      expect(container.read(quickCaptureNotifierProvider).isOpen, isTrue);

      // Case 4: Quick Capture active, open Vault Hub -> Quick Capture dismisses
      container.read(vaultHubNotifierProvider.notifier).open();
      await tester.pump();
      expect(container.read(quickCaptureNotifierProvider).isOpen, isFalse);
      expect(container.read(vaultHubNotifierProvider), isTrue);
    });

    testWidgets('VaultHub.show fallback sheet functions on non-AppShell screen',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 3, totalWords: 600, totalLinks: 2)),
        ],
      );
      addTearDown(container.dispose);

      // Standalone screen without AppShell
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => VaultHub.show(context),
                    child: const Text('Open Fallback Hub'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Fallback Hub'));
      await tester.pumpAndSettle();

      // Verify VaultHubFallbackSheet renders
      expect(find.byType(VaultHubFallbackSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_fallback_note_count_badge')),
          findsOneWidget);
      expect(find.text('3 Notes'), findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_fallback_serendipity')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_fallback_new_folder')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_fallback_tags')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('vault_hub_fallback_export')),
          findsOneWidget);
    });
  });
}
