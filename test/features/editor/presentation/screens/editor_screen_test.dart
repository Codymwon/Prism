import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian/features/editor/presentation/screens/editor_screen.dart';
import 'package:meridian/features/notes/data/note_model.dart';
import 'package:meridian/features/notes/data/note_repository.dart';
import 'package:meridian/features/notes/presentation/providers/notes_providers.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:meridian/features/notes/data/vault_service.dart';

class MockNoteRepository implements NoteRepository {
  final Note note;
  final void Function(String id, String content)? onSaveNote;
  MockNoteRepository(this.note, {this.onSaveNote});

  @override
  Ref get _ref => throw UnimplementedError();

  @override
  Future<Database> get _db => throw UnimplementedError();

  @override
  Future<VaultService> get _vaultService => throw UnimplementedError();

  @override
  Future<Note> createNote({String? title, String initialContent = '', bool isDaily = false, String? dailyDate}) => throw UnimplementedError();

  @override
  Future<Note> createGhostNote(String title) => throw UnimplementedError();

  @override
  Future<List<Note>> getAllNotes({NoteSort sort = NoteSort.updated}) => throw UnimplementedError();

  @override
  Future<Note?> getNoteById(String id) async => note;

  @override
  Future<Note?> getNoteByTitle(String title) => throw UnimplementedError();

  @override
  Future<Note?> getDailyNote(String date) => throw UnimplementedError();

  @override
  Future<List<Note>> searchNotes(String query) => throw UnimplementedError();

  @override
  Future<List<Note>> getNotesByTag(String tag) => throw UnimplementedError();

  @override
  Future<List<Note>> getTitleSuggestions(String query) => throw UnimplementedError();

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => [];

  @override
  Future<({List<GraphNode> nodes, List<GraphEdge> edges})> getGraphData() => throw UnimplementedError();

  @override
  Future<void> saveNote(String id, String content) async {
    onSaveNote?.call(id, content);
  }

  @override
  Future<void> deleteNote(String id) => throw UnimplementedError();

  @override
  Future<List<String>> getTagsForNote(String noteId) async => [];

  @override
  Future<List<String>> getUniqueTags() => throw UnimplementedError();

  @override
  Future<({int totalNotes, int totalWords, int totalLinks})> getVaultStats() => throw UnimplementedError();
}

void main() {
  late Directory tempDir;
  late File noteFile;
  late File imageFile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('meridian_test_vault');
    noteFile = File(p.join(tempDir.path, 'note1.md'));
    await noteFile.writeAsString('# Test Note\n\n![image](attachments/test.png)\n');

    final attachmentsDir = Directory(p.join(tempDir.path, 'attachments'));
    await attachmentsDir.create(recursive: true);
    imageFile = File(p.join(attachmentsDir.path, 'test.png'));
    // Write 10 mock bytes for a valid-looking file existence check
    await imageFile.writeAsBytes(List.generate(10, (index) => index));
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('EditorScreen in preview mode renders local attachments images using custom builder', (WidgetTester tester) async {
    // Mock the record plugin method channel
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-1';
    final note = Note(
      id: noteId,
      title: 'Test Note',
      filePath: noteFile.path,
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockRepo = MockNoteRepository(note);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockRepo),
          noteByIdProvider(noteId).overrideWith((ref) => note),
          backlinksProvider(noteId).overrideWith((ref) => []),
        ],
        child: MaterialApp(
          home: EditorScreen(
            noteId: noteId,
            isNew: false,
          ),
        ),
      ),
    );

    // Yield to the real event loop so filesystem I/O can complete
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });

    // Pump to process setState and render the updated widget tree
    await tester.pump();

    // Ensure we are in preview mode
    final containerFinder = find.byType(EditorScreen);
    expect(containerFinder, findsOneWidget);

    // Verify the image is rendered inside the Markdown view
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<FileImage>());
    
    final fileImage = imageWidget.image as FileImage;
    expect(p.normalize(fileImage.file.path), p.normalize(imageFile.path));
  });

  testWidgets('EditorScreen in preview mode renders interactive checklists and toggles them', (WidgetTester tester) async {
    // Mock the record plugin method channel
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-2';
    final initialContent = '# Test Note\n\n- [ ] Task A\n- [x] Task B\n';
    noteFile.writeAsStringSync(initialContent);

    final note = Note(
      id: noteId,
      title: 'Test Note',
      filePath: noteFile.path,
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? savedContent;
    final mockRepo = MockNoteRepository(
      note,
      onSaveNote: (id, content) {
        savedContent = content;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockRepo),
          noteByIdProvider(noteId).overrideWith((ref) => note),
          backlinksProvider(noteId).overrideWith((ref) => []),
        ],
        child: MaterialApp(
          home: EditorScreen(
            noteId: noteId,
            isNew: false,
          ),
        ),
      ),
    );

    // Yield to the real event loop so filesystem I/O can complete
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });

    // Pump to process setState and render the updated widget tree
    await tester.pump();

    // Verify Checkboxes are rendered
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNWidgets(2));

    // Get the first Checkbox and tap it
    await tester.tap(checkboxFinder.at(0));
    await tester.pump();

    // Verify saveNote was called with the updated content
    expect(savedContent, equals('# Test Note\n\n- [x] Task A\n- [x] Task B\n'));
  });
}
