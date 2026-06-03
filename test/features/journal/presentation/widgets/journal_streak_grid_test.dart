import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/core/utils/utils.dart';
import 'package:meridian/features/journal/presentation/widgets/journal_streak_grid.dart';
import 'package:meridian/features/notes/presentation/providers/notes_providers.dart';

void main() {
  testWidgets('JournalStreakGrid renders active streak number and label', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalStreakProvider.overrideWith((ref) => (streak: 24, totalCount: 30)),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalStreakGrid(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify streak count and label are present
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Day Active Streak'), findsOneWidget);
  });

  testWidgets('JournalStreakGrid renders 4x7 grid of 28 cells and label', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalStreakProvider.overrideWith((ref) => (streak: 24, totalCount: 30)),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: JournalStreakGrid(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify grid label is present
    expect(find.text('Consistency Grid'), findsOneWidget);

    // Verify all 28 cells are present
    for (int i = 0; i < 28; i++) {
      expect(find.byKey(ValueKey('grid_cell_$i')), findsOneWidget);
    }
  });

  testWidgets('JournalStreakGrid color-codes cells chronologically based on daily dates history', (WidgetTester tester) async {
    const activeColor = Colors.green;
    const inactiveColor = Colors.grey;

    final todayStr = formatDailyDate(DateTime.now());
    final yesterdayStr = formatDailyDate(DateTime.now().subtract(const Duration(days: 1)));
    final oldestStr = formatDailyDate(DateTime.now().subtract(const Duration(days: 27)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalStreakProvider.overrideWith((ref) => (streak: 2, totalCount: 3)),
          allDailyDatesProvider.overrideWith((ref) => <String>{todayStr, yesterdayStr, oldestStr}),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              primary: activeColor,
              surfaceContainerHighest: inactiveColor,
            ),
          ),
          home: const Scaffold(
            body: JournalStreakGrid(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Check cells:
    // Cell 0 represents 27 days ago (oldestStr) -> should be active (activeColor)
    // Cell 1 represents 26 days ago -> should be inactive (inactiveColor)
    // Cell 26 represents 1 day ago (yesterdayStr) -> should be active (activeColor)
    // Cell 27 represents 0 days ago (todayStr) -> should be active (activeColor)

    BoxDecoration getCellDecoration(int index) {
      final container = tester.widget<Container>(find.byKey(ValueKey('grid_cell_$index')));
      return container.decoration as BoxDecoration;
    }

    expect(getCellDecoration(0).color, activeColor);
    expect(getCellDecoration(1).color, inactiveColor);
    expect(getCellDecoration(26).color, activeColor);
    expect(getCellDecoration(27).color, activeColor);

    // Verify streak number is colored with the primary color
    final textWidget = tester.widget<Text>(find.text('2'));
    expect(textWidget.style?.color, activeColor);
  });
}
