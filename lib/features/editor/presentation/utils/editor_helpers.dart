import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../settings/presentation/providers/custom_macro_provider.dart';

/// Standard wikilink tapping navigation helper.
///
/// Looks up or creates target notes from dynamic [[wikilinks]] inside markdown rendering and navigates to them.
Future<void> handleWikilinkTap({
  required String? href,
  required WidgetRef ref,
  required BuildContext context,
}) async {
  if (href != null && href.startsWith('wikilink:')) {
    final encodedTitle = href.substring('wikilink:'.length);
    final targetTitle = Uri.decodeComponent(encodedTitle);
    final repo = ref.read(noteRepositoryProvider);
    var targetNote = await repo.getNoteByTitle(targetTitle);
    targetNote ??= await repo.createNote(title: targetTitle);
    if (context.mounted) {
      context.push('/editor/${targetNote.id}');
    }
  }
}

/// Helper to insert Markdown formatting at the current selection of the text editor.
void insertFormatting({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String prefix,
  String suffix = '',
}) {
  final text = controller.text;
  final selection = controller.selection;
  
  if (!selection.isValid) {
    final newText = text + prefix + suffix;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length - suffix.length),
    );
    return;
  }
  
  final start = selection.start;
  final end = selection.end;
  final selectedText = text.substring(start, end);
  
  final newSelectedText = prefix + selectedText + suffix;
  final newText = text.replaceRange(start, end, newSelectedText);
  
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    ),
  );
  
  focusNode.requestFocus();
}

/// Helper to insert/toggle block formatting (e.g. lists, blockquotes) for all lines in the selection.
void toggleBlockStyle({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String prefix,
}) {
  final text = controller.text;
  final selection = controller.selection;

  if (!selection.isValid) {
    final cursor = text.length;
    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final currentLine = text.substring(lineStart);
    
    final String newLine;
    final int diff;
    if (currentLine.startsWith(prefix)) {
      newLine = currentLine.substring(prefix.length);
      diff = -prefix.length;
    } else {
      newLine = '$prefix$currentLine';
      diff = prefix.length;
    }
    
    final newText = text.replaceRange(lineStart, text.length, newLine);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: (cursor + diff).clamp(0, newText.length)),
    );
    focusNode.requestFocus();
    return;
  }

  final start = selection.start;
  final end = selection.end;

  final startLineOffset = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  final endLineOffset = text.indexOf('\n', end);
  final actualEndLineOffset = endLineOffset == -1 ? text.length : endLineOffset;

  final selectedLinesText = text.substring(startLineOffset, actualEndLineOffset);
  final lines = selectedLinesText.split('\n');

  final allHavePrefix = lines.every((line) => line.startsWith(prefix));
  final updatedLines = lines.map((line) {
    if (allHavePrefix) {
      return line.substring(prefix.length);
    } else {
      if (line.startsWith(prefix)) {
        return line;
      } else {
        return '$prefix$line';
      }
    }
  }).toList();

  final newSelectedLinesText = updatedLines.join('\n');
  final newText = text.replaceRange(startLineOffset, actualEndLineOffset, newSelectedLinesText);

  final difference = newSelectedLinesText.length - selectedLinesText.length;
  if (start == end) {
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (start + difference).clamp(0, newText.length),
      ),
    );
  } else {
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: startLineOffset,
        extentOffset: actualEndLineOffset + difference,
      ),
    );
  }
  focusNode.requestFocus();
}

/// Helper to insert a horizontal rule (divider) dynamically on its own line.
void insertDivider({
  required TextEditingController controller,
  required FocusNode focusNode,
}) {
  final text = controller.text;
  final selection = controller.selection;
  final cursor = selection.isValid ? selection.baseOffset : text.length;

  // Find start of current line
  final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
  final lineEnd = text.indexOf('\n', cursor);
  final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;
  final currentLine = text.substring(lineStart, actualLineEnd);

  // Determine prefix: if current line is not empty, insert a newline first
  final String prefix = currentLine.trim().isEmpty ? '' : '\n';
  // Determine suffix: always insert a newline after the horizontal rule to keep markdown valid
  final String dividerText = '${prefix}---';
  final String suffix = '\n';

  final start = selection.isValid ? selection.start : text.length;
  final end = selection.isValid ? selection.end : text.length;

  final newText = text.replaceRange(start, end, '$dividerText$suffix');
  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: (start + dividerText.length).clamp(0, newText.length)),
  );
  focusNode.requestFocus();
}

/// Helper to resolve template variables inside a macro and insert the resolved text.
void insertMacro({
  required TextEditingController controller,
  required FocusNode focusNode,
  required CustomMacro macro,
}) {
  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final dateStr = '$year-$month-$day';

  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  final timeStr = '$hour:$minute';

  final resolvedText = macro.text
      .replaceAll('{{date}}', dateStr)
      .replaceAll('{{time}}', timeStr)
      .replaceAll('{{datetime}}', '$dateStr $timeStr');

  insertFormatting(
    controller: controller,
    focusNode: focusNode,
    prefix: resolvedText,
  );
}

/// Custom Inline Markdown Syntax for Highlights (==text==)
class HighlightSyntax extends md.InlineSyntax {
  HighlightSyntax() : super(r'==([^=]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match.group(1)!));
    return true;
  }
}

/// Custom Element Builder to render the custom 'mark' highlight tag
class HighlightElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  HighlightElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: TextStyle(
          backgroundColor: DesignColors.accentAmber(context).withValues(alpha: 0.3),
          color: DesignColors.text(context),
          fontWeight: preferredStyle?.fontWeight,
          fontStyle: preferredStyle?.fontStyle,
        ),
      ),
    );
  }
}

/// Custom Inline Markdown Syntax for Hashtags (#tag)
class HashtagSyntax extends md.InlineSyntax {
  HashtagSyntax() : super(r'(?<!\w)#([a-zA-Z][a-zA-Z0-9_]*)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('hashtag', match.group(0)!));
    return true;
  }
}

/// Custom Element Builder to render the custom 'hashtag' tag
class HashtagElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  HashtagElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final primary = DesignColors.primary(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: DesignTypography.metadata(
          context,
          fontSize: (preferredStyle?.fontSize ?? 12) * 0.85,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }
}

/// Helper to resolve typeface fonts dynamically based on user preferences.
TextStyle getEditorFont(
  String family, {
  double? fontSize,
  double? height,
  Color? color,
  FontWeight? fontWeight,
  TextDecoration? decoration,
}) {
  switch (family) {
    case 'Roboto Mono (Mono)':
      return GoogleFonts.robotoMono(
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
      );
    case 'Lora (Serif)':
      return GoogleFonts.lora(
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
      );
    case 'Merriweather (Serif)':
      return GoogleFonts.merriweather(
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
      );
    case 'Inter (Sans)':
    default:
      return GoogleFonts.inter(
        fontSize: fontSize,
        height: height,
        color: color,
        fontWeight: fontWeight,
        decoration: decoration,
      );
  }
}

/// Helper to build uniform MarkdownStyleSheet based on current theme, fonts and sizes.
MarkdownStyleSheet buildMarkdownStyleSheet(
  BuildContext context,
  String family,
  double size,
  ColorScheme colorScheme,
) {
  return MarkdownStyleSheet(
    h1: getEditorFont(
      family,
      fontSize: size * 1.625,
      fontWeight: FontWeight.w700,
      color: DesignColors.text(context),
    ),
    h2: getEditorFont(
      family,
      fontSize: size * 1.25,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    ),
    h3: getEditorFont(
      family,
      fontSize: size * 1.0625,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    ),
    h4: getEditorFont(
      family,
      fontSize: size * 0.95,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    ),
    h5: getEditorFont(
      family,
      fontSize: size * 0.88,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    ),
    h6: getEditorFont(
      family,
      fontSize: size * 0.81,
      fontWeight: FontWeight.w600,
      color: DesignColors.text(context),
    ),
    p: getEditorFont(
      family,
      fontSize: size,
      height: 1.7,
      color: DesignColors.text(context),
    ),
    strong: getEditorFont(
      family,
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: DesignColors.text(context),
    ),
    em: getEditorFont(
      family,
      fontSize: size,
      color: DesignColors.text(context),
    ).copyWith(fontStyle: FontStyle.italic),
    listBullet: getEditorFont(
      family,
      fontSize: size,
      color: DesignColors.text(context),
    ),
    blockquote: getEditorFont(
      family,
      fontSize: size,
      color: DesignColors.textSecondary(context),
    ),
    tableHead: getEditorFont(
      family,
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: DesignColors.text(context),
    ),
    tableBody: getEditorFont(
      family,
      fontSize: size,
      color: DesignColors.text(context),
    ),
    code: GoogleFonts.robotoMono(
      fontSize: size * 0.8125,
      color: DesignColors.accentGreen(context),
      backgroundColor: DesignColors.surfaceVariant(context),
    ),
    a: getEditorFont(
      family,
      fontSize: size,
      color: colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: colorScheme.primary,
          width: 3,
        ),
      ),
    ),
  );
}

/// Helper to render image attachments inside Markdown body previews.
Widget buildMarkdownImage({
  required Uri uri,
  required String noteId,
  required WidgetRef ref,
  required BuildContext context,
}) {
  final uriStr = uri.toString();
  final isNetwork = uriStr.startsWith('http://') || uriStr.startsWith('https://');
  final isAbsolute = uriStr.startsWith('/') || uriStr.contains(':/') || uriStr.startsWith('file:');

  if (isNetwork) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DesignColors.border(context), width: 1),
      ),
      color: DesignColors.surface(context),
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 0,
      child: Image.network(
        uriStr,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined,
                    color: DesignColors.textSecondary(context)),
                const SizedBox(width: 12),
                Text(
                  'Failed to load image',
                  style: DesignTypography.body(context,
                      color: DesignColors.textSecondary(context)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  if (!isNetwork && !isAbsolute) {
    final note = ref.read(noteByIdProvider(noteId)).valueOrNull;
    if (note != null) {
      final vaultPath = p.dirname(note.filePath);
      final fullPath = p.join(vaultPath, uriStr);
      final file = File(fullPath);
      if (file.existsSync()) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  color: DesignColors.surfaceVariant(context),
                  child: Row(
                    children: [
                      Icon(Icons.broken_image_outlined,
                          color: DesignColors.textSecondary(context)),
                      const SizedBox(width: 12),
                      Text(
                        'Failed to load image',
                        style: DesignTypography.body(context,
                            color: DesignColors.textSecondary(context)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
  return const SizedBox.shrink();
}

/// A segment of note content that is either a block of markdown text or
/// an audio attachment reference.
class MarkdownSegment {
  final String? text;
  final String? audioLabel;
  final String? audioPath;
  final int startingCheckboxIndex;

  const MarkdownSegment._({this.text, this.audioLabel, this.audioPath, this.startingCheckboxIndex = 0});

  factory MarkdownSegment.text(String text, {int startingCheckboxIndex = 0}) =>
      MarkdownSegment._(text: text, startingCheckboxIndex: startingCheckboxIndex);

  factory MarkdownSegment.audio({
    required String label,
    required String path,
    int startingCheckboxIndex = 0,
  }) => MarkdownSegment._(audioLabel: label, audioPath: path, startingCheckboxIndex: startingCheckboxIndex);

  bool get isAudio => audioPath != null;
}

final RegExp _audioLinkRegex = RegExp(
  r'^\[([^\]]*)\]\((attachments/[^)]+\.(?:m4a|mp3|wav|aac|ogg))\)$',
  multiLine: true,
  caseSensitive: false,
);

/// Splits note markdown text into alternating markdown and audio segments.
List<MarkdownSegment> splitAudioLinks(String markdown) {
  final segments = <MarkdownSegment>[];
  int lastEnd = 0;
  int checkboxAccumulator = 0;

  int countCheckboxes(String text) {
    final regex = RegExp(r'^\s*([-*+]|\d+\.)\s+\[([ xX])\]', multiLine: true);
    return regex.allMatches(text).length;
  }

  for (final match in _audioLinkRegex.allMatches(markdown)) {
    if (match.start > lastEnd) {
      final textBefore = markdown.substring(lastEnd, match.start);
      if (textBefore.trim().isNotEmpty) {
        segments.add(MarkdownSegment.text(
          textBefore,
          startingCheckboxIndex: checkboxAccumulator,
        ));
        checkboxAccumulator += countCheckboxes(textBefore);
      }
    }
    segments.add(MarkdownSegment.audio(
      label: match.group(1)!,
      path: match.group(2)!,
      startingCheckboxIndex: checkboxAccumulator,
    ));
    lastEnd = match.end;
  }

  if (lastEnd < markdown.length) {
    final remaining = markdown.substring(lastEnd);
    if (remaining.trim().isNotEmpty) {
      segments.add(MarkdownSegment.text(
        remaining,
        startingCheckboxIndex: checkboxAccumulator,
      ));
    }
  }

  if (segments.isEmpty) {
    segments.add(MarkdownSegment.text(markdown, startingCheckboxIndex: 0));
  }

  return segments;
}

/// A section of a note grouped under a specific H1 heading.
class HeadingSection {
  final String? headingText;
  final List<MarkdownSegment> segments;

  HeadingSection({this.headingText, required this.segments});
}

/// Groups alternating text/audio markdown segments into H1 collapsible sections.
List<HeadingSection> groupSegmentsByH1(List<MarkdownSegment> segments) {
  final sections = <HeadingSection>[];
  String? currentHeading;
  var currentSegments = <MarkdownSegment>[];

  int countCheckboxes(String text) {
    final regex = RegExp(r'^\s*([-*+]|\d+\.)\s+\[([ xX])\]', multiLine: true);
    return regex.allMatches(text).length;
  }

  for (final segment in segments) {
    if (segment.isAudio) {
      currentSegments.add(segment);
    } else {
      final text = segment.text!;
      final lines = text.split('\n');
      var isInCodeBlock = false;
      var buffer = StringBuffer();
      int currentStartIdx = segment.startingCheckboxIndex;
      int accumulatedInSegment = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('```')) {
          isInCodeBlock = !isInCodeBlock;
        }

        if (!isInCodeBlock && line.startsWith('# ')) {
          // If we have accumulated content, save it
          if (buffer.isNotEmpty) {
            final textChunk = buffer.toString();
            currentSegments.add(MarkdownSegment.text(
              textChunk,
              startingCheckboxIndex: currentStartIdx,
            ));
            accumulatedInSegment += countCheckboxes(textChunk);
            buffer = StringBuffer();
          }

          // Finalize current section
          if (currentHeading != null || currentSegments.isNotEmpty) {
            sections.add(HeadingSection(
              headingText: currentHeading,
              segments: List.from(currentSegments),
            ));
            currentSegments.clear();
          }

          // Start a new section
          currentHeading = line.substring(2).trim();
          currentStartIdx = segment.startingCheckboxIndex + accumulatedInSegment;
        } else {
          buffer.write(line);
          // Keep newlines except for the very last line of the segment
          if (i < lines.length - 1) {
            buffer.write('\n');
          }
        }
      }

      if (buffer.isNotEmpty) {
        currentSegments.add(MarkdownSegment.text(
          buffer.toString(),
          startingCheckboxIndex: currentStartIdx,
        ));
      }
    }
  }

  // Finalize the last section
  if (currentHeading != null || currentSegments.isNotEmpty) {
    sections.add(HeadingSection(
      headingText: currentHeading,
      segments: List.from(currentSegments),
    ));
  }

  return sections;
}

