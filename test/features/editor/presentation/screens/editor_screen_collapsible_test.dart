import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/editor/presentation/screens/editor_screen.dart';
import 'package:prism/features/editor/presentation/utils/editor_helpers.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';

class FakeRef implements Ref<Object?> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockNoteRepository extends NoteRepository {
  final Note note;
  MockNoteRepository(this.note) : super(FakeRef());

  @override
  Future<Note?> getNoteById(String id) async => note;

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => [];

  @override
  Future<void> saveNote(String id, String content) async {}

  @override
  Future<String> readNoteContent(String noteId) async {
    final file = File(note.filePath);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
    throw ArgumentError('Note not found or file does not exist for ID: $noteId');
  }

  @override
  Future<List<String>> getTagsForNote(String noteId) async => [];
}

void main() {
  group('H1 Collapsible Heading Grouping', () {
    test('should group segments into sections by heading hierarchy', () {
      final segments = [
        MarkdownSegment.text('Intro text before heading.\n\n'),
        MarkdownSegment.text('# Section A\nContent of Section A\n'),
        MarkdownSegment.audio(label: 'audio1', path: 'attachments/audio1.m4a'),
        MarkdownSegment.text('\nMore text in Section A\n# Section B\nContent of Section B'),
      ];

      final root = parseHierarchicalSections(segments);

      expect(root.segments, hasLength(1));
      expect(root.segments[0].text, equals('Intro text before heading.\n\n'));
      expect(root.children, hasLength(2));

      // Section A
      final sectionA = root.children[0];
      expect(sectionA.headingText, equals('Section A'));
      expect(sectionA.level, equals(1));
      expect(sectionA.segments, hasLength(3));
      expect(sectionA.segments[0].text, equals('Content of Section A\n'));
      expect(sectionA.segments[1].isAudio, isTrue);
      expect(sectionA.segments[1].audioLabel, equals('audio1'));
      expect(sectionA.segments[2].text, equals('\nMore text in Section A'));

      // Section B
      final sectionB = root.children[1];
      expect(sectionB.headingText, equals('Section B'));
      expect(sectionB.level, equals(1));
      expect(sectionB.segments, hasLength(1));
      expect(sectionB.segments[0].text, equals('Content of Section B'));
    });

    test('should ignore H1 headers inside code blocks', () {
      final segments = [
        MarkdownSegment.text('Intro\n```javascript\n# This is comment, not H1\n```\n# Valid Section\nBody'),
      ];

      final root = parseHierarchicalSections(segments);

      expect(root.segments, hasLength(1));
      expect(root.segments[0].text, equals('Intro\n```javascript\n# This is comment, not H1\n```'));
      expect(root.children, hasLength(1));
      expect(root.children[0].headingText, equals('Valid Section'));
      expect(root.children[0].segments[0].text, equals('Body'));
    });

    test('should calculate correct checkboxLineIndices for segments', () {
      final segments = splitAudioLinks(
        '- [ ] task 1\n'
        '# Section A\n'
        '- [ ] task 2\n'
        '- [ ] task 3\n'
        '# Section B\n'
        '- [ ] task 4\n'
      );
      
      final root = parseHierarchicalSections(segments);
      
      // Root (before any heading) has task 1 (line 0)
      expect(root.segments[0].checkboxLineIndices, equals([0]));
      
      // Section A has task 2 (line 2) and task 3 (line 3)
      expect(root.children[0].segments[0].checkboxLineIndices, equals([2, 3]));
      
      // Section B has task 4 (line 5)
      expect(root.children[1].segments[0].checkboxLineIndices, equals([5]));
    });
  });

  group('EditorScreen Collapsible Heading Integration', () {
    late Directory tempDir;
    late File noteFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('prism_collapsible_test_vault');
      noteFile = File(p.join(tempDir.path, 'note1.md'));
      await noteFile.writeAsString('# Section A\nContent inside Section A\n\n# Section B\nContent inside Section B\n');
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    testWidgets('should load collapsed state from SharedPreferences and toggle collapse state on tap', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'collapsed_test-note-1': ['Section A'],
      });
      final prefs = await SharedPreferences.getInstance();

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (methodCall) async => null,
      );

      final noteId = 'test-note-1';
      final note = Note(
        id: noteId,
        title: 'note1',
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
        await Future.delayed(const Duration(seconds: 1));
      });
      await tester.pump();

      // Set mode to reading view (preview mode)
      final element = tester.element(find.byType(EditorScreen));
      ProviderScope.containerOf(element)
          .read(editorControllerProvider(noteId).notifier)
          .setEditorMode(EditorMode.reading);
      await tester.pump();

      // Find chevrons
      final chevronFinder = find.byIcon(Icons.chevron_right);
      // We expect 2 chevrons (one for Section A, one for Section B)
      expect(chevronFinder, findsNWidgets(2));

      // Verify that Section A's content is NOT visible (since it's collapsed)
      expect(find.textContaining('Content inside Section A'), findsNothing);

      // Verify that Section B's content IS visible (since it's expanded)
      expect(find.textContaining('Content inside Section B'), findsOneWidget);

      // Tap Section A's chevron to expand it
      await tester.tap(chevronFinder.at(0));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Section A's content is now visible
      expect(find.textContaining('Content inside Section A'), findsOneWidget);

      // Verify SharedPreferences has been updated (no longer has Section A collapsed)
      final collapsed = prefs.getStringList('collapsed_test-note-1') ?? [];
      expect(collapsed, isNot(contains('Section A')));

      // Tap Section B's chevron to collapse it
      await tester.tap(chevronFinder.at(1));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Section B's content is now hidden
      expect(find.textContaining('Content inside Section B'), findsNothing);

      // Verify SharedPreferences has been updated (has Section B collapsed)
      final collapsedAfter = prefs.getStringList('collapsed_test-note-1') ?? [];
      expect(collapsedAfter, contains('Section B'));
    });
  });
}
