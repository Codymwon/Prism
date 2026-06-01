import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../../../core/utils/utils.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';
import '../providers/folders_providers.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import 'add_folder_sheet.dart';
import 'edit_folder_sheet.dart';
import 'vault_status_panel.dart';
import 'tag_cloud_index.dart';
import 'vault_stats_board.dart';

class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final foldersAsync = ref.watch(foldersProvider);

    return Drawer(
      backgroundColor: DesignColors.background(context),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header status card
                    const VaultStatusPanel(),
                    const SizedBox(height: 20),

                    // 2. Command Shortcuts
                    _buildShortcutsSection(context, ref, selectedFolderId, selectedTag, colorScheme),
                    const SizedBox(height: 20),

                    // 3. Categories / Folders Section
                    _buildFoldersSection(context, ref, foldersAsync, selectedFolderId, colorScheme),
                    const SizedBox(height: 20),

                    // 4. Tag Index Section
                    const TagCloudIndex(),
                    const SizedBox(height: 20),

                    // 5. Vault Statistics Section
                    const VaultStatsBoard(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 6. Settings Quick Tile (Bottom Anchored)
            const Divider(height: 1),
            _buildSettingsTile(context),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.1, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildShortcutsSection(
    BuildContext context,
    WidgetRef ref,
    String? selectedFolderId,
    String? selectedTag,
    ColorScheme colorScheme,
  ) {
    final shortcuts = [
      (
        'All Notes',
        Icons.article_outlined,
        selectedFolderId == null && selectedTag == null,
        () {
          ref.read(selectedFolderIdProvider.notifier).state = null;
          ref.read(selectedTagProvider.notifier).state = null;
          Navigator.of(context).pop();
        }
      ),
      (
        'Daily Journal',
        Icons.calendar_today_outlined,
        false,
        () {
          Navigator.of(context).pop();
          context.go('/journal');
        }
      ),
      (
        'Graph Connection',
        Icons.hub_outlined,
        false,
        () {
          Navigator.of(context).pop();
          context.go('/graph');
        }
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            'COMMAND SHORTCUTS',
            style: DesignTypography.metadata(
              context,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: DesignColors.textTertiary(context),
            ).copyWith(letterSpacing: 1.0),
          ),
        ),
        Column(
          children: shortcuts.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TactileWrapper(
                style: TactileFeedbackStyle.standard,
                onTap: s.$4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: s.$3
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: s.$3
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.$2,
                        size: 16,
                        color: s.$3 ? colorScheme.primary : DesignColors.textSecondary(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.$1,
                        style: DesignTypography.body(
                          context,
                          fontSize: 13,
                          fontWeight: s.$3 ? FontWeight.w700 : FontWeight.w500,
                          color: s.$3 ? colorScheme.primary : DesignColors.text(context),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: DesignColors.textTertiary(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFoldersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VirtualFolder>> foldersAsync,
    String? selectedFolderId,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOLDERS / CATEGORIES',
                style: DesignTypography.metadata(
                  context,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DesignColors.textTertiary(context),
                ).copyWith(letterSpacing: 1.0),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  showAddFolderSheet(context, ref);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '+ Add',
                    style: DesignTypography.body(
                      context,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        foldersAsync.when(
          data: (folders) {
            if (folders.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Text(
                  'No folders created yet.',
                  style: DesignTypography.details(
                    context,
                    fontSize: 11,
                    color: DesignColors.textTertiary(context),
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              );
            }

            return Column(
              children: folders.map((folder) {
                final isSelected = selectedFolderId == folder.id;
                final folderColor = folder.colorHex.toColor();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TactileWrapper(
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      ref.read(selectedFolderIdProvider.notifier).state = folder.id;
                      ref.read(selectedTagProvider.notifier).state = null;
                      Navigator.of(context).pop();
                    },
                    onLongPress: () {
                      Navigator.of(context).pop();
                      showFolderOptions(context, ref, folder);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? folderColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? folderColor.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: folderColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              folder.name,
                              style: DesignTypography.body(
                                context,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: DesignColors.text(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? folderColor.withValues(alpha: 0.25)
                                  : DesignColors.surfaceVariant(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${folder.noteCount}',
                              style: DesignTypography.mono(
                                fontSize: 10,
                                color: isSelected ? folderColor : DesignColors.textSecondary(context),
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (err, _) => Text('Error: $err', style: TextStyle(color: colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () {
        Navigator.of(context).pop();
        context.go('/settings');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              size: 18,
              color: DesignColors.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Text(
              'Vault Settings',
              style: DesignTypography.body(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignColors.textSecondary(context),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: DesignColors.textTertiary(context),
            ),
          ],
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
