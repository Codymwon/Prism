import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/presentation/widgets/grouped_notes_list.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/folders/presentation/providers/folders_providers.dart';
import 'package:prism/shared/widgets/app_shell.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';

class MockTutorialNotifier extends TutorialNotifier {
  MockTutorialNotifier(bool value) : super() {
    state = value;
  }
  @override
  Future<void> completeTutorial() async {
    state = true;
  }
}

void main() {
  testWidgets('GroupedNotesList renders a styled Open button for virtual folders', (WidgetTester tester) async {
    final mockFolder = VirtualFolder(
      id: 'folder-1',
      name: 'Work',
      colorHex: '#FF0000',
      icon: 'folder',
      createdAt: DateTime.now(),
      sortOrder: 0,
    );

    final mockNote = Note(
      id: 'note-1',
      title: 'Sprint Plan',
      filePath: 'sprint_plan.md',
      wordCount: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedFolderIdProvider.overrideWith((ref) => null),
          noteSortProvider.overrideWith((ref) => NoteSort.title),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GroupedNotesList(
              allNotes: [mockNote],
              folders: [mockFolder],
              mappings: {
                'note-1': ['folder-1'],
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the folder title is present
    expect(find.text('Work'), findsOneWidget);

    // Verify that the "Open" button is present on the folder card
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('AppShell main tutorial has Open Folders step', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorialStateProvider.overrideWith((ref) => MockTutorialNotifier(false)), // main tutorial NOT completed
        ],
        child: const MaterialApp(
          home: AppShell(
            currentPath: '/notes',
            child: Scaffold(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 1: Virtual Folders & Tags
    expect(find.text('Virtual Folders & Tags'), findsOneWidget);
    
    // Tap Next
    await tester.tap(find.text('Next'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Step 2 should be 'Open Folders'
    expect(find.text('Open Folders'), findsOneWidget);
  });
}
