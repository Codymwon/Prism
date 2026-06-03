import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../settings/presentation/providers/custom_macro_provider.dart';
import '../utils/editor_helpers.dart';
import 'audio_player_bottom_sheet.dart';

class FormattingToolbar extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onToggleDictation;
  final VoidCallback onAttachImage;

  const FormattingToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onToggleDictation,
    required this.onAttachImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customMacros = ref.watch(customMacrosProvider);
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.8,
      maxScaleFactor: 1.25,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        height: 54,
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: DesignColors.border(context), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              _buildFormattingButton(
                context,
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '**',
                  suffix: '**',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '*',
                  suffix: '*',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_size_rounded,
                tooltip: 'Heading',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '# ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.link_rounded,
                tooltip: 'Wikilink',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '[[',
                  suffix: ']]',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.label_outline_rounded,
                tooltip: 'Tag',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '#',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet List',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '\n- ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.checklist_rounded,
                tooltip: 'Checklist',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '\n- [ ] ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.code_rounded,
                tooltip: 'Code',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '`',
                  suffix: '`',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_quote_rounded,
                tooltip: 'Blockquote',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '\n> ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.strikethrough_s_rounded,
                tooltip: 'Strikethrough',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '~~',
                  suffix: '~~',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.border_color_rounded,
                tooltip: 'Highlight',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '==',
                  suffix: '==',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.horizontal_rule_rounded,
                tooltip: 'Divider',
                onTap: () => insertFormatting(
                  controller: controller,
                  focusNode: focusNode,
                  prefix: '\n---\n',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.image_outlined,
                tooltip: 'Attach Image',
                onTap: onAttachImage,
              ),
              if (Platform.isAndroid)
                _buildFormattingButton(
                  context,
                  icon: Icons.mic_none_rounded,
                  tooltip: 'Dictate (Voice-to-Text)',
                  onTap: onToggleDictation,
                ),

              // Vertical Divider separating standard actions and custom macros
              if (customMacros.isNotEmpty) ...[
                Container(
                  height: 22,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: DesignColors.border(context),
                ),
                ...customMacros.map((macro) {
                  return _buildCustomMacroButton(
                    context,
                    label: macro.label,
                    tooltip: 'Insert: ${macro.text.replaceAll('\n', ' ')}',
                    onTap: () => insertMacro(
                      controller: controller,
                      focusNode: focusNode,
                      macro: macro,
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    ),);
  }

  Widget _buildFormattingButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 40,
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: DesignColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomMacroButton(
    BuildContext context, {
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DesignColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DesignColors.border(context),
              width: 0.8,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTypography.body(
                context,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DesignColors.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DictationOverlay extends StatelessWidget {
  final String currentWords;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  const DictationOverlay({
    super.key,
    required this.currentWords,
    required this.onCancel,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.8,
      maxScaleFactor: 1.25,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: clampedTextScaler),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        height: 54,
      decoration: BoxDecoration(
        color: DesignColors.surfaceVariant(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: DesignColors.border(context), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: onCancel,
              child: const Tooltip(
                message: 'Cancel & Discard',
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SubtlePulseIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentWords.isEmpty ? 'Listening...' : currentWords,
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  color: DesignColors.text(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            TactileWrapper(
              style: TactileFeedbackStyle.standard,
              onTap: onCommit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}
