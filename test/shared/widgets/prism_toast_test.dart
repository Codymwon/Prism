import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/shared/widgets/prism_toast.dart';

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
  group('IslandToastNotifier & PrismToast Seam Tests', () {
    tearDown(() {
      PrismToast.dismissOverlay();
    });

    test('initial state of islandToastNotifierProvider is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(islandToastNotifierProvider);
      expect(state, isNull);
    });

    test('show() updates state with correct data and increments id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(islandToastNotifierProvider.notifier);

      notifier.show(
        message: 'First message',
        icon: Icons.check,
        actionText: 'Undo',
        duration: const Duration(seconds: 4),
      );

      final state1 = container.read(islandToastNotifierProvider);
      expect(state1, isNotNull);
      expect(state1!.message, 'First message');
      expect(state1.icon, Icons.check);
      expect(state1.actionText, 'Undo');
      expect(state1.duration, const Duration(seconds: 4));
      final firstId = state1.id;

      // Rapid-fire in-place update
      notifier.show(
        message: 'Second message',
        icon: Icons.sync,
      );

      final state2 = container.read(islandToastNotifierProvider);
      expect(state2, isNotNull);
      expect(state2!.message, 'Second message');
      expect(state2.icon, Icons.sync);
      expect(state2.actionText, isNull);
      expect(state2.id, greaterThan(firstId));
    });

    test('dismiss() clears active toast state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(islandToastNotifierProvider.notifier);
      notifier.show(message: 'Test message');
      expect(container.read(islandToastNotifierProvider), isNotNull);

      notifier.dismiss();
      expect(container.read(islandToastNotifierProvider), isNull);
    });

    testWidgets('PrismToast.show outside AppShell renders fallback overlay and does not set islandToastNotifierProvider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      PrismToast.show(
                        context,
                        'Dispatched from button',
                        icon: Icons.archive,
                        actionText: 'View',
                      );
                    },
                    child: const Text('Show Toast'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      final element = tester.element(find.text('Show Toast'));
      final container = ProviderScope.containerOf(element);
      final toastState = container.read(islandToastNotifierProvider);

      // Outside AppShell, islandToastNotifierProvider MUST remain null!
      expect(toastState, isNull);

      // But the fallback overlay must be visible!
      expect(find.text('Dispatched from button'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);

      PrismToast.dismissOverlay();
      await tester.pump();
    });

    testWidgets('PrismToast.show inside AppShell dispatches to islandToastNotifierProvider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(FakeNoteRepository()),
            tutorialStateProvider.overrideWith(() => FakeTutorialState(true)),
            journalTutorialStateProvider.overrideWith(() => FakeJournalTutorialState(true)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AppShell(
              currentPath: '/notes',
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      PrismToast.show(
                        context,
                        'Dispatched inside AppShell',
                        icon: Icons.check,
                      );
                    },
                    child: const Text('Show AppShell Toast'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show AppShell Toast'));
      await tester.pump();

      final element = tester.element(find.text('Show AppShell Toast'));
      final container = ProviderScope.containerOf(element);
      final toastState = container.read(islandToastNotifierProvider);

      expect(toastState, isNotNull);
      expect(toastState!.message, 'Dispatched inside AppShell');
      expect(toastState.icon, Icons.check);

      container.read(islandToastNotifierProvider.notifier).dismiss();
      await tester.pumpAndSettle();
    });
  });
}
