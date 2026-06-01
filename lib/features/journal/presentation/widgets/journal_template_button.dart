import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';

class JournalTemplateItem {
  final IconData icon;
  final String label;
  final String emoji;
  final Color baseColor;

  const JournalTemplateItem({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.baseColor,
  });
}

class JournalTemplateButton extends StatelessWidget {
  final JournalTemplateItem template;

  const JournalTemplateButton({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBgColor = DesignColors.surface(context);
    final baseBorderColor = DesignColors.border(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: template.baseColor.withValues(alpha: isDark ? 0.04 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: template.baseColor.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              template.icon,
              size: 13,
              color: template.baseColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            template.label,
            style: DesignTypography.heading(
              context,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
