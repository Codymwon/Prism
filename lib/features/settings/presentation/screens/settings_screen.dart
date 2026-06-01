import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database_helper.dart';
import '../../../notes/data/note_repository.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final themeType = ref.watch(themeProvider);

    // Watch our newly created settings providers
    final fontFamily = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final lineWidth = ref.watch(lineWidthProvider);
    final baseVaultsDir = ref.watch(baseVaultsDirectoryProvider);

    return Scaffold(
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
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
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
            Expanded(
              child: ListView(
                children: [
                  // ── Appearance ───────────────────────────────────────────
                  _SectionHeader(title: 'Appearance', isDark: isDark),
                  _ThemeSelector(themeType: themeType, ref: ref, isDark: isDark, colorScheme: colorScheme),

                  // ── Gestures & Feedback ──────────────────────────────────
                  _SectionHeader(title: 'Gestures & Feedback', isDark: isDark),
                  _HapticToggleTile(isDark: isDark, colorScheme: colorScheme),

                  // ── Editor ────────────────────────────────────────────────
                  _SectionHeader(title: 'Editor', isDark: isDark),
                  _SettingsTile(
                    icon: Icons.text_fields_rounded,
                    title: 'Font family',
                    subtitle: fontFamily,
                    isDark: isDark,
                    colorScheme: colorScheme,
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
                    isDark: isDark,
                    colorScheme: colorScheme,
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
                    isDark: isDark,
                    colorScheme: colorScheme,
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
                  _SectionHeader(title: 'Sync', isDark: isDark),
                  _ProGateTile(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Google Drive Sync',
                    subtitle: 'Sync your vault to Google Drive',
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),

                  // ── Data ─────────────────────────────────────────────────
                  _SectionHeader(title: 'Data', isDark: isDark),
                  _ProGateTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export vault',
                    subtitle: 'Download all notes as ZIP or PDF',
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  _SettingsTile(
                    icon: Icons.folder_open_outlined,
                    title: 'Base Vaults Location',
                    subtitle: baseVaultsDir.isEmpty ? 'Loading...' : baseVaultsDir,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => _changeBaseVaultsDirectory(context, ref),
                  ),

                  // ── About ──────────────────────────────────────────────
                  _SectionHeader(title: 'About', isDark: isDark),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    subtitle: '1.0.0',
                    isDark: isDark,
                    colorScheme: colorScheme,
                    trailing: const SizedBox.shrink(),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Meridian v1.0.0 — private offline notebook.')),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    subtitle: 'All data stays on your device',
                    isDark: isDark,
                    colorScheme: colorScheme,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MeridianColors.darkBackground : MeridianColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (c, idx) {
                    final val = options[idx];
                    final isSelected = val == currentValue;

                    return ListTile(
                      title: Text(
                        val,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check_rounded, color: colorScheme.primary) : null,
                      onTap: () {
                        onSelected(val);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeBaseVaultsDirectory(BuildContext context, WidgetRef ref) async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) return;

      // Close database helper connection first
      await DatabaseHelper.instance.closeDatabase();

      // Update base vaults directory provider (saves to SharedPreferences)
      await ref.read(baseVaultsDirectoryProvider.notifier).setDirectory(path);

      // Find if there are existing vaults
      final dir = Directory(path);
      List<String> vaults = [];
      if (dir.existsSync()) {
        vaults = dir.listSync()
            .whereType<Directory>()
            .map((d) => p.basename(d.path))
            .where((name) => !name.startsWith('.'))
            .toList();
      }

      String activeVault = 'My Vault';
      if (vaults.isNotEmpty) {
        activeVault = vaults.first;
      } else {
        // Create a default vault folder inside the new directory
        final newVaultPath = p.join(path, activeVault);
        final vaultDir = Directory(newVaultPath);
        if (!vaultDir.existsSync()) vaultDir.createSync(recursive: true);

        // Initialize starter notes inside it
        final welcomeFile = File(p.join(newVaultPath, 'welcome.md'));
        await welcomeFile.writeAsString('# Welcome to Meridian\n\nNotes configured at new location.');
      }

      // Update active vault name provider
      await ref.read(activeVaultNameProvider.notifier).setVaultName(activeVault);

      // Invalidate notes list and folders list so they reconnect and refresh
      ref.invalidate(notesProvider);

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
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppThemeType themeType;
  final WidgetRef ref;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ThemeSelector({
    required this.themeType,
    required this.ref,
    required this.isDark,
    required this.colorScheme,
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
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).setTheme(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : (isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : (isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$2,
                        size: 18,
                        color: isSelected ? colorScheme.onPrimary : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opt.$3,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? colorScheme.onPrimary : (isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
                        ),
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
  final bool isDark;
  final ColorScheme colorScheme;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.colorScheme,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _ProGateTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ProGateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: colorScheme.primary),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PRO',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
      ),
      trailing: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start your 14-day free trial to unlock this feature',
              style: GoogleFonts.inter(),
            ),
            action: SnackBarAction(
              label: 'Try Pro',
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }
}

class _HapticToggleTile extends ConsumerWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _HapticToggleTile({
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          hapticsEnabled ? Icons.vibration_rounded : Icons.portable_wifi_off_rounded,
          size: 18,
          color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
        ),
      ),
      title: Text(
        'Haptic Feedback',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
        ),
      ),
      subtitle: Text(
        'Vibrate on satisfying button presses and interactions',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
        ),
      ),
      value: hapticsEnabled,
      activeThumbColor: colorScheme.primary,
      onChanged: (val) {
        ref.read(hapticsEnabledProvider.notifier).setHapticsEnabled(val);
      },
    );
  }
}

