import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:meridian/core/utils/utils.dart';
import 'package:meridian/features/journal/presentation/widgets/journal_entry_card.dart';
import 'package:meridian/features/notes/data/note_model.dart';

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
    expect(find.text('Tap to continue writing'), findsOneWidget);

    // 2. Render yesterday's note card (should NOT show prompt)
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
    expect(find.text('Tap to continue writing'), findsNothing);
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
}
