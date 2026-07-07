import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../settings/presentation/providers/custom_macro_provider.dart';
import '../utils/editor_helpers.dart';
import 'audio_player_bottom_sheet.dart';

class FormattingToolbar extends ConsumerStatefulWidget {
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
  ConsumerState<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends ConsumerState<FormattingToolbar> {
  final _headingKey = GlobalKey();

  void _showHeadingMenu(BuildContext context) {
    final RenderBox? box = _headingKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Size size = box.size;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headings = [
      ('H1', '# ', 'Heading 1'),
      ('H2', '## ', 'Heading 2'),
      ('H3', '### ', 'Heading 3'),
      ('H4', '#### ', 'Heading 4'),
    ];

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(const Offset(0, -178), ancestor: overlay),
        box.localToGlobal(Offset(size.width, 0), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      color: isDark ? DesignColors.surface(context) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: DesignColors.border(context),
          width: 1,
        ),
      ),
      elevation: 8,
      shadowColor: Colors.black26,
      position: position,
      items: headings.map((h) {
        final label = h.$1;
        final prefix = h.$2;
        final desc = h.$3;
        final fontSize = switch (label) {
          'H1' => 17.0,
          'H2' => 15.0,
          'H3' => 13.5,
          _    => 12.5,
        };
        return PopupMenuItem<String>(
          value: prefix,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          height: 42,
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                desc,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: label == 'H1' ? FontWeight.w700 : FontWeight.w600,
                  color: DesignColors.text(context),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((prefix) {
      if (prefix == null) return;
      _insertHeadingPrefix(prefix);
    });
  }

  /// Inserts a heading prefix at the beginning of the line containing the cursor.
  /// Replaces any existing heading prefix on that line.
  void _insertHeadingPrefix(String newPrefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final cursor = selection.isValid ? selection.baseOffset : text.length;

    // Find start of current line
    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final lineEnd = text.indexOf('\n', cursor);
    final actualLineEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualLineEnd);

    // Strip any existing heading prefix
    final stripped = currentLine.replaceFirst(RegExp(r'^#{1,6} ?'), '');
    final newLine = '$newPrefix$stripped';

    final newText = text.replaceRange(lineStart, actualLineEnd, newLine);
    final newCursor = (lineStart + newPrefix.length + stripped.length).clamp(0, newText.length);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
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
                icon: Icons.checklist_rounded,
                tooltip: 'Checklist',
                onTap: () => toggleBlockStyle(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '- [ ] ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_list_bulleted_rounded,
                tooltip: 'Bullet List',
                onTap: () => toggleBlockStyle(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '- ',
                ),
              ),
              // Heading button with H1–H4 popup menu
              _buildFormattingButton(
                context,
                icon: Icons.format_size_rounded,
                tooltip: 'Heading (H1–H4)',
                key: _headingKey,
                onTap: () => _showHeadingMenu(context),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_bold_rounded,
                tooltip: 'Bold',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '**',
                  suffix: '**',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_italic_rounded,
                tooltip: 'Italic',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '*',
                  suffix: '*',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.link_rounded,
                tooltip: 'Wikilink',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '[[',
                  suffix: ']]',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.label_outline_rounded,
                tooltip: 'Tag',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '#',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.image_outlined,
                tooltip: 'Attach Image',
                onTap: widget.onAttachImage,
              ),
              if (Platform.isAndroid)
                _buildFormattingButton(
                  context,
                  icon: Icons.mic_none_rounded,
                  tooltip: 'Dictate (Voice-to-Text)',
                  onTap: widget.onToggleDictation,
                ),
              _buildFormattingButton(
                context,
                icon: Icons.border_color_rounded,
                tooltip: 'Highlight',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '==',
                  suffix: '==',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.code_rounded,
                tooltip: 'Code',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '`',
                  suffix: '`',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.format_quote_rounded,
                tooltip: 'Blockquote',
                onTap: () => toggleBlockStyle(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '> ',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.strikethrough_s_rounded,
                tooltip: 'Strikethrough',
                onTap: () => insertFormatting(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  prefix: '~~',
                  suffix: '~~',
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.horizontal_rule_rounded,
                tooltip: 'Divider',
                onTap: () => insertDivider(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                ),
              ),
              _buildFormattingButton(
                context,
                icon: Icons.table_chart_rounded,
                tooltip: 'Table',
                onTap: () => insertTable(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                ),
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
                      controller: widget.controller,
                      focusNode: widget.focusNode,
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
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      key: key,
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      semanticLabel: tooltip,
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
      semanticLabel: tooltip,
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

class AudioRecordOverlay extends StatelessWidget {
  final int durationSeconds;
  final VoidCallback onCancel;
  final VoidCallback onCommit;

  const AudioRecordOverlay({
    super.key,
    required this.durationSeconds,
    required this.onCancel,
    required this.onCommit,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return 'Recording $minutes:$secs...';
  }

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
              semanticLabel: 'Cancel & Discard recording',
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
                _formatDuration(durationSeconds),
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
              semanticLabel: 'Save & Insert recording',
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
