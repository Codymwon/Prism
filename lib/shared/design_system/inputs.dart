import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';
import 'icons.dart';

class DesignInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const DesignInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = DesignColors.surfaceVariant(context);
    final border = DesignColors.border(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      style: DesignTypography.body(context),
      decoration: InputDecoration(
        filled: true,
        fillColor: bg,
        hintText: hintText,
        hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: DesignColors.primary(context)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          borderSide: BorderSide(color: DesignColors.primary(context), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class DesignSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFocused;
  final String hintText;

  const DesignSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.onFocused,
    this.hintText = 'Search notes…',
  });

  @override
  State<DesignSearchBar> createState() => _DesignSearchBarState();
}

class _DesignSearchBarState extends State<DesignSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _hasFocus = _focus.hasFocus);
      if (_focus.hasFocus) widget.onFocused();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = DesignColors.surfaceVariant(context);
    final borderColor = DesignColors.border(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
        border: Border.all(
          color: _hasFocus
              ? DesignColors.primary(context).withValues(alpha: 0.6)
              : borderColor,
          width: _hasFocus ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            DesignIcons.search,
            size: 18,
            color: _hasFocus
                ? DesignColors.primary(context)
                : DesignColors.textTertiary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: (val) {
                setState(() {});
                widget.onChanged(val);
              },
              style: DesignTypography.body(context, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: DesignTypography.body(context, fontSize: 14, color: DesignColors.textTertiary(context)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
                widget.onClear();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  DesignIcons.close,
                  size: 16,
                  color: DesignColors.textSecondary(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
