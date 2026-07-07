import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:prism/features/onboarding/data/tutorial_provider.dart';
import 'package:prism/l10n/l10n.dart';
import '../design_system/design_system.dart';
import 'tactile_wrapper.dart';
import 'tutorial_overlay.dart';
import '../../features/notes/data/note_repository.dart';
import '../../features/folders/presentation/providers/folders_providers.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../core/utils/utils.dart';



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
      context.push('/editor/${note.id}?new=true');
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
      context.push('/editor/${note.id}?date=$todayStr&new=true');
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
                                  child: Text(_getTabLabel(context, i)),
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



  @override
  Widget build(BuildContext context) {
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
