import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import '../providers/editor_controller.dart';
import '../utils/markdown_line_parser.dart';

class _LineSpanCacheKey {
  final String lineText;
  final MarkdownLineType lineType;
  final bool isCursorOnLine;
  final bool isInActiveTable;
  final bool isInActiveCodeBlock;
  final bool isSourceMode;
  final bool isLastLine;
  final int styleHashCode;
  final int lineIndex;

  const _LineSpanCacheKey({
    required this.lineText,
    required this.lineType,
    required this.isCursorOnLine,
    required this.isInActiveTable,
    required this.isInActiveCodeBlock,
    required this.isSourceMode,
    required this.isLastLine,
    required this.styleHashCode,
    required this.lineIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LineSpanCacheKey &&
          runtimeType == other.runtimeType &&
          lineText == other.lineText &&
          lineType == other.lineType &&
          isCursorOnLine == other.isCursorOnLine &&
          isInActiveTable == other.isInActiveTable &&
          isInActiveCodeBlock == other.isInActiveCodeBlock &&
          isSourceMode == other.isSourceMode &&
          isLastLine == other.isLastLine &&
          styleHashCode == other.styleHashCode &&
          lineIndex == other.lineIndex;

  @override
  int get hashCode => Object.hash(
        lineText,
        lineType,
        isCursorOnLine,
        isInActiveTable,
        isInActiveCodeBlock,
        isSourceMode,
        isLastLine,
        styleHashCode,
        lineIndex,
      );
}

class LivePreviewController extends TextEditingController {
  final String noteId;
  EditorMode mode;

  // Builder callbacks for block elements
  final Widget Function(String path, String? label)? audioPlayerBuilder;
  final Widget Function(String path, String? alt)? imageBuilder;
  final Widget Function(List<String> tableLines)? tableBuilder;
  final Widget Function(int lineIndex, bool checked)? checkboxBuilder;
  final void Function(Duration position)? onTimestampTap;

  final Map<_LineSpanCacheKey, InlineSpan> _lineSpanCache = {};
  static const int _maxLineSpanCacheSize = 5000;

  void clearSpanCache() {
    _lineSpanCache.clear();
  }

  int get spanCacheSize => _lineSpanCache.length;

  @override
  void dispose() {
    _lineSpanCache.clear();
    super.dispose();
  }

  LivePreviewController({
    required this.noteId,
    this.mode = EditorMode.livePreview,
    this.audioPlayerBuilder,
    this.imageBuilder,
    this.tableBuilder,
    this.checkboxBuilder,
    this.onTimestampTap,
    super.text,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final defaultStyle = style ?? TextStyle(
      color: DesignColors.text(context),
      fontSize: 15,
    );

    final textVal = text;
    if (textVal.isEmpty) {
      return TextSpan(style: defaultStyle);
    }

    final parsedLines = MarkdownLineParser.parse(textVal);
    final lineSpans = <InlineSpan>[];

    // Find the cursor line index
    final cursorPosition = selection.baseOffset;
    int cursorLineIndex = -1;
    if (cursorPosition >= 0) {
      int currentOffset = 0;
      for (int i = 0; i < parsedLines.length; i++) {
        final lineLength = parsedLines[i].rawText.length;
        if (cursorPosition >= currentOffset && cursorPosition <= currentOffset + lineLength) {
          cursorLineIndex = i;
          break;
        }
        currentOffset += lineLength + 1; // +1 for the newline character
      }
    }

    // Pre-identify table blocks and code blocks
    final tableBlocks = _identifyTableBlocks(parsedLines);
    final codeBlocks = _identifyCodeBlocks(parsedLines);

    // Pre-calculate active table and code blocks containing the cursor (O(B) once)
    final activeTableBlock = cursorLineIndex >= 0
        ? tableBlocks.where((b) => b.contains(cursorLineIndex)).firstOrNull
        : null;
    final activeCodeBlock = cursorLineIndex >= 0
        ? codeBlocks.where((b) => b.contains(cursorLineIndex)).firstOrNull
        : null;

    // Fast O(1) index mappings for table and code blocks
    final lineToTableBlock = <int, List<int>>{};
    for (final block in tableBlocks) {
      for (final idx in block) {
        lineToTableBlock[idx] = block;
      }
    }

    final lineToCodeBlock = <int, List<int>>{};
    for (final block in codeBlocks) {
      for (final idx in block) {
        lineToCodeBlock[idx] = block;
      }
    }

    final styleHashCode = Object.hash(
      defaultStyle.color,
      defaultStyle.fontSize,
      defaultStyle.fontFamily,
      Theme.of(context).brightness,
    );

    for (int i = 0; i < parsedLines.length; i++) {
      final line = parsedLines[i];

      // O(1) range comparison against pre-calculated active blocks
      final isInActiveTable = activeTableBlock != null &&
          i >= activeTableBlock.first &&
          i <= activeTableBlock.last;
      final isInActiveCodeBlock = activeCodeBlock != null &&
          i >= activeCodeBlock.first &&
          i <= activeCodeBlock.last;

      final isCursorLine = i == cursorLineIndex;
      final isSourceMode = mode == EditorMode.source;

      // A line is rendered raw if:
      // 1. We are in Source Mode
      // 2. It is the cursor line
      // 3. It belongs to a table that the cursor is currently in
      // 4. It belongs to a code block that the cursor is currently in
      final isRawLine = isSourceMode ||
          (mode == EditorMode.livePreview && (isCursorLine || isInActiveTable || isInActiveCodeBlock));

      // Handle table rendering (non-active table)
      final tableBlock = lineToTableBlock[i] ?? const [];
      if (tableBlock.isNotEmpty && !isRawLine) {
        // If this is the first line of the table, render the entire table widget
        if (tableBlock.first == i) {
          final tableLines = tableBlock.map((idx) => parsedLines[idx].rawText).toList();
          if (tableBuilder != null) {
            lineSpans.add(WidgetSpan(
              child: tableBuilder!(tableLines),
              alignment: PlaceholderAlignment.middle,
            ));
            // Add newline after the table
            if (tableBlock.last < parsedLines.length - 1) {
              lineSpans.add(TextSpan(text: '\n', style: defaultStyle));
            }
          }
        }
        // Skip rendering individual lines of the table (they are drawn by the table widget)
        continue;
      }

      // Handle code block fence rendering (non-active code block)
      final codeBlock = lineToCodeBlock[i] ?? const [];
      if (codeBlock.isNotEmpty && !isRawLine) {
        // Hide the opening and closing fence lines
        if (line.type == MarkdownLineType.codeFenceStart || line.type == MarkdownLineType.codeFenceEnd) {
          continue;
        }
      }

      // Handle Block-level elements (Audio, Image) on non-cursor lines
      if (!isRawLine) {
        if (line.type == MarkdownLineType.audioLink && audioPlayerBuilder != null) {
          final audioMatch = MarkdownLineParser.audioRegex.firstMatch(line.rawText.trim());
          if (audioMatch != null) {
            lineSpans.add(WidgetSpan(
              child: Padding(
                key: ValueKey('audio_${audioMatch.group(2)}'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: audioPlayerBuilder!(audioMatch.group(2)!, audioMatch.group(1)),
              ),
              alignment: PlaceholderAlignment.middle,
            ));
            if (i < parsedLines.length - 1) {
              lineSpans.add(TextSpan(text: '\n', style: defaultStyle));
            }
            continue;
          }
        }

        if (line.type == MarkdownLineType.image && imageBuilder != null) {
          final imageMatch = MarkdownLineParser.imageRegex.firstMatch(line.rawText.trim());
          if (imageMatch != null) {
            lineSpans.add(WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: imageBuilder!(imageMatch.group(2)!, imageMatch.group(1)),
              ),
              alignment: PlaceholderAlignment.middle,
            ));
            if (i < parsedLines.length - 1) {
              lineSpans.add(TextSpan(text: '\n', style: defaultStyle));
            }
            continue;
          }
        }

        if (line.type == MarkdownLineType.horizontalRule) {
          lineSpans.add(WidgetSpan(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: DesignColors.border(context),
            ),
            alignment: PlaceholderAlignment.middle,
          ));
          if (i < parsedLines.length - 1) {
            lineSpans.add(TextSpan(text: '\n', style: defaultStyle));
          }
          continue;
        }
      }

      final isLastLine = i == parsedLines.length - 1;
      final cacheKey = _LineSpanCacheKey(
        lineText: line.rawText,
        lineType: line.type,
        isCursorOnLine: isCursorLine,
        isInActiveTable: isInActiveTable,
        isInActiveCodeBlock: isInActiveCodeBlock,
        isSourceMode: isSourceMode,
        isLastLine: isLastLine,
        styleHashCode: styleHashCode,
        lineIndex: line.lineIndex,
      );

      final cachedSpan = _lineSpanCache.remove(cacheKey);
      if (cachedSpan != null) {
        _lineSpanCache[cacheKey] = cachedSpan;
        lineSpans.add(cachedSpan);
        continue;
      }

      final spansOnLine = <InlineSpan>[];

      // Render inline checklist checkbox on non-cursor lines
      if (line.type == MarkdownLineType.checklist && !isRawLine && checkboxBuilder != null) {
        final checklistMatch = MarkdownLineParser.checklistRegex.firstMatch(line.rawText);
        if (checklistMatch != null) {
          final status = checklistMatch.group(2)!;
          final isChecked = status.toLowerCase() == 'x';
          spansOnLine.add(WidgetSpan(
            child: checkboxBuilder!(line.lineIndex, isChecked),
            alignment: PlaceholderAlignment.middle,
          ));
        }
      }

      bool seenHeadingText = false;
      for (final spanInfo in line.inlineSpans) {
        // Skip rendering the raw checklist syntax characters `- [ ]` on non-cursor lines
        if (line.type == MarkdownLineType.checklist && !isRawLine && spanInfo.isSyntaxChar && spanInfo.text.startsWith('- [')) {
          continue;
        }

        // On non-cursor heading lines, completely omit syntax characters and any leading whitespace spans before heading text
        if (line.type == MarkdownLineType.heading && !isRawLine) {
          if (spanInfo.isSyntaxChar) {
            continue;
          }
          if (!seenHeadingText && spanInfo.text.trim().isEmpty) {
            continue;
          }
          seenHeadingText = true;
        }

        TextStyle spanStyle;

        if (isRawLine) {
          // Raw rendering (cursor line or source mode)
          if (spanInfo.isSyntaxChar) {
            spanStyle = defaultStyle.copyWith(
              color: DesignColors.textTertiary(context),
            );
          } else {
            spanStyle = _getInlineStyle(spanInfo.type, defaultStyle, context);
          }
        } else {
          // Rich rendering (non-cursor line in live preview)
          if (spanInfo.isSyntaxChar) {
            spanStyle = defaultStyle.copyWith(
              fontSize: 0,
              color: Colors.transparent,
            );
          } else {
            spanStyle = _getInlineStyle(spanInfo.type, defaultStyle, context);
          }
        }

        // Apply heading styles if it's a heading line
        if (line.type == MarkdownLineType.heading) {
          final headingStyle = _getHeadingStyle(line.headingLevel, defaultStyle, context);
          if (spanInfo.isSyntaxChar && isRawLine) {
            spanStyle = spanStyle.copyWith(
              fontSize: headingStyle.fontSize,
              fontWeight: headingStyle.fontWeight,
            );
          } else if (!spanInfo.isSyntaxChar) {
            spanStyle = spanStyle.copyWith(
              fontSize: headingStyle.fontSize,
              fontWeight: headingStyle.fontWeight,
              color: headingStyle.color,
            );
          }
        }

        // Handle blockquote styling
        if (line.type == MarkdownLineType.blockquote) {
          if (spanInfo.isSyntaxChar) {
            if (isRawLine) {
              spanStyle = spanStyle.copyWith(color: DesignColors.textTertiary(context));
            } else {
              spanStyle = spanStyle.copyWith(fontSize: 0, color: Colors.transparent);
            }
          } else {
            spanStyle = spanStyle.copyWith(
              color: DesignColors.textSecondary(context),
              fontStyle: FontStyle.italic,
            );
          }
        }

        // Handle code content styling
        if (line.type == MarkdownLineType.codeContent) {
          spanStyle = GoogleFonts.robotoMono(
            textStyle: spanStyle.copyWith(
              fontSize: (defaultStyle.fontSize ?? 15) * 0.9,
              color: DesignColors.accentGreen(context),
            ),
          );
        }

        GestureRecognizer? recognizer;
        if (spanInfo.type == InlineType.timestamp && onTimestampTap != null && !isRawLine) {
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(spanInfo.text);
          if (timeMatch != null) {
            final mins = int.parse(timeMatch.group(1)!);
            final secs = int.parse(timeMatch.group(2)!);
            final pos = Duration(minutes: mins, seconds: secs);
            recognizer = TapGestureRecognizer()..onTap = () => onTimestampTap!(pos);
          }
        }

        spansOnLine.add(TextSpan(
          text: spanInfo.text,
          style: spanStyle,
          recognizer: recognizer,
        ));
      }

      // Add a newline after each line except the last one
      if (i < parsedLines.length - 1) {
        spansOnLine.add(TextSpan(text: '\n', style: defaultStyle));
      }

      final builtLineSpan = TextSpan(children: spansOnLine);
      if (_lineSpanCache.length >= _maxLineSpanCacheSize) {
        _lineSpanCache.remove(_lineSpanCache.keys.first);
      }
      _lineSpanCache[cacheKey] = builtLineSpan;
      lineSpans.add(builtLineSpan);
    }

    return TextSpan(children: lineSpans, style: defaultStyle);
  }

  List<List<int>> _identifyTableBlocks(List<ParsedLine> lines) {
    final blocks = <List<int>>[];
    var currentBlock = <int>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.type == MarkdownLineType.tableRow || line.type == MarkdownLineType.tableSeparator) {
        currentBlock.add(i);
      } else {
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock);
          currentBlock = [];
        }
      }
    }
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock);
    }
    return blocks;
  }

  List<List<int>> _identifyCodeBlocks(List<ParsedLine> lines) {
    final blocks = <List<int>>[];
    var currentBlock = <int>[];
    bool inBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.type == MarkdownLineType.codeFenceStart) {
        inBlock = true;
        currentBlock.add(i);
      } else if (line.type == MarkdownLineType.codeFenceEnd) {
        currentBlock.add(i);
        blocks.add(currentBlock);
        currentBlock = [];
        inBlock = false;
      } else if (inBlock) {
        currentBlock.add(i);
      }
    }
    return blocks;
  }

  TextStyle _getInlineStyle(InlineType type, TextStyle defaultStyle, BuildContext context) {
    switch (type) {
      case InlineType.bold:
        return defaultStyle.copyWith(fontWeight: FontWeight.bold);
      case InlineType.italic:
        return defaultStyle.copyWith(fontStyle: FontStyle.italic);
      case InlineType.strikethrough:
        return defaultStyle.copyWith(decoration: TextDecoration.lineThrough);
      case InlineType.code:
        return GoogleFonts.robotoMono(
          textStyle: defaultStyle.copyWith(
            fontSize: (defaultStyle.fontSize ?? 15) * 0.9,
            color: DesignColors.accentGreen(context),
            backgroundColor: DesignColors.surfaceVariant(context),
          ),
        );
      case InlineType.highlight:
        return defaultStyle.copyWith(
          backgroundColor: DesignColors.primary(context).withValues(alpha: 0.15),
        );
      case InlineType.hashtag:
        return defaultStyle.copyWith(
          color: DesignColors.primary(context),
          fontWeight: FontWeight.bold,
          backgroundColor: DesignColors.primary(context).withValues(alpha: 0.08),
          fontSize: (defaultStyle.fontSize ?? 15) * 0.85,
        );
      case InlineType.wikilink:
      case InlineType.link:
        return defaultStyle.copyWith(
          color: DesignColors.primary(context),
          decoration: TextDecoration.underline,
        );
      case InlineType.timestamp:
        return defaultStyle.copyWith(
          color: DesignColors.primary(context),
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          backgroundColor: DesignColors.primary(context).withValues(alpha: 0.10),
        );
      case InlineType.plain:
        return defaultStyle;
    }
  }

  TextStyle _getHeadingStyle(int level, TextStyle defaultStyle, BuildContext context) {
    final baseSize = defaultStyle.fontSize ?? 15.0;
    double scale = 1.0;
    switch (level) {
      case 1:
        scale = 1.8;
        break;
      case 2:
        scale = 1.5;
        break;
      case 3:
        scale = 1.3;
        break;
      case 4:
        scale = 1.2;
        break;
      case 5:
        scale = 1.1;
        break;
      case 6:
        scale = 1.0;
        break;
    }

    return TextStyle(
      fontSize: baseSize * scale,
      fontWeight: FontWeight.bold,
      color: DesignColors.text(context),
    );
  }
}

