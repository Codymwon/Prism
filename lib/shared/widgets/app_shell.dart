import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/onboarding/data/tutorial_provider.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'tutorial_overlay.dart';

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCompletedTutorial = ref.watch(tutorialStateProvider);

    final mainScaffold = Scaffold(
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
                begin: const Offset(0.0, 0.015), // Subtle lift up
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

    if (hasCompletedTutorial) {
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
        title: 'Daily Reflection Logs',
        description: 'Access today\'s dedicated calendar note immediately. jot down raw thoughts, tasks, and structured daily reflections.',
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
