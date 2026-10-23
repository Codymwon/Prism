import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/notes/presentation/widgets/notes_bento_grid.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/presentation/providers/notes_providers.dart';

void main() {
  final mockNotes = [
    Note(
      id: 'note-1',
      title: 'Note One',
      filePath: 'one.md',
      wordCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Note(
      id: 'note-2',
      title: 'Note Two',
      filePath: 'two.md',
      wordCount: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  Widget buildBentoGrid({
    required List<Note> notes,
  }) {
    return ProviderScope(
      overrides: [
        allNoteTagsMapProvider.overrideWith((ref) async => {}),
        noteDetailsProvider('note-1').overrideWith((ref) async {
          return (tags: <String>[], snippet: '');
        }),
        noteDetailsProvider('note-2').overrideWith((ref) async {
          return (tags: <String>[], snippet: '');
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotesBentoGrid(
            notes: notes,
            onNoteTap: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );
  }

  group('NotesBentoGrid Responsiveness', () {
    testWidgets('renders in a single column on narrow viewports (< 600px)', (WidgetTester tester) async {
      // Set viewport width to 450px (< 600px)
      tester.view.physicalSize = const Size(450, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildBentoGrid(notes: mockNotes));
      await tester.pumpAndSettle();

      // Find the positions of the two note cards
      final offset1 = tester.getTopLeft(find.text('Note One'));
      final offset2 = tester.getTopLeft(find.text('Note Two'));

      // In a 1-column layout, note cards are stacked vertically (same x, different y)
      expect(offset1.dx, equals(offset2.dx));
      expect(offset1.dy, lessThan(offset2.dy));
    });

    testWidgets('renders in two columns on wider viewports (>= 600px)', (WidgetTester tester) async {
      // Set viewport width to 700px (>= 600px)
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildBentoGrid(notes: mockNotes));
      await tester.pumpAndSettle();

      // Find the positions of the two note cards
      final offset1 = tester.getTopLeft(find.text('Note One'));
      final offset2 = tester.getTopLeft(find.text('Note Two'));

      // In a 2-column layout, cards are placed side-by-side (same y, different x)
      expect(offset1.dy, equals(offset2.dy));
      expect(offset1.dx, lessThan(offset2.dx));
    });
  });
}
