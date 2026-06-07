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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            DesignIcons.warning,
            color: isDark ? Colors.orange[300] : Colors.orange[800],
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
                color: isDark ? Colors.orange[200] : Colors.orange[900],
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/editor/$noteId/merge'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: isDark
                  ? Colors.orange[800]!.withValues(alpha: 0.3)
                  : Colors.orange[100],
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
                    color: isDark ? Colors.orange[200] : Colors.orange[900],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  DesignIcons.chevronRight,
                  size: 14,
                  color: isDark ? Colors.orange[200] : Colors.orange[900],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}
