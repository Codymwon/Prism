import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database; // warm up DB
  runApp(const ProviderScope(child: MeridianApp()));
}

class MeridianApp extends ConsumerWidget {
  const MeridianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeType = ref.watch(themeProvider);
    final fontFamily = ref.watch(fontFamilyProvider).valueOrNull ?? 'Inter (Sans)';

    ThemeMode mode;
    ThemeData themeData;
    ThemeData darkThemeData;

    switch (themeType) {
      case AppThemeType.light:
        themeData = AppTheme.applyFontFamily(AppTheme.light(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.dark(), fontFamily);
        mode = ThemeMode.light;
        break;
      case AppThemeType.dark:
        themeData = AppTheme.applyFontFamily(AppTheme.light(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.dark(), fontFamily);
        mode = ThemeMode.dark;
        break;
      case AppThemeType.sepia:
        themeData = AppTheme.applyFontFamily(AppTheme.sepia(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.sepia(), fontFamily);
        mode = ThemeMode.light;
        break;
      case AppThemeType.forest:
        themeData = AppTheme.applyFontFamily(AppTheme.forest(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.forest(), fontFamily);
        mode = ThemeMode.dark;
        break;
      case AppThemeType.slate:
        themeData = AppTheme.applyFontFamily(AppTheme.slate(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.slate(), fontFamily);
        mode = ThemeMode.dark;
        break;
      case AppThemeType.arctic:
        themeData = AppTheme.applyFontFamily(AppTheme.arctic(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.arctic(), fontFamily);
        mode = ThemeMode.light;
        break;
      case AppThemeType.noir:
        themeData = AppTheme.applyFontFamily(AppTheme.noir(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.noir(), fontFamily);
        mode = ThemeMode.dark;
        break;
      case AppThemeType.blush:
        themeData = AppTheme.applyFontFamily(AppTheme.blush(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.blush(), fontFamily);
        mode = ThemeMode.light;
        break;
      case AppThemeType.system:
        themeData = AppTheme.applyFontFamily(AppTheme.light(), fontFamily);
        darkThemeData = AppTheme.applyFontFamily(AppTheme.dark(), fontFamily);
        mode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'Meridian',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: darkThemeData,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
