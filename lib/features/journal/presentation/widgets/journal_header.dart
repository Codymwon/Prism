import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

class JournalHeader extends ConsumerWidget {
  final DateTime selectedDay;
  final bool showCalendar;
  final VoidCallback onToggleCalendar;

  const JournalHeader({
    super.key,
    required this.selectedDay,
    required this.showCalendar,
    required this.onToggleCalendar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday_ = isToday(formatDailyDate(selectedDay));
    final streakAsync = ref.watch(journalStreakProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignSpacing.screenPadding + 2,
        16,
        DesignSpacing.screenPadding,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal',
                  style: DesignTypography.display(
                    context,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isToday_ ? 'Today' : DateFormat('EEEE, MMMM d').format(selectedDay),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTypography.body(
                          context,
                          fontSize: 14,
                          color: DesignColors.textSecondary(context),
                        ),
                      ),
                    ),
                    streakAsync.maybeWhen(
                      data: (stats) {
                        if (stats.totalCount == 0) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: DesignColors.textTertiary(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(
                              Icons.history_edu_rounded,
                              size: 13,
                              color: DesignColors.textSecondary(context),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${stats.totalCount} entries',
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                color: DesignColors.textSecondary(context),
                              ),
                            ),
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Interactive themed streak pill placed next to calendar button
          streakAsync.maybeWhen(
            data: (stats) {
              if (stats.streak == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: TactileWrapper(
                  style: TactileFeedbackStyle.highImpact,
                  onTap: () => _showStreakDialog(context, stats.streak, stats.totalCount),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.15),
                          colorScheme.tertiary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
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
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.streak}d streak',
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 11,
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
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                showCalendar ? Icons.calendar_today : Icons.calendar_month_outlined,
                key: ValueKey(showCalendar),
                size: 22,
                color: showCalendar ? colorScheme.primary : DesignColors.textSecondary(context),
              ),
            ),
            onPressed: onToggleCalendar,
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
                // Pulsing themed fire icon
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
                // Stats breakdown cards
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
