import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';
import 'folder_icon_display.dart';
import 'folder_icon_picker.dart';
import 'hsv_color_picker.dart';

// ── Preset accent swatches ────────────────────────────────────────────────────
const List<Color> _kSwatches = [
  Color(0xFF7C6FF7),
  Color(0xFFA855F7),
  Color(0xFF3B82F6),
  Color(0xFF06B6D4),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF64748B),
];

class EditFolderSheet extends ConsumerStatefulWidget {
  final VirtualFolder folder;

  const EditFolderSheet({super.key, required this.folder});

  @override
  ConsumerState<EditFolderSheet> createState() => _EditFolderSheetState();
}

class _EditFolderSheetState extends ConsumerState<EditFolderSheet> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder.name);
    _selectedColor = widget.folder.colorHex.toColor();
    _selectedIconKey = widget.folder.icon.isNotEmpty ? widget.folder.icon : 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openIconPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FolderIconPickerSheet(
        selectedKey: _selectedIconKey,
        accentColor: _selectedColor,
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedIconKey = result);
    }
  }

  Future<void> _openCustomColorPicker() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => HsvColorPickerDialog(initialColor: _selectedColor),
    );
    if (picked != null && mounted) {
      setState(() => _selectedColor = picked);
    }
  }

  String get _colorHex =>
      '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignSheetHeader(
            title: 'Edit Folder',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),

          // ── Live preview + icon tap ──────────────────────────────────────
          Center(
            child: GestureDetector(
              onTap: _openIconPicker,
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: FolderIconDisplay(
                      key: ValueKey('$_selectedIconKey-${_selectedColor.toARGB32()}'),
                      iconKey: _selectedIconKey,
                      color: _selectedColor,
                      size: 72,
                      badgeSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 12,
                        color: DesignColors.textTertiary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to change icon',
                        style: DesignTypography.metadata(
                          context,
                          fontSize: 11,
                          color: DesignColors.textTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Folder name ──────────────────────────────────────────────────
          TextField(
            controller: _nameController,
            autofocus: true,
            style: DesignTypography.body(context, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Folder name',
              hintStyle: DesignTypography.body(
                  context, color: DesignColors.textTertiary(context)),
              filled: true,
              fillColor: DesignColors.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: DesignColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: DesignColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // ── Accent color swatches ────────────────────────────────────────
          Row(
            children: [
              Text(
                'Accent',
                style: DesignTypography.body(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._kSwatches.map((color) {
                        final isSelected =
                            color.toARGB32() == _selectedColor.toARGB32();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedColor = color);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: color.withValues(alpha: 0.5),
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check_rounded,
                                      size: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.9))
                                  : null,
                            ),
                          ),
                        );
                      }),
                      // Custom color button
                      GestureDetector(
                        onTap: _openCustomColorPicker,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignColors.surfaceVariant(context),
                            border: Border.all(
                              color: DesignColors.border(context),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: DesignColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Submit ───────────────────────────────────────────────────────
          DesignPrimaryButton(
            label: 'Save Changes',
            backgroundColor: _selectedColor,
            onTap: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                await ref.read(folderRepositoryProvider).updateFolder(
                      widget.folder.id,
                      name,
                      _colorHex,
                      _selectedIconKey,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
