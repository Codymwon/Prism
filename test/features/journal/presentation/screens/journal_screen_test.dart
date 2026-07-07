import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/journal/presentation/screens/journal_screen.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:prism/features/journal/presentation/widgets/journal_week_strip.dart';
import 'package:prism/features/journal/presentation/widgets/journal_streak_grid.dart';
import 'package:prism/features/journal/presentation/widgets/journal_empty_state.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/shared/widgets/tutorial_overlay.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';

class MockTutorialState extends TutorialState {
  final bool initialValue;
  MockTutorialState(this.initialValue);

  @override
  bool build() {
    return initialValue;
  }

  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

class MockJournalTutorialState extends JournalTutorialState {
  final bool initialValue;
  MockJournalTutorialState(this.initialValue);

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
  testWidgets('Journal screen content starts immediately below the date strip without a large vertical gap', (WidgetTester tester) async {
    // Set screen size to 1000 height to ensure content is smaller than screen
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Build the widget with overridden providers to simulate a day with no entry yet
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );

    // Let the initial asynchronous providers load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the navigation week strip is present
    final stripFinder = find.byType(JournalWeekStrip);
    expect(stripFinder, findsOneWidget);

    // Verify that the JournalStreakGrid is present (now at the top of content)
    final streakGridFinder = find.byType(JournalStreakGrid);
    expect(streakGridFinder, findsOneWidget);

    // Find the bottom edge of the week strip
    final stripBottom = tester.getBottomLeft(stripFinder).dy;

    // Find the top edge of the streak grid
    final gridTop = tester.getTopLeft(streakGridFinder).dy;

    // The gap should be small
    final gap = gridTop - stripBottom;
    debugPrint('Measured vertical gap to streak grid: $gap pixels');

    // We expect the gap to be less than 20 pixels in a correct layout
    expect(gap, lessThan(20.0), reason: 'There is a large vertical gap ($gap px) between the date strip and the content.');
  });

  testWidgets('JournalStreakGrid is visible in empty state and rendered above the template picker', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 2, totalCount: 2)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that JournalStreakGrid is present
    final streakGridFinder = find.byType(JournalStreakGrid);
    expect(streakGridFinder, findsOneWidget);

    // Verify that the template picker header is present
    final templateHeaderFinder = find.text('START WITH A TEMPLATE');
    expect(templateHeaderFinder, findsOneWidget);

    // Verify JournalStreakGrid is placed vertically above the template header
    final gridBottom = tester.getBottomLeft(streakGridFinder).dy;
    final headerTop = tester.getTopLeft(templateHeaderFinder).dy;
    expect(gridBottom, lessThan(headerTop), reason: 'Streak Grid should be placed above the template picker');
  });

  testWidgets('JournalStreakGrid is visible on a future day empty state and rendered above the empty state message', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final futureDate = DateTime.now().add(const Duration(days: 5));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDayProvider.overrideWith((ref) => futureDate),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 2, totalCount: 2)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that JournalStreakGrid is present
    final streakGridFinder = find.byType(JournalStreakGrid);
    expect(streakGridFinder, findsOneWidget);

    // Verify that the empty state widget is present
    final emptyStateFinder = find.byType(JournalEmptyState);
    expect(emptyStateFinder, findsOneWidget);

    // Verify that the template picker header is NOT present (since it is a future day)
    final templateHeaderFinder = find.text('START WITH A TEMPLATE');
    expect(templateHeaderFinder, findsNothing);

    // Verify JournalStreakGrid is placed vertically above the empty state message
    final gridBottom = tester.getBottomLeft(streakGridFinder).dy;
    final emptyStateTop = tester.getTopLeft(emptyStateFinder).dy;
    expect(gridBottom, lessThan(emptyStateTop), reason: 'Streak Grid should be placed above the empty state');
  });

  testWidgets('Past empty day content uses empty_past key', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDayProvider.overrideWith((ref) => yesterday),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('empty_past')), findsOneWidget);
  });

  testWidgets('Future empty day content uses empty_future key', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final tomorrow = DateTime.now().add(const Duration(days: 5));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDayProvider.overrideWith((ref) => tomorrow),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('empty_future')), findsOneWidget);
  });

  testWidgets('Daily note entry content uses dynamic entry key to trigger rebuild transition on switcher', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dummyNote = Note(
      id: 'abc',
      title: formatDailyDate(yesterday),
      filePath: 'dummy.md',
      wordCount: 10,
      createdAt: yesterday,
      updatedAt: yesterday,
      isDaily: true,
      dailyDate: formatDailyDate(yesterday),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedDayProvider.overrideWith((ref) => yesterday),
          allDailyDatesProvider.overrideWith((ref) => <String>{formatDailyDate(yesterday)}),
          journalStreakProvider.overrideWith((ref) => (streak: 1, totalCount: 1)),
          dailyNoteProvider.overrideWith((ref, dateStr) => (note: dummyNote, content: '# reflection\nsome content')),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('entry_abc')), findsOneWidget);
  });

  testWidgets('AppShell displays SpotlightTutorialOverlay when navigating to Journal tab if journal tutorial is not completed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Main tutorial completed
          tutorialStateProvider.overrideWith(() => MockTutorialState(true)),
          // Journal tutorial NOT completed
          journalTutorialStateProvider.overrideWith(() => MockJournalTutorialState(false)),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: const MaterialApp(
          home: AppShell(
            currentPath: '/journal',
            child: JournalScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify overlay is visible
    expect(find.byType(SpotlightTutorialOverlay), findsOneWidget);

    // Step 1: Calendar Navigation
    expect(find.text('Calendar Navigation'), findsOneWidget);
    expect(find.text('STEP 1 OF 4'), findsOneWidget);
    
    // Tap Next
    await tester.tap(find.text('Next'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2: Weekly Quick Strip
    expect(find.text('Weekly Quick Strip'), findsOneWidget);
    expect(find.text('STEP 2 OF 4'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 3: Daily Streak & Grid
    expect(find.text('Daily Streak & Grid'), findsOneWidget);
    expect(find.text('STEP 3 OF 4'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Next'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 4: Reflection Templates
    expect(find.text('Reflection Templates'), findsOneWidget);
    expect(find.text('STEP 4 OF 4'), findsOneWidget);

    // Tap Got it!
    await tester.tap(find.text('Got it!'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify overlay is now dismissed
    expect(find.byType(SpotlightTutorialOverlay), findsNothing);
  });
}

