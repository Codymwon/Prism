import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/presentation/widgets/virtual_folders_bento_row.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/folders/presentation/providers/folders_providers.dart';

class FakeSelectedFolderIdNotifier extends SelectedFolderId {
  final String? initialValue;
  FakeSelectedFolderIdNotifier(this.initialValue);
  @override
  String? build() => initialValue;
}

void main() {
  Widget buildBentoRow({
    required List<Note> allNotes,
    required List<VirtualFolder> folders,
    required Map<String, List<String>> mappings,
    String? initialSelectedFolderId,
  }) {
    return ProviderScope(
      overrides: [
        selectedFolderIdProvider.overrideWith(() => FakeSelectedFolderIdNotifier(initialSelectedFolderId)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: VirtualFoldersBentoRow(
            allNotes: allNotes,
            folders: folders,
            mappings: mappings,
          ),
        ),
      ),
    );
  }

  testWidgets('VirtualFoldersBentoRow renders items in a GridView', (WidgetTester tester) async {
    final mockFolders = [
      VirtualFolder(
        id: 'folder-work',
        name: 'Work',
        createdAt: DateTime.now(),
        sortOrder: 0,
      ),
      VirtualFolder(
        id: 'folder-personal',
        name: 'Personal',
        createdAt: DateTime.now(),
        sortOrder: 1,
      ),
    ];

    final mockNotes = [
      Note(
        id: 'note-1',
        title: 'Work Note',
        filePath: 'work.md',
        wordCount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Note(
        id: 'note-2',
        title: 'Daily Note',
        filePath: 'daily.md',
        wordCount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDaily: true,
      ),
    ];

    await tester.pumpWidget(
      buildBentoRow(
        allNotes: mockNotes,
        folders: mockFolders,
        mappings: {
          'note-1': ['folder-work'],
        },
      ),
    );
    await tester.pumpAndSettle();

    // Verify GridView is used
    expect(find.byType(GridView), findsOneWidget);

    // Verify folder cards are displayed
    expect(find.text('All Notes'), findsOneWidget);
    expect(find.text('Journal Logs'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
  });

  testWidgets('VirtualFoldersBentoRow shows See All card when there are > 6 total cards', (WidgetTester tester) async {
    // 3 system folders + 4 custom folders = 7 cards. Maximum allowed in grid is 6 (5 folders + 1 See All)
    final mockFolders = List.generate(4, (i) => VirtualFolder(
      id: 'folder-$i',
      name: 'Folder $i',
      createdAt: DateTime.now(),
      sortOrder: i,
    ));

    await tester.pumpWidget(
      buildBentoRow(
        allNotes: const [],
        folders: mockFolders,
        mappings: const {},
      ),
    );
    await tester.pumpAndSettle();

    // Verify See All card is displayed
    expect(find.text('See All'), findsOneWidget);
    
    // Verify only the first 5 folders are displayed (All Notes, Journal Logs, Uncategorized, Folder 0, Folder 1)
    expect(find.text('All Notes'), findsOneWidget);
    expect(find.text('Journal Logs'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.text('Folder 0'), findsOneWidget);
    expect(find.text('Folder 1'), findsOneWidget);
    expect(find.text('Folder 2'), findsNothing);
  });

  testWidgets('tapping folder updates selectedFolderIdProvider', (WidgetTester tester) async {
    final mockFolders = [
      VirtualFolder(
        id: 'folder-work',
        name: 'Work',
        createdAt: DateTime.now(),
        sortOrder: 0,
      ),
    ];

    final container = ProviderContainer();
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: VirtualFoldersBentoRow(
              allNotes: const [],
              folders: mockFolders,
              mappings: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial selection is null
    expect(container.read(selectedFolderIdProvider), isNull);

    // Tap "Work" card
    await tester.tap(find.text('Work'), warnIfMissed: false);
    await tester.pump();

    // Verify selection is updated to 'folder-work'
    expect(container.read(selectedFolderIdProvider), equals('folder-work'));

    // Tap "All Notes" card
    await tester.tap(find.text('All Notes'), warnIfMissed: false);
    await tester.pump();

    // Verify selection is updated to '__all__'
    expect(container.read(selectedFolderIdProvider), equals('__all__'));
  });
}

