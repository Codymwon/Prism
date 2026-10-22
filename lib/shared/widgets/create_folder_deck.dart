import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/folders/data/folder_repository.dart';
import '../design_system/design_system.dart';
import 'dynamic_island_state.dart';
import 'prism_toast.dart';
import 'tactile_wrapper.dart';

const List<Color> _kFolderSwatches = [
  Color(0xFF7C6FF7), // Indigo (default)
  Color(0xFFA855F7), // Violet
  Color(0xFF3B82F6), // Blue
  Color(0xFF06B6D4), // Cyan
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Rose
  Color(0xFF64748B), // Slate
];

/// In-island subdeck displaying inline folder creation with name input & color swatches.
class CreateFolderDeck extends ConsumerStatefulWidget {
  const CreateFolderDeck({super.key});

  @override
  ConsumerState<CreateFolderDeck> createState() => _CreateFolderDeckState();
}

class _CreateFolderDeckState extends ConsumerState<CreateFolderDeck> {
  late final TextEditingController _nameController;
  final FocusNode _focusNode = FocusNode();
  Color _selectedColor = _kFolderSwatches.first;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _colorHex =>
      '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _submitFolder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      PrismToast.show(
        context,
        'Please enter a folder name',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(folderRepositoryProvider).createFolder(
            name,
            colorHex: _colorHex,
          );
      ref.read(dynamicIslandControllerProvider.notifier).dismiss();
      if (mounted) {
        PrismToast.show(
          context,
          'Folder "$name" created',
          icon: Icons.create_new_folder_outlined,
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        PrismToast.show(
          context,
          'Failed to create folder: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Back button & Title
          Row(
            children: [
              TactileWrapper(
                key: const ValueKey('create_folder_back_btn'),
                style: TactileFeedbackStyle.standard,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(dynamicIslandControllerProvider.notifier)
                      .switchVaultHubSubDeck(VaultHubSubDeck.tools);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context)
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: DesignColors.text(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEW FOLDER',
                style: DesignTypography.heading(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Folder Name Input Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DesignColors.surfaceVariant(context).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedColor.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  DesignIcons.folder,
                  size: 18,
                  color: _selectedColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const ValueKey('create_folder_name_input'),
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: DesignTypography.body(context, fontSize: 13),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitFolder(),
                    decoration: InputDecoration(
                      hintText: 'Folder name...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: DesignColors.textTertiary(context),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Color Swatches Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _kFolderSwatches.map((color) {
              final isSelected = color.toARGB32() == _selectedColor.toARGB32();
              return GestureDetector(
                key: ValueKey('folder_swatch_${color.toARGB32()}'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColor = color);
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Submit Action Button
          TactileWrapper(
            key: const ValueKey('create_folder_submit_btn'),
            style: TactileFeedbackStyle.highImpact,
            onTap: _submitFolder,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Create Folder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
