import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: DesignTypography.metadata(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: DesignColors.textTertiary(context),
        ),
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  final AppThemeType themeType;
  final WidgetRef ref;

  const ThemeSelector({
    super.key,
    required this.themeType,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (AppThemeType.system, Icons.brightness_auto_rounded, 'System', const Color(0xFF888888)),
      (AppThemeType.light, Icons.light_mode_outlined, 'Paper', const Color(0xFFC8A97E)),
      (AppThemeType.dark, Icons.dark_mode_outlined, 'Dusk', const Color(0xFFE07A5F)),
      (AppThemeType.sepia, Icons.auto_stories_outlined, 'Sepia', const Color(0xFF5C3D2E)),
      (AppThemeType.forest, Icons.forest_outlined, 'Forest', const Color(0xFF81B29A)),
      (AppThemeType.slate, Icons.water_outlined, 'Slate', const Color(0xFF7DAFE8)),
      (AppThemeType.arctic, Icons.ac_unit_outlined, 'Arctic', const Color(0xFF3A8FA8)),
      (AppThemeType.noir, Icons.movie_creation_outlined, 'Noir', const Color(0xFFC9A84C)),
      (AppThemeType.blush, Icons.favorite_border_rounded, 'Blush', const Color(0xFFB0637A)),
    ];

    // Split into three rows of 3
    final rows = [
      options.sublist(0, 3),
      options.sublist(3, 6),
      options.sublist(6, 9),
    ];

    Widget buildChip(
      (AppThemeType, IconData, String, Color) opt,
    ) {
      final isSelected = themeType == opt.$1;
      final primaryColor = DesignColors.primary(context);
      final accentColor = opt.$4;

      return TactileWrapper(
        style: TactileFeedbackStyle.standard,
        onTap: () => ref.read(themeProvider.notifier).setTheme(opt.$1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : DesignColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : DesignColors.border(context),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.7) : accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    opt.$2,
                    size: 15,
                    color: isSelected ? Colors.white : DesignColors.textSecondary(context),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                opt.$3,
                style: DesignTypography.metadata(
                  context,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : DesignColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: rows.asMap().entries.map((rowEntry) {
          final isLastRow = rowEntry.key == rows.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLastRow ? 0 : 6),
            child: Row(
              children: rowEntry.value.asMap().entries.map((cellEntry) {
                final isLastCell = cellEntry.key == rowEntry.value.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLastCell ? 0 : 6),
                    child: buildChip(cellEntry.value),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );

  }
}


class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DesignColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: DesignColors.textSecondary(context),
          ),
        ),
        title: Text(
          title,
          style: DesignTypography.body(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: DesignTypography.details(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}

class ProGateTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProGateTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = DesignColors.primary(context);

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start your 14-day free trial to unlock this feature',
              style: DesignTypography.body(context, color: Colors.white),
            ),
            action: SnackBarAction(
              label: 'Try Pro',
              onPressed: () {},
            ),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: DesignTypography.body(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PRO',
                style: DesignTypography.metadata(
                  context,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: DesignTypography.details(context),
        ),
        trailing: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
      ),
    );
  }
}

class HapticToggleTile extends ConsumerWidget {
  const HapticToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          hapticsEnabled ? Icons.vibration_rounded : Icons.portable_wifi_off_rounded,
          size: 18,
          color: DesignColors.textSecondary(context),
        ),
      ),
      title: Text(
        'Haptic Feedback',
        style: DesignTypography.body(
          context,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Vibrate on satisfying button presses and interactions',
        style: DesignTypography.details(context),
      ),
      value: hapticsEnabled,
      activeThumbColor: DesignColors.primary(context),
      onChanged: (val) {
        ref.read(hapticsEnabledProvider.notifier).setHapticsEnabled(val);
      },
    );
  }
}
