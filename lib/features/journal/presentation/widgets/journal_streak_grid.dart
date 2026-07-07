import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/utils.dart';
import '../../../../shared/design_system/design_system.dart';
import '../providers/journal_providers.dart';
import 'package:prism/l10n/l10n.dart';

class JournalStreakGrid extends ConsumerWidget {
  const JournalStreakGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(journalStreakProvider);
    final datesAsync = ref.watch(allDailyDatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignColors.surface(context),
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(color: DesignColors.border(context)),
      ),
      child: streakAsync.maybeWhen(
        data: (stats) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Streak Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${stats.streak}',
                    style: DesignTypography.display(
                      context,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.journal_streak_grid_title,
                    style: DesignTypography.body(
                      context,
                      fontSize: 12,
                      color: DesignColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              // Right Column: Consistency Grid
              datesAsync.maybeWhen(
                data: (datesSet) {
                  // Calculate activity for the last 28 days (4 weeks of 7 days)
                  final now = DateTime.now();
                  final gridDays = List.generate(28, (index) {
                    final day = now.subtract(Duration(days: 27 - index));
                    final dateStr = formatDailyDate(day);
                    return datesSet.contains(dateStr);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.journal_streak_grid_consistency_grid,
                        style: DesignTypography.body(
                          context,
                          fontSize: 12,
                          color: DesignColors.textSecondary(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(4, (rowIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(7, (colIndex) {
                                final index = rowIndex * 7 + colIndex;
                                final isActive = gridDays[index];
                                return Container(
                                  key: ValueKey('grid_cell_$index'),
                                  margin: const EdgeInsets.only(right: 4.0),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? colorScheme.primary
                                        : DesignColors.surfaceVariant(context),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}