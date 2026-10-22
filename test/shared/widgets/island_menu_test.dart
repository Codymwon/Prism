import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/shared/widgets/island_menu.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/l10n/l10n.dart';

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

void main() {
  group('IslandMenuNotifier & IslandMenu Seam Tests', () {
    test('initial state of islandMenuNotifierProvider is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(islandMenuNotifierProvider);
      expect(state, isNull);
    });

    test('show() updates state with correct data and increments id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(islandMenuNotifierProvider.notifier);

      notifier.show(
        title: 'Note 1',
        icon: Icons.article,
        items: [
          IslandMenuItem(
            label: 'Open',
            icon: Icons.open_in_new,
            onTap: () {},
          ),
          IslandMenuItem(
            label: 'Delete',
            icon: Icons.delete,
            isDestructive: true,
            onTap: () {},
          ),
        ],
      );

      final state1 = container.read(islandMenuNotifierProvider);
      expect(state1, isNotNull);
      expect(state1!.title, 'Note 1');
      expect(state1.icon, Icons.article);
      expect(state1.items.length, 2);
      expect(state1.items[0].label, 'Open');
      expect(state1.items[1].label, 'Delete');
      expect(state1.items[1].isDestructive, isTrue);
      final firstId = state1.id;

      notifier.show(
        title: 'Folder A',
        items: [
          IslandMenuItem(
            label: 'Edit',
            icon: Icons.edit,
            onTap: () {},
          ),
        ],
      );

      final state2 = container.read(islandMenuNotifierProvider);
      expect(state2, isNotNull);
      expect(state2!.title, 'Folder A');
      expect(state2.id, greaterThan(firstId));
      expect(state2.items.length, 1);
    });

    test('dismiss() clears active menu state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(islandMenuNotifierProvider.notifier);
      notifier.show(
        title: 'Test',
        items: [],
      );
      expect(container.read(islandMenuNotifierProvider), isNotNull);

      notifier.dismiss();
      expect(container.read(islandMenuNotifierProvider), isNull);
    });

    testWidgets('IslandMenu.show outside AppShell falls back to modal bottom sheet', (tester) async {
      bool openTapped = false;
      bool deleteTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      IslandMenu.show(
                        context,
                        title: 'Fallback Note',
                        icon: Icons.description,
                        items: [
                          IslandMenuItem(
                            label: 'Open',
                            icon: Icons.open_in_new,
                            onTap: () {
                              openTapped = true;
                            },
                          ),
                          IslandMenuItem(
                            label: 'Delete',
                            icon: Icons.delete,
                            isDestructive: true,
                            onTap: () {
                              deleteTapped = true;
                            },
                          ),
                        ],
                      );
                    },
                    child: const Text('Show Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap show menu button
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Bottom sheet should be shown with title and options
      expect(find.text('Fallback Note'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap 'Open'
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(openTapped, isTrue);
      expect(deleteTapped, isFalse);
      // Sheet should be dismissed
      expect(find.text('Fallback Note'), findsNothing);
    });

    testWidgets('IslandMenu.show inside AppShell dispatches to islandMenuNotifierProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
          tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
          journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              currentPath: '/notes',
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      IslandMenu.show(
                        context,
                        title: 'AppShell Note',
                        icon: Icons.article,
                        items: [
                          IslandMenuItem(
                            label: 'Open',
                            icon: Icons.open_in_new,
                            onTap: () {},
                          ),
                        ],
                      );
                    },
                    child: const Text('Trigger AppShell Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(islandMenuNotifierProvider), isNull);

      await tester.tap(find.text('Trigger AppShell Menu'));
      await tester.pump();

      final state = container.read(islandMenuNotifierProvider);
      expect(state, isNotNull);
      expect(state!.title, 'AppShell Note');
      expect(state.items.length, 1);
    });
  });
}
