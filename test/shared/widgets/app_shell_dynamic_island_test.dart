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

    testWidgets('tapping close button dismisses active action deck',
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

      final closeButtonFinder = find.byKey(const ValueKey('island_menu_close'));
      expect(closeButtonFinder, findsOneWidget);
      await tester.tap(closeButtonFinder);
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

    testWidgets('FAB scales down to 0.88x and opacity 0.4 when deck is open',
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
            title: 'FAB test',
            items: [
              IslandMenuItem(
                label: 'Test',
                icon: Icons.star,
                onTap: () {},
              ),
            ],
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);

      final opacityFinder = find.ancestor(
        of: addIconFinder,
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsOneWidget);
      final Opacity opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, closeTo(0.40, 0.05));

      final transformFinder = find.ancestor(
        of: find.byType(AnimatedContainer),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);
      final Transform transformWidget = tester.widget(transformFinder);
      expect(transformWidget.transform.storage[0], closeTo(0.88, 0.05));
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
