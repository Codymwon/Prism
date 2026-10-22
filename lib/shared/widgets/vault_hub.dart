import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/l10n/l10n.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'prism_toast.dart';
import 'app_shell.dart';
import '../../features/notes/data/note_repository.dart';
import '../../features/notes/presentation/providers/notes_providers.dart';
import '../../features/notes/presentation/widgets/vault_selector_title.dart';
import '../../features/folders/presentation/widgets/tag_cloud_index.dart';

import 'dynamic_island_state.dart';

/// Riverpod notifier coordinating Vault Hub Action Deck state across the app.
class VaultHubNotifier extends Notifier<bool> {
  @override
  bool build() {
    final state = ref.watch(dynamicIslandControllerProvider);
    return state is DynamicIslandVaultHub;
  }

  void open() {
    ref.read(dynamicIslandControllerProvider.notifier).openVaultHub();
  }

  void dismiss() {
    final s = ref.read(dynamicIslandControllerProvider);
    if (s is DynamicIslandVaultHub) {
      ref.read(dynamicIslandControllerProvider.notifier).dismiss();
    }
  }

  void toggle() {
    ref.read(dynamicIslandControllerProvider.notifier).toggleVaultHub();
  }
}

final vaultHubNotifierProvider =
    NotifierProvider<VaultHubNotifier, bool>(VaultHubNotifier.new);

/// Helper function to open a random note from the active workspace.
Future<void> openRandomNote(BuildContext context, WidgetRef ref) async {
  try {
    final repo = ref.read(noteRepositoryProvider);
    final allNotes = await repo.getAllNotes();
    final eligibleNotes =
        allNotes.where((n) => !n.isDaily && !n.isGhost).toList();

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

    final randomNote =
        eligibleNotes[math.Random().nextInt(eligibleNotes.length)];

    if (context.mounted) {
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

/// Helper function to display the TagCloudIndex in a modal bottom sheet.
void showTagCloudModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: DesignColors.background(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignSpacing.borderRadiusLarge),
      ),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TAGS',
                  style: DesignTypography.heading(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TagCloudIndex(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

/// Helper class to invoke or dismiss the Dynamic Island Vault Hub.
/// Falls back to a standard modal bottom sheet when outside AppShell.
class VaultHub {
  static void show(BuildContext context) {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    final hasAppShell =
        context.findAncestorWidgetOfExactType<AppShell>() != null ||
        context.widget is AppShell;

    if (container != null && hasAppShell) {
      container.read(dynamicIslandControllerProvider.notifier).openVaultHub();
      return;
    }

    // Fallback bottom sheet on non-AppShell screens
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSpacing.borderRadiusLarge),
        ),
      ),
      builder: (ctx) => const VaultHubFallbackSheet(),
    );
  }

  static void dismiss(BuildContext context) {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    if (container != null) {
      container.read(dynamicIslandControllerProvider.notifier).dismiss();
    }
  }

  static void toggle(BuildContext context) {
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      container = null;
    }

    if (container != null) {
      container.read(dynamicIslandControllerProvider.notifier).toggleVaultHub();
    }
  }
}

/// Fallback modal bottom sheet for screens without AppShell.
class VaultHubFallbackSheet extends ConsumerWidget {
  const VaultHubFallbackSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vaultStatsProvider);
    final totalNotes = statsAsync.valueOrNull?.totalNotes ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: VaultSelectorTitle()),
                Container(
                  key: const ValueKey('vault_hub_fallback_note_count_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context)
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          DesignColors.border(context).withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 13,
                        color: DesignColors.primary(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$totalNotes ${totalNotes == 1 ? 'Note' : 'Notes'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DesignColors.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTile(
                    context,
                    key: const ValueKey('vault_hub_fallback_serendipity'),
                    icon: Icons.shuffle_rounded,
                    label: 'Serendipity',
                    onTap: () {
                      Navigator.of(context).pop();
                      openRandomNote(context, ref);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTile(
                    context,
                    key: const ValueKey('vault_hub_fallback_new_folder'),
                    icon: Icons.create_new_folder_outlined,
                    label: 'New Folder',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/folders/create');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTile(
                    context,
                    key: const ValueKey('vault_hub_fallback_tags'),
                    icon: Icons.tag_rounded,
                    label: 'Tags',
                    onTap: () {
                      Navigator.of(context).pop();
                      showTagCloudModal(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTile(
                    context,
                    key: const ValueKey('vault_hub_fallback_export'),
                    icon: Icons.file_upload_outlined,
                    label: 'Export',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/settings/vault-export');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bgColor =
        DesignColors.surfaceVariant(context).withValues(alpha: 0.7);
    final borderColor = DesignColors.border(context).withValues(alpha: 0.5);
    final iconColor = DesignColors.primary(context);
    final textColor = DesignColors.text(context);

    return TactileWrapper(
      key: key,
      style: TactileFeedbackStyle.standard,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
