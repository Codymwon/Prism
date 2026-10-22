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
import '../../../../shared/widgets/prism_toast.dart';
import '../../../../shared/widgets/island_menu.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/config/app_config.dart';

class FolderDrawer extends ConsumerWidget {
  const FolderDrawer({super.key});

  Future<void> _openRandomNote(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(noteRepositoryProvider);
      final allNotes = await repo.getAllNotes();
      final eligibleNotes = allNotes.where((n) => !n.isDaily && !n.isGhost).toList();
      
      if (eligibleNotes.isEmpty) {
        if (context.mounted) {
          PrismToast.show(
            context,
            context.l10n.folders_drawer_no_notes,
            icon: Icons.explore_off_outlined,
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
        PrismToast.show(
          context,
          context.l10n.folders_drawer_random_note_error(e.toString()),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPro = ref.watch(isProProvider);

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

              // Manage Templates & Macros Shortcuts
              if (AppConfig.enableSubscriptions) ...[
                _buildToolTile(
                  context,
                  icon: Icons.description_outlined,
                  title: context.l10n.folders_drawer_manage_templates,
                  isLocked: !isPro,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isPro) {
                      context.push('/settings/paywall');
                    } else {
                      context.push('/settings/custom-templates');
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Manage Macros Shortcut
                _buildToolTile(
                  context,
                  icon: Icons.bolt_outlined,
                  title: context.l10n.folders_drawer_manage_macros,
                  isLocked: !isPro,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (!isPro) {
                      context.push('/settings/paywall');
                    } else {
                      context.push('/settings/custom-macros');
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],

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
    bool isLocked = false,
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
              isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
              size: 16,
              color: isLocked ? DesignColors.primary(context) : DesignColors.textTertiary(context),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> navigateToAddFolderScreen(BuildContext context) async {
    final result = await context.push<String>('/folders/create');
    if (result != null && context.mounted) {
      PrismToast.show(
        context,
        'Folder "$result" created',
        icon: Icons.create_new_folder_outlined,
      );
    }
  }

  static void showFolderOptions(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    IslandMenu.show(
      context,
      title: folder.name,
      icon: Icons.folder_outlined,
      items: [
        IslandMenuItem(
          label: context.l10n.folders_drawer_edit_details,
          icon: Icons.edit_outlined,
          onTap: () {
            navigateToEditFolderScreen(context, folder.id);
          },
        ),
        IslandMenuItem(
          label: 'Delete Folder',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onTap: () {
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
                if (context.mounted) {
                  PrismToast.show(
                    context,
                    'Folder "${folder.name}" deleted',
                    icon: Icons.delete_outline_rounded,
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  static Future<void> navigateToEditFolderScreen(BuildContext context, String folderId) async {
    final result = await context.push<String>('/folders/edit/$folderId');
    if (result != null && context.mounted) {
      PrismToast.show(
        context,
        'Folder "$result" updated',
        icon: Icons.folder_outlined,
      );
    }
  }
}