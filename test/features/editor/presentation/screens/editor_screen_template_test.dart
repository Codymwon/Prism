import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/screens/editor_screen.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRef implements Ref<Object?> {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockTemplateNoteRepository extends NoteRepository {
  final Note note;
  final String content;

  MockTemplateNoteRepository(this.note, this.content) : super(FakeRef());

  @override
  Future<Note?> getNoteById(String id) async => note;

  @override
  Future<List<Backlink>> getBacklinks(String noteId) async => [];

  @override
  Future<String> readNoteContent(String noteId) async => content;

  @override
  Future<void> saveNote(String id, String content) async {}

  @override
  Future<List<String>> getTagsForNote(String noteId) async => [];
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows TEMPLATE badge in editor header for template notes', (WidgetTester tester) async {
    // Mock the record plugin method channel to prevent MissingPluginException
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (methodCall) async {
        return null;
      },
    );

    final noteId = 'template:Gratitude';
    final note = Note(
      id: noteId,
      title: 'Gratitude',
      filePath: '',
      wordCount: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    final mockRepo = MockTemplateNoteRepository(note, '---\ntitle: "Gratitude"\n---\n\nBe grateful.');

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
          home: EditorScreen(
            noteId: noteId,
            isNew: false,
          ),
        ),
      ),
    );

    // Advance fake async clock to fire the 300ms autofocus timer and finish load
    await tester.pump(const Duration(milliseconds: 500));

    // Verify title text is rendered in the AppBar
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Gratitude')),
      findsOneWidget,
    );

    // Verify TEMPLATE badge text is rendered
    expect(find.text('TEMPLATE'), findsOneWidget);
  });
}
