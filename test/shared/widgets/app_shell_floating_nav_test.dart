import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';

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

class FakeTutorialNotifier extends TutorialNotifier {
  FakeTutorialNotifier(bool val) : super() {
    state = val;
  }
}

class FakeJournalTutorialNotifier extends JournalTutorialNotifier {
  FakeJournalTutorialNotifier(bool val) : super() {
    state = val;
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
        tutorialStateProvider.overrideWith((ref) => FakeTutorialNotifier(true)),
        journalTutorialStateProvider.overrideWith((ref) => FakeJournalTutorialNotifier(true)),
      ],
      child: MaterialApp.router(
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
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildAppShell(currentPath: '/notes'));
      await tester.pumpAndSettle();

      final fabFinder = find.byIcon(Icons.add);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder, warnIfMissed: false);
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
  });
}
