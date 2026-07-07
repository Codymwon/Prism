import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/widgets/tactile_wrapper.dart';
import '../../data/folder_model.dart';
import '../../data/folder_repository.dart';
import '../providers/folders_providers.dart';
import '../../../notes/data/note_repository.dart';
import '../../../notes/presentation/widgets/vault_selector_title.dart';
import 'tag_cloud_index.dart';
import 'vault_stats_board.dart';
import 'package:prism/l10n/l10n.dart';

class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  Future<void> _openRandomNote(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(noteRepositoryProvider);
      final allNotes = await repo.getAllNotes();
      final eligibleNotes = allNotes.where((n) => !n.isDaily && !n.isGhost).toList();
      
      if (eligibleNotes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.folders_drawer_no_notes)),
          );
        }
        return;
      }
      
      final randomNote = eligibleNotes[Random().nextInt(eligibleNotes.length)];
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close drawer
        context.push('/editor/${randomNote.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.folders_drawer_random_note_error(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: DesignColors.background(context),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: PRISM Title & Vault Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRISM',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Flexible(
                      child: VaultSelectorTitle(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),

              // Tools Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'TOOLS',
                  style: DesignTypography.metadata(
                    context,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DesignColors.textTertiary(context),
                  ).copyWith(letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 8),

              // Manage Templates Shortcut
              _buildToolTile(
                context,
                icon: Icons.description_outlined,
                title: context.l10n.folders_drawer_manage_templates,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/custom-templates');
                },
              ),
              const SizedBox(height: 8),

              // Manage Macros Shortcut
              _buildToolTile(
                context,
                icon: Icons.bolt_outlined,
                title: context.l10n.folders_drawer_manage_macros,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/custom-macros');
                },
              ),
              const SizedBox(height: 8),

              // Serendipity (Random Note) Tool
              _buildToolTile(
                context,
                icon: Icons.shuffle_rounded,
                title: 'Serendipity',
                onTap: () => _openRandomNote(context, ref),
              ),
              const SizedBox(height: 24),

              // Tag Index Section
              const TagCloudIndex(),
              const SizedBox(height: 24),

              // Vault Statistics Section
              const VaultStatsBoard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: DesignColors.surfaceVariant(context),
          borderRadius: BorderRadius.circular(DesignSpacing.borderRadiusMedium),
          border: Border.all(
            color: DesignColors.border(context),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: DesignColors.primary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: DesignTypography.body(
                  context,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DesignColors.text(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: DesignColors.textTertiary(context),
            ),
          ],
        ),
      ),
    );
  }

  static void navigateToAddFolderScreen(BuildContext context) {
    context.push('/folders/create');
  }

  static void showFolderOptions(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
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
                context.l10n.folders_drawer_folder_menu_title(folder.name),
                style: DesignTypography.heading(context, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Edit
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.folders_drawer_edit_details, style: DesignTypography.body(context)),
              onTap: () {
                Navigator.pop(ctx);
                navigateToEditFolderScreen(context, folder.id);
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
                  content: context.l10n.folders_drawer_delete_warning(folder.name),
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

  static void navigateToEditFolderScreen(BuildContext context, String folderId) {
    context.push('/folders/edit/$folderId');
  }
}