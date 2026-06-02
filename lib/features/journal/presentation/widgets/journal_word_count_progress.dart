import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';

class JournalWordCountProgress extends StatelessWidget {
  final int wordCount;

  const JournalWordCountProgress({
    super.key,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const goal = 250;
    final progress = (wordCount / goal).clamp(0.0, 1.0);
    final isDone = wordCount >= goal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.edit_rounded,
            size: 14,
            color: isDone ? Colors.green : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDone ? 'Daily goal reached!' : '$wordCount / $goal words',
                      style: DesignTypography.body(
                        context,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.green : DesignColors.text(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isDone ? '✓ $wordCount words' : '${(goal - wordCount).clamp(0, goal)} to go',
                      style: DesignTypography.metadata(
                        context,
                        fontSize: 10,
                        color: DesignColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: DesignColors.surfaceVariant(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
