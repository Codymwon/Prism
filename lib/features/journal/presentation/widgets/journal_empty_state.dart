import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import 'journal_empty_illustration.dart';

class JournalEmptyState extends StatelessWidget {
  final String dateStr;
  final bool showCalendar;
  final VoidCallback onStartWriting;

  const JournalEmptyState({
    super.key,
    required this.dateStr,
    required this.showCalendar,
    required this.onStartWriting,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!showCalendar) ...[
            JournalEmptyIllustration(
              isFuture: isFuture,
              colorScheme: colorScheme,
              size: 110.0,
            ),
            const SizedBox(height: 20),
          ],
          Text(
            isFuture ? 'A future day' : 'No entry yet',
            style: DesignTypography.heading(
              context,
              fontSize: showCalendar ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFuture
                ? 'Come back on this day to start writing'
                : 'Tap below to start your entry for today',
            style: DesignTypography.body(
              context,
              fontSize: showCalendar ? 13 : 14,
              color: DesignColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isFuture) ...[
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: showCalendar ? 40.0 : 20.0),
              child: DesignPrimaryButton(
                label: 'Start Writing',
                icon: DesignIcons.add,
                height: showCalendar ? 44.0 : 52.0,
                onTap: onStartWriting,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
