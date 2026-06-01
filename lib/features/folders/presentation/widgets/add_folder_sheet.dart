import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../data/folder_repository.dart';
import 'hsv_color_picker.dart';

class AddFolderSheet extends ConsumerStatefulWidget {
  const AddFolderSheet({super.key});

  @override
  ConsumerState<AddFolderSheet> createState() => _AddFolderSheetState();
}

class _AddFolderSheetState extends ConsumerState<AddFolderSheet> {
  final _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF7C6FF7);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            title: 'Create Folder',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),

          // Name Input
          TextField(
            controller: _nameController,
            autofocus: true,
            style: DesignTypography.body(context, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Folder name',
              hintStyle: DesignTypography.body(context, color: DesignColors.textTertiary(context)),
              filled: true,
              fillColor: DesignColors.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: DesignColors.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: DesignColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Color Display Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Folder Color',
                    style: DesignTypography.body(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.color_lens_outlined, size: 16),
                label: Text(
                  'Change',
                  style: DesignTypography.body(context, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                ),
                onPressed: () async {
                  final pickedColor = await showDialog<Color>(
                    context: context,
                    builder: (dialogCtx) => HsvColorPickerDialog(
                      initialColor: _selectedColor,
                    ),
                  );
                  if (pickedColor != null) {
                    setState(() {
                      _selectedColor = pickedColor;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          DesignPrimaryButton(
            label: 'Create Folder',
            backgroundColor: _selectedColor,
            onTap: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                final hex = '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                await ref.read(folderRepositoryProvider).createFolder(
                      name,
                      colorHex: hex,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
