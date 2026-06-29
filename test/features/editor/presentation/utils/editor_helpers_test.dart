import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/editor/presentation/utils/editor_helpers.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:prism/core/utils/utils.dart';
import 'package:markdown/markdown.dart' as md;

class TestImageWidget extends ConsumerWidget {
  final Uri uri;
  final String noteId;

  const TestImageWidget({super.key, required this.uri, required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetResult = buildMarkdownImage(
      uri: uri,
      noteId: noteId,
      ref: ref,
      context: context,
    );
    return MaterialApp(
      home: Scaffold(
        body: widgetResult,
      ),
    );
  }
}

void main() {
  group('buildMarkdownImage', () {
    testWidgets('should render a Card with Image.network for remote network images', (WidgetTester tester) async {
      final uri = Uri.parse('https://example.com/image.png');
      await tester.pumpWidget(
        ProviderScope(
          child: TestImageWidget(uri: uri, noteId: 'note-id'),
        ),
      );

      // Should not be empty/SizedBox.shrink
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Hashtag Rendering', () {
    Widget buildMarkdown(String data) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MarkdownBody(
                  data: preprocessMarkdown(data),
                  softLineBreak: true,
                  inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
                  builders: {
                    'mark': HighlightElementBuilder(context),
                    'hashtag': HashtagElementBuilder(context),
                  },
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets('should render hashtag pill for normal hashtag', (WidgetTester tester) async {
      await tester.pumpWidget(buildMarkdown('This is a #tag in text'));
      await tester.pumpAndSettle();

      // Should find the HashtagPill widget
      expect(find.byType(HashtagPill), findsOneWidget);
      expect(find.text('#tag'), findsOneWidget);
    });

    testWidgets('should NOT render hashtag pill inside inline code', (WidgetTester tester) async {
      await tester.pumpWidget(buildMarkdown('This is inline code `#notatag`'));
      await tester.pumpAndSettle();

      // Use a finder that can find text inside RichText/TextSpan
      final richTextFinder = find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains('#notatag'));
      expect(richTextFinder, findsOneWidget);

      // The HashtagPill widget should NOT be rendered
      expect(find.byType(HashtagPill), findsNothing);
    });

    testWidgets('should NOT render hashtag pill inside code blocks', (WidgetTester tester) async {
      await tester.pumpWidget(buildMarkdown('```\n#notatag\n```'));
      await tester.pumpAndSettle();

      final richTextFinder = find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains('#notatag'));
      expect(richTextFinder, findsOneWidget);

      expect(find.byType(HashtagPill), findsNothing);
    });

    testWidgets('should render hashtag pill at the start of a line without treating as heading or using zero-width space', (WidgetTester tester) async {
      await tester.pumpWidget(buildMarkdown('#tag\nSome text'));
      await tester.pumpAndSettle();

      expect(find.byType(HashtagPill), findsOneWidget);
      expect(find.text('#tag'), findsOneWidget);
    });

    testWidgets('should render hashtag pill after a newline without zero-width space prefix', (WidgetTester tester) async {
      await tester.pumpWidget(buildMarkdown('Some text\n#tag'));
      await tester.pumpAndSettle();

      expect(find.byType(HashtagPill), findsOneWidget);
      expect(find.text('#tag'), findsOneWidget);

      // Verify that no zero-width space (\u200B) is present in the rendered RichText
      final zeroWidthFinder = find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains('\u200B'));
      expect(zeroWidthFinder, findsNothing);
    });

    testWidgets('should preserve newlines when hashtag is rendered on its own line', (WidgetTester tester) async {
      // Input markdown with single newlines
      await tester.pumpWidget(buildMarkdown('Hey dude\n#tag\nwhatsapp\nhello'));
      await tester.pumpAndSettle();

      // Find the text elements
      final heyDudeFinder = find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains('Hey dude'));
      final tagFinder = find.byType(HashtagPill);
      final whatsappFinder = find.byWidgetPredicate((widget) =>
          widget is RichText && widget.text.toPlainText().contains('whatsapp'));

      expect(heyDudeFinder, findsOneWidget);
      expect(tagFinder, findsOneWidget);
      expect(whatsappFinder, findsOneWidget);

      final heyDudeY = tester.getTopLeft(heyDudeFinder).dy;
      final tagY = tester.getTopLeft(tagFinder).dy;
      final whatsappY = tester.getTopLeft(whatsappFinder).dy;

      expect(heyDudeY < tagY, isTrue, reason: 'Hey dude ($heyDudeY) should be above #tag ($tagY)');
      expect(tagY < whatsappY, isTrue, reason: '#tag ($tagY) should be above whatsapp ($whatsappY)');
    });
  });
}

