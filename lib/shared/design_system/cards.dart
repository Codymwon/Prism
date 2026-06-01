import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/tactile_wrapper.dart';
import '../../features/notes/data/note_model.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'icons.dart';

class DesignNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DesignNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bg = DesignColors.surface(context);
    final border = DesignColors.border(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TactileWrapper(
      onTap: onTap,
      onLongPress: onLongPress,
      style: TactileFeedbackStyle.longPressLift,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(color: border, width: 0.5),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isDaily) ...[
                    Icon(
                      DesignIcons.dailyNote,
                      size: 13,
                      color: DesignColors.primary(context),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            note.title,
                            style: DesignTypography.heading(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (note.isConflicted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.5),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'CONFLICTED',
                              style: DesignTypography.metadata(
                                context,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.orange[300] : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(note.updatedAt),
                    style: DesignTypography.metadata(context),
                  ),
                ],
              ),
              if (note.wordCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${note.wordCount} words',
                  style: DesignTypography.metadata(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
