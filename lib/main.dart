import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_providers.dart';
import 'core/utils/storage_permission_helper.dart';
import 'shared/widgets/storage_permission_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'core/platform/widget_helper.dart';
import 'features/journal/presentation/providers/journal_providers.dart';
import 'features/subscription/presentation/providers/subscription_providers.dart';
import 'shared/design_system/design_system.dart';
import 'core/utils/utils.dart';
import 'core/services/note_ingestion_service.dart';
import 'features/onboarding/data/onboarding_provider.dart';
import 'core/services/analytics_service.dart';
import 'l10n/l10n.dart';
import 'features/folders/data/virtual_folder_sync_helper.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();



  // Allow google_fonts to download real font files from Google CDN.
  // They are cached on-device after first download, so this works offline too.
  GoogleFonts.config.allowRuntimeFetching = true;

  final prefs = await SharedPreferences.getInstance();
  AnalyticsService.initialize(prefs);
  final vaultType = prefs.getString('vaultType') ?? 'sandbox';

  bool isFirebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;

    // On a fresh install, analyticsEnabled is not yet set. We write false
    // immediately so Firebase initialises with collection DISABLED — no events
    // fire before the user reaches the Telemetry Consent toggle in onboarding.
    // The onboarding screen will write true if the user leaves the toggle ON.
    final isFirstInstall = !prefs.containsKey('analyticsEnabled');
    if (isFirstInstall) {
      await prefs.setBool('analyticsEnabled', false);
    }

    // Read the user consent preference (now guaranteed to exist)
    final analyticsEnabled = prefs.getBool('analyticsEnabled') ?? false;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(analyticsEnabled);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);
  } catch (e) {
    debugPrint('Firebase failed to initialize (expected in tests/mock setups): $e');
  }

  // Catch all unhandled library/framework errors unconditionally
  FlutterError.onError = (errorDetails) {
    debugPrint('Global FlutterError: ${errorDetails.exceptionAsString()}');
    AnalyticsService.logError(errorDetails.exception, errorDetails.stack, fatal: true);
    if (isFirebaseInitialized) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    }
  };

  // Catch all unhandled platform/asynchronous errors unconditionally
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global PlatformDispatcher error: $error');
    AnalyticsService.logError(error, stack, fatal: true);
    if (isFirebaseInitialized) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };


  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      noteSyncedCallbackProvider.overrideWithValue((noteId, filePath, txn) async {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await VirtualFolderSyncHelper.handleNoteSync(
          txn: txn,
          noteId: noteId,
          filePath: filePath,
          nowMs: nowMs,
        );
      }),
    ],
  );


  if (AppConfig.enableExternalStorage && vaultType == 'custom') {
    // Check if we have Android Scoped Storage (All Files Access) permission
    final hasAccess = await StoragePermissionHelper.hasAllFilesAccess();

    if (!hasAccess) {
      final themeIdx = prefs.getInt('themeType') ?? 0;
      final themeType = AppThemeType.values[themeIdx];
      final fontFamily = prefs.getString('fontFamily') ?? 'Inter (Sans)';

      runApp(StoragePermissionScreen(
        themeType: themeType,
        fontFamily: fontFamily,
        onPermissionGranted: () async {
          // Warm up DB in the background
          container.read(databaseProvider.future).then((_) {}).catchError((e) {
            debugPrint('Failed to warm up database after permission grant: $e');
          });
          runApp(UncontrolledProviderScope(container: container, child: const PrismApp()));
        },
      ));
      return; // Stop execution here to let the permission screen run
    }
  }

  final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
  if (hasOnboarded) {
    // Warm up database in the background without blocking the UI thread
    container.read(databaseProvider.future).then((_) {}).catchError((e) {
      debugPrint('Failed to warm up database at startup: $e');
    });
  }

  if (AppConfig.enableSubscriptions) {
    // Initialize RevenueCat SDK in the background
    container.read(subscriptionRepositoryProvider).initialize().then((_) {
      debugPrint('Subscription repository initialized.');
    }).catchError((e) {
      debugPrint('Failed to initialize subscription repository at startup: $e');
    });

    // Silent restore on first launch after a fresh install.
    // This recovers purchases for anonymous users who reinstalled or switched devices.
    // We use a flag so this only fires once per install, not on every launch
    // (Apple guidelines prohibit automatic restore on every launch for iOS).
    final hasRestoredOnInstall = prefs.getBool('hasRestoredOnInstall') ?? false;
    if (!hasRestoredOnInstall && (Platform.isAndroid || Platform.isIOS)) {
      prefs.setBool('hasRestoredOnInstall', true);
      container.read(subscriptionRepositoryProvider).restorePurchases().then((_) {
        debugPrint('Silent restore on fresh install completed.');
      }).catchError((e) {
        debugPrint('Silent restore on fresh install failed (non-critical): $e');
      });
    }
  }

  runApp(UncontrolledProviderScope(container: container, child: const PrismApp()));
}

class PrismApp extends ConsumerStatefulWidget {
  const PrismApp({super.key});

  @override
  ConsumerState<PrismApp> createState() => _PrismAppState();
}

class _PrismAppState extends ConsumerState<PrismApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widgetHelperProvider).init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final vaultPath = ref.read(activeVaultPathProvider).valueOrNull;
      if (vaultPath != null && vaultPath.isNotEmpty) {
        ref.read(noteIngestionServiceProvider).syncVault(vaultPath).then((hasChanges) {
          if (hasChanges) {
            ref.read(notesVersionProvider.notifier).update((v) => v + 1);
            ref.read(foldersVersionProvider.notifier).update((v) => v + 1);
          }
        }).catchError((e) {
          debugPrint('Error syncing vault on resume: $e');
        });
      }
    }
  }

  void _triggerWidgetUpdate(int streak, bool todayReflected, ColorScheme colorScheme, BuildContext context) {
    final bg = DesignColors.surface(context);
    final accent = colorScheme.primary;
    final textPrimary = DesignColors.text(context);
    final textSecondary = DesignColors.textSecondary(context);

    String colorToHex(Color color) {
      return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    }

    ref.read(widgetHelperProvider).updateWidgetData(
      streak: streak,
      todayReflected: todayReflected,
      bgHex: colorToHex(bg),
      accentHex: colorToHex(accent),
      textPrimaryHex: colorToHex(textPrimary),
      textSecondaryHex: colorToHex(textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeType = ref.watch(themeStateProvider);
    final fontFamily = ref.watch(fontFamilyProvider);

    final resolution = AppTheme.resolve(themeType, fontFamily);
    final themeData = resolution.themeData;
    final darkThemeData = resolution.darkThemeData;
    final mode = resolution.mode;

    // Watch values to trigger widget update on post frame
    final hasOnboarded = ref.watch(onboardingStateProvider);
    final streakVal = hasOnboarded
        ? (ref.watch(journalStreakProvider).valueOrNull?.streak ?? 0)
        : 0;
    final dates = hasOnboarded
        ? (ref.watch(allDailyDatesProvider).valueOrNull ?? {})
        : <String>{};
    final todayStr = formatDailyDate(DateTime.now());
    final todayReflected = dates.contains(todayStr);

    final activeTheme = (mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark))
        ? darkThemeData
        : themeData;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerWidgetUpdate(streakVal, todayReflected, activeTheme.colorScheme, context);
    });

    return MaterialApp.router(
      title: 'Prism',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: darkThemeData,
      themeMode: mode,
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
