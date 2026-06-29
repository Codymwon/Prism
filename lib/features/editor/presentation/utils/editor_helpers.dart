import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../../settings/presentation/providers/custom_macro_provider.dart';

/// Standard markdown link tapping handler.
///
/// Handles both internal [[wikilinks]] and external web URLs.
Future<void> handleMarkdownLinkTap({
  required String? href,
  required WidgetRef ref,
  required BuildContext context,
}) async {
  if (href == null) return;

  if (href.startsWith('wikilink:')) {
    final encodedTitle = href.substring('wikilink:'.length);
    final targetTitle = Uri.decodeComponent(encodedTitle);
    final repo = ref.read(noteRepositoryProvider);
    var targetNote = await repo.getNoteByTitle(targetTitle);
    targetNote ??= await repo.createNote(title: targetTitle);
    if (context.mounted) {
      context.push('/editor/${targetNote.id}');
    }
  } else if (href.startsWith('http://') || href.startsWith('https://')) {
    final uri = Uri.tryParse(href);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error launching URL: $e');
      }
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
  final String dividerText = '$prefix---';
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

/// A custom widget representing a hashtag pill, used for encapsulation and testing.
class HashtagPill extends StatelessWidget {
  final String text;
  const HashtagPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final primary = DesignColors.primary(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        child: Text(
          text,
          style: DesignTypography.metadata(
            context,
            fontSize: 10, // 12 * 0.85 approx 10
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
    );
  }
}

/// Custom Element Builder to render the custom 'hashtag' tag
class HashtagElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  HashtagElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return HashtagPill(text: element.textContent);
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
  final List<int> checkboxLineIndices;

  const MarkdownSegment._({
    this.text,
    this.audioLabel,
    this.audioPath,
    this.checkboxLineIndices = const [],
  });

  factory MarkdownSegment.text(String text, {List<int> checkboxLineIndices = const []}) =>
      MarkdownSegment._(text: text, checkboxLineIndices: checkboxLineIndices);

  factory MarkdownSegment.audio({
    required String label,
    required String path,
    List<int> checkboxLineIndices = const [],
  }) => MarkdownSegment._(audioLabel: label, audioPath: path, checkboxLineIndices: checkboxLineIndices);

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
  final lines = markdown.split('\n');
  
  var currentTextLines = <String>[];
  var currentCheckboxLineIndices = <int>[];
  
  final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\]');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final isAudio = _audioLinkRegex.hasMatch(line.trim());
    
    if (isAudio) {
      if (currentTextLines.isNotEmpty) {
        segments.add(MarkdownSegment.text(
          currentTextLines.join('\n'),
          checkboxLineIndices: List.from(currentCheckboxLineIndices),
        ));
        currentTextLines.clear();
        currentCheckboxLineIndices.clear();
      }
      
      final match = _audioLinkRegex.firstMatch(line.trim())!;
      segments.add(MarkdownSegment.audio(
        label: match.group(1)!,
        path: match.group(2)!,
      ));
    } else {
      currentTextLines.add(line);
      if (checkboxRegExp.hasMatch(line)) {
        currentCheckboxLineIndices.add(i);
      }
    }
  }
  
  if (currentTextLines.isNotEmpty) {
    segments.add(MarkdownSegment.text(
      currentTextLines.join('\n'),
      checkboxLineIndices: List.from(currentCheckboxLineIndices),
    ));
  }
  
  if (segments.isEmpty) {
    segments.add(MarkdownSegment.text(markdown));
  }
  
  return segments;
}

/// A section of a note grouped under a specific heading level.
class HeadingNode {
  final String headingText;
  final int level; // 1 for H1, 2 for H2, etc. 0 for root.
  final List<MarkdownSegment> segments;
  final List<HeadingNode> children;

  HeadingNode({
    required this.headingText,
    required this.level,
    required this.segments,
    required this.children,
  });
}

/// Groups alternating text/audio markdown segments into a hierarchical heading tree.
HeadingNode parseHierarchicalSections(List<MarkdownSegment> segments) {
  final root = HeadingNode(headingText: 'Root', level: 0, segments: [], children: []);
  final stack = <HeadingNode>[root];
  
  bool isInCodeBlock = false;

  for (final segment in segments) {
    if (segment.isAudio) {
      stack.last.segments.add(segment);
    } else {
      final lines = segment.text!.split('\n');
      var currentTextLines = <String>[];
      var currentCheckboxLineIndices = <int>[];
      int segmentCheckboxIndex = 0;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();
        
        if (trimmed.startsWith('```')) {
          isInCodeBlock = !isInCodeBlock;
        }

        final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
        if (!isInCodeBlock && headingMatch != null) {
          final level = headingMatch.group(1)!.length;
          final title = headingMatch.group(2)!.trim();

          if (currentTextLines.isNotEmpty) {
            stack.last.segments.add(MarkdownSegment.text(
              currentTextLines.join('\n'),
              checkboxLineIndices: List.from(currentCheckboxLineIndices),
            ));
            currentTextLines.clear();
            currentCheckboxLineIndices.clear();
          }

          while (stack.last.level >= level && stack.length > 1) {
            stack.removeLast();
          }

          final newNode = HeadingNode(headingText: title, level: level, segments: [], children: []);
          stack.last.children.add(newNode);
          stack.add(newNode);
        } else {
          currentTextLines.add(line);
          final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\]');
          if (checkboxRegExp.hasMatch(line)) {
            if (segment.checkboxLineIndices.isNotEmpty && segmentCheckboxIndex < segment.checkboxLineIndices.length) {
              final absIndex = segment.checkboxLineIndices[segmentCheckboxIndex++];
              currentCheckboxLineIndices.add(absIndex);
            }
          }
        }
      }

      if (currentTextLines.isNotEmpty) {
        stack.last.segments.add(MarkdownSegment.text(
          currentTextLines.join('\n'),
          checkboxLineIndices: List.from(currentCheckboxLineIndices),
        ));
      }
    }
  }

  return root;
}

