import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';
import '../providers/folders_providers.dart';
import 'add_folder_sheet.dart';
import 'edit_folder_sheet.dart';

class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return Drawer(
      backgroundColor: DesignColors.background(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vault Folders',
                    style: DesignTypography.display(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: DesignColors.text(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.create_new_folder_outlined,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => showAddFolderSheet(context, ref),
                    tooltip: 'Add Folder',
                  ),
                ],
              ),
            ),

            Divider(height: 1, indent: 20, endIndent: 20, color: DesignColors.border(context)),

            // List of Folders
            Expanded(
              child: foldersAsync.when(
                data: (folders) => _buildFolderList(
                  context,
                  ref,
                  folders,
                  selectedFolderId,
                  isDark,
                  colorScheme,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error loading folders: $err', style: TextStyle(color: colorScheme.error)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.1, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildFolderList(
    BuildContext context,
    WidgetRef ref,
    List<VirtualFolder> folders,
    String? selectedFolderId,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // "All Notes" (system folder)
        _buildFolderTile(
          context: context,
          name: 'All Notes',
          color: colorScheme.primary,
          icon: Icons.notes_rounded,
          isSelected: selectedFolderId == null,
          noteCount: null,
          isDark: isDark,
          onTap: () {
            ref.read(selectedFolderIdProvider.notifier).state = null;
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 6),
          child: Text(
            'CATEGORIES',
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: DesignColors.textTertiary(context),
            ),
          ),
        ),

        if (folders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: Text(
              'No virtual folders created yet. Tap the top icon to organize your files.',
              style: DesignTypography.details(
                context,
                fontSize: 12,
                color: DesignColors.textTertiary(context),
              ),
            ),
          )
        else
          ...folders.map((folder) {
            final isSelected = selectedFolderId == folder.id;
            final folderColor = folder.colorHex.toColor();

            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildFolderTile(
                context: context,
                name: folder.name,
                color: folderColor,
                icon: Icons.folder_rounded,
                isSelected: isSelected,
                noteCount: folder.noteCount,
                isDark: isDark,
                onTap: () {
                  ref.read(selectedFolderIdProvider.notifier).state = folder.id;
                  Navigator.pop(context);
                },
                onLongPress: () => showFolderOptions(context, ref, folder),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFolderTile({
    required BuildContext context,
    required String name,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required int? noteCount,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final activeTextColor = DesignColors.text(context);
    final inactiveTextColor = DesignColors.textSecondary(context);

    return TactileWrapper(
      onTap: onTap,
      onLongPress: onLongPress,
      style: onLongPress != null ? TactileFeedbackStyle.longPressLift : TactileFeedbackStyle.standard,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.15 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Folder Dot/Icon
              icon == Icons.notes_rounded
                  ? Icon(icon, size: 18, color: color)
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 16),

              // Name
              Expanded(
                child: Text(
                  name,
                  style: DesignTypography.body(
                    context,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),

              // Note Count Badge
              if (noteCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.25 : 0.2)
                        : DesignColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$noteCount',
                    style: DesignTypography.mono(
                      fontSize: 10,
                      color: isSelected ? color : inactiveTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void showAddFolderSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const AddFolderSheet(),
    );
  }

  static void showFolderOptions(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const DesignSheetDragHandle(),
            
            // Header
            ListTile(
              title: Text(
                'Folder: ${folder.name}',
                style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Edit
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('Edit details', style: DesignTypography.body(context)),
              onTap: () {
                Navigator.pop(ctx);
                showEditFolderSheet(context, ref, folder);
              },
            ),

            // Delete
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
              title: Text('Delete folder', style: DesignTypography.body(context, color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                DesignDialogs.showSimpleConfirmDialog(
                  context: context,
                  title: 'Delete Folder?',
                  content: 'This will delete the "${folder.name}" category organization. None of the physical markdown files will be deleted.',
                  confirmText: 'Delete',
                  onConfirm: () async {
                    // If deleted folder was active, clear filter
                    if (ref.read(selectedFolderIdProvider) == folder.id) {
                      ref.read(selectedFolderIdProvider.notifier).state = null;
                    }
                    await ref.read(folderRepositoryProvider).deleteFolder(folder.id);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void showEditFolderSheet(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => EditFolderSheet(folder: folder),
    );
  }
}
