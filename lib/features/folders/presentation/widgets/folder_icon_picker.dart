import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/design_system/design_system.dart';
import 'folder_icon_display.dart';

/// Full bottom-sheet icon picker.
/// Returns the selected icon key string via [Navigator.pop].
class FolderIconPickerSheet extends StatefulWidget {
  final String selectedKey;
  final Color accentColor;

  const FolderIconPickerSheet({
    super.key,
    required this.selectedKey,
    required this.accentColor,
  });

  @override
  State<FolderIconPickerSheet> createState() => _FolderIconPickerSheetState();
}

class _FolderIconPickerSheetState extends State<FolderIconPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedKey;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: DesignColors.background(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              const SizedBox(height: 8),
              const DesignSheetDragHandle(),
              const SizedBox(height: 4),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Icon',
                      style: DesignTypography.heading(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text(
                        'Done',
                        style: DesignTypography.body(
                          context,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Scrollable grid ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: DesignIcons.folderIconCategories.length,
                  itemBuilder: (context, catIndex) {
                    final category = DesignIcons.folderIconCategories[catIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (catIndex > 0) const SizedBox(height: 20),
                        // Category label
                        Text(
                          category.label.toUpperCase(),
                          style: DesignTypography.metadata(
                            context,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.textTertiary(context),
                          ).copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 12),
                        // Icon grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: category.keys.map((key) {
                            final isSelected = key == _selected;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selected = key);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.accentColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: FolderIconDisplay(
                                  iconKey: key,
                                  color: isSelected
                                      ? widget.accentColor
                                      : DesignColors.textTertiary(context),
                                  size: 48,
                                  badgeSize: 0, // hide badge in picker
                                  useThemedIcon: false,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
