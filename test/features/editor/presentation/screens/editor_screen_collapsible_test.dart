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
  Future<List<String>> getTagsForNote(String noteId) async => [];
}

void main() {
  group('H1 Collapsible Heading Grouping', () {
    test('should group segments into sections by H1 heading', () {
      final segments = [
        MarkdownSegment.text('Intro text before heading.\n\n'),
        MarkdownSegment.text('# Section A\nContent of Section A\n'),
        MarkdownSegment.audio(label: 'audio1', path: 'attachments/audio1.m4a'),
        MarkdownSegment.text('\nMore text in Section A\n# Section B\nContent of Section B'),
      ];

      final sections = groupSegmentsByH1(segments);

      expect(sections, hasLength(3));

      // Section 1: Intro (headingText is null)
      expect(sections[0].headingText, isNull);
      expect(sections[0].segments, hasLength(1));
      expect(sections[0].segments[0].text, equals('Intro text before heading.\n\n'));

      // Section 2: Section A
      expect(sections[1].headingText, equals('Section A'));
      expect(sections[1].segments, hasLength(3));
      expect(sections[1].segments[0].text, equals('Content of Section A\n'));
      expect(sections[1].segments[1].isAudio, isTrue);
      expect(sections[1].segments[1].audioLabel, equals('audio1'));
      expect(sections[1].segments[2].text, equals('\nMore text in Section A\n'));

      // Section 3: Section B
      expect(sections[2].headingText, equals('Section B'));
      expect(sections[2].segments, hasLength(1));
      expect(sections[2].segments[0].text, equals('Content of Section B'));
    });

    test('should ignore H1 headers inside code blocks', () {
      final segments = [
        MarkdownSegment.text('Intro\n```javascript\n# This is comment, not H1\n```\n# Valid Section\nBody'),
      ];

      final sections = groupSegmentsByH1(segments);

      expect(sections, hasLength(2));
      expect(sections[0].headingText, isNull);
      expect(sections[1].headingText, equals('Valid Section'));
      expect(sections[1].segments[0].text, equals('Body'));
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
      // Set initial mock collapsed value in SharedPreferences: Section A is collapsed, Section B is expanded
      SharedPreferences.setMockInitialValues({
        'collapsed_test-note-1': ['Section A'],
      });

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
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Find chevrons
      final chevronFinder = find.byIcon(Icons.chevron_right);
      // We expect 2 chevrons (one for Section A, one for Section B)
      expect(chevronFinder, findsNWidgets(2));

      // Verify that Section A's content is NOT visible (since it's collapsed)
      expect(find.text('Content inside Section A'), findsNothing);

      // Verify that Section B's content IS visible (since it's expanded)
      expect(find.text('Content inside Section B'), findsOneWidget);

      // Tap Section A's chevron to expand it
      await tester.tap(chevronFinder.at(0));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Section A's content is now visible
      expect(find.text('Content inside Section A'), findsOneWidget);

      // Verify SharedPreferences has been updated (no longer has Section A collapsed)
      final prefs = await SharedPreferences.getInstance();
      final collapsed = prefs.getStringList('collapsed_test-note-1') ?? [];
      expect(collapsed, isNot(contains('Section A')));

      // Tap Section B's chevron to collapse it
      await tester.tap(chevronFinder.at(1));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Section B's content is now hidden
      expect(find.text('Content inside Section B'), findsNothing);

      // Verify SharedPreferences has been updated (has Section B collapsed)
      final collapsedAfter = prefs.getStringList('collapsed_test-note-1') ?? [];
      expect(collapsedAfter, contains('Section B'));
    });
  });
}
