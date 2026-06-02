import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import 'journal_template_button.dart';

class JournalTemplatesRow extends StatelessWidget {
  final Function(String emoji, String templateName) onTemplateSelected;

  const JournalTemplatesRow({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final templates = [
      const JournalTemplateItem(
        icon: DesignIcons.gratitude,
        label: 'Gratitude',
        emoji: '🙏',
        baseColor: MeridianColors.darkAccentRose,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.dailyPlan,
        label: 'Daily Plan',
        emoji: '📋',
        baseColor: MeridianColors.darkAccentGreen,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.reflection,
        label: 'Reflection',
        emoji: '💭',
        baseColor: MeridianColors.darkAccentAmber,
      ),
      const JournalTemplateItem(
        icon: DesignIcons.goals,
        label: 'Goals',
        emoji: '🎯',
        baseColor: Color(0xFF8AB4F8),
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
              onTap: () => onTemplateSelected(t.emoji, t.label),
              child: JournalTemplateButton(template: t),
            ),
          );
        },
      ),
    );
  }
}
