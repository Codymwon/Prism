import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/editor/presentation/providers/editor_controller.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:prism/features/onboarding/data/onboarding_provider.dart';

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
  late SharedPreferences prefs;
  late ProviderContainer container;
  late FakeNoteRepository fakeNoteRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeNoteRepository = FakeNoteRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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

    test('should persist mode to SharedPreferences when setEditorMode is called with livePreview or reading', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      await controller.setEditorMode(EditorMode.reading);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.reading);

      // Verify SharedPreferences has the value
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('editorMode_note-1'), 'reading');
    });

    test('should load persisted mode from SharedPreferences on loadNote', () async {
      await prefs.setString('editorMode_note-1', 'reading');

      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.reading);
    });

    test('should NOT persist to SharedPreferences when setEditorMode is called with source (transient)', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      await controller.setEditorMode(EditorMode.source);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.source);

      // Verify SharedPreferences does NOT have 'source' (it might have been deleted, or never written)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('editorMode_note-1'), isNot('source'));
    });

    test('should default to livePreview on loadNote if persisted mode is source', () async {
      await prefs.setString('editorMode_note-1', 'source');

      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.editorMode, EditorMode.livePreview);
    });

    test('should default showBacklinks to false and load global showBacklinks from SharedPreferences', () async {
      await prefs.setBool('showBacklinks', true);

      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      final state = container.read(editorControllerProvider('note-1'));
      expect(state.showBacklinks, isTrue);
    });

    test('should toggle showBacklinks globally and persist to SharedPreferences', () async {
      final controller = container.read(editorControllerProvider('note-1').notifier);
      await controller.loadNote(isNew: false);

      // Default is false
      var state = container.read(editorControllerProvider('note-1'));
      expect(state.showBacklinks, isFalse);

      await controller.toggleShowBacklinks();

      state = container.read(editorControllerProvider('note-1'));
      expect(state.showBacklinks, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('showBacklinks'), isTrue);
    });
  });
}
