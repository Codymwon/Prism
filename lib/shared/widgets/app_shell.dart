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
import '../../features/notes/data/note_repository.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../core/utils/utils.dart';



class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If AppShell is covered by another modal route, collapse any active island toast, menu, or quick capture
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
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _timerController.dispose();
    _menuExpansionController.dispose();
    _quickCaptureController.dispose();
    super.dispose();
  }

  int get _currentIndex {
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
    ref.read(islandToastNotifierProvider.notifier).dismiss();
    ref.read(islandMenuNotifierProvider.notifier).dismiss();
    ref.read(quickCaptureNotifierProvider.notifier).dismiss();
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
                  // Top row: Icon + Title + Close Button
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
                      const SizedBox(width: 8),
                      GestureDetector(
                        key: const ValueKey('island_menu_close'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(islandMenuNotifierProvider.notifier).dismiss();
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: DesignColors.border(context).withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: DesignColors.textSecondary(context),
                          ),
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
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
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
              child: widget.child,
            ),
          ),
          AnimatedBuilder(
            animation: Listenable.merge(
                [_menuExpansionController, _quickCaptureController]),
            builder: (context, child) {
              final menuVal = _menuExpansionController.value;
              final qcVal = _quickCaptureController.value;
              final maxVal = menuVal > qcVal ? menuVal : qcVal;
              final scrimOpacity = maxVal.clamp(0.0, 1.0);
              if (scrimOpacity <= 0.001) return const SizedBox.shrink();
              return Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('island_modal_scrim'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(islandMenuNotifierProvider.notifier).dismiss();
                    ref.read(quickCaptureNotifierProvider.notifier).dismiss();
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Monolithic Expanding Capsule
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _expansionController,
                    _menuExpansionController,
                    _quickCaptureController,
                  ]),
                  builder: (context, child) {
                    final toastExpansion = _expansionAnimation.value;
                    final menuExpansion = _menuExpansionAnimation.value;
                    final qcExpansion = _quickCaptureAnimation.value;

                    final qcData = ref.watch(quickCaptureNotifierProvider);
                    final isRecording =
                        qcData.mode == QuickCaptureMode.recording;
                    final targetQcHeight = isRecording ? 104.0 : 116.0;

                    final toastHeight =
                        48.0 * (toastExpansion < 0.0 ? 0.0 : toastExpansion);
                    final menuHeight =
                        116.0 * (menuExpansion < 0.0 ? 0.0 : menuExpansion);
                    final qcHeight =
                        targetQcHeight * (qcExpansion < 0.0 ? 0.0 : qcExpansion);
                    final currentHeight =
                        56.0 + toastHeight + menuHeight + qcHeight + 1.6;

                    final activeExpansion = [
                      menuExpansion,
                      toastExpansion,
                      qcExpansion,
                    ].reduce((a, b) => a > b ? a : b);
                    final cornerRadius =
                        (28.0 - (4.0 * activeExpansion)).clamp(20.0, 28.0);
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    final toastData = ref.watch(islandToastNotifierProvider);
                    final menuData = ref.watch(islandMenuNotifierProvider);

                    return Container(
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Animated Circular action button with magnetic compression
              AnimatedBuilder(
                animation: Listenable.merge([
                  _expansionController,
                  _menuExpansionController,
                  _quickCaptureController,
                ]),
                builder: (context, child) {
                  final toastExp = _expansionController.value;
                  final menuExp = _menuExpansionController.value;
                  final qcExp = _quickCaptureController.value;
                  final fabScale =
                      (1.0 - (0.09 * toastExp) - (0.12 * menuExp) - (0.12 * qcExp))
                          .clamp(0.80, 1.0);
                  final fabOpacity =
                      (1.0 - (0.60 * menuExp) - (0.60 * qcExp)).clamp(0.40, 1.0);
                  return Transform.scale(
                    scale: fabScale,
                    child: Opacity(
                      opacity: fabOpacity,
                      child: child,
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: _currentIndex == 3 ? 0 : 56,
                  height: 56,
                  margin: EdgeInsets.only(left: _currentIndex == 3 ? 0 : 12),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _currentIndex == 3 ? 0.0 : 1.0,
                    child: TactileWrapper(
                      key: const ValueKey('app_shell_fab'),
                      style: TactileFeedbackStyle.highImpact,
                      onTap: () {
                        if (_currentIndex == 1) {
                          _createDailyNoteForToday();
                        } else {
                          final qcState =
                              ref.read(quickCaptureNotifierProvider);
                          if (qcState.isOpen) {
                            ref
                                .read(quickCaptureNotifierProvider.notifier)
                                .dismiss();
                          } else {
                            ref
                                .read(quickCaptureNotifierProvider.notifier)
                                .open();
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _currentIndex == 3
                            ? const SizedBox.shrink()
                            : Icon(
                                Icons.add,
                                color: colorScheme.onPrimary,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    ref.listen<IslandToastData?>(islandToastNotifierProvider, (previous, next) {
      if (next != null) {
        if (ref.read(islandMenuNotifierProvider) != null) {
          ref.read(islandMenuNotifierProvider.notifier).dismiss();
          _menuExpansionController.reverse();
        }
        if (ref.read(quickCaptureNotifierProvider).isOpen) {
          ref.read(quickCaptureNotifierProvider.notifier).dismiss();
          _quickCaptureController.reverse();
        }
        // Do not trigger forward animation if AppShell is not the foreground route
        if (ModalRoute.of(context)?.isCurrent == false) {
          return;
        }
        if (previous == null || !_expansionController.isCompleted) {
          HapticFeedback.selectionClick();
          _expansionController.forward();
        }
        _timerController.duration = next.duration;
        _timerController.forward(from: 0.0);
      } else {
        HapticFeedback.selectionClick();
        _expansionController.reverse();
        _timerController.stop();
      }
    });

    ref.listen<IslandMenuData?>(islandMenuNotifierProvider, (previous, next) {
      if (next != null) {
        if (ref.read(islandToastNotifierProvider) != null) {
          ref.read(islandToastNotifierProvider.notifier).dismiss();
          _expansionController.reverse();
          _timerController.stop();
        }
        if (ref.read(quickCaptureNotifierProvider).isOpen) {
          ref.read(quickCaptureNotifierProvider.notifier).dismiss();
          _quickCaptureController.reverse();
        }
        // Do not trigger forward animation if AppShell is not the foreground route
        if (ModalRoute.of(context)?.isCurrent == false) {
          return;
        }
        HapticFeedback.selectionClick();
        _menuExpansionController.forward();
      } else {
        HapticFeedback.selectionClick();
        _menuExpansionController.reverse();
      }
    });

    ref.listen<QuickCaptureState>(quickCaptureNotifierProvider,
        (previous, next) {
      if (next.isOpen) {
        if (ref.read(islandToastNotifierProvider) != null) {
          ref.read(islandToastNotifierProvider.notifier).dismiss();
          _expansionController.reverse();
          _timerController.stop();
        }
        if (ref.read(islandMenuNotifierProvider) != null) {
          ref.read(islandMenuNotifierProvider.notifier).dismiss();
          _menuExpansionController.reverse();
        }
        // Do not trigger forward animation if AppShell is not the foreground route
        if (ModalRoute.of(context)?.isCurrent == false) {
          return;
        }
        HapticFeedback.selectionClick();
        _quickCaptureController.forward();
      } else {
        HapticFeedback.selectionClick();
        _quickCaptureController.reverse();
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

    // Force index back to 0 (Notes page) so that elements are exactly where spotlight expects them to be!
    if (_currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/notes');
      });
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
