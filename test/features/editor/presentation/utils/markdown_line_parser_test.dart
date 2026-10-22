import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/presentation/utils/markdown_line_parser.dart';

void main() {
  group('MarkdownLineParser Tests', () {
    test('should parse heading correctly with syntax characters marked', () {
      final text = '### Heading Three';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 1);
      final line = result[0];
      expect(line.type, MarkdownLineType.heading);
      expect(line.headingLevel, 3);
      expect(line.rawText, text);

      // Spans: '###' (syntax), ' ' (plain), 'Heading Three' (plain)
      expect(line.inlineSpans.length, 3);
      expect(line.inlineSpans[0].text, '###');
      expect(line.inlineSpans[0].isSyntaxChar, isTrue);
      expect(line.inlineSpans[0].type, InlineType.plain);

      expect(line.inlineSpans[1].text, ' ');
      expect(line.inlineSpans[1].isSyntaxChar, isFalse);

      expect(line.inlineSpans[2].text, 'Heading Three');
      expect(line.inlineSpans[2].isSyntaxChar, isFalse);
      expect(line.inlineSpans[2].type, InlineType.plain);
    });

    test('should parse bold, italic and highlights inline styles', () {
      final text = 'This is **bold** and *italic* and ==highlight==';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 1);
      final line = result[0];
      expect(line.type, MarkdownLineType.paragraph);

      // Verify bold spans
      final boldSpans = line.inlineSpans.where((s) => s.type == InlineType.bold).toList();
      expect(boldSpans.length, 1);
      expect(boldSpans[0].text, 'bold');

      // Verify syntax chars around bold
      final boldSyntax = line.inlineSpans.where((s) => s.isSyntaxChar && s.text == '**').toList();
      expect(boldSyntax.length, 2);

      // Verify italic spans
      final italicSpans = line.inlineSpans.where((s) => s.type == InlineType.italic).toList();
      expect(italicSpans.length, 1);
      expect(italicSpans[0].text, 'italic');

      // Verify highlight spans
      final highlightSpans = line.inlineSpans.where((s) => s.type == InlineType.highlight).toList();
      expect(highlightSpans.length, 1);
      expect(highlightSpans[0].text, 'highlight');
      expect(line.inlineSpans.any((s) => s.isSyntaxChar && s.text == '=='), isTrue);
    });

    test('should parse hashtags and ignore them inside inline code', () {
      final text = 'Hello #world and `#notatag`';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 1);
      final line = result[0];

      // Has hashtag #world
      final hashtagSpans = line.inlineSpans.where((s) => s.type == InlineType.hashtag).toList();
      expect(hashtagSpans.length, 1);
      expect(hashtagSpans[0].text, '#world');

      // Has inline code `#notatag`
      final codeSpans = line.inlineSpans.where((s) => s.type == InlineType.code).toList();
      expect(codeSpans.length, 1);
      expect(codeSpans[0].text, '#notatag');

      // No hashtag for #notatag
      expect(line.inlineSpans.any((s) => s.type == InlineType.hashtag && s.text == '#notatag'), isFalse);
    });

    test('should parse fenced code blocks correctly', () {
      final text = '```\n#notatag\n```';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 3);
      expect(result[0].type, MarkdownLineType.codeFenceStart);
      expect(result[1].type, MarkdownLineType.codeContent);
      expect(result[2].type, MarkdownLineType.codeFenceEnd);

      // The line inside code block should NOT have hashtag spans
      expect(result[1].inlineSpans.length, 1);
      expect(result[1].inlineSpans[0].text, '#notatag');
      expect(result[1].inlineSpans[0].type, InlineType.plain);
    });

    test('should parse checklists and bullets', () {
      final text = '- [ ] Todo item\n* Bullet item';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 2);
      expect(result[0].type, MarkdownLineType.checklist);
      expect(result[1].type, MarkdownLineType.bullet);

      // Checklist: syntax '- [ ]'
      final checkboxSyntax = result[0].inlineSpans.firstWhere((s) => s.isSyntaxChar);
      expect(checkboxSyntax.text, '- [ ]');

      // Bullet: syntax '*'
      final bulletSyntax = result[1].inlineSpans.firstWhere((s) => s.isSyntaxChar);
      expect(bulletSyntax.text, '*');
    });

    test('should parse wikilinks and standard links', () {
      final text = 'Read [[Productivity Guide]] or [Google](https://google.com)';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 1);
      final line = result[0];

      // Wikilink
      final wikilink = line.inlineSpans.firstWhere((s) => s.type == InlineType.wikilink);
      expect(wikilink.text, 'Productivity Guide');
      expect(wikilink.url, 'Productivity Guide');

      // Standard link
      final link = line.inlineSpans.firstWhere((s) => s.type == InlineType.link);
      expect(link.text, 'Google');
      expect(link.url, 'https://google.com');
    });

    test('should parse timestamp tags [04:12 - Bookmark] and [00:05]', () {
      final text = 'Note bookmark at [04:12 - Bookmark] and also [00:05] intro';
      final result = MarkdownLineParser.parse(text);

      expect(result.length, 1);
      final line = result[0];
      final timestamps = line.inlineSpans.where((s) => s.type == InlineType.timestamp).toList();

      expect(timestamps.length, 2);
      expect(timestamps[0].text, '[04:12 - Bookmark]');
      expect(timestamps[1].text, '[00:05]');
    });
  });
}
