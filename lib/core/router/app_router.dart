import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notes/presentation/screens/notes_list_screen.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/editor/presentation/screens/merge_comparison_screen.dart';
import '../../features/journal/presentation/screens/journal_screen.dart';
import '../../features/graph/presentation/screens/graph_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/theme_gallery_screen.dart';
import '../../features/settings/presentation/screens/custom_macros_screen.dart';
import '../../features/settings/presentation/screens/custom_templates_screen.dart';
import '../../features/settings/presentation/screens/attachments_screen.dart';
import '../../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/cloud_sync_screen.dart';
import '../../features/settings/presentation/screens/editor_preferences_screen.dart';
import '../../features/settings/presentation/screens/journal_preferences_screen.dart';
import '../../features/settings/presentation/screens/manage_vaults_screen.dart';
import '../../features/subscription/presentation/screens/custom_paywall_screen.dart';
import '../../features/onboarding/data/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/folders/presentation/screens/add_folder_screen.dart';
import '../../features/folders/presentation/screens/edit_folder_screen.dart';

// ── Router Notifier ──────────────────────────────────────────────────────────
// A ChangeNotifier that bridges Riverpod state → GoRouter's refreshListenable.
// This allows the router to re-run its redirect when onboardingStateProvider
// changes WITHOUT recreating the GoRouter instance itself.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Listen to onboarding state; notify router to re-evaluate redirect when it changes
    _ref.listen<bool>(onboardingStateProvider, (_, _) => notifyListeners());
  }

  bool get hasOnboarded => _ref.read(onboardingStateProvider);
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: notifier.hasOnboarded ? '/notes' : '/onboarding',
    refreshListenable: notifier,
    redirect: (context, state) {
      final hasOnboarded = notifier.hasOnboarded;
      final isGoingToOnboarding = state.uri.path == '/onboarding';
      if (!hasOnboarded) {
        if (!isGoingToOnboarding) return '/onboarding';
      } else {
        if (isGoingToOnboarding) return '/notes';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
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
        path: '/settings/theme-gallery',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ThemeGalleryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/custom-macros',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomMacrosScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/custom-templates',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomTemplatesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/attachments',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AttachmentsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/privacy-policy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/cloud-sync',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CloudSyncScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/editor-preferences',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditorPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/journal-preferences',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JournalPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/manage-vaults',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManageVaultsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/settings/paywall',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomPaywallScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
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
        ),
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
                    begin: const Offset(0.08, 0.0),
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
                    begin: const Offset(0.08, 0.0),
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
        path: '/folders/create',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddFolderScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
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
        ),
      ),
      GoRoute(
        path: '/folders/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EditFolderScreen(folderId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0.0),
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
