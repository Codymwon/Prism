import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    // 1. Core modes
    final coreModes = [
      (AppThemeType.system, 'System Sync'),
      (AppThemeType.light, 'Clean Paper'),
      (AppThemeType.dark, 'Dusk Dark'),
    ];

    // 2. Light Editorial Themes
    final lightEditorials = [
      (AppThemeType.sepia, 'Sepia', 'Lora', const Color(0xFF5C3D2E), const Color(0xFFFAF6EE), const Color(0xFF2A1F19)),
      (AppThemeType.arctic, 'Arctic', 'Inter', const Color(0xFF3A8FA8), const Color(0xFFF4F8FB), const Color(0xFF152632)),
      (AppThemeType.blush, 'Blush', 'Inter', const Color(0xFFB0637A), const Color(0xFFFDF8F8), const Color(0xFF2E1F24)),
    ];

    // 3. Dark Editorial Themes
    final darkEditorials = [
      (AppThemeType.forest, 'Forest', 'Inter', const Color(0xFF81B29A), const Color(0xFF141C18), const Color(0xFFDEEDE5)),
      (AppThemeType.slate, 'Slate', 'Inter', const Color(0xFF7DAFE8), const Color(0xFF0F1117), const Color(0xFFE4EAF5)),
      (AppThemeType.noir, 'Noir', 'Inter', const Color(0xFFC9A84C), const Color(0xFF111110), const Color(0xFFF0EDE6)),
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
                      onTap: () => ref.read(themeProvider.notifier).setTheme(mode.$1),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Light Editorial Themes Heading ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'LIGHT EDITORIAL THEMES',
              style: DesignTypography.metadata(
                context,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: DesignColors.textTertiary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal scroll of Light Editorial themes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: lightEditorials.map((theme) {
                final isSelected = themeType == theme.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _EditorialThemeCard(
                    name: theme.$2,
                    fontFamily: theme.$3,
                    primaryColor: theme.$4,
                    backgroundColor: theme.$5,
                    textColor: theme.$6,
                    isSelected: isSelected,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(theme.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Dark Editorial Themes Heading ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'DARK EDITORIAL THEMES',
              style: DesignTypography.metadata(
                context,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: DesignColors.textTertiary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal scroll of Dark Editorial themes
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: darkEditorials.map((theme) {
                final isSelected = themeType == theme.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _EditorialThemeCard(
                    name: theme.$2,
                    fontFamily: theme.$3,
                    primaryColor: theme.$4,
                    backgroundColor: theme.$5,
                    textColor: theme.$6,
                    isSelected: isSelected,
                    onTap: () => ref.read(themeProvider.notifier).setTheme(theme.$1),
                  ),
                );
              }).toList(),
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? DesignColors.primary(context) : DesignColors.surface(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                )
              ],
            ),
            child: Icon(
              Icons.brightness_auto_rounded,
              size: 13,
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
              top: 6,
              left: 6,
              child: Icon(Icons.light_mode_outlined, size: 13, color: isSelected ? const Color(0xFFC8A97E) : Colors.grey),
            ),
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFECE7DE), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 2),
                  Container(width: 28, height: 2, decoration: BoxDecoration(color: const Color(0xFFECE7DE), borderRadius: BorderRadius.circular(1))),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 6,
              child: Container(
                width: 6,
                height: 6,
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
              top: 6,
              left: 6,
              child: Icon(Icons.dark_mode_outlined, size: 13, color: isSelected ? const Color(0xFFE07A5F) : Colors.grey),
            ),
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(1))),
                  const SizedBox(height: 2),
                  Container(width: 28, height: 2, decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(1))),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              right: 6,
              child: Container(
                width: 6,
                height: 6,
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
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentBorderColor,
                width: isSelected ? 2.0 : 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: DesignColors.primary(context).withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: mockup,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? DesignColors.primary(context) : DesignColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialThemeCard extends StatelessWidget {
  final String name;
  final String fontFamily;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditorialThemeCard({
    required this.name,
    required this.fontFamily,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle;
    if (fontFamily == 'Lora') {
      textStyle = GoogleFonts.lora(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: textColor,
      );
    } else {
      textStyle = GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: textColor,
      );
    }

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 106,
        height: 60,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryColor : DesignColors.border(context),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                name,
                style: textStyle,
              ),
            ),
            // Triple-color dots in bottom left
            Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                height: 10,
                width: 22,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: textColor.withValues(alpha: 0.25), width: 0.8),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 5,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: textColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: backgroundColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: backgroundColor.withValues(alpha: 0.4), width: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Accent dot/indicator in bottom right
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 0.8),
                ),
              ),
            ),
          ],
        ),
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
