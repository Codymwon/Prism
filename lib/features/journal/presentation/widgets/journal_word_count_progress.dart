import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

class JournalWordCountProgress extends ConsumerWidget {
  final int wordCount;

  const JournalWordCountProgress({
    super.key,
    required this.wordCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final streakAsync = ref.watch(journalStreakProvider);
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
                    streakAsync.maybeWhen(
                      data: (stats) {
                        if (stats.streak == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TactileWrapper(
                            style: TactileFeedbackStyle.highImpact,
                            onTap: () => _showStreakDialog(context, stats.streak, stats.totalCount),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.15),
                                    colorScheme.tertiary.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.whatshot_rounded,
                                    size: 11,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${stats.streak}d streak',
                                    style: DesignTypography.metadata(
                                      context,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
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

  void _showStreakDialog(BuildContext context, int streak, int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    String encouragement;
    if (streak <= 2) {
      encouragement = 'Off to a fantastic start! Keep writing daily to build a powerful self-reflection habit.';
    } else if (streak <= 5) {
      encouragement = 'Incredible dedication! You are forming a powerful ritual. Every word is a step inward.';
    } else {
      encouragement = 'A legendary writing habit! You are unstoppable. Keep exploring your thoughts daily.';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surface(context),
      barrierColor: Colors.black.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DesignSheetDragHandle(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.whatshot_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(end: const Offset(1.1, 1.1), duration: 1000.ms, curve: Curves.easeInOut),
                const SizedBox(height: 20),
                Text(
                  '$streak-Day Writing Streak!',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  encouragement,
                  style: DesignTypography.body(
                    context,
                    fontSize: 14,
                    color: DesignColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesignColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$streak Days',
                              style: DesignTypography.heading(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active Streak',
                              style: DesignTypography.details(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignColors.surfaceVariant(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesignColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$totalCount',
                              style: DesignTypography.heading(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Entries',
                              style: DesignTypography.details(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DesignPrimaryButton(
                  label: 'Keep it going!',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
