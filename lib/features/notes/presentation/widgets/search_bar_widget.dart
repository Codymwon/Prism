import 'package:flutter/material.dart';
import '../../../../shared/design_system/design_system.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFocused;
  final FocusNode? focusNode;

  const SearchBarWidget({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.onFocused,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return DesignSearchBar(
      onChanged: onChanged,
      onClear: onClear,
      onFocused: onFocused,
      focusNode: focusNode,
    );
  }
}
