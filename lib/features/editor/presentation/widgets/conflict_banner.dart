import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';

class ConflictBanner extends StatelessWidget {
  final String noteId;

  const ConflictBanner({
    super.key,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amberColor = DesignColors.accentAmber(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: amberColor.withValues(alpha: isDark ? 0.15 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: amberColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            DesignIcons.warning,
            color: amberColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Conflicted Copy: Review and resolve changes.',
              style: DesignTypography.heading(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: amberColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/editor/$noteId/merge'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: amberColor.withValues(alpha: isDark ? 0.3 : 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resolve',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: amberColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  DesignIcons.chevronRight,
                  size: 14,
                  color: amberColor,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}
