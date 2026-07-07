import 'package:prism/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:prism/features/journal/presentation/widgets/journal_entry_card.dart';
import 'package:prism/features/notes/data/note_model.dart';
import 'package:prism/features/notes/data/note_repository.dart';

void main() {
  testWidgets('JournalEntryCard extracts custom title and formats subtitle date/time', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 45,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    const noteContent = '''# 2026-06-03
## Morning Gratitude & Intentions

The morning is crisp and quiet. Grateful for the warm tea.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: dummyNote,
              content: noteContent,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // The card title should be "Morning Gratitude & Intentions" (extracted from ## Morning Gratitude & Intentions)
    expect(find.text('Morning Gratitude & Intentions'), findsOneWidget);

    // The subtitle should be "Wednesday, June 3 • 8:30 AM • 45 words"
    expect(find.textContaining('Wednesday, June 3'), findsOneWidget);
    expect(find.textContaining('8:30 AM'), findsOneWidget);
    expect(find.textContaining('45 words'), findsOneWidget);
  });

  testWidgets('JournalEntryCard renders markdown body and separate checklist section', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 45,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    const contentWithChecklist = '''# 2026-06-03
## My Daily Notes
### Tasks
- [x] Drink 500ml water
- [ ] Go for a run
- [ ] 

Some other journal text here.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: dummyNote,
              content: contentWithChecklist,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify MarkdownBody is rendered (for non-checklist content, e.g. ### Tasks)
    expect(find.byType(MarkdownBody), findsOneWidget);

    final markdownWidget = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    // It should not contain checklist items inside the markdown body preview (so they aren't duplicate)
    expect(markdownWidget.data, contains('### Tasks'));
    expect(markdownWidget.data, contains('Some other journal text here.'));
    expect(markdownWidget.data, isNot(contains('Drink 500ml water')));

    // Verify that separate checklist header is visible
    expect(find.text('DAILY MINDFUL CHECKLIST'), findsOneWidget);
    
    // Verify checklist items are rendered separately
    expect(find.text('Drink 500ml water'), findsOneWidget);
    expect(find.text('Go for a run'), findsOneWidget);
  });

  testWidgets('JournalEntryCard renders image preview when markdown image is present and hides when absent', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 45,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    // 1. With Image
    const contentWithImage = '''# 2026-06-03
Here is a beautiful picture:
![sunset](attachments/image_123.jpg)
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: dummyNote,
              content: contentWithImage,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Image widget is rendered
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<FileImage>());
    final fileImage = imageWidget.image as FileImage;
    expect(fileImage.file.path, contains('attachments/image_123.jpg'));

    // 2. Without Image
    const contentWithoutImage = '''# 2026-06-03
No images here, just plain text.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: dummyNote,
              content: contentWithoutImage,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Image widget should be hidden
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('JournalEntryCard renders network image preview when image path starts with http/https', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 45,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    const contentWithNetworkImage = '''# 2026-06-03
Here is a web image:
![web-sunset](https://example.com/sunset.jpg)
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: dummyNote,
              content: contentWithNetworkImage,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Image widget is rendered
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<NetworkImage>());
    final networkImage = imageWidget.image as NetworkImage;
    expect(networkImage.url, equals('https://example.com/sunset.jpg'));
  });

  testWidgets('JournalEntryCard displays Tap to continue writing only for today\'s card', (WidgetTester tester) async {
    final todayStr = formatDailyDate(DateTime.now());
    final yesterdayStr = formatDailyDate(DateTime.now().subtract(const Duration(days: 1)));

    final todayNote = Note(
      id: 'today-note-id',
      title: todayStr,
      filePath: 'today_path.md',
      wordCount: 15,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDaily: true,
      dailyDate: todayStr,
    );

    final yesterdayNote = Note(
      id: 'yesterday-note-id',
      title: yesterdayStr,
      filePath: 'yesterday_path.md',
      wordCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      isDaily: true,
      dailyDate: yesterdayStr,
    );

    const dummyContent = 'Some daily content...';

    // 1. Render today's note card (should show prompt)
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: todayNote,
              content: dummyContent,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Continue writing'), findsOneWidget);

    // 2. Render yesterday's note card (should NOT show prompt)
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: JournalEntryCard(
              note: yesterdayNote,
              content: dummyContent,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Continue writing'), findsNothing);
  });

  testWidgets('JournalEntryCard does not overflow when markdown body is extremely long', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 1000,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    // Create a very long markdown content with many lines to trigger the overflow
    final longContent = StringBuffer('# 2026-06-03\n');
    for (int i = 0; i < 100; i++) {
      longContent.writeln('This is line $i of the extremely long markdown body preview.');
    }

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: JournalEntryCard(
                  note: dummyNote,
                  content: longContent.toString(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // If it overflows, it will throw an exception and fail.
    expect(tester.takeException(), isNull);
  });

  testWidgets('JournalEntryCard renders hashtags in theme primary color', (WidgetTester tester) async {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 15,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    const contentWithHashtag = '''# 2026-06-03
Writing a entry with a #journaling hashtag.
''';

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return JournalEntryCard(
                  note: dummyNote,
                  content: contentWithHashtag,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify the hashtag #journaling is rendered as a styled widget
    final hashtagFinder = find.text('#journaling');
    expect(hashtagFinder, findsOneWidget);

    final hashtagText = tester.widget<Text>(hashtagFinder);
    expect(hashtagText.style?.color, isNotNull);

    final BuildContext context = tester.element(find.byType(JournalEntryCard));
    final expectedColor = Theme.of(context).colorScheme.primary;
    expect(hashtagText.style?.color, equals(expectedColor));
  });

  group('JournalEntryCard Bento Layout (Option A)', () {
    final noteDate = DateTime(2026, 6, 3, 8, 30);
    final dummyNote = Note(
      id: 'test-note-id',
      title: '2026-06-03',
      filePath: 'test_path.md',
      wordCount: 45,
      createdAt: noteDate,
      updatedAt: noteDate,
      isDaily: true,
      dailyDate: '2026-06-03',
    );

    testWidgets('renders full-width NoteContentCard when checklist and image are empty', (WidgetTester tester) async {
      const content = 'Just plain journal entry text with no checklist and no image.';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('bento_note_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_sidebar')), findsNothing);
    });

    testWidgets('renders side-by-side columns (flex 6 and flex 4) when both checklist and image are present', (WidgetTester tester) async {
      const content = '''# 2026-06-03
Here is the daily entry.
- [ ] Checklist item 1
- [ ] Checklist item 2

![cabin](attachments/cabin.jpg)
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('bento_note_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_sidebar')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_checklist_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_image_card')), findsOneWidget);

      // Verify they are children of a Row
      final rowFinder = find.byWidgetPredicate(
        (widget) => widget is Row && widget.children.any((c) => c is Expanded && (c.child.key == const ValueKey('bento_note_card') || (c.child is Column && (c.child as Column).key == const ValueKey('bento_sidebar'))))
      );
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('renders side-by-side columns when only checklist is present', (WidgetTester tester) async {
      const content = '''# 2026-06-03
Here is the daily entry.
- [ ] Checklist item 1
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('bento_note_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_sidebar')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_checklist_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_image_card')), findsNothing);
    });

    testWidgets('renders side-by-side columns when only image is present', (WidgetTester tester) async {
      const content = '''# 2026-06-03
Here is the daily entry.
![cabin](attachments/cabin.jpg)
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('bento_note_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_sidebar')), findsOneWidget);
      expect(find.byKey(const ValueKey('bento_checklist_card')), findsNothing);
      expect(find.byKey(const ValueKey('bento_image_card')), findsOneWidget);
    });

    testWidgets('parent Row container height is exactly 260px', (WidgetTester tester) async {
      const content = '''# 2026-06-03
Here is the daily entry.
- [ ] Checklist item 1
![cabin](attachments/cabin.jpg)
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final bentoRowFinder = find.byWidgetPredicate(
        (widget) => widget is Row && widget.children.any((c) => c is Expanded && c.child.key == const ValueKey('bento_note_card'))
      );
      expect(bentoRowFinder, findsOneWidget);
      final Size rowSize = tester.getSize(bentoRowFinder);
      expect(rowSize.height, equals(360.0));
    });

    testWidgets('note content card has Expanded body preview to fill height', (WidgetTester tester) async {
      const content = 'Just plain journal entry text with no checklist and no image.';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final noteCardFinder = find.byKey(const ValueKey('bento_note_card'));
      expect(noteCardFinder, findsOneWidget);

      final expandedFinder = find.descendant(
        of: noteCardFinder,
        matching: find.byWidgetPredicate((widget) => widget is Expanded),
      );
      expect(expandedFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('checklist items are scrollable inside bento checklist card', (WidgetTester tester) async {
      const content = '''# 2026-06-03
- [ ] Item 1
- [ ] Item 2
- [ ] Item 3
- [ ] Item 4
- [ ] Item 5
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final checklistCardFinder = find.byKey(const ValueKey('bento_checklist_card'));
      expect(checklistCardFinder, findsOneWidget);

      final scrollFinder = find.descendant(
        of: checklistCardFinder,
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollFinder, findsOneWidget);
    });

    testWidgets('tapping checklist item triggers saveNote with updated markdown content', (WidgetTester tester) async {
      String? savedId;
      String? savedContent;

      final mockRepo = MockJournalNoteRepository(
        onSaveNote: (id, content) {
          savedId = id;
          savedContent = content;
        },
      );

      const content = '''# 2026-06-03
Here is the daily entry.
- [ ] Checklist item 1
- [x] Checklist item 2
''';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final itemFinder = find.text('Checklist item 1');
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pump();

      expect(savedId, equals(dummyNote.id));
      expect(savedContent, contains('- [x] Checklist item 1'));
      expect(savedContent, contains('- [x] Checklist item 2'));
    });

    testWidgets('collapses empty lines and skips empty headings in note body preview', (WidgetTester tester) async {
      const content = '''# 2026-06-03
## Today's Focus
Focusing on coding this project.

## Daily Habits
- [ ] Exercise
- [ ] Meditate

## Gratitude
I am grateful for food.
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final markdownWidget = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
      final data = markdownWidget.data;

      // Should not contain the empty heading
      expect(data, isNot(contains('## Daily Habits')));
      // Should not contain the title heading (since it is skipped/used as card title)
      expect(data, isNot(contains("## Today's Focus")));
      // Should contain the other content
      expect(data, contains('Focusing on coding this project.'));
      expect(data, contains('## Gratitude'));
      expect(data, contains('I am grateful for food.'));
      // Should not have multiple consecutive empty lines/spaces
      expect(data, isNot(contains('&nbsp;\n&nbsp;')));
    });

    testWidgets('long checklist items are truncated to 2 lines with ellipsis', (WidgetTester tester) async {
      const content = '''# 2026-06-03
- [ ] This is an extremely long checklist item label that goes on and on and should be truncated to prevent the narrow sidebar layout from looking weird.
''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JournalEntryCard(
                note: dummyNote,
                content: content,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final textFinder = find.textContaining('extremely long checklist item');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });
}

class FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockJournalNoteRepository extends NoteRepository {
  final void Function(String id, String content)? onSaveNote;
  MockJournalNoteRepository({this.onSaveNote}) : super(FakeRef());

  @override
  Future<void> saveNote(String id, String content) async {
    onSaveNote?.call(id, content);
  }
}

