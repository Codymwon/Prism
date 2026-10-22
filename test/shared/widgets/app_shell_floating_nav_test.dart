import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/shared/widgets/tutorial_overlay.dart';

class FakeNoteRepository extends Fake implements NoteRepository {
  bool createNoteCalled = false;
  bool isDailyPassed = false;

  @override
  Future<Note?> getDailyNote(String dateStr) async {
    return null;
  }

  @override
  Future<Note> createNote({
    String? title,
    String initialContent = '',
    bool isDaily = false,
    String? dailyDate,
  }) async {
    createNoteCalled = true;
    isDailyPassed = isDaily;
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
  bool build() {
    return initialValue;
  }

  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

class FakeJournalTutorialState extends JournalTutorialState {
  final bool initialValue;
  FakeJournalTutorialState(this.initialValue);

  @override
  bool build() {
    return initialValue;
  }

  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

void main() {
  late FakeNoteRepository fakeNoteRepository;

  setUp(() {
    fakeNoteRepository = FakeNoteRepository();
  });

  Widget buildAppShell({
    required String currentPath,
  }) {
    final router = GoRouter(
      initialLocation: currentPath,
      routes: [
        GoRoute(
          path: '/notes',
          builder: (context, state) => AppShell(
            currentPath: '/notes',
            child: const Scaffold(body: Text('Notes Screen')),
          ),
        ),
        GoRoute(
          path: '/journal',
          builder: (context, state) => AppShell(
            currentPath: '/journal',
            child: const Scaffold(body: Text('Journal Screen')),
          ),
        ),
        GoRoute(
          path: '/graph',
          builder: (context, state) => AppShell(
            currentPath: '/graph',
            child: const Scaffold(body: Text('Graph Screen')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => AppShell(
            currentPath: '/settings',
            child: const Scaffold(body: Text('Settings Screen')),
          ),
        ),
        GoRoute(
          path: '/editor/:id',
          builder: (context, state) => const Scaffold(body: Text('Editor Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(fakeNoteRepository),
        tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
        journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('AppShell Floating Navigation Bar & FAB', () {
    testWidgets('renders floating navigation pill and "+" button on mobile', (WidgetTester tester) async {
      // Set viewport to mobile width (400px)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppShell(currentPath: '/notes'));
      await tester.pumpAndSettle();

      // Find the circular Floating Action Button "+"
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);

      // Verify that navigation items (icons or labels) are rendered
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets('hides "+" button and expands navigation pill on Settings tab', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppShell(currentPath: '/settings'));
      await tester.pumpAndSettle();

      // "+" button should be hidden (doesn't render / has no icon)
      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsNothing);

      // Verify navigation items still render
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tapping "+" on Notes tab creates a standard note', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppShell(currentPath: '/notes'));
      await tester.pumpAndSettle();

      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Quick Capture blooms; tap "Blank Document" to create standard note
      final blankDocFinder = find.byKey(const ValueKey('quick_capture_blank_document'));
      expect(blankDocFinder, findsOneWidget);
      await tester.tap(blankDocFinder);
      await tester.pumpAndSettle();

      expect(fakeNoteRepository.createNoteCalled, isTrue);
      expect(fakeNoteRepository.isDailyPassed, isFalse);
    });

    testWidgets('tapping "+" on Journal tab creates a daily note', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppShell(currentPath: '/journal'));
      await tester.pumpAndSettle();

      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(fakeNoteRepository.createNoteCalled, isTrue);
      expect(fakeNoteRepository.isDailyPassed, isTrue);
    });
    testWidgets('displays SpotlightTutorialOverlay and runs through the 5 steps of the main app tutorial', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/notes',
        routes: [
          GoRoute(
            path: '/notes',
            builder: (context, state) => AppShell(
              currentPath: '/notes',
              child: const Scaffold(body: Text('Notes Screen')),
            ),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => AppShell(
              currentPath: '/journal',
              child: const Scaffold(body: Text('Journal Screen')),
            ),
          ),
          GoRoute(
            path: '/graph',
            builder: (context, state) => AppShell(
              currentPath: '/graph',
              child: const Scaffold(body: Text('Graph Screen')),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => AppShell(
              currentPath: '/settings',
              child: const Scaffold(body: Text('Settings Screen')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(fakeNoteRepository),
            tutorialStateProvider.overrideWith(() => FakeTutorialState(false)),
            journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
          ],
          child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify overlay is visible
      expect(find.byType(SpotlightTutorialOverlay), findsOneWidget);

      // Step 1: Virtual Folders & Tags
      expect(find.text('Virtual Folders & Tags'), findsOneWidget);
      expect(find.text('STEP 1 OF 5'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Step 2: Virtual Folders
      expect(find.text('Virtual Folders'), findsOneWidget);
      expect(find.text('STEP 2 OF 5'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Step 3: Daily Reflection Logs
      expect(find.text('Daily Reflection Logs'), findsOneWidget);
      expect(find.text('STEP 3 OF 5'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Step 4: Mindmap Thought Graph
      expect(find.text('Mindmap Thought Graph'), findsOneWidget);
      expect(find.text('STEP 4 OF 5'), findsOneWidget);

      // Tap Next
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Step 5: Create & Link Notes
      expect(find.text('Create & Link Notes'), findsOneWidget);
      expect(find.text('STEP 5 OF 5'), findsOneWidget);

      // Tap Got it!
      await tester.tap(find.text('Got it!'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Overlay should be gone
      expect(find.byType(SpotlightTutorialOverlay), findsNothing);
    });
  });
}
