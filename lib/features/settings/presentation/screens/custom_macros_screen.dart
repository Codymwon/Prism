import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/custom_macro_provider.dart';

class CustomMacrosScreen extends ConsumerStatefulWidget {
  const CustomMacrosScreen({super.key});

  @override
  ConsumerState<CustomMacrosScreen> createState() => _CustomMacrosScreenState();
}

class _CustomMacrosScreenState extends ConsumerState<CustomMacrosScreen> {
  @override
  void initState() {
    super.initState();
    // Defense-in-depth runtime guard: redirect to the paywall if the user is
    // not Pro. Handles deep links that bypass the ProGateTile in Settings.
    // We await the first subscription-status emission so we don't redirect a
    // Pro user while RevenueCat status is still loading.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final status = await ref.read(subscriptionStatusProvider.future);
      if (!mounted) return;
      if (!status.isPro) {
        context.go('/settings/paywall');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final macros = ref.watch(customMacrosProvider);

    return Scaffold(
      backgroundColor: DesignColors.background(context),
      appBar: AppBar(
        backgroundColor: DesignColors.background(context),
        leading: IconButton(
          icon: const Icon(DesignIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Toolbar Macros',
          style: DesignTypography.heading(
            context,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset to Defaults',
            onPressed: () => _confirmReset(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Macros',
                    style: DesignTypography.display(
                      context,
                      fontSize: 24,
                      color: DesignColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define 3 to 5 custom text injection macros for your accessory formatting toolbar.',
                    style: DesignTypography.details(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                children: [
                  ...List.generate(macros.length, (idx) {
                    final macro = macros[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMacroCard(context, ref, macro, idx, macros.length),
                    );
                  }).animate(interval: 50.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
                  
                  if (macros.length < 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildAddButton(context, ref),
                    ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(
    BuildContext context,
    WidgetRef ref,
    CustomMacro macro,
    int index,
    int totalCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignColors.border(context),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openMacroEditor(context, ref, index, macro),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Macro Label Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DesignColors.surface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DesignColors.border(context),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    macro.label,
                    style: DesignTypography.body(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DesignColors.text(context),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Macro Text Preview
                Expanded(
                  child: Text(
                    macro.text.replaceAll('\n', '↵'),
                    style: DesignTypography.body(
                      context,
                      fontSize: 13,
                      color: DesignColors.textSecondary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _openMacroEditor(context, ref, index, macro),
                  tooltip: 'Edit Macro',
                  color: DesignColors.textTertiary(context),
                ),
                // Delete Icon (Only if total count is > 3)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: totalCount > 3
                        ? Colors.red.withValues(alpha: 0.8)
                        : DesignColors.textTertiary(context).withValues(alpha: 0.3),
                  ),
                  onPressed: totalCount > 3
                      ? () => ref.read(customMacrosProvider.notifier).removeMacro(index)
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You must keep at least 3 custom macros.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  tooltip: totalCount > 3 ? 'Delete Macro' : 'Cannot delete (Min 3 required)',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () => _openMacroEditor(context, ref),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignColors.primary(context).withValues(alpha: 0.5),
            width: 1.0,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: DesignColors.primary(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Custom Macro',
              style: DesignTypography.body(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DesignColors.primary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMacroEditor(
    BuildContext context,
    WidgetRef ref, [
    int? index,
    CustomMacro? existingMacro,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _MacroEditorSheet(
          existingMacro: existingMacro,
          index: index,
        );
      },
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignColors.background(context),
        title: Text(
          'Reset Macros',
          style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to reset all macros to their defaults? This will erase your custom edits.',
          style: DesignTypography.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: DesignTypography.body(context)),
          ),
          TextButton(
            onPressed: () {
              ref.read(customMacrosProvider.notifier).resetToDefaults();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Macros reset to defaults.')),
              );
            },
            child: Text(
              'Reset',
              style: DesignTypography.body(context, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroEditorSheet extends ConsumerStatefulWidget {
  final CustomMacro? existingMacro;
  final int? index;

  const _MacroEditorSheet({
    this.existingMacro,
    this.index,
  });

  @override
  ConsumerState<_MacroEditorSheet> createState() => _MacroEditorSheetState();
}

class _MacroEditorSheetState extends ConsumerState<_MacroEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _textController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.existingMacro?.label ?? '');
    _textController = TextEditingController(text: widget.existingMacro?.text ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildPlaceholderPill(
    BuildContext context,
    TextEditingController controller,
    String placeholder,
    String description,
  ) {
    return Tooltip(
      message: description,
      child: Material(
        color: DesignColors.surfaceVariant(context),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            final text = controller.text;
            final selection = controller.selection;
            if (!selection.isValid) {
              final newText = text + placeholder;
              controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
              return;
            }
            final start = selection.start;
            final end = selection.end;
            final newText = text.replaceRange(start, end, placeholder);
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: start + placeholder.length),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 12, color: DesignColors.primary(context)),
                const SizedBox(width: 4),
                Text(
                  placeholder,
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DesignColors.text(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.index != null && widget.existingMacro != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DesignSheetDragHandle(),
            Text(
              isEdit ? 'Edit Custom Macro' : 'Create Custom Macro',
              style: DesignTypography.heading(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Label Input
            Text(
              'BUTTON LABEL',
              style: DesignTypography.metadata(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _labelController,
              maxLength: 12,
              style: DesignTypography.body(context, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Date, Todo, Tag',
                hintStyle: DesignTypography.body(context, fontSize: 14, color: DesignColors.textTertiary(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.primary(context), width: 1.5),
                ),
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Label is required';
                }
                if (val.trim().length > 12) {
                  return 'Label must be 12 chars or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Text Input
            Text(
              'MACRO INJECTION TEXT',
              style: DesignTypography.metadata(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              minLines: 2,
              style: DesignTypography.body(context, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter text, templates, tags, or placeholders…',
                hintStyle: DesignTypography.body(context, fontSize: 14, color: DesignColors.textTertiary(context)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.primary(context), width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Injection text is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Placeholder Pill Shelf
            Text(
              'TAP DYNAMIC PLACEHOLDERS TO INSERT:',
              style: DesignTypography.metadata(
                context,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPlaceholderPill(context, _textController, '{{date}}', 'Current Date'),
                _buildPlaceholderPill(context, _textController, '{{time}}', 'Current Time'),
                _buildPlaceholderPill(context, _textController, '{{datetime}}', 'Date & Time'),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: DesignColors.border(context)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: DesignTypography.body(context, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TactileWrapper(
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        final macro = CustomMacro(
                          label: _labelController.text.trim(),
                          text: _textController.text,
                        );
                        if (isEdit) {
                          ref.read(customMacrosProvider.notifier).updateMacro(widget.index!, macro);
                        } else {
                          ref.read(customMacrosProvider.notifier).addMacro(macro);
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: DesignColors.primary(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isEdit ? 'Save Changes' : 'Create Macro',
                        style: DesignTypography.body(
                          context,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
