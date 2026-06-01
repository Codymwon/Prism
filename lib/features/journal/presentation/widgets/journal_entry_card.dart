import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../notes/data/note_model.dart';

class JournalEntryCard extends StatelessWidget {
  final Note note;
  final String content;

  const JournalEntryCard({
    super.key,
    required this.note,
    required this.content,
  });

  String _getCleanPreview(String content) {
    final lines = content.split('\n');
    final previewLines = <String>[];
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('#')) continue; // Skip titles / headers
      
      var cleanLine = trimmed;
      if (cleanLine.startsWith('- ')) {
        cleanLine = cleanLine.substring(2);
      } else if (cleanLine.startsWith('* ')) {
        cleanLine = cleanLine.substring(2);
      }
      
      if (cleanLine.isNotEmpty) {
        previewLines.add(cleanLine);
      }
      if (previewLines.length >= 3) break; // Fetch up to 3 content lines
    }
    
    if (previewLines.isEmpty) {
      return 'No text written yet. Tap to start writing…';
    }
    return previewLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewText = _getCleanPreview(content);

    return GestureDetector(
      onTap: () => context.push('/editor/${note.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusLarge),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
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
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Entry Written',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${note.wordCount} words',
                  style: DesignTypography.mono(
                    fontSize: 11,
                    color: DesignColors.textSecondary(context),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DesignColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
              ),
              child: Text(
                previewText,
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  color: DesignColors.textSecondary(context),
                  height: 1.5,
                ).copyWith(fontStyle: previewText.startsWith('No text') ? FontStyle.italic : FontStyle.normal),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 14),
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
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.97, 0.97));
  }
}
