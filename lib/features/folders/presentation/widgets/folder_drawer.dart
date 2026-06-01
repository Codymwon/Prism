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
import '../../../notes/data/note_model.dart';
import 'add_folder_sheet.dart';
import 'edit_folder_sheet.dart';
import 'folder_icon_display.dart';
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
    final recentNotesAsync = ref.watch(notesProvider);

    return Drawer(
      backgroundColor: DesignColors.background(context),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Recent Notes
              _buildRecentNotesSection(context, ref, recentNotesAsync, colorScheme),
              const SizedBox(height: 20),

              // 3. Categories / Folders Section (includes All Notes reset)
              _buildFoldersSection(context, ref, foldersAsync, selectedFolderId, selectedTag, colorScheme),
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
    ).animate().slideX(begin: -0.1, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildRecentNotesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Note>> notesAsync,
    ColorScheme colorScheme,
  ) {
    return notesAsync.when(
      data: (notes) {
        // Filter out ghost/daily notes, take top 4 by updatedAt (already sorted)
        final recent = notes
            .where((n) => !n.isGhost && !n.isDaily)
            .take(4)
            .toList();

        if (recent.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 8),
              child: Text(
                'RECENTLY EDITED',
                style: DesignTypography.metadata(
                  context,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DesignColors.textTertiary(context),
                ).copyWith(letterSpacing: 1.0),
              ),
            ),
            ...recent.map((note) {
              final timeAgo = _formatTimeAgo(note.updatedAt);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TactileWrapper(
                  style: TactileFeedbackStyle.standard,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/editor/${note.id}');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: DesignColors.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: DesignColors.textTertiary(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: DesignTypography.body(
                                  context,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DesignColors.text(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeAgo,
                                style: DesignTypography.metadata(
                                  context,
                                  fontSize: 10,
                                  color: DesignColors.textTertiary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: DesignColors.textTertiary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildFoldersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<VirtualFolder>> foldersAsync,
    String? selectedFolderId,
    String? selectedTag,
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
        // "All Notes" reset row — clears any active folder / tag filter
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: TactileWrapper(
            style: TactileFeedbackStyle.standard,
            onTap: () {
              ref.read(selectedFolderIdProvider.notifier).state = null;
              ref.read(selectedTagProvider.notifier).state = null;
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (selectedFolderId == null && selectedTag == null)
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (selectedFolderId == null && selectedTag == null)
                      ? colorScheme.primary.withValues(alpha: 0.2)
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
                      color: (selectedFolderId == null && selectedTag == null)
                          ? colorScheme.primary
                          : DesignColors.textTertiary(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Notes',
                      style: DesignTypography.body(
                        context,
                        fontSize: 13,
                        fontWeight: (selectedFolderId == null && selectedTag == null)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: (selectedFolderId == null && selectedTag == null)
                            ? colorScheme.primary
                            : DesignColors.text(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                          FolderIconDisplay(
                            iconKey: folder.icon,
                            color: folderColor,
                            size: 36,
                            badgeSize: 9,
                          ),
                          const SizedBox(width: 10),
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
