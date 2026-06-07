import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/screens/editor_screen.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/utils/utils.dart';

class FakeRef implements Ref<Object?> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockNoteRepository extends NoteRepository {
  final Note note;
  final void Function(String id, String content)? onSaveNote;
  MockNoteRepository(this.note, {this.onSaveNote}) : super(FakeRef());

  @override
  Future<Note?> getNoteById(String id) async => note;

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => [];

  @override
  Future<void> saveNote(String id, String content) async {
    onSaveNote?.call(id, content);
  }

  @override
  Future<List<String>> getTagsForNote(String noteId) async => [];
}

void main() {
  late Directory tempDir;
  late File noteFile;
  late File imageFile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('prism_test_vault');
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
    expect(savedContent, equals('---\ntitle: "Test Note"\n---\n\n- [x] Task A\n- [x] Task B\n'));
  });

  testWidgets('EditorScreen renders and toggles spaced-out checklist items without rendering them as list dots', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-spaced-checklists';
    final rawContent = '# Test Note\n\n- [ ] Task A\n\n- [ ] Task B\n\n- [ ] Task C\n- Normal bullet\n';
    noteFile.writeAsStringSync(rawContent);

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

    // Yield to the event loop so file I/O can complete
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Verify Checkboxes are rendered despite spacing and normal bullets
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNWidgets(3));

    // Tap the second checkbox (Task B)
    await tester.tap(checkboxFinder.at(1));
    await tester.pump();

    // Verify that the second checklist item is toggled, and the raw formatting (spacing) is preserved
    final expectedContent = '---\ntitle: "Test Note"\n---\n\n- [ ] Task A\n\n- [x] Task B\n\n- [ ] Task C\n- Normal bullet\n';
    expect(savedContent, equals(expectedContent));
  });

  testWidgets('EditorScreen preserves paragraph and heading empty line spaces in preview mode', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-paragraph-spaces';
    final rawContent = '# Test Note\n\nParagraph A\n\n\nParagraph B\n';
    noteFile.writeAsStringSync(rawContent);

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

    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Verify that the parser correctly processed the empty newlines to &nbsp; while keeping blank lines
    final processedData = preprocessMarkdown(rawContent);
    expect(processedData, equals('# Test Note\n\n&nbsp;\n\nParagraph A\n\n&nbsp;\n\n\n&nbsp;\n\nParagraph B\n'));
  });
}
