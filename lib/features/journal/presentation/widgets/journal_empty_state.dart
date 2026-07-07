import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import 'package:prism/l10n/l10n.dart';

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
            isFuture ? context.l10n.journal_empty_state_future_day_title : context.l10n.journal_empty_state_no_entry_title,
            style: DesignTypography.heading(
              context,
              fontSize: showCalendar ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFuture
                ? context.l10n.journal_empty_state_future_day_desc
                : context.l10n.journal_empty_state_no_entry_desc,
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
              label: context.l10n.journal_empty_state_start_writing_button,
              icon: DesignIcons.add,
              onTap: onStartWriting,
            ),
          ],
        ],
      ),
    );
  }
}