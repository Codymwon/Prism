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
import '../../../subscription/presentation/providers/subscription_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);

    // Watch settings providers (StateNotifier)
    final fontFamily = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final lineWidth = ref.watch(lineWidthProvider);
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
                  SettingsTile(
                    icon: Icons.text_fields_rounded,
                    title: 'Font family',
                    subtitle: fontFamily == 'Inter (Sans)' ? 'Inter (Sans) (Default)' : fontFamily,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Font Family',
                      options: ['Inter (Sans)', 'Roboto Mono (Mono)', 'Lora (Serif)', 'Merriweather (Serif)'],
                      optionLabels: {
                        'Inter (Sans)': 'Inter (Sans) (Default)',
                      },
                      currentValue: fontFamily,
                      onSelected: (val) => ref.read(fontFamilyProvider.notifier).setFontFamily(val),
                    ),
                  ),

                  // ── Gestures & Feedback ──────────────────────────────────
                  const SettingsSectionHeader(title: 'Gestures & Feedback'),
                  const HapticToggleTile(),
                  SettingsTile(
                    icon: Icons.explore_outlined,
                    title: 'Replay interactive tutorial',
                    subtitle: 'Walk through the core features of Prism',
                    trailing: const Icon(Icons.refresh_rounded, size: 20),
                    onTap: () async {
                      await ref.read(tutorialStateProvider.notifier).resetTutorial();
                      await ref.read(editorTutorialStateProvider.notifier).resetTutorial();
                      await ref.read(journalTutorialStateProvider.notifier).resetTutorial();
                      if (context.mounted) {
                        context.go('/notes');
                      }
                    },
                  ),

                  // ── Editor ────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Editor'),
                  SettingsTile(
                    icon: Icons.format_size_rounded,
                    title: 'Font size',
                    subtitle: fontSize == '16pt' ? '16pt (Default)' : fontSize,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Font Size',
                      options: ['12pt', '14pt', '16pt', '18pt', '20pt'],
                      optionLabels: {
                        '16pt': '16pt (Default)',
                      },
                      currentValue: fontSize,
                      onSelected: (val) => ref.read(fontSizeProvider.notifier).setFontSize(val),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.wrap_text_rounded,
                    title: 'Line width',
                    subtitle: lineWidth == 'Comfortable' ? 'Comfortable (Default)' : lineWidth,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: 'Select Line Width',
                      options: ['Narrow', 'Comfortable', 'Wide'],
                      optionLabels: {
                        'Comfortable': 'Comfortable (Default)',
                      },
                      currentValue: lineWidth,
                      onSelected: (val) => ref.read(lineWidthProvider.notifier).setLineWidth(val),
                    ),
                  ),
                  ProGateTile(
                    icon: Icons.keyboard_command_key_rounded,
                    title: 'Custom Toolbar Macros',
                    subtitle: 'Define 3–5 custom quick-insert macros',
                    onTap: () => context.push('/settings/custom-macros'),
                  ),
                  const VoiceRecordingsToggleTile(),
                  SettingsTile(
                    icon: Icons.audio_file_rounded,
                    title: 'Manage Attachments',
                    subtitle: 'View and delete voice dictation files',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/attachments'),
                  ),

                  // ── Sync ────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Sync'),
                  SettingsTile(
                    icon: Icons.sync_rounded,
                    title: 'Backup & Sync',
                    subtitle: 'Google Drive sync, vault export, and more',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/backup-and-sync'),
                  ),

                  // ── Subscription ──────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Subscription'),
                  ref.watch(isProProvider)
                      ? SettingsTile(
                          icon: Icons.star_rounded,
                          title: 'Prism Pro Active',
                          subtitle: 'Manage subscription & billing',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final result = await ref.read(subscriptionRepositoryProvider).presentCustomerCenter();
                            result.fold(
                              (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to open Customer Center: ${failure.message}'),
                                  ),
                                );
                              },
                              (_) {},
                            );
                          },
                        )
                      : SettingsTile(
                          icon: Icons.star_outline_rounded,
                          title: 'Try Prism Pro',
                          subtitle: 'Unlock sync, custom templates & macros',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/settings/paywall'),
                        ),

                  // ── Data ─────────────────────────────────────────────────
                  const SettingsSectionHeader(title: 'Data'),
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
                        const SnackBar(content: Text('Prism v1.0.0 — private offline notebook.')),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    subtitle: 'All data stays on your device',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings/privacy-policy'),
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
    Map<String, String>? optionLabels,
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
                      final displayLabel = optionLabels?[val] ?? val;
                      final isSelected = val == currentValue;

                      return TactileWrapper(
                        style: TactileFeedbackStyle.standard,
                        onTap: () {
                          Navigator.pop(ctx);
                          onSelected(val);
                        },
                        child: ListTile(
                          title: Text(
                            displayLabel,
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

      await ref.read(vaultManagementServiceProvider).changeBaseDirectory(newPath: path, ref: ref);

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
