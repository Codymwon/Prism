import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/l10n/l10n.dart';
import '../../core/services/vault_service.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../design_system/design_system.dart';
import 'dynamic_island_state.dart';
import 'prism_toast.dart';
import 'tactile_wrapper.dart';

/// In-island subdeck displaying available workspaces, active vault selection,
/// and inline workspace creation.
class WorkspaceSelectorDeck extends ConsumerStatefulWidget {
  final bool isCreatingWorkspace;

  const WorkspaceSelectorDeck({
    super.key,
    this.isCreatingWorkspace = false,
  });

  @override
  ConsumerState<WorkspaceSelectorDeck> createState() =>
      _WorkspaceSelectorDeckState();
}

class _WorkspaceSelectorDeckState
    extends ConsumerState<WorkspaceSelectorDeck> {
  late final TextEditingController _nameController;
  final FocusNode _focusNode = FocusNode();
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

  Future<void> _switchVault(String vaultName) async {
    HapticFeedback.selectionClick();
    ref.read(dynamicIslandControllerProvider.notifier).dismiss();

    try {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref
          .read(vaultManagementServiceProvider)
          .switchVault(vaultName: vaultName);
      if (mounted) {
        PrismToast.show(
          context,
          'Switched to workspace: $vaultName',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        PrismToast.show(
          context,
          context.l10n.notes_vault_selector_switch_error(e.toString()),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<void> _submitNewWorkspace() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final safePattern = RegExp(r'^[a-zA-Z0-9 _\-]+$');
    if (!safePattern.hasMatch(name)) {
      PrismToast.show(
        context,
        context.l10n.notes_vault_selector_validation_error,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baseDir = await ref.read(baseVaultsDirectoryProvider.future);
      ref.read(selectedFolderIdProvider.notifier).state = null;
      await ref.read(vaultManagementServiceProvider).createVault(
            vaultName: name,
            baseDir: baseDir,
          );
      ref.read(dynamicIslandControllerProvider.notifier).dismiss();
      if (mounted) {
        PrismToast.show(
          context,
          'Workspace "$name" created',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        PrismToast.show(
          context,
          context.l10n.notes_vault_selector_create_error(e.toString()),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVault =
        ref.watch(activeVaultNameProvider).valueOrNull ?? '';
    final vaultsAsync = ref.watch(availableVaultsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Back button, Title, and Workspace Count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TactileWrapper(
                    key: const ValueKey('workspace_selector_back_btn'),
                    style: TactileFeedbackStyle.standard,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (widget.isCreatingWorkspace) {
                        ref
                            .read(dynamicIslandControllerProvider.notifier)
                            .setCreatingWorkspace(false);
                      } else {
                        ref
                            .read(dynamicIslandControllerProvider.notifier)
                            .switchVaultHubSubDeck(VaultHubSubDeck.tools);
                      }
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
                    widget.isCreatingWorkspace
                        ? 'NEW WORKSPACE'
                        : 'WORKSPACES',
                    style: DesignTypography.heading(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              vaultsAsync.when(
                data: (vaults) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DesignColors.surfaceVariant(context)
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: DesignColors.border(context)
                          .withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${vaults.length} ${vaults.length == 1 ? 'Workspace' : 'Workspaces'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: DesignColors.textSecondary(context),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Content area: Inline Creation Form OR Scrollable Workspace List
          if (widget.isCreatingWorkspace)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignColors.surfaceVariant(context)
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignColors.primary(context).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      DesignIcons.folder,
                      size: 16,
                      color: DesignColors.primary(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('workspace_inline_input'),
                        controller: _nameController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: DesignTypography.body(context, fontSize: 13),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitNewWorkspace(),
                        decoration: InputDecoration(
                          hintText: 'Workspace name...',
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
                    if (_isSubmitting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      TactileWrapper(
                        key: const ValueKey('workspace_inline_confirm_btn'),
                        style: TactileFeedbackStyle.highImpact,
                        onTap: _submitNewWorkspace,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TactileWrapper(
                        key: const ValueKey('workspace_inline_cancel_btn'),
                        style: TactileFeedbackStyle.standard,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(dynamicIslandControllerProvider.notifier)
                              .setCreatingWorkspace(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: DesignColors.surfaceVariant(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: DesignColors.textTertiary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            Flexible(
              child: vaultsAsync.when(
                data: (vaults) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: vaults.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (ctx, idx) {
                      final vaultName = vaults[idx];
                      final isActive = vaultName == activeVault;

                      return TactileWrapper(
                        key: ValueKey('workspace_tile_$vaultName'),
                        style: TactileFeedbackStyle.standard,
                        onTap: () {
                          if (isActive) {
                            HapticFeedback.selectionClick();
                            ref
                                .read(dynamicIslandControllerProvider.notifier)
                                .dismiss();
                          } else {
                            _switchVault(vaultName);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary.withValues(alpha: 0.12)
                                : DesignColors.surfaceVariant(context)
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? colorScheme.primary.withValues(alpha: 0.4)
                                  : DesignColors.border(context)
                                      .withValues(alpha: 0.3),
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                DesignIcons.folder,
                                size: 16,
                                color: isActive
                                    ? colorScheme.primary
                                    : DesignColors.textSecondary(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vaultName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? colorScheme.primary
                                        : DesignColors.text(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  DesignIcons.check,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            TactileWrapper(
              key: const ValueKey('workspace_create_new_btn'),
              style: TactileFeedbackStyle.standard,
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(dynamicIslandControllerProvider.notifier)
                    .setCreatingWorkspace(true);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DesignColors.surfaceVariant(context)
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DesignColors.border(context)
                        .withValues(alpha: 0.3),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      DesignIcons.add,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create New Workspace',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
