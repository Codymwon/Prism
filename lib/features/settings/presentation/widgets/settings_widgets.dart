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
      (AppThemeType.system, Icons.brightness_auto_rounded, 'System'),
      (AppThemeType.light, Icons.light_mode_outlined, 'Paper'),
      (AppThemeType.dark, Icons.dark_mode_outlined, 'OLED'),
      (AppThemeType.sepia, Icons.auto_stories_outlined, 'Sepia'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: options.map((opt) {
          final isSelected = themeType == opt.$1;
          final primaryColor = DesignColors.primary(context);
          final textStyle = DesignTypography.metadata(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : DesignColors.textSecondary(context),
          );

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: () => ref.read(themeProvider.notifier).setTheme(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : DesignColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : DesignColors.border(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$2,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : DesignColors.textSecondary(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt.$3,
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
              ),
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
