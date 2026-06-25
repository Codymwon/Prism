import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'tutorial_overlay.dart';
import '../../features/notes/data/note_repository.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../features/notes/presentation/providers/notes_providers.dart';
import '../../core/utils/utils.dart';

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

  Future<void> _createStandardNote() async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.createNote();

    final selectedFolderId = ref.read(selectedFolderIdProvider);
    if (selectedFolderId != null) {
      final folderRepo = ref.read(folderRepositoryProvider);
      await folderRepo.addNoteToFolder(note.id, selectedFolderId);
    }

    if (mounted) {
      final isDesktop = MediaQuery.of(context).size.width >= _kDesktopBreakpoint;
      if (isDesktop) {
        ref.read(activeDesktopNoteIdProvider.notifier).state = note.id;
      } else {
        context.push('/editor/${note.id}?new=true');
      }
    }
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
      final isDesktop = MediaQuery.of(context).size.width >= _kDesktopBreakpoint;
      if (isDesktop) {
        ref.read(activeDesktopNoteIdProvider.notifier).state = note.id;
      } else {
        context.push('/editor/${note.id}?date=$todayStr&new=true');
      }
    }
  }

  // ─── Mobile scaffold (original, untouched) ─────────────────────────────────
  Widget _buildMobileScaffold(BuildContext context, ColorScheme colorScheme) {
    return Scaffold(
      extendBody: true,
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // Floating Capsule Container for tabs
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: DesignColors.surface(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DesignColors.border(context),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
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
              
              // Animated Circular action button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _currentIndex == 3 ? 0 : 56,
                height: 56,
                margin: EdgeInsets.only(left: _currentIndex == 3 ? 0 : 12),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _currentIndex == 3 ? 0.0 : 1.0,
                  child: TactileWrapper(
                    style: TactileFeedbackStyle.highImpact,
                    onTap: () {
                      if (_currentIndex == 1) {
                        _createDailyNoteForToday();
                      } else {
                        _createStandardNote();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
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
            ],
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
      child: isDesktop
          ? _buildDesktopScaffold(context, colorScheme)
          : _buildMobileScaffold(context, colorScheme),
    );

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
        title: 'Virtual Folders',
        description: 'Tap any virtual folder card in the horizontal row to filter the notes list below. Tap the "All Notes" card to reset the filter.',
        icon: Icons.folder_open_rounded,
        getTargetRect: (size) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Rect.fromLTWH(16, topPadding + 120, size.width - 32, 90);
        },
      ),
      TutorialStep(
        title: 'Daily Reflection Logs',
        description: 'Access today\'s dedicated calendar note immediately. Jot down reflections with templates (Gratitude, Reflection, Goals), hit word count targets, and grow your daily writing streak.',
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
        title: 'Mindmap Thought Graph',
        description: 'Explore your connected mind network. Watch notes become nodes and wikilinks become edges in a dynamic 2D graph layout.',
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
        title: 'Create & Link Notes',
        description: 'Tap the floating "+" button to create a new note. Within any note, simply type double brackets [[like this]] to link ideas together and expand your brain.',
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
