import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';

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

    ThemeMode mode;
    ThemeData themeData;
    ThemeData darkThemeData;

    switch (themeType) {
      case AppThemeType.light:
        themeData = AppTheme.light();
        darkThemeData = AppTheme.dark();
        mode = ThemeMode.light;
        break;
      case AppThemeType.dark:
        themeData = AppTheme.light();
        darkThemeData = AppTheme.dark();
        mode = ThemeMode.dark;
        break;
      case AppThemeType.sepia:
        themeData = AppTheme.sepia();
        darkThemeData = AppTheme.sepia();
        mode = ThemeMode.light; // fallback to light mode rules in system
        break;
      case AppThemeType.system:
        themeData = AppTheme.light();
        darkThemeData = AppTheme.dark();
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
