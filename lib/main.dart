import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_providers.dart';
import 'core/utils/storage_permission_helper.dart';
import 'shared/widgets/storage_permission_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/widgets/widget_helper.dart';
import 'features/journal/presentation/providers/journal_providers.dart';
import 'shared/design_system/design_system.dart';
import 'core/utils/utils.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isAndroid) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Allow google_fonts to download real font files from Google CDN.
  // They are cached on-device after first download, so this works offline too.
  GoogleFonts.config.allowRuntimeFetching = true;

  final prefs = await SharedPreferences.getInstance();
  final vaultType = prefs.getString('vaultType') ?? 'sandbox';

  final container = ProviderContainer();

  if (vaultType == 'custom') {
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
          try {
            await container.read(databaseProvider.future); // warm up DB via Riverpod
          } catch (e) {
            debugPrint('Failed to warm up database after permission grant: $e');
          }
          runApp(UncontrolledProviderScope(container: container, child: const PrismApp()));
        },
      ));
      return; // Stop execution here to let the permission screen run
    }
  }

  final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
  if (hasOnboarded) {
    try {
      await container.read(databaseProvider.future); // warm up DB via Riverpod
    } catch (e) {
      debugPrint('Failed to warm up database at startup: $e');
    }
  }
  runApp(UncontrolledProviderScope(container: container, child: const PrismApp()));
}

class PrismApp extends ConsumerStatefulWidget {
  const PrismApp({super.key});

  @override
  ConsumerState<PrismApp> createState() => _PrismAppState();
}

class _PrismAppState extends ConsumerState<PrismApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widgetHelperProvider).init();
    });
  }

  void _triggerWidgetUpdate(int streak, bool todayReflected, ColorScheme colorScheme, BuildContext context) {
    final bg = DesignColors.surface(context);
    final accent = colorScheme.primary;
    final textPrimary = DesignColors.text(context);
    final textSecondary = DesignColors.textSecondary(context);

    String colorToHex(Color color) {
      return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    }

    WidgetHelper.updateWidgetData(
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
    final themeType = ref.watch(themeProvider);
    final fontFamily = ref.watch(fontFamilyProvider);

    final resolution = AppTheme.resolve(themeType, fontFamily);
    final themeData = resolution.themeData;
    final darkThemeData = resolution.darkThemeData;
    final mode = resolution.mode;

    // Watch values to trigger widget update on post frame
    final streakVal = ref.watch(journalStreakProvider).valueOrNull?.streak ?? 0;
    final dates = ref.watch(allDailyDatesProvider).valueOrNull ?? {};
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
    );
  }
}
