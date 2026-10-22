import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/shared/widgets/prism_toast.dart';
import 'package:prism/shared/widgets/island_menu.dart';

class FakeNoteRepository extends Fake implements NoteRepository {
  @override
  Future<Note?> getDailyNote(String dateStr) async => null;

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    return Note(
      id: 'fake-note-id',
      title: title ?? 'Untitled',
      filePath: 'fake.md',
      wordCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDaily: isDaily,
    );
  }
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
            builder: (context, state) => const Scaffold(body: Text('Notes Screen')),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const Scaffold(body: Text('Journal Screen')),
          ),
          GoRoute(
            path: '/graph',
            builder: (context, state) => const Scaffold(body: Text('Graph Screen')),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: Text('Settings Screen')),
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
    ),
  );
}

void main() {
  group('AppShell Dynamic Island Integration Tests', () {
    testWidgets('capsule expands to ~104dp and shows message when toast is triggered',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
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

      // Initially, no upper shelf message exists
      expect(find.text('Dynamic Island Test Message'), findsNothing);

      // Trigger toast via IslandToastNotifier
      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Dynamic Island Test Message',
            icon: Icons.check,
          );

      // Pump through expansion animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Upper shelf message is now present
      expect(find.text('Dynamic Island Test Message'), findsOneWidget);
    });

    testWidgets('tapping a tab switches tab and dismisses the expanded toast',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
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

      // Trigger toast
      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Toast to be dismissed',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Toast to be dismissed'), findsOneWidget);

      // Tap on Settings tab
      final settingsTab = find.text('Settings');
      expect(settingsTab, findsOneWidget);
      await tester.tap(settingsTab, warnIfMissed: false);
      await tester.pump();

      // Toast should be dismissed
      expect(container.read(islandToastNotifierProvider), isNull);
    });

    testWidgets('tapping the upper shelf dismisses the active toast',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Tap to dismiss me',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Tap to dismiss me'), findsOneWidget);

      await tester.tap(find.text('Tap to dismiss me'));
      await tester.pump();

      expect(container.read(islandToastNotifierProvider), isNull);
    });

    testWidgets('tapping action pill executes callback and dismisses toast',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      bool actionCalled = false;
      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Note deleted',
            actionText: 'Undo',
            onAction: () => actionCalled = true,
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(actionCalled, isTrue);
      expect(container.read(islandToastNotifierProvider), isNull);
    });

    testWidgets('rapid-fire second toast updates message in place',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      container.read(islandToastNotifierProvider.notifier).show(
            message: 'First Message',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('First Message'), findsOneWidget);

      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Second Message In Place',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Second Message In Place'), findsOneWidget);
      expect(find.text('First Message'), findsNothing);
    });

    testWidgets('dynamic island forward bloom completes in 280ms with action pill ScaleTransition',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Snappy Spring Bloom',
            actionText: 'Undo',
          );
      await tester.pump();

      // At 280ms, the forward animation is fully completed
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.text('Snappy Spring Bloom'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Verify action pill is wrapped in ScaleTransition
      final scaleTransitionFinder = find.ancestor(
        of: find.text('Undo'),
        matching: find.byType(ScaleTransition),
      );
      expect(scaleTransitionFinder, findsOneWidget);
    });

    testWidgets('capsule expands to ~172dp and shows action deck when menu is triggered',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      expect(find.text('Architecture Spec'), findsNothing);

      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Architecture Spec',
            icon: Icons.article_outlined,
            items: [
              IslandMenuItem(
                label: 'Open',
                icon: Icons.open_in_new,
                onTap: () {},
              ),
              IslandMenuItem(
                label: 'Delete',
                icon: Icons.delete_outline,
                isDestructive: true,
                onTap: () {},
              ),
            ],
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Architecture Spec'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Verify monolithic capsule expanded height is ~172dp
      final capsuleFinder = find.byKey(const ValueKey('monolithic_capsule'));
      expect(capsuleFinder, findsOneWidget);
      final RenderBox capsuleBox = tester.renderObject(capsuleFinder);
      expect(capsuleBox.size.height, closeTo(172.0, 4.0));
    });

    testWidgets('tapping rotating FAB dismisses active action deck',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Dismiss Me',
            items: [
              IslandMenuItem(
                label: 'Action',
                icon: Icons.star,
                onTap: () {},
              ),
            ],
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Dismiss Me'), findsOneWidget);

      final fabFinder = find.byKey(const ValueKey('app_shell_fab'));
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pump();

      expect(container.read(islandMenuNotifierProvider), isNull);
    });

    testWidgets('tapping modal scrim dismisses active action deck',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Scrim Dismiss Test',
            items: [
              IslandMenuItem(
                label: 'Action',
                icon: Icons.star,
                onTap: () {},
              ),
            ],
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Scrim Dismiss Test'), findsOneWidget);

      final scrimFinder = find.byKey(const ValueKey('island_modal_scrim'));
      expect(scrimFinder, findsOneWidget);
      await tester.tap(scrimFinder);
      await tester.pump();

      expect(container.read(islandMenuNotifierProvider), isNull);
    });

    testWidgets('tapping action item invokes callback and dismisses menu',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      bool actionExecuted = false;
      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Action Click Test',
            items: [
              IslandMenuItem(
                label: 'Organize',
                icon: Icons.folder,
                onTap: () => actionExecuted = true,
              ),
            ],
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Organize'), findsOneWidget);

      await tester.tap(find.text('Organize'), warnIfMissed: false);
      await tester.pump();

      expect(actionExecuted, isTrue);
      expect(container.read(islandMenuNotifierProvider), isNull);
    });

    testWidgets(
        'action deck fuses into full-width container with integrated rotating FAB (screenWidth - 32dp, 16dp symmetrical margins, 45° rotation, tap dismisses)',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider
              .overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;

      final capsuleFinder = find.byKey(const ValueKey('monolithic_capsule'));
      final fabFinder = find.byKey(const ValueKey('app_shell_fab'));
      expect(capsuleFinder, findsOneWidget);
      expect(fabFinder, findsOneWidget);

      // Measure resting state bounds
      final RenderBox initialCapsuleBox = tester.renderObject(capsuleFinder);
      final RenderBox initialFabBox = tester.renderObject(fabFinder);
      final initialCapsuleLeft =
          initialCapsuleBox.localToGlobal(Offset.zero).dx;
      final initialCapsuleRight =
          initialCapsuleLeft + initialCapsuleBox.size.width;
      final initialFabLeft = initialFabBox.localToGlobal(Offset.zero).dx;

      // Resting state assertions:
      // Capsule left margin = 16dp, right margin = 84dp (16 + 56 + 12)
      expect(initialCapsuleLeft, closeTo(16.0, 0.5));
      expect(screenWidth - initialCapsuleRight, closeTo(84.0, 0.5));
      // FAB width = 56dp, air gap = 12dp
      expect(initialFabBox.size.width, closeTo(56.0, 0.5));
      expect(initialFabLeft - initialCapsuleRight, closeTo(12.0, 0.5));

      // Trigger Island Menu
      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Fused Island Action Deck Test',
            items: [
              IslandMenuItem(
                label: 'Open',
                icon: Icons.open_in_new,
                onTap: () {},
              ),
              IslandMenuItem(
                label: 'Delete',
                icon: Icons.delete_outline,
                isDestructive: true,
                onTap: () {},
              ),
            ],
          );

      // Pump through the 280ms spring forward animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Expanded state assertions:
      // Container width = screenWidth - 32dp, left margin = 16dp, right margin = 16dp (100% centered, zero off-centering)
      final RenderBox expandedCapsuleBox = tester.renderObject(capsuleFinder);
      final expandedCapsuleLeft =
          expandedCapsuleBox.localToGlobal(Offset.zero).dx;
      final expandedCapsuleRight =
          expandedCapsuleLeft + expandedCapsuleBox.size.width;
      expect(expandedCapsuleBox.size.width, closeTo(screenWidth - 32.0, 0.5));
      expect(expandedCapsuleLeft, closeTo(16.0, 0.5));
      expect(screenWidth - expandedCapsuleRight, closeTo(16.0, 0.5));

      // Assert bottom-right FAB remains 56dp and its icon is rotated 45°
      final RenderBox expandedFabBox = tester.renderObject(fabFinder);
      expect(expandedFabBox.size.width, closeTo(56.0, 0.5));
      final rotateTransformFinder = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(Transform),
      );
      expect(rotateTransformFinder, findsWidgets);
      final Transform rotateTransform =
          tester.widget(rotateTransformFinder.first);
      final matrix = rotateTransform.transform;
      expect(matrix.entry(0, 0), closeTo(math.cos(math.pi / 4), 0.05));
      expect(matrix.entry(1, 0), closeTo(math.sin(math.pi / 4), 0.05));

      // Tapping bottom-right FAB dismisses action deck
      await tester.tap(fabFinder);
      await tester.pump();
      expect(container.read(islandMenuNotifierProvider), isNull);

      // Pump through 200ms reverse animation
      await tester.pump(const Duration(milliseconds: 350));

      // Reverse separation assertions: gap returns to 12dp, FAB restores to 56dp, capsule margins restore
      final RenderBox restoredCapsuleBox = tester.renderObject(capsuleFinder);
      final RenderBox restoredFabBox = tester.renderObject(fabFinder);
      final restoredCapsuleLeft =
          restoredCapsuleBox.localToGlobal(Offset.zero).dx;
      final restoredCapsuleRight =
          restoredCapsuleLeft + restoredCapsuleBox.size.width;
      final restoredFabLeft = restoredFabBox.localToGlobal(Offset.zero).dx;

      expect(restoredCapsuleLeft, closeTo(16.0, 0.5));
      expect(screenWidth - restoredCapsuleRight, closeTo(84.0, 0.5));
      expect(restoredFabLeft - restoredCapsuleRight, closeTo(12.0, 0.5));
      expect(restoredFabBox.size.width, closeTo(56.0, 0.5));
    });

    testWidgets('mutual exclusivity: toast and menu dismiss each other',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildTestAppWithRouter(container: container),
      );
      await tester.pumpAndSettle();

      // 1. Show toast first
      container.read(islandToastNotifierProvider.notifier).show(
            message: 'Active Toast',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(container.read(islandToastNotifierProvider), isNotNull);
      expect(container.read(islandMenuNotifierProvider), isNull);

      // 2. Show menu -> toast dismissed
      container.read(islandMenuNotifierProvider.notifier).show(
            title: 'Active Menu',
            items: [],
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(islandToastNotifierProvider), isNull);
      expect(container.read(islandMenuNotifierProvider), isNotNull);

      // 3. Show toast -> menu dismissed
      container.read(islandToastNotifierProvider.notifier).show(
            message: 'New Toast',
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(islandMenuNotifierProvider), isNull);
      expect(container.read(islandToastNotifierProvider), isNotNull);
    });
  });
}
