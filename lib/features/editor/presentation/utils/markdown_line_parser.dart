enum MarkdownLineType {
  heading,
  bullet,
  checklist,
  blockquote,
  codeFenceStart,
  codeFenceEnd,
  codeContent,
  tableRow,
  tableSeparator,
  horizontalRule,
  image,
  audioLink,
  paragraph,
  empty
}

enum InlineType {
  plain,
  bold,
  italic,
  strikethrough,
  code,
  highlight,
  hashtag,
  wikilink,
  link
}

class InlineSpanInfo {
  final String text;
  final String? url;
  final InlineType type;
  final bool isSyntaxChar;

  InlineSpanInfo({
    required this.text,
    required this.type,
    this.url,
    this.isSyntaxChar = false,
  });

  @override
  String toString() => 'InlineSpanInfo(text: "$text", type: $type, isSyntax: $isSyntaxChar)';
}

class ParsedLine {
  final int lineIndex;
  final String rawText;
  final MarkdownLineType type;
  final int headingLevel;
  final List<InlineSpanInfo> inlineSpans;

  ParsedLine({
    required this.lineIndex,
    required this.rawText,
    required this.type,
    this.headingLevel = 0,
    required this.inlineSpans,
  });

  @override
  String toString() => 'ParsedLine(index: $lineIndex, type: $type, spans: ${inlineSpans.length})';
}

class MarkdownLineParser {
  static final RegExp _headingRegex = RegExp(r'^(#{1,6})(\s+)(.*)$');
  static final RegExp checklistRegex = RegExp(r'^(\s*[-*+]\s+\[)([ xX])(\])(\s+)(.*)$');
  static final RegExp _bulletRegex = RegExp(r'^(\s*[-*+])(\s+)(.*)$');
  static final RegExp _blockquoteRegex = RegExp(r'^(\s*>\s*)(.*)$');
  static final RegExp _hrRegex = RegExp(r'^\s*([-*_])\1\1+\s*$');
  static final RegExp audioRegex = RegExp(r'^\[([^\]]*)\]\((attachments/[^)]+\.(?:m4a|mp3|wav|aac|ogg))\)$', caseSensitive: false);
  static final RegExp imageRegex = RegExp(r'^!\[([^\]]*)\]\(([^)]+)\)$');
  static final RegExp _tableRowRegex = RegExp(r'^\s*\|.*\|\s*$');
  static final RegExp _tableSepRegex = RegExp(r'^\s*\|(?:\s*:?-+:?\s*\|)+\s*$');

  static final RegExp _inlineRegex = RegExp(
    r'(`[^`]+`)' // 1. Inline code
    r'|(\*\*[^*]+\*\*)' // 2. Bold **
    r'|(__[^_]+__)' // 3. Bold __
    r'|(\*[^*]+\*)' // 4. Italic *
    r'|(_[^_]+_)' // 5. Italic _
    r'|(~~[^~]+~~)' // 6. Strikethrough
    r'|(==[^=]+==)' // 7. Highlight
    r'|(\[\[[^\]]+\]\])' // 8. Wikilink
    r'|(\[[^\]]+\]\([^)]+\))' // 9. Link
    r'|((?<!\w)#[a-zA-Z][a-zA-Z0-9_]*)' // 10. Hashtag
  );

  static List<ParsedLine> parse(String text) {
    final lines = text.split('\n');
    final result = <ParsedLine>[];
    bool isInCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Handle Code Blocks
      if (trimmed.startsWith('```')) {
        if (isInCodeBlock) {
          isInCodeBlock = false;
          result.add(ParsedLine(
            lineIndex: i,
            rawText: line,
            type: MarkdownLineType.codeFenceEnd,
            inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain, isSyntaxChar: true)],
          ));
        } else {
          isInCodeBlock = true;
          result.add(ParsedLine(
            lineIndex: i,
            rawText: line,
            type: MarkdownLineType.codeFenceStart,
            inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain, isSyntaxChar: true)],
          ));
        }
        continue;
      }

      if (isInCodeBlock) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.codeContent,
          inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain)],
        ));
        continue;
      }

      // Empty Line
      if (line.isEmpty) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.empty,
          inlineSpans: [],
        ));
        continue;
      }

      // Horizontal Rule
      if (_hrRegex.hasMatch(line)) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.horizontalRule,
          inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain, isSyntaxChar: true)],
        ));
        continue;
      }

      // Audio Link
      final audioMatch = audioRegex.firstMatch(trimmed);
      if (audioMatch != null) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.audioLink,
          inlineSpans: [
            InlineSpanInfo(text: '[', type: InlineType.plain, isSyntaxChar: true),
            InlineSpanInfo(text: audioMatch.group(1)!, type: InlineType.plain),
            InlineSpanInfo(text: ']', type: InlineType.plain, isSyntaxChar: true),
            InlineSpanInfo(text: '(${audioMatch.group(2)!})', type: InlineType.plain, isSyntaxChar: true),
          ],
        ));
        continue;
      }

      // Image Link
      final imageMatch = imageRegex.firstMatch(trimmed);
      if (imageMatch != null) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.image,
          inlineSpans: [
            InlineSpanInfo(text: '![', type: InlineType.plain, isSyntaxChar: true),
            InlineSpanInfo(text: imageMatch.group(1)!, type: InlineType.plain),
            InlineSpanInfo(text: ']', type: InlineType.plain, isSyntaxChar: true),
            InlineSpanInfo(text: '(${imageMatch.group(2)!})', type: InlineType.plain, isSyntaxChar: true),
          ],
        ));
        continue;
      }

      // Table Separator
      if (_tableSepRegex.hasMatch(line)) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.tableSeparator,
          inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain)],
        ));
        continue;
      }

      // Table Row
      if (_tableRowRegex.hasMatch(line)) {
        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.tableRow,
          inlineSpans: [InlineSpanInfo(text: line, type: InlineType.plain)],
        ));
        continue;
      }

      // Heading
      final headingMatch = _headingRegex.firstMatch(line);
      if (headingMatch != null) {
        final hashes = headingMatch.group(1)!;
        final spaces = headingMatch.group(2)!;
        final headingText = headingMatch.group(3)!;

        final spans = <InlineSpanInfo>[
          InlineSpanInfo(text: hashes, type: InlineType.plain, isSyntaxChar: true),
          InlineSpanInfo(text: spaces, type: InlineType.plain),
          ..._parseInline(headingText),
        ];

        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.heading,
          headingLevel: hashes.length,
          inlineSpans: spans,
        ));
        continue;
      }

      // Checklist
      final checklistMatch = checklistRegex.firstMatch(line);
      if (checklistMatch != null) {
        final prefix = checklistMatch.group(1)!;
        final status = checklistMatch.group(2)!;
        final suffixBracket = checklistMatch.group(3)!;
        final spaceAfter = checklistMatch.group(4)!;
        final taskText = checklistMatch.group(5)!;

        final spans = <InlineSpanInfo>[
          InlineSpanInfo(text: '$prefix$status$suffixBracket', type: InlineType.plain, isSyntaxChar: true),
          InlineSpanInfo(text: spaceAfter, type: InlineType.plain),
          ..._parseInline(taskText),
        ];

        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.checklist,
          inlineSpans: spans,
        ));
        continue;
      }

      // Bullet List
      final bulletMatch = _bulletRegex.firstMatch(line);
      if (bulletMatch != null) {
        final symbol = bulletMatch.group(1)!;
        final spaces = bulletMatch.group(2)!;
        final bulletText = bulletMatch.group(3)!;

        final spans = <InlineSpanInfo>[
          InlineSpanInfo(text: symbol, type: InlineType.plain, isSyntaxChar: true),
          InlineSpanInfo(text: spaces, type: InlineType.plain),
          ..._parseInline(bulletText),
        ];

        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.bullet,
          inlineSpans: spans,
        ));
        continue;
      }

      // Blockquote
      final blockquoteMatch = _blockquoteRegex.firstMatch(line);
      if (blockquoteMatch != null) {
        final prefix = blockquoteMatch.group(1)!;
        final quoteText = blockquoteMatch.group(2)!;

        final spans = <InlineSpanInfo>[
          InlineSpanInfo(text: prefix, type: InlineType.plain, isSyntaxChar: true),
          ..._parseInline(quoteText),
        ];

        result.add(ParsedLine(
          lineIndex: i,
          rawText: line,
          type: MarkdownLineType.blockquote,
          inlineSpans: spans,
        ));
        continue;
      }

      // Standard Paragraph
      result.add(ParsedLine(
        lineIndex: i,
        rawText: line,
        type: MarkdownLineType.paragraph,
        inlineSpans: _parseInline(line),
      ));
    }

    return result;
  }

  static List<InlineSpanInfo> _parseInline(String text) {
    final spans = <InlineSpanInfo>[];
    int lastIndex = 0;

    for (final match in _inlineRegex.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastIndex) {
        spans.add(InlineSpanInfo(
          text: text.substring(lastIndex, match.start),
          type: InlineType.plain,
        ));
      }

      final matchText = match.group(0)!;

      if (match.group(1) != null) {
        // Inline code: `code`
        spans.add(InlineSpanInfo(text: '`', type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: matchText.substring(1, matchText.length - 1), type: InlineType.code));
        spans.add(InlineSpanInfo(text: '`', type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(2) != null || match.group(3) != null) {
        // Bold: **bold** or __bold__
        final syntax = matchText.substring(0, 2);
        spans.add(InlineSpanInfo(text: syntax, type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: matchText.substring(2, matchText.length - 2), type: InlineType.bold));
        spans.add(InlineSpanInfo(text: syntax, type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(4) != null || match.group(5) != null) {
        // Italic: *italic* or _italic_
        final syntax = matchText.substring(0, 1);
        spans.add(InlineSpanInfo(text: syntax, type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: matchText.substring(1, matchText.length - 1), type: InlineType.italic));
        spans.add(InlineSpanInfo(text: syntax, type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(6) != null) {
        // Strikethrough: ~~strikethrough~~
        spans.add(InlineSpanInfo(text: '~~', type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: matchText.substring(2, matchText.length - 2), type: InlineType.strikethrough));
        spans.add(InlineSpanInfo(text: '~~', type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(7) != null) {
        // Highlight: ==highlight==
        spans.add(InlineSpanInfo(text: '==', type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: matchText.substring(2, matchText.length - 2), type: InlineType.highlight));
        spans.add(InlineSpanInfo(text: '==', type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(8) != null) {
        // Wikilink: [[target]]
        spans.add(InlineSpanInfo(text: '[[', type: InlineType.plain, isSyntaxChar: true));
        final target = matchText.substring(2, matchText.length - 2);
        spans.add(InlineSpanInfo(text: target, type: InlineType.wikilink, url: target));
        spans.add(InlineSpanInfo(text: ']]', type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(9) != null) {
        // Standard link: [text](url)
        final openBracket = matchText.indexOf('[');
        final closeBracket = matchText.indexOf(']');
        final openParen = matchText.indexOf('(');
        final closeParen = matchText.indexOf(')');

        final linkText = matchText.substring(openBracket + 1, closeBracket);
        final linkUrl = matchText.substring(openParen + 1, closeParen);

        spans.add(InlineSpanInfo(text: '[', type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: linkText, type: InlineType.link, url: linkUrl));
        spans.add(InlineSpanInfo(text: ']', type: InlineType.plain, isSyntaxChar: true));
        spans.add(InlineSpanInfo(text: '($linkUrl)', type: InlineType.plain, isSyntaxChar: true));
      } else if (match.group(10) != null) {
        // Hashtag: #tag
        spans.add(InlineSpanInfo(text: matchText, type: InlineType.hashtag));
      }

      lastIndex = match.end;
    }

    // Add remaining plain text
    if (lastIndex < text.length) {
      spans.add(InlineSpanInfo(
        text: text.substring(lastIndex),
        type: InlineType.plain,
      ));
    }

    return spans;
  }
}
