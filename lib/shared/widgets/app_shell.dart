import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'tactile_wrapper.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Notes', path: '/notes'),
    _TabDef(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Journal', path: '/journal'),
    _TabDef(icon: Icons.hub_outlined, activeIcon: Icons.hub, label: 'Graph', path: '/graph'),
    _TabDef(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: '/settings'),
  ];

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? MeridianColors.darkSurface : MeridianColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? MeridianColors.darkBorder : MeridianColors.lightBorder,
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
                                : (isDark
                                    ? MeridianColors.darkTextTertiary
                                    : MeridianColors.lightTextTertiary),
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
                                : (isDark
                                    ? MeridianColors.darkTextTertiary
                                    : MeridianColors.lightTextTertiary),
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
