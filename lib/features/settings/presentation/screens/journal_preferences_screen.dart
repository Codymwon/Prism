import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import 'package:prism/l10n/l10n.dart';

class JournalPreferencesScreen extends ConsumerWidget {
  const JournalPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startOfWeek = ref.watch(startOfWeekProvider).valueOrNull ?? context.l10n.settings_journal_pref_week_start_sunday;
    final autoCreate = ref.watch(autoCreateDailyNoteOnLaunchProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: DesignColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(DesignIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.settings_journal_pref_title,
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            SettingsSectionHeader(title: context.l10n.settings_journal_pref_section_calendar),
            Card(
              color: DesignColors.surface(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: DesignColors.text(context).withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.calendar_today_rounded,
                    title: context.l10n.settings_journal_pref_week_start,
                    subtitle: startOfWeek,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showOptionSelector(
                      context: context,
                      title: context.l10n.settings_journal_pref_select_week_start,
                      options: [context.l10n.settings_journal_pref_week_start_sunday, context.l10n.settings_journal_pref_week_start_monday],
                      currentValue: startOfWeek,
                      onSelected: (val) => ref.read(startOfWeekProvider.notifier).setStartOfWeek(val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SettingsSectionHeader(title: context.l10n.settings_journal_pref_section_behavior),
            Card(
              color: DesignColors.surface(context),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: DesignColors.text(context).withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: DesignColors.primary(context),
                    title: Text(
                      context.l10n.settings_journal_pref_auto_create,
                      style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      context.l10n.settings_journal_pref_auto_create_desc,
                      style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                    ),
                    value: autoCreate,
                    onChanged: (val) => ref.read(autoCreateDailyNoteOnLaunchProvider.notifier).setEnabled(val),
                  ),
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
                          Navigator.pop(ctx);
                          onSelected(val);
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
}