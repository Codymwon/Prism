import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/utils.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../notes/data/note_model.dart';
import '../../../notes/data/note_repository.dart';
import '../../../editor/presentation/utils/editor_helpers.dart';

class JournalEntryCard extends ConsumerStatefulWidget {
  final Note note;
  final String content;

  const JournalEntryCard({
    super.key,
    required this.note,
    required this.content,
  });

  @override
  ConsumerState<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends ConsumerState<JournalEntryCard> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getCardTitle(String content, String fallback) {
    final fmTitle = extractFrontmatterValue(content, 'title');
    if (fmTitle != null && fmTitle.isNotEmpty) {
      return fmTitle;
    }

    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('#')) {
        final cleanText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        // Skip date pattern, e.g., YYYY-MM-DD
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleanText)) {
          continue;
        }
        return cleanText;
      }
    }
    // If fallback is a date, format it nicely
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fallback)) {
      try {
        final parsed = DateTime.parse(fallback);
        return DateFormat('EEEE, MMMM d').format(parsed);
      } catch (_) {}
      return 'Daily Reflection';
    }
    return fallback;
  }

  String _getFormattedSubtitle(Note note) {
    DateTime displayDate = note.createdAt;
    if (note.isDaily && note.dailyDate != null) {
      try {
        final parsed = DateTime.parse(note.dailyDate!);
        displayDate = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          note.createdAt.hour,
          note.createdAt.minute,
          note.createdAt.second,
        );
      } catch (_) {}
    }
    final dateFormatted = DateFormat('EEEE, MMMM d').format(displayDate);
    final timeFormatted = DateFormat('h:mm a').format(displayDate);
    return '$dateFormatted • $timeFormatted';
  }

  String _getBodyMarkdown(String content, String cardTitle) {
    final cleanContent = stripFrontmatter(content);
    final lines = cleanContent.split('\n');
    int skipCount = 0;
    for (int i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('# ')) {
        final cleanText = trimmed.substring(2).trim();
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleanText)) {
          skipCount = i + 1;
          break;
        }
      }
    }
    final remainingLines = lines.sublist(skipCount);
    
    // Skip the heading line that matches the cardTitle
    int titleHeadingIndex = -1;
    for (int i = 0; i < remainingLines.length; i++) {
      final trimmed = remainingLines[i].trim();
      if (trimmed.startsWith('#')) {
        final cleanText = trimmed.replaceFirst(RegExp(r'^#+\s*'), '').trim();
        if (cleanText == cardTitle) {
          titleHeadingIndex = i;
          break;
        }
      }
    }
    if (titleHeadingIndex != -1) {
      remainingLines.removeAt(titleHeadingIndex);
    } else {
      // Fallback: Skip the first h1 heading (exactly one '#')
      for (int i = 0; i < remainingLines.length; i++) {
        final trimmed = remainingLines[i].trim();
        if (trimmed.startsWith('# ') && !trimmed.startsWith('## ')) {
          remainingLines.removeAt(i);
          break;
        }
      }
    }
    
    // Filter out markdown checklist items and image tags from the body preview
    final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\]');
    final imageRegExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final bodyLines = <String>[];
    for (final line in remainingLines) {
      if (checkboxRegExp.hasMatch(line)) {
        continue;
      }
      if (imageRegExp.hasMatch(line)) {
        final cleanedLine = line.replaceAll(imageRegExp, '').trim();
        if (cleanedLine.isEmpty) {
          continue;
        }
        bodyLines.add(cleanedLine);
        continue;
      }
      bodyLines.add(line);
    }

    // Strip leading blank lines left behind after removing the title heading
    while (bodyLines.isNotEmpty && bodyLines.first.trim().isEmpty) {
      bodyLines.removeAt(0);
    }
    
    return preprocessMarkdown(bodyLines.join('\n'));
  }

  Widget _buildChecklistWidget(BuildContext context, List<DailyChecklistItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final listWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final updatedContent = toggleMarkdownCheckboxAtLine(widget.content, item.lineIndex);
              await ref.read(noteRepositoryProvider).saveNote(widget.note.id, updatedContent);
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: item.isChecked
                        ? colorScheme.primary
                        : DesignColors.textSecondary(context).withValues(alpha: 0.5),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: DesignTypography.body(
                        context,
                        fontSize: 13,
                        color: item.isChecked
                            ? DesignColors.textSecondary(context).withValues(alpha: 0.6)
                            : DesignColors.text(context),
                      ).copyWith(
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );

    return listWidget;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTitle = _getCardTitle(widget.content, widget.note.title);
    final cardSubtitle = '${_getFormattedSubtitle(widget.note)} • ${widget.note.wordCount} words';
    final bodyMarkdown = _getBodyMarkdown(widget.content, cardTitle);
    final checklist = extractChecklist(widget.content);
    final imagePath = extractPreviewImage(widget.content);
    final showPrompt = widget.note.isDaily && widget.note.dailyDate != null && isToday(widget.note.dailyDate!);

    void openNote() {
      context.push('/editor/${widget.note.id}');
    }

    final hasContent = bodyMarkdown.trim().isNotEmpty;
    final showChecklist = checklist.isNotEmpty;
    final showImage = imagePath != null;
    final showSidebar = showChecklist || showImage;

    final noteContentCard = TactileWrapper(
      key: const ValueKey('bento_note_card'),
      style: TactileFeedbackStyle.highImpact,
      onTap: openNote,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title & Date Header
            Text(
              cardTitle,
              style: DesignTypography.heading(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DesignColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              cardSubtitle,
              style: DesignTypography.body(
                context,
                fontSize: 12,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 0.5,
              color: DesignColors.border(context),
            ),
            const SizedBox(height: 14),

            // Markdown Body Preview Block (Excluding Checklist items)
            if (hasContent)
              Expanded(
                child: ClipRect(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.black,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 0.95, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: IgnorePointer(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: MarkdownBody(
                          data: bodyMarkdown,
                          softLineBreak: true,
                          inlineSyntaxes: [HighlightSyntax(), HashtagSyntax()],
                          builders: {
                            'mark': HighlightElementBuilder(context),
                            'hashtag': HashtagElementBuilder(context),
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: DesignTypography.body(
                              context,
                              fontSize: 13,
                              height: 1.5,
                              color: DesignColors.textSecondary(context),
                            ),
                            h1: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w700),
                            h2: DesignTypography.heading(context, fontSize: 14, fontWeight: FontWeight.w600),
                            h3: DesignTypography.heading(context, fontSize: 13, fontWeight: FontWeight.w600),
                            listBullet: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
                            code: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: DesignColors.accentGreen(context),
                              backgroundColor: DesignColors.surfaceVariant(context),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            blockquote: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)).copyWith(fontStyle: FontStyle.italic),
                          ),
                          checkboxBuilder: (bool value) {
                            return const SizedBox.shrink(); // Not used here since checklists are excluded
                          },
                          imageBuilder: (uri, title, alt) {
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Text(
                  'No text written yet. Tap to start writing…',
                  style: DesignTypography.body(
                    context,
                    fontSize: 13,
                    color: DesignColors.textSecondary(context),
                    height: 1.6,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),

            // Conditional "Tap to continue writing" Prompt
            if (showPrompt) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Continue writing',
                    style: DesignTypography.body(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    final checklistCard = showChecklist
        ? Container(
            key: const ValueKey('bento_checklist_card'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: DesignColors.surface(context),
              borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAILY MINDFUL CHECKLIST',
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildChecklistWidget(context, checklist),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final imageCard = showImage
        ? TactileWrapper(
            style: TactileFeedbackStyle.highImpact,
            onTap: openNote,
            child: Container(
              key: const ValueKey('bento_image_card'),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: DesignColors.surface(context),
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge - 1),
                child: Builder(
                  builder: (context) {
                    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');
                    if (isNetwork) {
                      return Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      );
                    } else {
                      return Image.file(
                        File(p.isAbsolute(imagePath) ? imagePath : p.join(p.dirname(widget.note.filePath), imagePath)),
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      );
                    }
                  }
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    if (showSidebar) {
      final Widget sidebar;
      if (showChecklist && showImage) {
        sidebar = Column(
          key: const ValueKey('bento_sidebar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 7, child: checklistCard),
            const SizedBox(height: 10),
            Expanded(flex: 3, child: imageCard),
          ],
        );
      } else if (showChecklist) {
        sidebar = Column(
          key: const ValueKey('bento_sidebar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: checklistCard),
          ],
        );
      } else {
        sidebar = Column(
          key: const ValueKey('bento_sidebar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: imageCard),
          ],
        );
      }

      return SizedBox(
        height: 360.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: noteContentCard,
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: sidebar,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 340.0,
      child: noteContentCard,
    );
  }
}

