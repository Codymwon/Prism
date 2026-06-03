import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/features/journal/presentation/screens/journal_screen.dart';
import 'package:meridian/features/notes/presentation/providers/notes_providers.dart';
import 'package:meridian/features/journal/presentation/widgets/journal_week_strip.dart';

void main() {
  testWidgets('Journal screen content starts immediately below the date strip without a large vertical gap', (WidgetTester tester) async {
    // Set screen size to 1000 height to ensure content is smaller than screen
    tester.view.physicalSize = const Size(400, 1000);
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

    // Verify the "START WITH A TEMPLATE" text is present
    final textFinder = find.text('START WITH A TEMPLATE');
    expect(textFinder, findsOneWidget);

    // Find the bottom edge of the week strip
    final stripBottom = tester.getBottomLeft(stripFinder).dy;

    // Find the top edge of the template text
    final textTop = tester.getTopLeft(textFinder).dy;

    // The gap should be small (about 10 pixels: 6 bottom margin of JournalWeekStrip + 4 top margin of SingleChildScrollView)
    final gap = textTop - stripBottom;
    debugPrint('Measured vertical gap: $gap pixels');

    // If centered vertically, this gap will be much larger (often > 100 pixels depending on screen height)
    // We expect the gap to be less than 20 pixels in a correct layout
    expect(gap, lessThan(20.0), reason: 'There is a large vertical gap ($gap px) between the date strip and the content, likely due to vertical centering.');
  });
}
