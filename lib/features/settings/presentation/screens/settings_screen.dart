import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/vault_service.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    // Watch settings providers
    final fontFamily = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final lineWidth = ref.watch(lineWidthProvider);
    final baseVaultsDir = ref.watch(baseVaultsDirectoryProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: DesignTypography.display(
                      context,
                      color: DesignColors.text(context),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
            Expanded(
              child: ListView(
                children: [
                  // ── Appearance ───────────────────────────────────────────
                  const _SectionHeader(title: 'Appearance'),
                  _ThemeSelector(themeType: themeType, ref: ref),

                  // ── Gestures & Feedback ──────────────────────────────────
                  const _SectionHeader(title: 'Gestures & Feedback'),
                  const _HapticToggleTile(),

                  // ── Editor ────────────────────────────────────────────────
                  const _SectionHeader(title: 'Editor'),
                  _SettingsTile(
                    icon: Icons.text_fields_rounded,
                    title: 'Font family',
                    subtitle: fontFamily,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Font Family',
                      options: ['Inter (Sans)', 'Roboto Mono (Mono)', 'Lora (Serif)', 'Merriweather (Serif)'],
                      currentValue: fontFamily,
                      onSelected: (val) => ref.read(fontFamilyProvider.notifier).setFontFamily(val),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.format_size_rounded,
                    title: 'Font size',
                    subtitle: fontSize,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Font Size',
                      options: ['12pt', '14pt', '16pt', '18pt', '20pt'],
                      currentValue: fontSize,
                      onSelected: (val) => ref.read(fontSizeProvider.notifier).setFontSize(val),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.wrap_text_rounded,
                    title: 'Line width',
                    subtitle: lineWidth,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Line Width',
                      options: ['Narrow', 'Comfortable', 'Wide'],
                      currentValue: lineWidth,
                      onSelected: (val) => ref.read(lineWidthProvider.notifier).setLineWidth(val),
                    ),
                  ),

                  // ── Sync ────────────────────────────────────────────────
                  const _SectionHeader(title: 'Sync'),
                  const _ProGateTile(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Google Drive Sync',
                    subtitle: 'Sync your vault to Google Drive',
                  ),

                  // ── Data ─────────────────────────────────────────────────
                  const _SectionHeader(title: 'Data'),
                  const _ProGateTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export vault',
                    subtitle: 'Download all notes as ZIP or PDF',
                  ),
                  _SettingsTile(
                    icon: Icons.folder_open_outlined,
                    title: 'Base Vaults Location',
                    subtitle: baseVaultsDir.isEmpty ? 'Loading...' : baseVaultsDir,
                    onTap: () => _changeBaseVaultsDirectory(context, ref),
                  ),

                  // ── About ──────────────────────────────────────────────
                  const _SectionHeader(title: 'About'),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    subtitle: '1.0.0',
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meridian v1.0.0 — private offline notebook.')),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    subtitle: 'All data stays on your device',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Standard Offline Privacy: 100% of your notes remain securely on this physical device.')),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionSelector({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const DesignSheetDragHandle(),
                Text(
                  title,
                  style: DesignTypography.heading(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (c, idx) {
                      final val = options[idx];
                      final isSelected = val == currentValue;

                      return TactileWrapper(
                        style: TactileFeedbackStyle.standard,
                        onTap: () {
                          onSelected(val);
                          Navigator.pop(ctx);
                        },
                        child: ListTile(
                          title: Text(
                            val,
                            style: DesignTypography.body(
                              context,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_rounded, color: DesignColors.primary(context))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeBaseVaultsDirectory(BuildContext context, WidgetRef ref) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) return;

      await ref.read(vaultServiceProvider).changeBaseDirectory(newPath: path, ref: ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage directory changed to: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing storage location: $e')),
        );
      }
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

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

class _ThemeSelector extends StatelessWidget {
  final AppThemeType themeType;
  final WidgetRef ref;

  const _ThemeSelector({
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
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

class _ProGateTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProGateTile({
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

class _HapticToggleTile extends ConsumerWidget {
  const _HapticToggleTile();

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

