import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/vault_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../../../onboarding/data/tutorial_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    // Watch settings providers (AsyncNotifier — unwrap with valueOrNull + default)
    final fontFamily = ref.watch(fontFamilyProvider).valueOrNull ?? 'Inter (Sans)';
    final fontSize = ref.watch(fontSizeProvider).valueOrNull ?? '16pt';
    final lineWidth = ref.watch(lineWidthProvider).valueOrNull ?? 'Comfortable';
    final baseVaultsDir = ref.watch(baseVaultsDirectoryProvider).valueOrNull ?? '';

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
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
                  const SettingsSectionHeader(title: 'Appearance'),
                  ThemeSelector(themeType: themeType, ref: ref),

                  // ── Gestures & Feedback ──────────────────────────────────
                  const SettingsSectionHeader(title: 'Gestures & Feedback'),
                  const HapticToggleTile(),
                  SettingsTile(
                    icon: Icons.explore_outlined,
                    title: 'Replay interactive tutorial',
                    subtitle: 'Walk through the core features of Meridian',
                    trailing: const Icon(Icons.refresh_rounded, size: 20),
                    onTap: () async {
                      await ref.read(tutorialStateProvider.notifier).resetTutorial();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Interactive walkthrough reset! Returning home to start.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        context.go('/notes');
                      }
                    },
                  ),

                  // ── Editor ────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Editor'),
                  SettingsTile(
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
                  SettingsTile(
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
                  SettingsTile(
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
                  const SettingsSectionHeader(title: 'Sync'),
                  const ProGateTile(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Google Drive Sync',
                    subtitle: 'Sync your vault to Google Drive',
                  ),

                  // ── Data ─────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Data'),
                  const ProGateTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export vault',
                    subtitle: 'Download all notes as ZIP or PDF',
                  ),
                  SettingsTile(
                    icon: Icons.folder_open_outlined,
                    title: 'Base Vaults Location',
                    subtitle: baseVaultsDir.isEmpty ? 'Loading...' : baseVaultsDir,
                    onTap: () => _changeBaseVaultsDirectory(context, ref),
                  ),

                  // ── About ──────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'About'),
                  SettingsTile(
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
                  SettingsTile(
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
