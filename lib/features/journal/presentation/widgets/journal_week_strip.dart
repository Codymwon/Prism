import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../providers/journal_providers.dart';

class JournalWeekStrip extends ConsumerWidget {
  const JournalWeekStrip({super.key});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDay = ref.watch(selectedDayProvider);
    final today = DateTime.now();
    final writtenDates = ref.watch(allDailyDatesProvider).valueOrNull ?? const <String>{};

    // Show today + 6 days back
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Padding(
      padding: const EdgeInsets.only(
        left: DesignSpacing.screenPadding,
        right: DesignSpacing.screenPadding,
        top: 4,
        bottom: 6,
      ),
      child: Row(
        children: List.generate(days.length, (i) {
          final day = days[i];
          final dateStr = formatDailyDate(day);
          final isSelected = _isSameDay(day, selectedDay);
          final isToday_ = _isSameDay(day, today);
          final hasEntry = writtenDates.contains(dateStr);
          final isFuture = day.isAfter(today);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == days.length - 1 ? 0 : 5),
              child: TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: isFuture ? null : () {
                  ref.read(selectedDayProvider.notifier).state = day;
                  ref.read(focusedDayProvider.notifier).state = day;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : DesignColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday_
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : DesignColors.border(context),
                      width: isToday_ && !isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day).substring(0, 1), // M, T, W…
                        style: DesignTypography.metadata(
                          context,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.75)
                              : DesignColors.textTertiary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${day.day}',
                        style: DesignTypography.heading(
                          context,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday_
                                  ? colorScheme.primary
                                  : DesignColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Entry dot indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEntry
                              ? (isSelected ? Colors.white : colorScheme.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
