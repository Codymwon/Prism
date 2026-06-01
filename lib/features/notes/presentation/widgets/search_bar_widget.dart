import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFocused;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.onFocused,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? MeridianColors.darkSurfaceVariant : MeridianColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus
              ? colorScheme.primary.withValues(alpha: 0.6)
              : (isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder),
          width: _hasFocus ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: _hasFocus
                ? colorScheme.primary
                : (isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? MeridianColors.darkText : MeridianColors.lightText,
              ),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? MeridianColors.darkTextTertiary : MeridianColors.lightTextTertiary,
                ),
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
                widget.onClear();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: isDark ? MeridianColors.darkTextSecondary : MeridianColors.lightTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
