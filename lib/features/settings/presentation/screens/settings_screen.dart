import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/export_bottom_sheet.dart';
import '../../../onboarding/data/tutorial_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
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
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // ── Prism Pro Banner (Free users only) ─────────────────────────
                if (!isPro)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Prism Pro',
                                style: DesignTypography.heading(context, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Unlock cloud sync, custom templates & macros, and premium typography & themes.',
                            style: DesignTypography.body(context, fontSize: 12.5, color: DesignColors.textSecondary(context)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.push('/settings/paywall'),
                            child: Text('Upgrade to Pro', style: DesignTypography.body(context, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                // ── Appearance ───────────────────────────────────────────
                const SettingsSectionHeader(title: 'Appearance'),
                ThemeSelector(themeType: themeType, ref: ref),
                SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Font family',
                  subtitle: fontFamily == 'Inter (Sans)' ? 'Inter (Sans) (Default)' : fontFamily,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showFontSelector(
                    context: context,
                    ref: ref,
                    title: 'Select Font Family',
                    options: ['Inter (Sans)', 'Roboto Mono (Mono)', 'Lora (Serif)', 'Merriweather (Serif)'],
                    optionLabels: {
                      'Inter (Sans)': 'Inter (Sans) (Default)',
                    },
                    currentValue: fontFamily,
                    onSelected: (val) => ref.read(fontFamilyProvider.notifier).setFontFamily(val),
                  ),
                ),

                // ── Preferences ──────────────────────────────────────────
                const SettingsSectionHeader(title: 'Preferences'),
                SettingsTile(
                  icon: Icons.edit_note_rounded,
                  title: 'Editor Preferences',
                  subtitle: 'Font size, line width, line numbers, and auto-pairing',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/editor-preferences'),
                ),
                SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'Journal Preferences',
                  subtitle: 'Start of week and auto-creation settings',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/journal-preferences'),
                ),
                ProGateTile(
                  icon: Icons.keyboard_command_key_rounded,
                  title: 'Custom Toolbar Macros',
                  subtitle: 'Define 3–5 custom quick-insert macros',
                  onTap: () => context.push('/settings/custom-macros'),
                ),
                ProGateTile(
                  icon: Icons.note_add_rounded,
                  title: 'Custom Templates',
                  subtitle: 'Create reusable note templates',
                  onTap: () => context.push('/settings/custom-templates'),
                ),
                SettingsTile(
                  icon: Icons.audio_file_rounded,
                  title: 'Manage Attachments',
                  subtitle: 'View and delete audio attachments',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/attachments'),
                ),

                // ── Sync & Data ─────────────────────────────────────────
                const SettingsSectionHeader(title: 'Sync & Data'),
                ProGateTile(
                  icon: Icons.sync_rounded,
                  title: 'Cloud Sync',
                  subtitle: 'Google Drive sync, backups, and security',
                  onTap: () => context.push('/settings/cloud-sync'),
                ),
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Vault Export',
                  subtitle: 'Download all notes as ZIP, PDF or JSON',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ExportBottomSheet(),
                  ),
                ),
                SettingsTile(
                  icon: Icons.folder_open_outlined,
                  title: 'Manage Vaults',
                  subtitle: 'Switch vaults, check stats, or change Hub location',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/manage-vaults'),
                ),

                // ── Gestures & Feedback ──────────────────────────────────
                const SettingsSectionHeader(title: 'Gestures & Feedback'),
                const HapticToggleTile(),
                const DragToPinToggleTile(),
                const AnalyticsToggleTile(),

                // ── Pro Settings Management (Pro only) ──────────────────────
                if (isPro) ...[
                  const SettingsSectionHeader(title: 'Subscription'),
                  SettingsTile(
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
                  ),
                ],

                // ── About ──────────────────────────────────────────────
                const SettingsSectionHeader(title: 'About'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSelector({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<String> options,
    Map<String, String>? optionLabels,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    final isPro = ref.read(isProProvider);

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
                      final isLocked = val != 'Inter (Sans)' && !isPro;

                      return TactileWrapper(
                        style: TactileFeedbackStyle.standard,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (isLocked) {
                            context.push('/settings/paywall');
                          } else {
                            onSelected(val);
                          }
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
                              : isLocked
                                  ? Icon(Icons.lock_outline_rounded, size: 16, color: DesignColors.textTertiary(context))
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
}
