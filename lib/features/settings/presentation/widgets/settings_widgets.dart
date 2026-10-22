import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import 'package:prism/l10n/l10n.dart';

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
    final isPro = ref.watch(isProProvider);
    // 1. Core modes
    final coreModes = [
      (AppThemeType.system, context.l10n.settings_widgets_theme_system),
      (AppThemeType.light, context.l10n.settings_widgets_theme_light),
      (AppThemeType.dark, context.l10n.settings_widgets_theme_dark),
    ];

    // Overlapping visual circles representing editorial theme colors
    final editorialTeaserColors = [
      const Color(0xFF5C3D2E), // Sepia
      const Color(0xFF3A8FA8), // Arctic
      const Color(0xFFB0637A), // Blush
      const Color(0xFF81B29A), // Forest
      const Color(0xFFC9A84C), // Noir
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Core Themes Row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: coreModes.map((mode) {
                final isSelected = themeType == mode.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _CoreThemeCard(
                      type: mode.$1,
                      title: mode.$2,
                      isSelected: isSelected,
                      onTap: () => ref.read(themeStateProvider.notifier).setTheme(mode.$1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Theme Gallery Teaser Card ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: () => context.push('/settings/theme-gallery'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: DesignColors.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignColors.border(context),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Interlocking colorful circles represent theme gallery
                    SizedBox(
                      width: 32,
                      height: 24,
                      child: Stack(
                        children: List.generate(editorialTeaserColors.length, (idx) {
                          return Positioned(
                            left: idx * 5.0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: editorialTeaserColors[idx],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: DesignColors.background(context),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.settings_widgets_theme_explore_teaser,
                            style: DesignTypography.body(
                              context,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.settings_widgets_theme_teaser_list,
                            style: DesignTypography.details(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isPro) ...[
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: DesignColors.primary(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: DesignColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CoreThemeCard extends StatelessWidget {
  final AppThemeType type;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CoreThemeCard({
    required this.type,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget mockup;
    if (type == AppThemeType.system) {
      mockup = Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(child: Container(color: const Color(0xFFFAF8F4))),
              Expanded(child: Container(color: const Color(0xFF1C1C1E))),
            ],
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isSelected ? DesignColors.primary(context) : DesignColors.surface(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  spreadRadius: 0.5,
                )
              ],
            ),
            child: Icon(
              Icons.brightness_auto_rounded,
              size: 9,
              color: isSelected ? Colors.white : DesignColors.textSecondary(context),
            ),
          ),
        ],
      );
    } else if (type == AppThemeType.light) {
      mockup = Container(
        color: const Color(0xFFFAF8F4),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.light_mode_outlined, size: 9, color: isSelected ? const Color(0xFFC8A97E) : Colors.grey),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 1.2, decoration: BoxDecoration(color: const Color(0xFFECE7DE), borderRadius: BorderRadius.circular(0.5))),
                  const SizedBox(height: 1.5),
                  Container(width: 16, height: 1.2, decoration: BoxDecoration(color: const Color(0xFFECE7DE), borderRadius: BorderRadius.circular(0.5))),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8A97E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      mockup = Container(
        color: const Color(0xFF1C1C1E),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.dark_mode_outlined, size: 9, color: isSelected ? const Color(0xFFE07A5F) : Colors.grey),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 1.2, decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(0.5))),
                  const SizedBox(height: 1.5),
                  Container(width: 16, height: 1.2, decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(0.5))),
                ],
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFE07A5F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final accentBorderColor = isSelected
        ? DesignColors.primary(context)
        : DesignColors.border(context);

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentBorderColor,
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DesignColors.primary(context).withValues(alpha: 0.15),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: mockup,
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: DesignTypography.metadata(
              context,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? DesignColors.primary(context) : DesignColors.textSecondary(context),
            ),
          ),
        ],
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
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? textColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.textColor,
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
            color: iconBackgroundColor ?? DesignColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? DesignColors.textSecondary(context),
          ),
        ),
        title: Text(
          title,
          style: DesignTypography.body(
            context,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
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

class ProGateTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ProGateTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = DesignColors.primary(context);
    final isPro = ref.watch(isProProvider);

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () {
        if (!isPro) {
          context.push('/settings/paywall');
        } else {
          if (onTap != null) {
            onTap!();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.settings_widgets_coming_soon(title)),
              ),
            );
          }
        }
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
            if (!isPro) ...[
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
          ],
        ),
        subtitle: Text(
          subtitle,
          style: DesignTypography.details(context),
        ),
        trailing: Icon(
          isPro ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
          size: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class HapticToggleTile extends ConsumerWidget {
  const HapticToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier — unwrap safely; default true (haptics on)
    final hapticsEnabled = ref.watch(hapticsEnabledProvider).valueOrNull ?? true;

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
        context.l10n.settings_widgets_haptic_feedback,
        style: DesignTypography.body(
          context,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        context.l10n.settings_widgets_haptic_feedback_desc,
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

class DragToPinToggleTile extends ConsumerWidget {
  const DragToPinToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragToPinEnabled = ref.watch(dragToPinEnabledProvider).valueOrNull ?? false;

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
          Icons.hub_outlined,
          size: 18,
          color: DesignColors.textSecondary(context),
        ),
      ),
      title: Text(
        context.l10n.settings_widgets_pin_nodes,
        style: DesignTypography.body(
          context,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        context.l10n.settings_widgets_pin_nodes_desc,
        style: DesignTypography.details(context),
      ),
      value: dragToPinEnabled,
      activeThumbColor: DesignColors.primary(context),
      onChanged: (val) {
        ref.read(dragToPinEnabledProvider.notifier).setDragToPinEnabled(val);
      },
    );
  }
}

class AnalyticsToggleTile extends ConsumerWidget {
  const AnalyticsToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsEnabled = ref.watch(analyticsEnabledProvider).valueOrNull ?? false;

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
          Icons.analytics_outlined,
          size: 18,
          color: DesignColors.textSecondary(context),
        ),
      ),
      title: Text(
        context.l10n.settings_widgets_analytics,
        style: DesignTypography.body(
          context,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        context.l10n.settings_widgets_analytics_desc,
        style: DesignTypography.details(context),
      ),
      value: analyticsEnabled,
      activeThumbColor: DesignColors.primary(context),
      onChanged: (val) {
        ref.read(analyticsEnabledProvider.notifier).setEnabled(val);
      },
    );
  }
}



