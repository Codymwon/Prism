import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/editor/presentation/screens/merge_comparison_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/graph/presentation/screens/graph_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/data/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final hasOnboarded = ref.watch(onboardingStateProvider);

  return GoRouter(
    initialLocation: hasOnboarded ? '/notes' : '/onboarding',
    redirect: (context, state) {
      final isGoingToOnboarding = state.uri.path == '/onboarding';
      if (!hasOnboarded) {
        if (!isGoingToOnboarding) {
          return '/onboarding';
        }
      } else {
        if (isGoingToOnboarding) {
          return '/notes';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesListScreen(),
            ),
          ),
          GoRoute(
            path: '/journal',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: JournalScreen(),
            ),
          ),
          GoRoute(
            path: '/graph',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GraphScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/editor/:id',
        pageBuilder: (context, state) {
          final noteId = state.pathParameters['id']!;
          final isNew = state.uri.queryParameters['new'] == 'true';
          final dailyDate = state.uri.queryParameters['date'];
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: EditorScreen(noteId: noteId, isNew: isNew, dailyDate: dailyDate),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0.0), // Subtle slide from right
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 240),
          );
        },
      ),
      GoRoute(
        path: '/editor/:id/merge',
        pageBuilder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: MergeComparisonScreen(noteId: noteId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0.0), // Subtle slide from right
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 280),
            reverseTransitionDuration: const Duration(milliseconds: 240),
          );
        },
      ),
    ],
  );
});

