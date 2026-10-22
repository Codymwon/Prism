import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/providers/shared_preferences_provider.dart';
import 'package:prism/features/journal/presentation/providers/journal_providers.dart';
import 'package:prism/features/journal/presentation/screens/journal_screen.dart';
import 'package:prism/features/journal/presentation/widgets/journal_header.dart';
import 'package:prism/features/journal/presentation/widgets/journal_streak_grid.dart';
import 'package:prism/features/settings/presentation/providers/settings_provider.dart';
import 'package:prism/features/settings/presentation/screens/journal_preferences_screen.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildJournalScreen({
    Map<String, Object>? initialPrefs,
    List<Override> extraOverrides = const [],
  }) {
    if (initialPrefs != null) {
      SharedPreferences.setMockInitialValues(initialPrefs);
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allDailyDatesProvider.overrideWith((ref) => <String>{}),
        journalStreakProvider.overrideWith((ref) => (streak: 5, totalCount: 12)),
        dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: JournalScreen(),
        ),
      ),
    );
  }

  Widget buildJournalPreferencesScreen({
    required SharedPreferences prefsInstance,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefsInstance),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: JournalPreferencesScreen(),
      ),
    );
  }

  group('Journal Gamification & Quiet Mode Toggle (PLAN 3 / TASK-061)', () {
    testWidgets('Default state: habit mode is ON, streak grid and badge are visible', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildJournalScreen());
      await tester.pumpAndSettle();

      // Verify JournalStreakGrid is visible
      expect(find.byType(JournalStreakGrid), findsOneWidget);

      // Verify JournalHeader contains the entries badge with history_edu_rounded icon
      expect(find.byType(JournalHeader), findsOneWidget);
      expect(find.byIcon(Icons.history_edu_rounded), findsOneWidget);
      expect(find.text('12 entries'), findsOneWidget);
    });

    testWidgets('Quiet / Professional mode: when toggled OFF, streak grid and header badge are hidden', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set pref to false
      await prefs.setBool('prism_pref_show_journal_streaks', false);

      await tester.pumpWidget(buildJournalScreen());
      await tester.pumpAndSettle();

      // Verify JournalStreakGrid is completely absent
      expect(find.byType(JournalStreakGrid), findsNothing);

      // Verify JournalHeader suppresses the streak/entries badge
      expect(find.byIcon(Icons.history_edu_rounded), findsNothing);
      expect(find.text('12 Entries'), findsNothing);

      // Verify clean header title remains visible
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Reactive toggle: toggling provider immediately updates JournalScreen UI', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          allDailyDatesProvider.overrideWith((ref) => <String>{}),
          journalStreakProvider.overrideWith((ref) => (streak: 3, totalCount: 8)),
          dailyNoteProvider.overrideWith((ref, dateStr) => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially visible
      expect(find.byType(JournalStreakGrid), findsOneWidget);
      expect(find.byIcon(Icons.history_edu_rounded), findsOneWidget);

      // Switch to Quiet Mode
      await container.read(showJournalStreaksProvider.notifier).setEnabled(false);
      await tester.pumpAndSettle();

      // Verify hidden in UI
      expect(find.byType(JournalStreakGrid), findsNothing);
      expect(find.byIcon(Icons.history_edu_rounded), findsNothing);

      // Switch back to Habit Mode
      await container.read(showJournalStreaksProvider.notifier).setEnabled(true);
      await tester.pumpAndSettle();

      // Verify re-appears
      expect(find.byType(JournalStreakGrid), findsOneWidget);
      expect(find.byIcon(Icons.history_edu_rounded), findsOneWidget);
    });

    testWidgets('JournalPreferencesScreen: renders Habits & Consistency section and toggles persistence', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildJournalPreferencesScreen(prefsInstance: prefs));
      await tester.pumpAndSettle();

      // Verify section header exists
      expect(find.text('HABITS & CONSISTENCY'), findsOneWidget);

      // Verify tile title and description exist
      expect(find.text('Show Streaks & Consistency Grid'), findsOneWidget);
      expect(
        find.text('Display consecutive days counter and activity matrix in the daily journal.'),
        findsOneWidget,
      );

      // Verify SwitchListTile is initially checked (true by default)
      final switchFinder = find.widgetWithText(SwitchListTile, 'Show Streaks & Consistency Grid');
      expect(switchFinder, findsOneWidget);
      final initialSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(initialSwitch.value, isTrue);

      // Tap to toggle OFF
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify SharedPreferences persisted false
      expect(prefs.getBool('prism_pref_show_journal_streaks'), isFalse);
      final toggledSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(toggledSwitch.value, isFalse);

      // Tap to toggle ON again
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify SharedPreferences persisted true
      expect(prefs.getBool('prism_pref_show_journal_streaks'), isTrue);
      final reToggledSwitch = tester.widget<SwitchListTile>(switchFinder);
      expect(reToggledSwitch.value, isTrue);
    });
  });
}
