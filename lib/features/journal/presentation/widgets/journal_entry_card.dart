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
import '../../../notes/presentation/providers/notes_providers.dart';

class JournalEntryCard extends ConsumerWidget {
  final Note note;
  final String content;

  const JournalEntryCard({
    super.key,
    required this.note,
    required this.content,
  });

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
    
    // Filter out markdown checklist items from the body preview
    final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\]');
    final bodyLines = <String>[];
    for (final line in remainingLines) {
      if (checkboxRegExp.hasMatch(line)) {
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

  List<_ChecklistItem> _getChecklist(String content) {
    final lines = content.split('\n');
    final items = <_ChecklistItem>[];
    final checkboxRegExp = RegExp(r'^\s*[-*+]\s+\[([ xX])\](?:\s+(.*))?$');
    for (final line in lines) {
      final match = checkboxRegExp.firstMatch(line);
      if (match != null) {
        final isChecked = match.group(1)!.trim().isNotEmpty;
        final label = match.group(2)?.trim() ?? '';
        items.add(_ChecklistItem(label, isChecked));
      }
    }
    return items;
  }

  Widget _buildChecklistWidget(BuildContext context, List<_ChecklistItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final listWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
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
        );
      }).toList(),
    );

    if (items.length > 4) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 120),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: listWidget,
            ),
          ),
        ),
      );
    }
    return listWidget;
  }

  String? _getImagePath(String content) {
    final match = RegExp(r'!\[.*?\]\((.*?)\)').firstMatch(content);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTitle = _getCardTitle(content, note.title);
    final cardSubtitle = '${_getFormattedSubtitle(note)} • ${note.wordCount} words';
    final bodyMarkdown = _getBodyMarkdown(content, cardTitle);
    final checklist = _getChecklist(content);
    final imagePath = _getImagePath(content);
    final showPrompt = note.isDaily && note.dailyDate != null && isToday(note.dailyDate!);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    void openNote() {
      if (isDesktop) {
        ref.read(activeDesktopNoteIdProvider.notifier).state = note.id;
      } else {
        context.push('/editor/${note.id}');
      }
    }

    final hasContent = bodyMarkdown.trim().isNotEmpty;

    return TactileWrapper(
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
              SizedBox(
                height: 180,
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
              Text(
                'No text written yet. Tap to start writing…',
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  color: DesignColors.textSecondary(context),
                  height: 1.6,
                ).copyWith(fontStyle: FontStyle.italic),
              ),

            // Checklist Section (Separated at the bottom)
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 18),
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
              _buildChecklistWidget(context, checklist),
            ],

            // Image Preview Section
            if (imagePath != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(p.isAbsolute(imagePath) ? imagePath : p.join(p.dirname(note.filePath), imagePath)),
                  fit: BoxFit.cover,
                  height: 180,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],

            // Conditional "Tap to continue writing" Prompt
            if (showPrompt) ...[
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to continue writing',
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
  }
}

class _ChecklistItem {
  final String label;
  final bool isChecked;
  const _ChecklistItem(this.label, this.isChecked);
}
