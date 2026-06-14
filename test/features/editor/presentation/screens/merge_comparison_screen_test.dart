import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prism/features/editor/presentation/screens/merge_comparison_screen.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';

import 'dart:convert';

class FakeRef implements Ref<Object?> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockNoteRepository extends NoteRepository {
  final Map<String, Note> notes;
  final Map<String, String> noteContents;
  final Function(String id, String content)? onSaveNote;
  final Function(String id)? onDeleteNote;

  MockNoteRepository({
    required this.notes,
    required this.noteContents,
    this.onSaveNote,
    this.onDeleteNote,
  }) : super(FakeRef());

  @override
  Future<Note?> getNoteById(String id) async {
    debugPrint('*** MockNoteRepository.getNoteById: id = $id, note = ${notes[id]}');
    return notes[id];
  }

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => [];

  @override
  Future<void> saveNote(String id, String content) async {
    noteContents[id] = content;
    onSaveNote?.call(id, content);
  }

  @override
  Future<void> deleteNote(String id) async {
    notes.remove(id);
    onDeleteNote?.call(id);
  }

  @override
  Future<String> readNoteContent(String noteId) async {
    return noteContents[noteId] ?? '';
  }

  @override
  Future<List<String>> getTagsForNote(String noteId) async => [];
}

void main() {
  late Directory tempDir;
  late File originalFile;
  late File conflictFile;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    
    // Intercept asset loading to load google_fonts from the local directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(message.buffer.asUint8List());
        debugPrint('*** ASSET KEY REQUESTED: $key');
        if (key == 'AssetManifest.json') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
            'google_fonts/RobotoMono-Regular.ttf': ['google_fonts/RobotoMono-Regular.ttf'],
          };
          final jsonStr = json.encode(manifest);
          final bytes = utf8.encode(jsonStr);
          return ByteData.view(Uint8List.fromList(bytes).buffer);
        }
        if (key == 'AssetManifest.bin') {
          final manifest = {
            'google_fonts/Inter-Bold.ttf': ['google_fonts/Inter-Bold.ttf'],
            'google_fonts/Inter-Regular.ttf': ['google_fonts/Inter-Regular.ttf'],
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
    tempDir = await Directory.systemTemp.createTemp('prism_conflict_test_vault');
    originalFile = File(p.join(tempDir.path, 'original.md'));
    conflictFile = File(p.join(tempDir.path, 'conflict.md'));

    await originalFile.writeAsString('# Original Title\n\nThis is original content.');
    await conflictFile.writeAsString('# Conflict Title\n\nThis is conflicted content.');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('MergeComparisonScreen loads and displays original and conflict content', (WidgetTester tester) async {
    final originalNote = Note(
      id: 'original-id',
      title: 'Original Title',
      filePath: originalFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final conflictNote = Note(
      id: 'conflict-id',
      title: 'Conflict Title',
      filePath: conflictFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isConflicted: true,
      originalNoteId: 'original-id',
    );

    final mockRepo = MockNoteRepository(
      notes: {
        'original-id': originalNote,
        'conflict-id': conflictNote,
      },
      noteContents: {
        'original-id': '# Original Title\n\nThis is original content.',
        'conflict-id': '# Conflict Title\n\nThis is conflicted content.',
      },
    );

    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const MergeComparisonScreen(noteId: 'conflict-id'),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
            noteByIdProvider('conflict-id').overrideWith((ref) => conflictNote),
            noteByIdProvider('original-id').overrideWith((ref) => originalNote),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      // Allow file I/O and font loading to complete
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pump();

    Finder findRichText(String text) {
      return find.byWidgetPredicate((widget) =>
          widget is Text &&
          (widget.data == text ||
              (widget.textSpan != null &&
                  widget.textSpan!.toPlainText().contains(text))));
    }

    // Verify tabs are present
    expect(find.text('Original Note'), findsOneWidget);
    expect(find.text('Conflicted Copy'), findsOneWidget);

    // Verify original content is visible initially
    expect(findRichText('This is original content.'), findsOneWidget);

    // Switch to Conflicted Copy tab
    await tester.tap(find.text('Conflicted Copy'));
    await tester.pumpAndSettle();

    // Verify conflicted content is visible
    expect(findRichText('This is conflicted content.'), findsOneWidget);
  });

  testWidgets('MergeComparisonScreen resolves conflict using Keep Original option', (WidgetTester tester) async {
    final originalNote = Note(
      id: 'original-id',
      title: 'Original Title',
      filePath: originalFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final conflictNote = Note(
      id: 'conflict-id',
      title: 'Conflict Title',
      filePath: conflictFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isConflicted: true,
      originalNoteId: 'original-id',
    );

    String? deletedId;
    final mockRepo = MockNoteRepository(
      notes: {
        'original-id': originalNote,
        'conflict-id': conflictNote,
      },
      noteContents: {
        'original-id': '# Original Title\n\nThis is original content.',
        'conflict-id': '# Conflict Title\n\nThis is conflicted content.',
      },
      onDeleteNote: (id) {
        deletedId = id;
      },
    );

    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const MergeComparisonScreen(noteId: 'conflict-id'),
        ),
        GoRoute(
          path: '/notes',
          builder: (context, state) => const Scaffold(body: Text('Notes Page')),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
            noteByIdProvider('conflict-id').overrideWith((ref) => conflictNote),
            noteByIdProvider('original-id').overrideWith((ref) => originalNote),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pump();

    // Verify button is present and tap it
    final keepOriginalButton = find.text('Keep Original');
    expect(keepOriginalButton, findsOneWidget);

    await tester.tap(keepOriginalButton);
    await tester.pumpAndSettle();

    // Verify conflict note deleted in repository
    expect(deletedId, equals('conflict-id'));

    // Verify navigation occurred to /notes
    expect(find.text('Notes Page'), findsOneWidget);

    // Verify snackbar is displayed
    expect(find.text('Conflicted copy discarded. Keeping original note.'), findsOneWidget);
  });

  testWidgets('MergeComparisonScreen resolves conflict using Keep Conflicted option', (WidgetTester tester) async {
    final originalNote = Note(
      id: 'original-id',
      title: 'Original Title',
      filePath: originalFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final conflictNote = Note(
      id: 'conflict-id',
      title: 'Conflict Title',
      filePath: conflictFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isConflicted: true,
      originalNoteId: 'original-id',
    );

    String? deletedId;
    String? savedId;
    String? savedContent;
    final mockRepo = MockNoteRepository(
      notes: {
        'original-id': originalNote,
        'conflict-id': conflictNote,
      },
      noteContents: {
        'original-id': '# Original Title\n\nThis is original content.',
        'conflict-id': '# Conflict Title\n\nThis is conflicted content.',
      },
      onSaveNote: (id, content) {
        savedId = id;
        savedContent = content;
      },
      onDeleteNote: (id) {
        deletedId = id;
      },
    );

    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const MergeComparisonScreen(noteId: 'conflict-id'),
        ),
        GoRoute(
          path: '/editor/:id',
          builder: (context, state) => Scaffold(body: Text('Editor Page: ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
            noteByIdProvider('conflict-id').overrideWith((ref) => conflictNote),
            noteByIdProvider('original-id').overrideWith((ref) => originalNote),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pump();

    // Verify button is present and tap it
    final keepConflictedButton = find.text('Keep Conflicted');
    expect(keepConflictedButton, findsOneWidget);

    await tester.tap(keepConflictedButton);
    await tester.pumpAndSettle();

    // Verify original note saved with conflicted content
    expect(savedId, equals('original-id'));
    expect(savedContent, equals('# Conflict Title\n\nThis is conflicted content.'));

    // Verify conflict note deleted in repository
    expect(deletedId, equals('conflict-id'));

    // Verify navigation occurred to /editor/original-id
    expect(find.text('Editor Page: original-id'), findsOneWidget);

    // Verify snackbar is displayed
    expect(find.text('Original note replaced with conflicted copy contents.'), findsOneWidget);
  });

  testWidgets('MergeComparisonScreen resolves conflict using Merge Both Copies option', (WidgetTester tester) async {
    final originalNote = Note(
      id: 'original-id',
      title: 'Original Title',
      filePath: originalFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final conflictNote = Note(
      id: 'conflict-id',
      title: 'Conflict Title',
      filePath: conflictFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isConflicted: true,
      originalNoteId: 'original-id',
    );

    String? deletedId;
    String? savedId;
    String? savedContent;
    final mockRepo = MockNoteRepository(
      notes: {
        'original-id': originalNote,
        'conflict-id': conflictNote,
      },
      noteContents: {
        'original-id': '# Original Title\n\nThis is original content.',
        'conflict-id': '# Conflict Title\n\nThis is conflicted content.',
      },
      onSaveNote: (id, content) {
        savedId = id;
        savedContent = content;
      },
      onDeleteNote: (id) {
        deletedId = id;
      },
    );

    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const MergeComparisonScreen(noteId: 'conflict-id'),
        ),
        GoRoute(
          path: '/editor/:id',
          builder: (context, state) {
            final isNew = state.uri.queryParameters['new'] == 'true';
            return Scaffold(body: Text('Editor Page: ${state.pathParameters['id']}, new=$isNew'));
          },
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
            noteByIdProvider('conflict-id').overrideWith((ref) => conflictNote),
            noteByIdProvider('original-id').overrideWith((ref) => originalNote),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    });

    await tester.pump();

    // Verify button is present and tap it
    final mergeBothButton = find.text('Merge Both Copies');
    expect(mergeBothButton, findsOneWidget);

    await tester.tap(mergeBothButton);
    await tester.pumpAndSettle();

    // Verify original note saved with merged content containing Git-style conflict markers
    expect(savedId, equals('original-id'));
    
    final expectedMergedContent = '''# Conflict Resolved: Original Title

<<<<<<< ORIGINAL COPY
# Original Title

This is original content.
=======
# Conflict Title

This is conflicted content.
>>>>>>> CONFLICTED COPY
''';
    expect(savedContent, equals(expectedMergedContent));

    // Verify conflict note deleted in repository
    expect(deletedId, equals('conflict-id'));

    // Verify navigation occurred to /editor/original-id with new=true query param
    expect(find.text('Editor Page: original-id, new=true'), findsOneWidget);

    // Verify snackbar is displayed
    expect(find.text('Notes merged with Git conflict markers. Please resolve manually.'), findsOneWidget);
  });

  testWidgets('MergeComparisonScreen renders hashtags in theme primary color', (WidgetTester tester) async {
    final originalNote = Note(
      id: 'original-id',
      title: 'Original Title',
      filePath: originalFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final conflictNote = Note(
      id: 'conflict-id',
      title: 'Conflict Title',
      filePath: conflictFile.path,
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isConflicted: true,
      originalNoteId: 'original-id',
    );

    final mockRepo = MockNoteRepository(
      notes: {
        'original-id': originalNote,
        'conflict-id': conflictNote,
      },
      noteContents: {},
    );

    final router = GoRouter(
      initialLocation: '/compare',
      routes: [
        GoRoute(
          path: '/compare',
          builder: (context, state) => const MergeComparisonScreen(noteId: 'conflict-id'),
        ),
      ],
    );

    await tester.runAsync(() async {
      // Write the contents containing hashtags directly to the files since the screen reads files from disk
      await originalFile.writeAsString('# Original Title\n\nOriginal content with #tagone.');
      await conflictFile.writeAsString('# Conflict Title\n\nConflicted content with #tagtwo.');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
            noteByIdProvider('conflict-id').overrideWith((ref) => conflictNote),
            noteByIdProvider('original-id').overrideWith((ref) => originalNote),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    });


    await tester.pump();

    // Verify #tagone is rendered in Original Note tab
    final tag1Finder = find.text('#tagone');
    expect(tag1Finder, findsOneWidget);

    final tag1Text = tester.widget<Text>(tag1Finder);
    expect(tag1Text.style?.color, isNotNull);

    final BuildContext context = tester.element(find.byType(MergeComparisonScreen));
    final expectedColor = Theme.of(context).colorScheme.primary;
    expect(tag1Text.style?.color, equals(expectedColor));
  });
}

