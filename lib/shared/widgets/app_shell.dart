import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/l10n/l10n.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'tutorial_overlay.dart';
import 'prism_toast.dart';
import 'island_menu.dart';
import 'quick_capture_bottom_sheet.dart';
import 'vault_hub.dart';
import '../../features/notes/data/note_repository.dart';
import '../../features/notes/presentation/providers/notes_providers.dart';
import '../../features/notes/presentation/widgets/vault_selector_title.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../core/utils/utils.dart';
import 'dynamic_island_state.dart';
import 'workspace_selector_deck.dart';
import 'tag_cloud_deck.dart';
import 'create_folder_deck.dart';



class AppShell extends ConsumerStatefulWidget {
  final Widget? child;
  final StatefulNavigationShell? navigationShell;
  final String currentPath;

  const AppShell({
    super.key,
    this.child,
    this.navigationShell,
    required this.currentPath,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}


class _AppShellState extends ConsumerState<AppShell> with TickerProviderStateMixin {
  static const _kSpringBloomCurve = Cubic(0.34, 1.56, 0.64, 1.0);
  static const _kSpringDismissCurve = Cubic(0.4, 0.0, 0.2, 1.0);

  late final AnimationController _expansionController;
  late final AnimationController _timerController;
  late final Animation<double> _expansionAnimation;
  late final Animation<double> _shelfFadeAnimation;
  late final Animation<double> _pillScaleAnimation;

  late final AnimationController _menuExpansionController;
  late final Animation<double> _menuExpansionAnimation;
  late final Animation<double> _menuFadeAnimation;
  late final Animation<double> _menuItemScaleAnimation;

  late final AnimationController _quickCaptureController;
  late final Animation<double> _quickCaptureAnimation;
  late final Animation<double> _quickCaptureFadeAnimation;

  late final AnimationController _vaultHubController;
  late final Animation<double> _vaultHubAnimation;
  late final Animation<double> _vaultHubFadeAnimation;
  late final Animation<double> _vaultHubItemScaleAnimation;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: _kSpringBloomCurve,
      reverseCurve: _kSpringDismissCurve,
    );
    _shelfFadeAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );
    _pillScaleAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: const Interval(0.25, 0.95, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          ref.read(islandToastNotifierProvider.notifier).dismiss();
        }
      }
    });

    _menuExpansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _menuExpansionAnimation = CurvedAnimation(
      parent: _menuExpansionController,
      curve: _kSpringBloomCurve,
      reverseCurve: _kSpringDismissCurve,
    );
    _menuFadeAnimation = CurvedAnimation(
      parent: _menuExpansionController,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );
    _menuItemScaleAnimation = CurvedAnimation(
      parent: _menuExpansionController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );

    _quickCaptureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _quickCaptureAnimation = CurvedAnimation(
      parent: _quickCaptureController,
      curve: _kSpringBloomCurve,
      reverseCurve: _kSpringDismissCurve,
    );
    _quickCaptureFadeAnimation = CurvedAnimation(
      parent: _quickCaptureController,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );

    _vaultHubController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _vaultHubAnimation = CurvedAnimation(
      parent: _vaultHubController,
      curve: _kSpringBloomCurve,
      reverseCurve: _kSpringDismissCurve,
    );
    _vaultHubFadeAnimation = CurvedAnimation(
      parent: _vaultHubController,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
      reverseCurve: Curves.easeInCubic,
    );
    _vaultHubItemScaleAnimation = CurvedAnimation(
      parent: _vaultHubController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeInCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(tutorialStateProvider) && _currentIndex != 0) {
        if (widget.navigationShell != null) {
          widget.navigationShell!.goBranch(0);
        } else {
          context.go('/notes');
        }
      }
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If AppShell is covered by another modal route, collapse any active island toast, menu, quick capture, or vault hub
    if (ModalRoute.of(context)?.isCurrent == false) {
      if (_expansionController.value > 0.0) {
        _expansionController.reset();
        _timerController.stop();
        Future.microtask(() {
          if (mounted) ref.read(islandToastNotifierProvider.notifier).dismiss();
        });
      }
      if (_menuExpansionController.value > 0.0) {
        _menuExpansionController.reset();
        Future.microtask(() {
          if (mounted) ref.read(islandMenuNotifierProvider.notifier).dismiss();
        });
      }
      if (_quickCaptureController.value > 0.0) {
        _quickCaptureController.reset();
        Future.microtask(() {
          if (mounted) ref.read(quickCaptureNotifierProvider.notifier).dismiss();
        });
      }
      if (_vaultHubController.value > 0.0) {
        _vaultHubController.reset();
        Future.microtask(() {
          if (mounted) ref.read(vaultHubNotifierProvider.notifier).dismiss();
        });
      }
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _timerController.dispose();
    _menuExpansionController.dispose();
    _quickCaptureController.dispose();
    _vaultHubController.dispose();
    super.dispose();
  }

  int get _currentIndex {
    if (widget.navigationShell != null) {
      return widget.navigationShell!.currentIndex;
    }
    final path = widget.currentPath;
    final index = _tabs.indexWhere((tab) => path.startsWith(tab.path));
    return index == -1 ? 0 : index;
  }

  String _getTabLabel(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.l10n.shared_app_shell_tab_notes;
      case 1:
        return context.l10n.shared_app_shell_tab_journal;
      case 2:
        return context.l10n.shared_app_shell_tab_graph;
      case 3:
        return context.l10n.shared_app_shell_tab_settings;
      default:
        return '';
    }
  }

  static const _tabs = [
    _TabDef(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Notes', path: '/notes'),
    _TabDef(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Journal', path: '/journal'),
    _TabDef(icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'Graph', path: '/graph'),
    _TabDef(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  void _onTabTap(int index) {
    ref.read(dynamicIslandControllerProvider.notifier).dismiss();
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(
        index,
        initialLocation: index == widget.navigationShell!.currentIndex,
      );
      return;
    }
    if (index == _currentIndex) return;
    context.go(_tabs[index].path);
  }


  Widget _buildUpperShelf(
    BuildContext context,
    IslandToastData toast,
    double expansionValue,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(islandToastNotifierProvider.notifier).dismiss();
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
          ref.read(islandToastNotifierProvider.notifier).dismiss();
        }
      },
      onTapDown: (_) {
        _timerController.stop();
      },
      onTapUp: (_) {
        _timerController.forward();
      },
      onTapCancel: () {
        _timerController.forward();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Opacity(
          opacity: _shelfFadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - expansionValue) * 10.0),
            child: Transform.scale(
              scale: (0.82 + (0.18 * expansionValue)).clamp(0.80, 1.05),
              child: Row(
                children: [
                  if (toast.icon != null) ...[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: DesignColors.primary(context).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        toast.icon,
                        size: 13,
                        color: DesignColors.primary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      toast.message,
                      style: DesignTypography.body(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignColors.text(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (toast.actionText != null) ...[
                    const SizedBox(width: 8),
                    ScaleTransition(
                      scale: _pillScaleAnimation,
                      child: GestureDetector(
                        onTap: () {
                          toast.onAction?.call();
                          ref.read(islandToastNotifierProvider.notifier).dismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignColors.primary(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            toast.actionText!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionDeck(
    BuildContext context,
    IslandMenuData menu,
    double expansionValue,
  ) {
    return Container(
      height: 116.0,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignColors.border(context).withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
            HapticFeedback.selectionClick();
            ref.read(islandMenuNotifierProvider.notifier).dismiss();
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Opacity(
            opacity: _menuFadeAnimation.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1.0 - expansionValue) * 12.0),
              child: Transform.scale(
                scale: (0.85 + (0.15 * expansionValue)).clamp(0.80, 1.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  // Top row: Icon + Title
                  Row(
                    children: [
                      if (menu.icon != null) ...[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: DesignColors.primary(context).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            menu.icon,
                            size: 13,
                            color: DesignColors.primary(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          menu.title,
                          style: DesignTypography.body(
                            context,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DesignColors.text(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action buttons row
                  Row(
                    children: [
                      for (int i = 0; i < menu.items.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: ScaleTransition(
                            scale: _menuItemScaleAnimation,
                            child: _buildActionTile(context, menu.items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildActionTile(BuildContext context, IslandMenuItem item) {
    final isDestructive = item.isDestructive;
    final errorColor = Theme.of(context).colorScheme.error;
    final bgColor = isDestructive
        ? errorColor.withValues(alpha: 0.12)
        : DesignColors.surfaceVariant(context).withValues(alpha: 0.7);
    final borderColor = isDestructive
        ? errorColor.withValues(alpha: 0.3)
        : DesignColors.border(context).withValues(alpha: 0.5);
    final iconColor = isDestructive ? errorColor : DesignColors.primary(context);
    final textColor = isDestructive ? errorColor : DesignColors.text(context);

    return TactileWrapper(
      style: TactileFeedbackStyle.standard,
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(islandMenuNotifierProvider.notifier).dismiss();
        item.onTap();
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
            Icon(item.icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              item.label,
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

  Widget _buildQuickCaptureDeck(
    BuildContext context,
    QuickCaptureState state,
    double expansionValue,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignColors.border(context).withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 100) {
            HapticFeedback.selectionClick();
            ref.read(quickCaptureNotifierProvider.notifier).dismiss();
          }
        },
        child: Opacity(
          opacity: _quickCaptureFadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - expansionValue) * 12.0),
            child: Transform.scale(
              scale: (0.85 + (0.15 * expansionValue)).clamp(0.80, 1.05),
              child: state.mode == QuickCaptureMode.recording
                  ? QuickCaptureRecordingDeck(
                      state: state,
                      onCancel: () {
                        ref
                            .read(quickCaptureNotifierProvider.notifier)
                            .cancelRecording();
                      },
                      onCommit: () async {
                        await ref
                            .read(quickCaptureNotifierProvider.notifier)
                            .commitRecording(context);
                      },
                    )
                  : QuickCaptureActionsDeck(
                      onRecordVoiceMemo: () {
                        ref
                            .read(quickCaptureNotifierProvider.notifier)
                            .startRecording(context);
                      },
                      onBlankDocument: () {
                        ref
                            .read(quickCaptureNotifierProvider.notifier)
                            .createBlankNote(context);
                      },
                      onClose: () {
                        ref
                            .read(quickCaptureNotifierProvider.notifier)
                            .dismiss();
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaultHubDeck(
    BuildContext context,
    double expansionValue,
  ) {
    final islandState = ref.watch(dynamicIslandControllerProvider);
    final isCreating = islandState is DynamicIslandVaultHub &&
        islandState.isCreatingWorkspace;

    return Container(
      key: const ValueKey('vault_hub_action_deck'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: DesignColors.border(context).withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 100) {
            HapticFeedback.selectionClick();
            ref.read(dynamicIslandControllerProvider.notifier).dismiss();
          }
        },
        child: Opacity(
          opacity: _vaultHubFadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - expansionValue) * 12.0),
            child: Transform.scale(
              scale: (0.85 + (0.15 * expansionValue)).clamp(0.80, 1.05),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final inFromRight =
                      child.key == const ValueKey('subdeck_workspaces') ||
                      child.key == const ValueKey('subdeck_tags') ||
                      child.key == const ValueKey('subdeck_create_folder');
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(inFromRight ? 0.08 : -0.08, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: () {
                  if (islandState is DynamicIslandVaultHub) {
                    switch (islandState.subDeck) {
                      case VaultHubSubDeck.workspaceSelector:
                        return WorkspaceSelectorDeck(
                          key: const ValueKey('subdeck_workspaces'),
                          isCreatingWorkspace: isCreating,
                        );
                      case VaultHubSubDeck.tags:
                        return const TagCloudDeck(
                          key: ValueKey('subdeck_tags'),
                        );
                      case VaultHubSubDeck.createFolder:
                        return const CreateFolderDeck(
                          key: ValueKey('subdeck_create_folder'),
                        );
                      case VaultHubSubDeck.tools:
                        return _buildVaultHubToolsView(context);
                    }
                  }
                  return _buildVaultHubToolsView(context);
                }(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVaultHubToolsView(BuildContext context) {
    final statsAsync = ref.watch(vaultStatsProvider);
    final totalNotes = statsAsync.valueOrNull?.totalNotes ?? 0;

    return Padding(
      key: const ValueKey('subdeck_tools'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header row: VaultSelector title pill & Note count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: VaultSelectorTitle(),
              ),
              Container(
                key: const ValueKey('vault_hub_note_count_badge'),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignColors.surfaceVariant(context)
                      .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignColors.border(context)
                        .withValues(alpha: 0.5),
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
          const SizedBox(height: 8),
          // Action tiles row
          Row(
            children: [
              Expanded(
                child: ScaleTransition(
                  scale: _vaultHubItemScaleAnimation,
                  child: _buildVaultHubTile(
                    context,
                    key: const ValueKey('vault_hub_serendipity_tile'),
                    icon: Icons.shuffle_rounded,
                    label: 'Serendipity',
                    onTap: () {
                      ref
                          .read(dynamicIslandControllerProvider.notifier)
                          .dismiss();
                      openRandomNote(context, ref);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScaleTransition(
                  scale: _vaultHubItemScaleAnimation,
                  child: _buildVaultHubTile(
                    context,
                    key: const ValueKey('vault_hub_new_folder_tile'),
                    icon: Icons.create_new_folder_outlined,
                    label: 'New Folder',
                    onTap: () {
                      ref
                          .read(dynamicIslandControllerProvider.notifier)
                          .switchVaultHubSubDeck(VaultHubSubDeck.createFolder);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScaleTransition(
                  scale: _vaultHubItemScaleAnimation,
                  child: _buildVaultHubTile(
                    context,
                    key: const ValueKey('vault_hub_tags_tile'),
                    icon: Icons.tag_rounded,
                    label: 'Tags',
                    onTap: () {
                      ref
                          .read(dynamicIslandControllerProvider.notifier)
                          .switchVaultHubSubDeck(VaultHubSubDeck.tags);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ScaleTransition(
                  scale: _vaultHubItemScaleAnimation,
                  child: _buildVaultHubTile(
                    context,
                    key: const ValueKey('vault_hub_export_tile'),
                    icon: Icons.file_upload_outlined,
                    label: 'Export',
                    onTap: () {
                      ref
                          .read(dynamicIslandControllerProvider.notifier)
                          .dismiss();
                      context.push('/settings/vault-export');
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaultHubTile(
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

  Widget _buildHairlineTimer(BuildContext context) {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        final progress = 1.0 - _timerController.value;
        return Container(
          height: 1.5,
          width: double.infinity,
          color: DesignColors.border(context).withValues(alpha: 0.25),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              color: DesignColors.primary(context).withValues(alpha: 0.8),
            ),
          ),
        );
      },
    );
  }


  Future<void> _createDailyNoteForToday() async {
    final repo = ref.read(noteRepositoryProvider);
    final todayStr = formatDailyDate(DateTime.now());
    var note = await repo.getDailyNote(todayStr);

    if (note == null) {
      final buffer = StringBuffer();
      buffer.writeln('---');
      buffer.writeln('title: "Daily Reflection"');
      buffer.writeln('date: $todayStr');
      buffer.writeln('---');
      buffer.writeln();
      final initialContent = buffer.toString();

      note = await repo.createNote(
        title: 'Daily Reflection',
        initialContent: initialContent,
        isDaily: true,
        dailyDate: todayStr,
      );
    }

    if (mounted) {
      context.push('/editor/${note.id}?date=$todayStr&new=true');
    }
  }

  // ─── Mobile scaffold (original, untouched) ─────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context, ColorScheme colorScheme) {
    final islandState = ref.watch(dynamicIslandControllerProvider);
    final toastData = islandState is DynamicIslandToast ? islandState.toast : null;
    final menuData = islandState is DynamicIslandMenu ? islandState.menu : null;
    final qcData = islandState is DynamicIslandQuickCapture ? islandState.qcState : const QuickCaptureState();
    final isVaultHubOpen = islandState is DynamicIslandVaultHub;
    final isRecording = qcData.mode == QuickCaptureMode.recording;
    final targetQcHeight = isRecording ? 104.0 : 116.0;

    double targetHubDeckHeight = 128.0;
    if (islandState is DynamicIslandVaultHub) {
      switch (islandState.subDeck) {
        case VaultHubSubDeck.workspaceSelector:
          targetHubDeckHeight = 200.0;
          break;
        case VaultHubSubDeck.tags:
          targetHubDeckHeight = 200.0;
          break;
        case VaultHubSubDeck.createFolder:
          targetHubDeckHeight = 210.0;
          break;
        case VaultHubSubDeck.tools:
          targetHubDeckHeight = 128.0;
          break;
      }
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          if (widget.navigationShell != null)
            widget.navigationShell!
          else if (widget.child != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.015),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(_currentIndex),
                child: widget.child!,
              ),
            )
          else
            const SizedBox.shrink(),
          AnimatedBuilder(
            animation: Listenable.merge(
                [_menuExpansionController, _quickCaptureController, _vaultHubController]),
            builder: (context, child) {
              final menuVal = _menuExpansionController.value;
              final qcVal = _quickCaptureController.value;
              final hubVal = _vaultHubController.value;
              final maxVal = [menuVal, qcVal, hubVal].reduce(math.max);
              final scrimOpacity = maxVal.clamp(0.0, 1.0);
              if (scrimOpacity <= 0.001) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('island_modal_scrim'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(dynamicIslandControllerProvider.notifier).dismiss();
                  },
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35 * scrimOpacity),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _expansionController,
                  _menuExpansionController,
                  _quickCaptureController,
                  _vaultHubController,
                ]),
                builder: (context, child) {
                  final toastExpansion = _expansionAnimation.value;
                  final menuExpansion = _menuExpansionAnimation.value;
                  final qcExpansion = _quickCaptureAnimation.value;
                  final vaultHubExpansion = _vaultHubAnimation.value;

                  final toastExp = toastExpansion.clamp(0.0, 1.0);
                  final menuExp = menuExpansion.clamp(0.0, 1.0);
                  final qcExp = qcExpansion.clamp(0.0, 1.0);
                  final vaultHubExp = vaultHubExpansion.clamp(0.0, 1.0);

                  final toastHeight =
                      48.0 * (toastExpansion < 0.0 ? 0.0 : toastExpansion);
                  final menuHeight =
                      116.0 * (menuExpansion < 0.0 ? 0.0 : menuExpansion);
                  final qcHeight =
                      targetQcHeight * (qcExpansion < 0.0 ? 0.0 : qcExpansion);
                  final vaultHubHeight =
                      targetHubDeckHeight * (vaultHubExpansion < 0.0 ? 0.0 : vaultHubExpansion);
                  final currentHeight =
                      56.0 + toastHeight + menuHeight + qcHeight + vaultHubHeight + 1.6;

                  final activeExpansion = [
                    menuExpansion,
                    toastExpansion,
                    qcExpansion,
                    vaultHubExpansion,
                  ].reduce((a, b) => a > b ? a : b);
                  final cornerRadius =
                      (28.0 - (4.0 * activeExpansion)).clamp(20.0, 28.0);
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  final isSettings = _currentIndex == 3;

                  // FAB dimensions and transitions
                  final dockExp = [menuExp, vaultHubExp, qcExp].reduce(math.max);

                  final fabWidth = isSettings ? 0.0 : 56.0;

                  // Universal Fusion: All 3 active decks (Menu, Vault Hub, Quick Capture) expand
                  // capsule width from (totalWidth - 68) to full totalWidth (16dp left, 16dp right).
                  final widthAddition = 68.0 * dockExp;
                  final capsuleWidth = isSettings
                      ? totalWidth
                      : (totalWidth - 68.0 + widthAddition).clamp(0.0, totalWidth);

                  final fabScale =
                      (1.0 - (0.09 * toastExp)).clamp(0.0, 1.0);
                  final fabOpacity = 1.0;

                  return SizedBox(
                    width: totalWidth,
                    height: currentHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Monolithic Expanding Capsule
                        Positioned(
                          left: 0,
                          bottom: 0,
                          width: capsuleWidth,
                          height: currentHeight,
                          child: Container(
                            key: const ValueKey('monolithic_capsule'),
                            height: currentHeight,
                            decoration: BoxDecoration(
                              color: DesignColors.surface(context)
                                  .withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(cornerRadius),
                              border: Border.all(
                                color: DesignColors.border(context)
                                    .withValues(alpha: 0.75),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark
                                        ? (0.12 +
                                            0.15 * activeExpansion.clamp(0.0, 1.0))
                                        : (0.05 +
                                            0.06 * activeExpansion.clamp(0.0, 1.0)),
                                  ),
                                  blurRadius:
                                      10 + 6 * activeExpansion.clamp(0.0, 1.0),
                                  offset: Offset(
                                      0, 4 + 2 * activeExpansion.clamp(0.0, 1.0)),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(cornerRadius),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isVaultHubOpen)
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor: vaultHubExpansion.clamp(0.0, 1.0),
                                          child: SizedBox(
                                            height: targetHubDeckHeight,
                                            child: _buildVaultHubDeck(
                                              context,
                                              vaultHubExpansion,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (qcData.isOpen)
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor: qcExpansion.clamp(0.0, 1.0),
                                          child: SizedBox(
                                            height: targetQcHeight,
                                            child: _buildQuickCaptureDeck(
                                              context,
                                              qcData,
                                              qcExpansion,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (menuData != null)
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor: menuExpansion.clamp(0.0, 1.0),
                                          child: SizedBox(
                                            height: 116.0,
                                            child: _buildActionDeck(
                                              context,
                                              menuData,
                                              menuExpansion,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (toastData != null)
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor:
                                              toastExpansion.clamp(0.0, 1.0),
                                          child: SizedBox(
                                            height: 48.0,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                SizedBox(
                                                  height: 46.5,
                                                  child: _buildUpperShelf(
                                                    context,
                                                    toastData,
                                                    toastExpansion,
                                                  ),
                                                ),
                                                _buildHairlineTimer(context),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                      height: 56,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: List.generate(_tabs.length, (i) {
                                                final tab = _tabs[i];
                                                final isActive = i == _currentIndex;
                                                return Expanded(
                                                  child: TactileWrapper(
                                                    style: TactileFeedbackStyle.standard,
                                                    onTap: () => _onTabTap(i),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        AnimatedSwitcher(
                                                          duration: const Duration(
                                                              milliseconds: 200),
                                                          child: Icon(
                                                            isActive
                                                                ? tab.activeIcon
                                                                : tab.icon,
                                                            key: ValueKey(isActive),
                                                            size: 22,
                                                            color: isActive
                                                                ? colorScheme.primary
                                                                : DesignColors.textTertiary(
                                                                    context),
                                                          ),
                                                        )
                                                            .animate(
                                                                target: isActive ? 1 : 0)
                                                            .scaleXY(
                                                              begin: 0.9,
                                                              end: 1.0,
                                                              duration: 150.ms,
                                                              curve: Curves.easeOut,
                                                            ),
                                                        const SizedBox(height: 3),
                                                        AnimatedDefaultTextStyle(
                                                          duration: const Duration(
                                                              milliseconds: 200),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: isActive
                                                                ? FontWeight.w600
                                                                : FontWeight.w400,
                                                            color: isActive
                                                                ? colorScheme.primary
                                                                : DesignColors.textTertiary(
                                                                    context),
                                                          ),
                                                          child: Text(_getTabLabel(
                                                              context, i)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                          if (!isSettings)
                                            SizedBox(width: 68.0 * dockExp),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Integrated / Magnetic Circular FAB
                        if (fabWidth >= 1.0)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            width: fabWidth,
                            height: 56,
                            child: Transform.scale(
                              scale: fabScale,
                              child: Opacity(
                                opacity: fabOpacity,
                                child: Center(
                                  child: SizedBox(
                                    width: fabWidth,
                                    height: fabWidth,
                                    child: TactileWrapper(
                                      key: const ValueKey('app_shell_fab'),
                                      style: TactileFeedbackStyle.highImpact,
                                      onTap: () {
                                        final islandState = ref.read(dynamicIslandControllerProvider);
                                        if (islandState.isActive && !islandState.isToast) {
                                          HapticFeedback.selectionClick();
                                          ref.read(dynamicIslandControllerProvider.notifier).dismiss();
                                          return;
                                        }
                                        if (_currentIndex == 1) {
                                          _createDailyNoteForToday();
                                        } else {
                                          final qcState =
                                              ref.read(quickCaptureNotifierProvider);
                                          if (qcState.isOpen) {
                                            ref
                                                .read(quickCaptureNotifierProvider
                                                    .notifier)
                                                .dismiss();
                                          } else {
                                            ref
                                                .read(quickCaptureNotifierProvider
                                                    .notifier)
                                                .open();
                                          }
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            if (dockExp < 0.95)
                                              BoxShadow(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.3 * (1.0 - dockExp)),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                          ],
                                        ),
                                        child: Transform.rotate(
                                          angle: dockExp * (math.pi / 4), // 45 degrees
                                          child: Icon(
                                            Icons.add,
                                            color: colorScheme.onPrimary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    ref.listen<DynamicIslandState>(dynamicIslandControllerProvider,
        (previous, next) {
      if (ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      switch (next) {
        case DynamicIslandResting():
          HapticFeedback.selectionClick();
          _expansionController.reverse();
          _menuExpansionController.reverse();
          _quickCaptureController.reverse();
          _vaultHubController.reverse();
          _timerController.stop();
        case DynamicIslandToast(:final toast):
          _menuExpansionController.reverse();
          _quickCaptureController.reverse();
          _vaultHubController.reverse();
          if (previous is! DynamicIslandToast ||
              !_expansionController.isCompleted) {
            HapticFeedback.selectionClick();
            _expansionController.forward();
          }
          _timerController.duration = toast.duration;
          _timerController.forward(from: 0.0);
        case DynamicIslandMenu():
          _expansionController.reverse();
          _quickCaptureController.reverse();
          _vaultHubController.reverse();
          _timerController.stop();
          HapticFeedback.selectionClick();
          _menuExpansionController.forward();
        case DynamicIslandQuickCapture():
          _expansionController.reverse();
          _menuExpansionController.reverse();
          _vaultHubController.reverse();
          _timerController.stop();
          HapticFeedback.selectionClick();
          _quickCaptureController.forward();
        case DynamicIslandVaultHub():
          _expansionController.reverse();
          _menuExpansionController.reverse();
          _quickCaptureController.reverse();
          _timerController.stop();
          HapticFeedback.selectionClick();
          _vaultHubController.forward();
      }
    });

    ref.listen<bool>(tutorialStateProvider, (previous, next) {
      if (!next && _currentIndex != 0) {
        if (widget.navigationShell != null) {
          widget.navigationShell!.goBranch(0);
        } else {
          context.go('/notes');
        }
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    final hasCompletedTutorial = ref.watch(tutorialStateProvider);
    final hasCompletedJournalTutorial = ref.watch(journalTutorialStateProvider);

    final selectedFolderId = ref.watch(selectedFolderIdProvider);
    final isNotesTab = _currentIndex == 0;

    final mainScaffold = PopScope(
      canPop: !isNotesTab || selectedFolderId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isNotesTab && selectedFolderId != null) {
          ref.read(selectedFolderIdProvider.notifier).state = null;
        }
      },
      child: _buildMobileScaffold(context, colorScheme),
    );

    if (hasCompletedTutorial) {
      if (!hasCompletedJournalTutorial && _currentIndex == 1) {
        final journalTutorialSteps = [
          TutorialStep(
            title: context.l10n.shared_app_shell_tutorial_journal_nav_title,
            description: context.l10n.shared_app_shell_tutorial_journal_nav_desc,
            icon: Icons.calendar_month_outlined,
            getTargetRect: (size) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Rect.fromLTWH(size.width - 64, topPadding + 16, 48, 48);
            },
          ),
          TutorialStep(
            title: context.l10n.shared_app_shell_tutorial_journal_strip_title,
            description: context.l10n.shared_app_shell_tutorial_journal_strip_desc,
            icon: Icons.view_week_rounded,
            getTargetRect: (size) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Rect.fromLTWH(
                16,
                topPadding + 68,
                size.width - 32,
                56,
              );
            },
          ),
          TutorialStep(
            title: context.l10n.shared_app_shell_tutorial_journal_streak_title,
            description: context.l10n.shared_app_shell_tutorial_journal_streak_desc,
            icon: Icons.local_fire_department_rounded,
            getTargetRect: (size) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Rect.fromLTWH(
                16,
                topPadding + 130,
                size.width - 32,
                102,
              );
            },
          ),
          TutorialStep(
            title: context.l10n.shared_app_shell_tutorial_journal_template_title,
            description: context.l10n.shared_app_shell_tutorial_journal_template_desc,
            icon: Icons.description_rounded,
            getTargetRect: (size) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Rect.fromLTWH(
                16,
                topPadding + 240,
                size.width - 32,
                64,
              );
            },
          ),
        ];

        return Stack(
          children: [
            mainScaffold,
            SpotlightTutorialOverlay(
              steps: journalTutorialSteps,
              onCompleted: () => ref.read(journalTutorialStateProvider.notifier).completeTutorial(),
              onSkipped: () => ref.read(journalTutorialStateProvider.notifier).completeTutorial(),
            ),
          ],
        );
      }
      return mainScaffold;
    }

    final tutorialSteps = [

      TutorialStep(
        title: context.l10n.shared_app_shell_tutorial_notes_nav_title,
        description: context.l10n.shared_app_shell_tutorial_notes_nav_desc,
        icon: Icons.folder_open_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(6, topPadding + 4, 48, 48);
        },
      ),
      TutorialStep(
        title: context.l10n.shared_app_shell_tutorial_notes_folders_title,
        description: context.l10n.shared_app_shell_tutorial_notes_folders_desc,
        icon: Icons.folder_open_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(16, topPadding + 120, size.width - 32, 90);
        },
      ),
      TutorialStep(
        title: context.l10n.shared_app_shell_tutorial_notes_daily_title,
        description: context.l10n.shared_app_shell_tutorial_notes_daily_desc,
        icon: Icons.calendar_today_rounded,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final tabWidth = (size.width - 32 - 12 - 56) / 4;
          final left = 16 + tabWidth * 1;
          final top = size.height - 56 - 12 - bottomPadding;
          return Rect.fromLTWH(left, top, tabWidth, 56);
        },
      ),
      TutorialStep(
        title: context.l10n.shared_app_shell_tutorial_notes_graph_title,
        description: context.l10n.shared_app_shell_tutorial_notes_graph_desc,
        icon: Icons.hub_outlined,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final tabWidth = (size.width - 32 - 12 - 56) / 4;
          final left = 16 + tabWidth * 2;
          final top = size.height - 56 - 12 - bottomPadding;
          return Rect.fromLTWH(left, top, tabWidth, 56);
        },
      ),
      TutorialStep(
        title: context.l10n.shared_app_shell_tutorial_notes_create_title,
        description: context.l10n.shared_app_shell_tutorial_notes_create_desc,
        icon: Icons.add_circle_outline_rounded,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final left = size.width - 72;
          final top = size.height - 56 - 12 - bottomPadding;
          return Rect.fromLTWH(left, top, 56, 56);
        },
      ),
    ];

    return Stack(
      children: [
        mainScaffold,
        SpotlightTutorialOverlay(
          steps: tutorialSteps,
          onCompleted: () => ref.read(tutorialStateProvider.notifier).completeTutorial(),
          onSkipped: () => ref.read(tutorialStateProvider.notifier).completeTutorial(),
        ),
      ],
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabDef({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
