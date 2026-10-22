import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../shared/widgets/prism_toast.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../../../onboarding/data/tutorial_provider.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/services/data_deletion_service.dart';
import 'package:prism/l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeStateProvider);
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
                    context.l10n.settings_main_title,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
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
                              Icon(Icons.diamond_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.settings_main_pro_tile_title,
                                style: DesignTypography.heading(context, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.settings_main_pro_tile_desc,
                            style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.push('/settings/paywall'),
                            child: Text(context.l10n.settings_main_pro_tile_upgrade_button, style: DesignTypography.body(context, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Appearance ───────────────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_appearance),
                ThemeSelector(themeType: themeType, ref: ref),
                SettingsTile(
                  icon: Icons.text_fields_rounded,
                  title: context.l10n.settings_main_appearance_font_family,
                  subtitle: fontFamily == 'Inter (Sans)' ? context.l10n.settings_main_appearance_font_family_default(fontFamily) : fontFamily,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showFontSelector(
                    context: context,
                    ref: ref,
                    title: context.l10n.settings_main_appearance_select_font_family,
                    options: ['Inter (Sans)', 'Roboto Mono (Mono)', 'Lora (Serif)', 'Merriweather (Serif)'],
                    optionLabels: {
                      'Inter (Sans)': context.l10n.settings_main_appearance_font_family_default('Inter (Sans)'),
                    },
                    currentValue: fontFamily,
                    onSelected: (val) => ref.read(fontFamilyProvider.notifier).setFontFamily(val),
                  ),
                ),

                // ── Preferences ──────────────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_preferences),
                SettingsTile(
                  icon: Icons.edit_note_rounded,
                  title: context.l10n.settings_main_editor_title,
                  subtitle: context.l10n.settings_main_editor_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/editor-preferences'),
                ),
                SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: context.l10n.settings_main_journal_title,
                  subtitle: context.l10n.settings_main_journal_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/journal-preferences'),
                ),
                ProGateTile(
                  icon: Icons.keyboard_command_key_rounded,
                  title: context.l10n.settings_main_macros_title,
                  subtitle: context.l10n.settings_main_macros_desc,
                  onTap: () => context.push('/settings/custom-macros'),
                ),
                ProGateTile(
                  icon: Icons.note_add_rounded,
                  title: context.l10n.settings_main_templates_title,
                  subtitle: context.l10n.settings_main_templates_desc,
                  onTap: () => context.push('/settings/custom-templates'),
                ),
                SettingsTile(
                  icon: Icons.audio_file_rounded,
                  title: context.l10n.settings_main_attachments_title,
                  subtitle: context.l10n.settings_main_attachments_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/attachments'),
                ),

                // ── Sync & Data ─────────────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_sync),
                ProGateTile(
                  icon: Icons.sync_rounded,
                  title: context.l10n.settings_main_sync_title,
                  subtitle: context.l10n.settings_main_sync_desc,
                  onTap: () => context.push('/settings/cloud-sync'),
                ),
                SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: context.l10n.settings_main_export_title,
                  subtitle: context.l10n.settings_main_export_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/vault-export'),
                ),
                SettingsTile(
                  icon: Icons.folder_open_outlined,
                  title: context.l10n.settings_main_vaults_title,
                  subtitle: context.l10n.settings_main_vaults_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/manage-vaults'),
                ),

                // ── Gestures & Feedback ──────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_gestures),
                const HapticToggleTile(),
                const DragToPinToggleTile(),
                const AnalyticsToggleTile(),

                // ── Pro Settings Management (Pro only) ──────────────────────
                if (isPro) ...[
                  SettingsSectionHeader(title: context.l10n.settings_main_section_subscription),
                  SettingsTile(
                    icon: Icons.diamond_rounded,
                    title: context.l10n.settings_main_pro_status_active,
                    subtitle: context.l10n.settings_main_pro_status_desc,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final result = await ref.read(subscriptionRepositoryProvider).presentCustomerCenter();
                      result.fold(
                        (failure) {
                          PrismToast.show(
                            context,
                            context.l10n.settings_main_pro_customer_center_error(failure.message),
                            icon: Icons.error_outline_rounded,
                          );
                        },
                        (_) {},
                      );
                    },
                  ),
                ],

                // ── Feedback & Support ──────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_feedback),
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: context.l10n.settings_main_support_title,
                  subtitle: context.l10n.settings_main_support_desc,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/support'),
                ),

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
                    PrismToast.show(
                      context,
                      'Prism v1.0.0 — private offline notebook.',
                      icon: Icons.info_outline_rounded,
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
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: context.l10n.settings_terms_of_service,
                  subtitle: context.l10n.settings_terms_of_service_subtitle,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/terms'),
                ),

                // ── Danger Zone ─────────────────────────────────────────
                SettingsSectionHeader(title: context.l10n.settings_main_section_danger),
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: DesignColors.accentRose(context),
                  iconBackgroundColor: DesignColors.accentRose(context).withValues(alpha: 0.12),
                  title: context.l10n.settings_data_deletion_title,
                  subtitle: context.l10n.settings_data_deletion_desc,
                  trailing: Icon(Icons.chevron_right_rounded, color: DesignColors.accentRose(context), size: 18),
                  onTap: () => _showDataDeletionDialog(context, ref),
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

  Future<void> _showDataDeletionDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => const _DataDeletionConfirmationDialog(),
    );

    if (confirmed == true && context.mounted) {
      // Show modal progress overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: DesignColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: DesignColors.accentRose(context),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      context.l10n.settings_data_deletion_progress,
                      style: DesignTypography.body(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        await ref.read(dataDeletionServiceProvider).executeFullReset();
        if (context.mounted) {
          // Dismiss progress dialog
          Navigator.of(context, rootNavigator: true).pop();

          PrismToast.show(
            context,
            context.l10n.settings_data_deletion_success,
            icon: Icons.check_circle_outline_rounded,
          );

          context.go('/onboarding');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          PrismToast.show(
            context,
            context.l10n.settings_data_deletion_failure(e.toString()),
            icon: Icons.error_outline_rounded,
          );
        }
      }
    }
  }
}

class _DataDeletionConfirmationDialog extends StatefulWidget {
  const _DataDeletionConfirmationDialog();

  @override
  State<_DataDeletionConfirmationDialog> createState() => _DataDeletionConfirmationDialogState();
}

class _DataDeletionConfirmationDialogState extends State<_DataDeletionConfirmationDialog> {
  late final TextEditingController _controller;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final can = text == 'DELETE';
    if (can != _canDelete) {
      setState(() {
        _canDelete = can;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rose = DesignColors.accentRose(context);

    return AlertDialog(
      backgroundColor: DesignColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: rose, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.settings_data_deletion_dialog_title,
              style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings_data_deletion_dialog_body,
              style: DesignTypography.body(context, fontSize: 13, color: DesignColors.textSecondary(context)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: l10n.settings_data_deletion_confirm_keyword,
                hintStyle: TextStyle(color: DesignColors.textTertiary(context), letterSpacing: 1.5),
                filled: true,
                fillColor: DesignColors.surfaceVariant(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.border(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: rose, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.settings_data_deletion_cancel_button,
            style: DesignTypography.body(context, color: DesignColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: rose,
            foregroundColor: Colors.white,
            disabledBackgroundColor: rose.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            l10n.settings_data_deletion_confirm_button,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}