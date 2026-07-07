import 'package:prism/l10n/l10n.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/editor/presentation/screens/editor_screen.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/shared/design_system/design_system.dart';

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

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('prism_test_vault');
    noteFile = File(p.join(tempDir.path, 'note1.md'));
    await noteFile.writeAsString('# Test Note\n\nHello #welcome to #productivity\n');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('EditorScreen in preview mode renders hashtags in theme primary color', (WidgetTester tester) async {
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return EditorScreen(
                noteId: noteId,
                isNew: false,
              );
            },
          ),
        ),
      ),
    );

    // Let filesystem I/O complete
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

    // Verify the hashtags #welcome and #productivity are rendered as styled widgets.
    // They should be inside a Container/Text with primary color.
    final welcomeFinder = find.text('#welcome');
    expect(welcomeFinder, findsOneWidget);

    final welcomeText = tester.widget<Text>(welcomeFinder);
    expect(welcomeText.style?.color, isNotNull);
    
    // We get the BuildContext from EditorScreen's location to compare colors
    final BuildContext context = tester.element(find.byType(EditorScreen));
    final expectedColor = DesignColors.primary(context);
    expect(welcomeText.style?.color, equals(expectedColor));
  });
}
