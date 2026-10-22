import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/journal_providers.dart';
import 'package:prism/l10n/l10n.dart';

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
    final showStreaks = ref.watch(showJournalStreaksProvider).valueOrNull ?? true;

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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      isToday_ ? context.l10n.journal_header_title_today : DateFormat('EEEE, MMMM d').format(selectedDay),
                      style: DesignTypography.body(
                        context,
                        fontSize: 14,
                        color: DesignColors.textSecondary(context),
                      ),
                    ),
                    if (showStreaks)
                      streakAsync.maybeWhen(
                      data: (stats) {
                        if (stats.totalCount == 0) return const SizedBox.shrink();
                        return Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                              context.l10n.journal_header_entries_count(stats.totalCount),
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
}