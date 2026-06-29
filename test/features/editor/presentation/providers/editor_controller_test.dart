import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';

// We can create a simple mock/fake for NoteRepository
class FakeNoteRepository extends Fake implements NoteRepository {
  @override
  Future<Note?> getNoteById(String id) async {
    return Note(
      id: id,
      title: 'Test Note',
      filePath: 'vault/Test Note.md',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      wordCount: 0,
    );
  }

  @override
  Future<String> readNoteContent(String id) async {
    return 'Content';
  }

  @override
  Future<void> saveNote(String id, String content) async {
    // No-op
  }
}

void main() {
  late ProviderContainer container;
  late FakeNoteRepository fakeNoteRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeNoteRepository = FakeNoteRepository();
    container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(fakeNoteRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('EditorController Mode and Persistence Tests', () {
    test('should default to livePreview when loading a note for the first time', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.livePreview);
    });

    test('should persist mode to SharedPreferences when setEditorMode is called with livePreview or source', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      await controller.setEditorMode(EditorMode.source);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.source);

      // Verify SharedPreferences has the value
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('editorMode_note-1'), 'source');
    });

    test('should load persisted mode from SharedPreferences on loadNote', () async {
      SharedPreferences.setMockInitialValues({
        'editorMode_note-1': 'source',
      });

      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.source);
    });

    test('should NOT persist to SharedPreferences when setEditorMode is called with reading (transient)', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      await controller.setEditorMode(EditorMode.reading);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.reading);

      // Verify SharedPreferences does NOT have 'reading'
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('editorMode_note-1'), isFalse);
    });
  });
}
