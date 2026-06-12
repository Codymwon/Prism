import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/onboarding/data/tutorial_provider.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'tutorial_overlay.dart';

// Breakpoint at which we switch from mobile bottom-nav to desktop side-rail.
const double _kDesktopBreakpoint = 800;

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const AppShell({super.key, required this.child, required this.currentPath});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int get _currentIndex {
    final path = widget.currentPath;
    final index = _tabs.indexWhere((tab) => path.startsWith(tab.path));
    return index == -1 ? 0 : index;
  }

  static const _tabs = [
    _TabDef(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Notes', path: '/notes'),
    _TabDef(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Journal', path: '/journal'),
    _TabDef(icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'Graph', path: '/graph'),
    _TabDef(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    context.go(_tabs[index].path);
  }

  // ─── Mobile scaffold (original, untouched) ─────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context, ColorScheme colorScheme) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (currentChild, previousChildren) => currentChild ?? const SizedBox.shrink(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DesignColors.surface(context),
          border: Border(
            top: BorderSide(
              color: DesignColors.border(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _currentIndex;
                return Expanded(
                  child: TactileWrapper(
                    style: TactileFeedbackStyle.standard,
                    onTap: () => _onTabTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            key: ValueKey(isActive),
                            size: 22,
                            color: isActive
                                ? colorScheme.primary
                                : DesignColors.textTertiary(context),
                          ),
                        ).animate(target: isActive ? 1 : 0).scaleXY(
                          begin: 0.9,
                          end: 1.0,
                          duration: 150.ms,
                          curve: Curves.easeOut,
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? colorScheme.primary
                                : DesignColors.textTertiary(context),
                          ),
                          child: Text(tab.label),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Desktop scaffold (NavigationRail + content) ────────────────────────────
  Widget _buildDesktopScaffold(BuildContext context, ColorScheme colorScheme) {
    return Scaffold(
      body: Row(
        children: [
          // Slim side navigation rail
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: DesignColors.surface(context),
              border: Border(
                right: BorderSide(
                  color: DesignColors.border(context),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // App logo / brand mark
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nav items
                  ...List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    final isActive = i == _currentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: TactileWrapper(
                        style: TactileFeedbackStyle.standard,
                        onTap: () => _onTabTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive ? tab.activeIcon : tab.icon,
                                size: 22,
                                color: isActive
                                    ? colorScheme.primary
                                    : DesignColors.textTertiary(context),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isActive
                                      ? colorScheme.primary
                                      : DesignColors.textTertiary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Main content area — screens fill the remaining space
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Container(
                key: ValueKey(_currentIndex),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCompletedTutorial = ref.watch(tutorialStateProvider);
    final hasCompletedJournalTutorial = ref.watch(journalTutorialStateProvider);
    final isDesktop = MediaQuery.of(context).size.width >= _kDesktopBreakpoint;

    final mainScaffold = isDesktop
        ? _buildDesktopScaffold(context, colorScheme)
        : _buildMobileScaffold(context, colorScheme);

    if (hasCompletedTutorial) {
      if (!hasCompletedJournalTutorial && _currentIndex == 1) {
        final journalTutorialSteps = [
          TutorialStep(
            title: 'Calendar Navigation',
            description: 'Tap the calendar icon to expand the monthly calendar view and navigate across all dates in your vault history.',
            icon: Icons.calendar_month_outlined,
            getTargetRect: (size) {
              final topPadding = MediaQuery.of(context).padding.top;
              return Rect.fromLTWH(size.width - 64, topPadding + 16, 48, 48);
            },
          ),
          TutorialStep(
            title: 'Weekly Quick Strip',
            description: 'Quickly slide or tap between the last 7 days to keep your reflection streak alive without opening the full calendar view.',
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
            title: 'Daily Streak & Grid',
            description: 'Track your active daily writing streak and visualize your consistency over the last 28 days with the contribution grid.',
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
            title: 'Reflection Templates',
            description: 'Select an expert journal template (Gratitude, Daily Plan, Reflection, Goals) to quickly structure your writing, or start typing in a blank daily page.',
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
        title: 'Virtual Folders & Tags',
        description: 'Open the sidebar navigation drawer to organize your notes into virtual folders or browse tag indexes across your vault.',
        icon: Icons.folder_open_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(6, topPadding + 4, 48, 48);
        },
      ),
      TutorialStep(
        title: 'Open Folders',
        description: 'Tap "Open" on any folder card to isolate its notes and view only that folder\'s contents in a focused list view.',
        icon: Icons.arrow_forward_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(size.width - 148, topPadding + 204, 56, 32);
        },
      ),
      TutorialStep(
        title: 'View Layout Toggle',
        description: 'Tap here to toggle between a folder-grouped layout for structured cataloging and a clean flat list to view all notes at a single glance.',
        icon: Icons.grid_view_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(size.width - 54, topPadding + 4, 48, 48);
        },
      ),
      TutorialStep(
        title: 'Daily Reflection Logs',
        description: 'Access today\'s dedicated calendar note immediately. Jot down reflections with templates (Gratitude, Reflection, Goals), hit word count targets, and grow your daily writing streak.',
        icon: Icons.calendar_today_rounded,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final tabWidth = size.width / 4;
          final left = tabWidth * 1 + (tabWidth / 2) - 26;
          final top = size.height - 60 - bottomPadding + 6;
          return Rect.fromLTWH(left, top, 52, 48);
        },
      ),
      TutorialStep(
        title: 'Mindmap Thought Graph',
        description: 'Explore your connected mind network. Watch notes become nodes and wikilinks become edges in a dynamic 2D graph layout.',
        icon: Icons.hub_outlined,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final tabWidth = size.width / 4;
          final left = tabWidth * 2 + (tabWidth / 2) - 26;
          final top = size.height - 60 - bottomPadding + 6;
          return Rect.fromLTWH(left, top, 52, 48);
        },
      ),
      TutorialStep(
        title: 'Create & Link Notes',
        description: 'Write your private thoughts! Within any note, simply type double brackets [[like this]] to link ideas together and expand your brain.',
        icon: Icons.add_circle_outline_rounded,
        getTargetRect: (size) {
          final bottomPadding = MediaQuery.of(context).padding.bottom;
          final left = size.width - 150;
          final top = size.height - 60 - bottomPadding - 16 - 54;
          return Rect.fromLTWH(left, top, 134, 52);
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
