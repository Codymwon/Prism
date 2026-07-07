import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class EditorPreferencesScreen extends ConsumerWidget {
  const EditorPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final lineWidth = ref.watch(lineWidthProvider);

    final lineNumbersGutter = ref.watch(lineNumbersGutterProvider).valueOrNull ?? false;
    final autoPairBrackets = ref.watch(autoPairBracketsProvider).valueOrNull ?? true;
    final showBacklinksDefault = ref.watch(showBacklinksDefaultProvider).valueOrNull ?? false;

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
          'Editor Preferences',
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
            const SettingsSectionHeader(title: 'Text & Layout'),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: DesignColors.border(context), height: 1),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            const SettingsSectionHeader(title: 'Editor Behaviors'),
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
                      'Display Line Numbers',
                      style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Show logical line numbers in the editor margin',
                      style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                    ),
                    value: lineNumbersGutter,
                    onChanged: (val) => ref.read(lineNumbersGutterProvider.notifier).setEnabled(val),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: DesignColors.border(context), height: 1),
                  ),
                  SwitchListTile(
                    activeThumbColor: DesignColors.primary(context),
                    title: Text(
                      'Auto-pair Brackets & Quotes',
                      style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Automatically insert closing brackets and quotes',
                      style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                    ),
                    value: autoPairBrackets,
                    onChanged: (val) => ref.read(autoPairBracketsProvider.notifier).setEnabled(val),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: DesignColors.border(context), height: 1),
                  ),
                  SwitchListTile(
                    activeThumbColor: DesignColors.primary(context),
                    title: Text(
                      'Show Backlinks by Default',
                      style: DesignTypography.body(context, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Display the backlinks panel at the bottom of notes',
                      style: DesignTypography.body(context, fontSize: 12, color: DesignColors.textSecondary(context)),
                    ),
                    value: showBacklinksDefault,
                    onChanged: (val) => ref.read(showBacklinksDefaultProvider.notifier).setEnabled(val),
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
}
