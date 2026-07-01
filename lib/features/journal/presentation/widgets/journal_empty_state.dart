import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';

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
    final isFuture = DateTime.parse(dateStr).isAfter(DateTime.now());

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            const SizedBox(height: 20),
            DesignSecondaryButton(
              label: 'Start Writing',
              icon: DesignIcons.add,
              onTap: onStartWriting,
            ),
          ],
        ],
      ),
    );
  }
}
