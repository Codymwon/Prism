import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/journal/presentation/screens/journal_screen.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';

void main() {
  testWidgets('Journal content ScrollView extends to the bottom of the screen, ignoring bottom safe area', (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build the JournalScreen wrapped with custom bottom safe area padding
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 0, totalCount: 0)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(600, 800),
            padding: EdgeInsets.only(bottom: 50.0), // Mock 50px bottom safe area inset
          ),
          child: const MaterialApp(
            home: JournalScreen(),
          ),
        ),
      ),
    );

    // Let the asynchronous providers load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find the scrollable container on the screen
    final scrollViewFinder = find.byType(SingleChildScrollView);
    expect(scrollViewFinder, findsOneWidget);

    // Calculate the bottom Y-coordinate of the ScrollView
    final scrollViewBottom = tester.getBottomLeft(scrollViewFinder).dy;

    // We expect the ScrollView to extend all the way to the bottom of the screen (y = 800)
    expect(scrollViewBottom, equals(800.0));
  });
}
