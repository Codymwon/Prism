import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/core/database/database_providers.dart';
import 'package:prism/core/providers/shared_preferences_provider.dart';
import 'package:prism/core/services/vault_service.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/notes/presentation/widgets/vault_selector_title.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/shared/widgets/dynamic_island_state.dart';
import 'package:prism/shared/widgets/quick_capture_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class FakeDatabase extends Fake implements Database {
  @override
  bool get isOpen => true;
}

class FakeNoteRepository extends Fake implements NoteRepository {
  final List<Note> notes;
  FakeNoteRepository({List<Note>? notes})
      : notes = notes ??
            [
              Note(
                id: 'ws-test-note-1',
                title: 'Workspace Test Note',
                filePath: 'test.md',
                wordCount: 100,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isDaily: false,
                isGhost: false,
              ),
            ];

  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) async =>
      notes;

  @override
  Future<Note?> getDailyNote(String dateStr) async => null;

  @override
  Future<({int totalNotes, int totalWords, int totalLinks})>
      getVaultStats() async =>
          (totalNotes: notes.length, totalWords: 100, totalLinks: 0);

  @override
  Future<List<String>> getUniqueTags() async => [];
}

class FakeTutorialState extends TutorialState {
  @override
  bool build() => true;
}

class FakeJournalTutorialState extends JournalTutorialState {
  @override
  bool build() => true;
}

class FakeActiveVaultName extends ActiveVaultName {
  final String initial;
  FakeActiveVaultName([this.initial = 'Personal']);

  @override
  Future<String> build() async => initial;

  @override
  Future<void> setVaultName(String name) async {
    state = AsyncData(name);
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
          currentPath: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/notes',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notes Screen Content')),
            ),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Journal Screen Content')),
            ),
          ),
          GoRoute(
            path: '/graph',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Graph Screen Content')),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings Screen Content')),
            ),
          ),
        ],
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1),
          surface: const Color(0xFF1E1E2E),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_accepted_audio_recording_notice': true,
      'has_accepted_telemetry_consent': false,
      'active_vault_name': 'Personal',
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('TASK-066: Dynamic Island In-Island Workspace Switcher & Fusion Tests', () {
    testWidgets(
        'tapping VaultSelectorTitle inside Vault Hub switches subdeck to WorkspaceSelectorDeck without opening a modal bottom sheet',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState()),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState()),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 2, totalWords: 150, totalLinks: 1)),
          availableVaultsProvider
              .overrideWith((ref) async => ['Personal', 'Work', 'Research']),
          activeVaultNameProvider.overrideWith(() => FakeActiveVaultName()),
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
      container.read(dynamicIslandControllerProvider.notifier).openVaultHub();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Tools subdeck is visible
      expect(find.byKey(const ValueKey('subdeck_tools')), findsOneWidget);
      expect(find.byType(VaultSelectorTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('subdeck_workspaces')), findsNothing);

      // Tap VaultSelectorTitle
      await tester.tap(find.byType(VaultSelectorTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Assert NO modal bottom sheet was opened:
      expect(find.byType(BottomSheet), findsNothing);

      // In-island subdeck transition occurred:
      expect(find.byKey(const ValueKey('subdeck_workspaces')), findsOneWidget);
      expect(find.text('WORKSPACES'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace_selector_back_btn')),
          findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Research'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace_create_new_btn')),
          findsOneWidget);

      // Tap Back button to return to Tools subdeck
      await tester.tap(find.byKey(const ValueKey('workspace_selector_back_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('subdeck_tools')), findsOneWidget);
      expect(find.byKey(const ValueKey('subdeck_workspaces')), findsNothing);
    });

    testWidgets(
        'tapping an inactive workspace switches vault and collapses the Dynamic Island',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState()),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState()),
          vaultStatsProvider.overrideWith((ref) async =>
              (totalNotes: 2, totalWords: 150, totalLinks: 1)),
          availableVaultsProvider
              .overrideWith((ref) async => ['Personal', 'Work']),
          activeVaultNameProvider.overrideWith(() => FakeActiveVaultName()),
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

      // Open workspace selector subdeck directly
      container
          .read(dynamicIslandControllerProvider.notifier)
          .openVaultHub(VaultHubSubDeck.workspaceSelector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('subdeck_workspaces')), findsOneWidget);

      // Tap on 'Work' workspace tile
      final workTile = find.byKey(const ValueKey('workspace_tile_Work'));
      expect(workTile, findsOneWidget);
      await tester.tap(workTile);
      await tester.pump();

      // Island collapses to resting
      final islandState = container.read(dynamicIslandControllerProvider);
      expect(islandState is DynamicIslandResting, isTrue);
    });

    testWidgets(
        'inline workspace creation: tap "+ Create New Workspace" shows inline input field, cancel exits creation mode',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState()),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState()),
          availableVaultsProvider
              .overrideWith((ref) async => ['Personal', 'Work']),
          activeVaultNameProvider.overrideWith(() => FakeActiveVaultName()),
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

      container
          .read(dynamicIslandControllerProvider.notifier)
          .openVaultHub(VaultHubSubDeck.workspaceSelector);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const ValueKey('workspace_create_new_btn')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('workspace_inline_input')), findsNothing);

      // Tap "+ Create New Workspace"
      await tester.tap(find.byKey(const ValueKey('workspace_create_new_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Inline input form is displayed without modal dialogs:
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const ValueKey('workspace_inline_input')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('workspace_inline_confirm_btn')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('workspace_inline_cancel_btn')),
          findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.byKey(const ValueKey('workspace_inline_cancel_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Returned to workspace list
      expect(find.byKey(const ValueKey('workspace_inline_input')), findsNothing);
      expect(find.byKey(const ValueKey('workspace_create_new_btn')),
          findsOneWidget);
    });

    testWidgets(
        'Quick Capture Universal Fusion: capsule expands full width, FAB does not vanish, rotates 45°, and tapping FAB dismisses',
        (tester) async {
      final fakeRepo = FakeNoteRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) async => FakeDatabase()),
          noteRepositoryProvider.overrideWithValue(fakeRepo),
          tutorialStateProvider.overrideWith(() => FakeTutorialState()),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState()),
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
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      // Resting state
      final RenderBox initialFab = tester.renderObject(fabFinder);
      expect(initialFab.size.width, closeTo(56.0, 0.5));

      // Tap FAB to open Quick Capture
      await tester.tap(fabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(quickCaptureNotifierProvider).isOpen, isTrue);

      // Assert Universal Fusion: capsule width is screenWidth - 32dp (16dp left, 16dp right)
      final RenderBox expandedCapsuleBox = tester.renderObject(capsuleFinder);
      final expandedCapsuleLeft =
          expandedCapsuleBox.localToGlobal(Offset.zero).dx;
      final expandedCapsuleRight =
          expandedCapsuleLeft + expandedCapsuleBox.size.width;

      expect(expandedCapsuleBox.size.width, closeTo(screenWidth - 32.0, 0.5));
      expect(expandedCapsuleLeft, closeTo(16.0, 0.5));
      expect(screenWidth - expandedCapsuleRight, closeTo(16.0, 0.5));

      // Assert FAB remains docked at 56dp and its + icon rotates 45° to ✕
      final RenderBox expandedFabBox = tester.renderObject(fabFinder);
      expect(expandedFabBox.size.width, closeTo(56.0, 0.5));

      final rotateTransformFinder = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Transform),
      );
      expect(rotateTransformFinder, findsWidgets);
      final Transform rotateTransform =
          tester.widget(rotateTransformFinder.first);
      expect(rotateTransform.transform.storage[0],
          closeTo(math.cos(math.pi / 4), 0.05));

      // Tapping the rotating ✕ FAB dismisses Quick Capture
      await tester.tap(fabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(quickCaptureNotifierProvider).isOpen, isFalse);
      final islandState = container.read(dynamicIslandControllerProvider);
      expect(islandState is DynamicIslandResting, isTrue);
    });
  });
}
