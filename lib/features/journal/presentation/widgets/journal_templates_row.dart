import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import 'journal_template_button.dart';
import 'package:prism/l10n/l10n.dart';

class JournalTemplatesRow extends StatelessWidget {
  final Function(String templateName) onTemplateSelected;

  const JournalTemplatesRow({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      JournalTemplateItem(
        icon: DesignIcons.gratitude,
        label: context.l10n.journal_templates_row_gratitude,
        emoji: '🙏',
        baseColor: PrismColors.darkAccentRose,
      ),
      JournalTemplateItem(
        icon: DesignIcons.dailyPlan,
        label: context.l10n.journal_templates_row_daily_plan,
        emoji: '📋',
        baseColor: PrismColors.darkAccentGreen,
      ),
      JournalTemplateItem(
        icon: DesignIcons.reflection,
        label: context.l10n.journal_templates_row_reflection,
        emoji: '💭',
        baseColor: PrismColors.darkAccentAmber,
      ),
      JournalTemplateItem(
        icon: DesignIcons.goals,
        label: context.l10n.journal_templates_row_goals,
        emoji: '🎯',
        baseColor: const Color(0xFF8AB4F8),
      ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final t = templates[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TactileWrapper(
              style: TactileFeedbackStyle.highImpact,
              onTap: () => onTemplateSelected(t.label),
              child: JournalTemplateButton(template: t),
            ),
          );
        },
      ),
    );
  }
}