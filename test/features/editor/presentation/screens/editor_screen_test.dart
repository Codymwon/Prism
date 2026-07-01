import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/screens/editor_screen.dart';
import 'package:prism/features/editor/presentation/widgets/backlinks_panel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';

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
  Future<String> readNoteContent(String noteId) async {
    final file = File(note.filePath);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    throw ArgumentError('Note not found or file does not exist for ID: $noteId');
  }

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
    GoogleFonts.config.allowRuntimeFetching = false;

    // Intercept asset loading to load google_fonts from the local directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(message.buffer.asUint8List());
        if (key == 'AssetManifest.json') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Medium.ttf': ['google_fonts/Inter-Medium.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
            'google_fonts/Inter-SemiBold.ttf': ['google_fonts/Inter-SemiBold.ttf'],
            'google_fonts/RobotoMono-Regular.ttf': ['google_fonts/RobotoMono-Regular.ttf'],
          };
          final jsonStr = json.encode(manifest);
          final bytes = utf8.encode(jsonStr);
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }
        if (key == 'AssetManifest.bin') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Medium.ttf': ['google_fonts/Inter-Medium.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
            'google_fonts/Inter-SemiBold.ttf': ['google_fonts/Inter-SemiBold.ttf'],
            'google_fonts/RobotoMono-Regular.ttf': ['google_fonts/RobotoMono-Regular.ttf'],
          };
          return const StandardMessageCodec().encodeMessage(manifest);
        }
        
        if (key.endsWith('.ttf')) {
          final filename = p.basename(key);
          final file = File('google_fonts/$filename');
          if (file.existsSync()) {
            final bytes = file.readAsBytesSync();
            return ByteData.view(bytes.buffer);
          }
        }
        return null;
      },
    );

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
    expect(processedData, equals('# Test Note\n&nbsp;\nParagraph A\n&nbsp;\n&nbsp;\nParagraph B\n'));
  });

  testWidgets('EditorScreen in preview mode enables softLineBreak on MarkdownBody', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-soft-breaks';
    final rawContent = '[[Wikilink Target]]\nSome text content on next line\n';
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

    // Set mode to reading view (preview mode)
    final element = tester.element(find.byType(EditorScreen));
    ProviderScope.containerOf(element)
        .read(editorControllerProvider(noteId).notifier)
        .setEditorMode(EditorMode.reading);
    await tester.pump();

    final markdownBodyFinder = find.byType(MarkdownBody);
    expect(markdownBodyFinder, findsAtLeastNWidgets(1));

    bool foundSoftLineBreak = false;
    for (final element in tester.widgetList<MarkdownBody>(markdownBodyFinder)) {
      if (element.softLineBreak == true) {
        foundSoftLineBreak = true;
      }
    }
    expect(foundSoftLineBreak, isTrue);
  });

  testWidgets('EditorScreen hides BacklinksPanel when keyboard is open (non-zero bottom view inset)', (WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'test-note-backlinks-keyboard';
    final note = Note(
      id: noteId,
      title: 'Test Note',
      filePath: noteFile.path,
      wordCount: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final backlinks = [
      Backlink(sourceId: 'src-1', sourceTitle: 'Source Title', contextSnippet: 'Mention [[Test Note]]'),
    ];

    final mockRepo = MockNoteRepository(note);

    // Ensure we start with keyboard closed and showBacklinks is enabled
    SharedPreferences.setMockInitialValues({
      'showBacklinks': true,
    });
    tester.view.viewInsets = const FakeViewPadding(bottom: 0);
    addTearDown(() {
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(mockRepo),
          noteByIdProvider(noteId).overrideWith((ref) => note),
          backlinksProvider(noteId).overrideWith((ref) => backlinks),
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

    // Verify BacklinksPanel is visible when keyboard is closed
    expect(find.byType(BacklinksPanel), findsOneWidget);

    // Simulate keyboard opening (non-zero bottom view inset)
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    // Verify BacklinksPanel is hidden
    expect(find.byType(BacklinksPanel), findsNothing);
  });
}
