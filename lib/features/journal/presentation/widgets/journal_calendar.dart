import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../providers/journal_providers.dart';

class JournalCalendar extends ConsumerWidget {
  final DateTime selectedDay;
  final StateProvider<DateTime> selectedDayProvider;
  final StateProvider<DateTime> focusedDayProvider;

  const JournalCalendar({
    super.key,
    required this.selectedDay,
    required this.selectedDayProvider,
    required this.focusedDayProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final writtenDates = ref.watch(allDailyDatesProvider).valueOrNull ?? const <String>{};
    final focusedDay = ref.watch(focusedDayProvider);

    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: DesignTypography.heading(
          context,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(
          DesignIcons.back,
          color: DesignColors.textSecondary(context),
        ),
        rightChevronIcon: Icon(
          DesignIcons.chevronRight,
          color: DesignColors.textSecondary(context),
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: DesignTypography.body(
          context,
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: DesignTypography.body(
          context,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        defaultTextStyle: DesignTypography.body(
          context,
        ),
        weekendTextStyle: DesignTypography.body(
          context,
          color: DesignColors.textSecondary(context),
        ),
        outsideTextStyle: DesignTypography.body(
          context,
          color: DesignColors.textTertiary(context),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: DesignTypography.body(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: DesignColors.textSecondary(context),
        ),
        weekendStyle: DesignTypography.body(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: DesignColors.textTertiary(context),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final dateStr = formatDailyDate(day);
          if (writtenDates.contains(dateStr)) {
            return Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
      onDaySelected: (selected, focused) {
        ref.read(selectedDayProvider.notifier).state = selected;
        ref.read(focusedDayProvider.notifier).state = selected;
      },
      onPageChanged: (focused) {
        ref.read(focusedDayProvider.notifier).state = focused;
      },
    );
  }
}
