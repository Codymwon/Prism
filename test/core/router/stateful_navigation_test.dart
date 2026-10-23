import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:prism/shared/widgets/app_shell.dart';

class _CounterScreen extends StatefulWidget {
  final String title;

  const _CounterScreen({required this.title});

  @override
  State<_CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<_CounterScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${widget.title} - Count: $_counter'),
            ElevatedButton(
              onPressed: () => setState(() => _counter++),
              child: Text('Increment ${widget.title}'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  @override
  bool build() => true;
}

class FakeJournalTutorialState extends JournalTutorialState {
  @override
  bool build() => true;
}

void main() {
  Widget buildStatefulNavApp() {
    final router = GoRouter(
      initialLocation: '/notes',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(
              currentPath: state.uri.path,
              navigationShell: navigationShell,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/notes',
                  builder: (context, state) =>
                      const _CounterScreen(title: 'Notes Tab'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/journal',
                  builder: (context, state) =>
                      const _CounterScreen(title: 'Journal Tab'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/graph',
                  builder: (context, state) =>
                      const _CounterScreen(title: 'Graph Tab'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (context, state) =>
                      const _CounterScreen(title: 'Settings Tab'),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
        tutorialStateProvider.overrideWith(() => FakeTutorialState()),
        journalTutorialStateProvider
            .overrideWith(() => FakeJournalTutorialState()),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
      'AppShell with StatefulShellRoute preserves tab state across branch switches',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildStatefulNavApp());
    await tester.pumpAndSettle();

    // Verify initial tab is Notes Tab and count is 0
    expect(find.text('Notes Tab - Count: 0'), findsOneWidget);

    // Increment Notes count to 2
    await tester.tap(find.text('Increment Notes Tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Increment Notes Tab'));
    await tester.pumpAndSettle();
    expect(find.text('Notes Tab - Count: 2'), findsOneWidget);

    // Switch to Journal tab by tapping the Journal nav item
    final journalTab = find.text('Journal');
    expect(journalTab, findsOneWidget);
    await tester.tap(journalTab, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Journal Tab is active and has initial count 0
    expect(find.text('Journal Tab - Count: 0'), findsOneWidget);

    // Increment Journal count to 1
    await tester.tap(find.text('Increment Journal Tab'));
    await tester.pumpAndSettle();
    expect(find.text('Journal Tab - Count: 1'), findsOneWidget);

    // Switch to Graph tab by tapping Graph nav item
    final graphTab = find.text('Graph');
    expect(graphTab, findsOneWidget);
    await tester.tap(graphTab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Graph Tab - Count: 0'), findsOneWidget);

    // Switch back to Notes tab
    final notesTab = find.text('Notes');
    expect(notesTab, findsOneWidget);
    await tester.tap(notesTab, warnIfMissed: false);
    await tester.pumpAndSettle();

    // CRITICAL ASSERTION: Notes Tab retained its state (Count: 2)
    expect(find.text('Notes Tab - Count: 2'), findsOneWidget);

    // Switch back to Journal tab
    await tester.tap(journalTab, warnIfMissed: false);
    await tester.pumpAndSettle();

    // CRITICAL ASSERTION: Journal Tab retained its state (Count: 1)
    expect(find.text('Journal Tab - Count: 1'), findsOneWidget);
  });
}
