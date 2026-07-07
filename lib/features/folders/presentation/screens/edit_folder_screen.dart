import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_repository.dart';
import '../providers/folders_providers.dart';
import '../widgets/folder_icon_display.dart';
import '../widgets/folder_icon_picker.dart';
import '../widgets/hsv_color_picker.dart';
import 'package:prism/l10n/l10n.dart';

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

class EditFolderScreen extends ConsumerStatefulWidget {
  final String folderId;

  const EditFolderScreen({super.key, required this.folderId});

  @override
  ConsumerState<EditFolderScreen> createState() => _EditFolderScreenState();
}

class _EditFolderScreenState extends ConsumerState<EditFolderScreen> {
  bool _initialized = false;
  late TextEditingController _nameController;
  late Color _selectedColor;
  late String _selectedIconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
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
      useSafeArea: true,
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
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      loading: () => Scaffold(
        backgroundColor: DesignColors.background(context),
        appBar: AppBar(
          title: Text(context.l10n.folders_edit_folder_title),
          backgroundColor: DesignColors.background(context),
        ),
        body: const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading'),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: DesignColors.background(context),
        appBar: AppBar(
          title: Text(context.l10n.folders_edit_folder_title),
          backgroundColor: DesignColors.background(context),
        ),
        body: Center(
          child: Text(context.l10n.folders_edit_folder_error(err.toString()), style: TextStyle(color: colorScheme.error)),
        ),
      ),
      data: (folders) {
        final folder = folders.firstWhereOrNull((f) => f.id == widget.folderId);
        if (folder == null) {
          return Scaffold(
            backgroundColor: DesignColors.background(context),
            appBar: AppBar(
              title: Text(context.l10n.folders_edit_folder_title),
              backgroundColor: DesignColors.background(context),
            ),
            body: Center(
              child: Text(context.l10n.folders_edit_folder_not_found),
            ),
          );
        }

        if (!_initialized) {
          _nameController.text = folder.name;
          _selectedColor = folder.colorHex.toColor();
          _selectedIconKey = folder.icon;
          _initialized = true;
        }

        return Scaffold(
          backgroundColor: DesignColors.background(context),
          appBar: AppBar(
            title: Text(context.l10n.folders_edit_folder_title),
            centerTitle: true,
            backgroundColor: DesignColors.background(context),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Icon preview (optional) ──────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _selectedIconKey.isNotEmpty ? _openIconPicker : null,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: _selectedIconKey.isNotEmpty
                              ? FolderIconDisplay(
                                  key: ValueKey('icon-$_selectedIconKey-${_selectedColor.toARGB32()}'),
                                  iconKey: _selectedIconKey,
                                  color: _selectedColor,
                                  size: 72,
                                  badgeSize: 14,
                                )
                              : Container(
                                  key: const ValueKey('plain-circle'),
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: _selectedColor.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(72 * 0.28),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedIconKey.isEmpty)
                        TextButton.icon(
                          onPressed: _openIconPicker,
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 14,
                            color: DesignColors.textSecondary(context),
                          ),
                          label: Text(
                            context.l10n.folders_add_folder_add_icon,
                            style: DesignTypography.metadata(
                              context,
                              fontSize: 12,
                              color: DesignColors.textSecondary(context),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: _openIconPicker,
                              icon: Icon(
                                Icons.touch_app_rounded,
                                size: 12,
                                color: DesignColors.textTertiary(context),
                              ),
                              label: Text(
                                context.l10n.folders_add_folder_change_icon,
                                style: DesignTypography.metadata(
                                  context,
                                  fontSize: 11,
                                  color: DesignColors.textTertiary(context),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () => setState(() => _selectedIconKey = ''),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                context.l10n.folders_add_folder_remove_icon,
                                style: DesignTypography.metadata(
                                  context,
                                  fontSize: 11,
                                  color: DesignColors.textTertiary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Folder name ──────────────────────────────────────────────────
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: DesignTypography.body(context, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: context.l10n.folders_add_folder_hint,
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
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),

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
                              final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedColor = color);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.only(right: 8),
                                  alignment: Alignment.center,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 28,
                                    height: 28,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Custom color button
                            GestureDetector(
                              onTap: _openCustomColorPicker,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Submit ───────────────────────────────────────────────────────
                DesignPrimaryButton(
                  label: context.l10n.folders_edit_folder_save,
                  onTap: () async {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      await ref.read(folderRepositoryProvider).updateFolder(
                            widget.folderId,
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
          ),
        );
      },
    );
  }
}