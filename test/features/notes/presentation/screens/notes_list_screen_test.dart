import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/folders/presentation/providers/folders_providers.dart';
import 'package:prism/features/notes/presentation/widgets/virtual_folders_bento_row.dart';
import 'package:prism/features/notes/presentation/widgets/notes_bento_grid.dart';
import 'package:prism/features/notes/presentation/widgets/note_card.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/folders/data/folder_model.dart';
import 'package:prism/core/services/vault_service.dart';

class FakeSearchQueryNotifier extends SearchQuery {
  final String initialValue;
  FakeSearchQueryNotifier(this.initialValue);
  @override
  String build() => initialValue;
}

class FakeSelectedFolderIdNotifier extends SelectedFolderId {
  final String? initialValue;
  FakeSelectedFolderIdNotifier(this.initialValue);
  @override
  String? build() => initialValue;
}

void main() {
  final mockFolders = [
    VirtualFolder(
      id: 'folder-work',
      name: 'Work',
      createdAt: DateTime.now(),
      sortOrder: 0,
      noteCount: 2,
    ),
  ];

  final mockNotes = [
    Note(
      id: 'note-1',
      title: 'Recent Note One',
      filePath: 'one.md',
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Note(
      id: 'note-2',
      title: 'Recent Note Two',
      filePath: 'two.md',
      wordCount: 20,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Widget buildNotesListScreen({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: NotesListScreen(),
      ),
    );
  }

  testWidgets('NotesListScreen displays Vault Home View (Bento Row & Recent Notes) when no folder is active', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        availableVaultsProvider.overrideWith((ref) => ['vault-1']),
        foldersProvider.overrideWith((ref) => mockFolders),
        noteFolderMappingsProvider.overrideWith((ref) => <String, List<String>>{}),
        notesProvider.overrideWith((ref) => mockNotes),
        recentNotesProvider.overrideWith((ref) => mockNotes),
        searchQueryProvider.overrideWith(() => FakeSearchQueryNotifier('')),
        selectedFolderIdProvider.overrideWith(() => FakeSelectedFolderIdNotifier(null)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildNotesListScreen(container: container));
    await tester.pumpAndSettle();

    // 1. Verify Folders section
    expect(find.text('FOLDERS'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byType(VirtualFoldersBentoRow), findsOneWidget);

    // 2. Verify Recent Notes section
    expect(find.text('RECENT NOTES'), findsOneWidget);
    expect(find.byType(NoteCard), findsNWidgets(2)); // NoteCards inside vertical recent list

    // 3. Verify NotesBentoGrid is NOT rendered on Vault Home
    expect(find.byType(NotesBentoGrid), findsNothing);
  });

  testWidgets('NotesListScreen displays Folder View (Header & Bento Grid, hides Bento Row) when a folder is selected', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        availableVaultsProvider.overrideWith((ref) => ['vault-1']),
        foldersProvider.overrideWith((ref) => mockFolders),
        noteFolderMappingsProvider.overrideWith((ref) => <String, List<String>>{}),
        notesProvider.overrideWith((ref) => mockNotes),
        recentNotesProvider.overrideWith((ref) => mockNotes),
        searchQueryProvider.overrideWith(() => FakeSearchQueryNotifier('')),
        selectedFolderIdProvider.overrideWith(() => FakeSelectedFolderIdNotifier('folder-work')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildNotesListScreen(container: container));
    await tester.pumpAndSettle();

    // 1. Verify Folders section is hidden
    expect(find.text('FOLDERS'), findsNothing);
    expect(find.byType(VirtualFoldersBentoRow), findsNothing);

    // 2. Verify Recent Notes section is hidden
    expect(find.text('RECENT NOTES'), findsNothing);

    // 3. Verify Folder Name and Count Header displays
    expect(find.text('Work • 2 notes'), findsOneWidget);

    // 4. Verify NotesBentoGrid renders
    expect(find.byType(NotesBentoGrid), findsOneWidget);

    // 5. Verify back button is visible and tap returns to Home View
    final backBtn = find.byIcon(Icons.arrow_back_rounded);
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(container.read(selectedFolderIdProvider), isNull);
  });

  testWidgets('NotesListScreen displays Folders Catalog View (all folder cards shown with showAll) when __folders__ is selected', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer(
      overrides: [
        availableVaultsProvider.overrideWith((ref) => ['vault-1']),
        foldersProvider.overrideWith((ref) => mockFolders),
        noteFolderMappingsProvider.overrideWith((ref) => <String, List<String>>{}),
        notesProvider.overrideWith((ref) => mockNotes),
        recentNotesProvider.overrideWith((ref) => mockNotes),
        searchQueryProvider.overrideWith(() => FakeSearchQueryNotifier('')),
        selectedFolderIdProvider.overrideWith(() => FakeSelectedFolderIdNotifier('__folders__')),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildNotesListScreen(container: container));
    await tester.pumpAndSettle();

    // 1. Verify standard FOLDERS header and bento grid are hidden
    expect(find.text('FOLDERS'), findsNothing);

    // 2. Verify header displays "Folders • 4 folders" (1 custom folder + 3 system folders)
    expect(find.text('Folders • 4 folders'), findsOneWidget);

    // 3. Verify Recent Notes section is hidden
    expect(find.text('RECENT NOTES'), findsNothing);

    // 4. Verify VirtualFoldersBentoRow is rendered inside Catalog scroll view
    final bentoRowFinder = find.byType(VirtualFoldersBentoRow);
    expect(bentoRowFinder, findsOneWidget);
    
    final VirtualFoldersBentoRow bentoRowWidget = tester.widget(bentoRowFinder);
    expect(bentoRowWidget.showAll, isTrue);

    // 5. Verify back button is visible and tap returns to Home View
    final backBtn = find.byIcon(Icons.arrow_back_rounded);
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(container.read(selectedFolderIdProvider), isNull);
  });
}
