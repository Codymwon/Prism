import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';

class JournalEmptyIllustration extends StatelessWidget {
  final bool isFuture;
  final ColorScheme colorScheme;

  const JournalEmptyIllustration({
    super.key,
    required this.isFuture,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = colorScheme.primary;
    final accentColor = DesignColors.accentAmber(context);

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  baseColor.withValues(alpha: 0.12),
                  baseColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.25),
                width: 1.2,
              ),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: DesignColors.surface(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignColors.border(context),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isFuture ? Icons.calendar_month_rounded : Icons.edit_note_rounded,
              size: 30,
              color: baseColor,
            ),
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
        ],
      ),
    );
  }
}
