import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_service.dart';

// ─── Theme Type Enum ─────────────────────────────────────────────────────────
enum AppThemeType { system, light, dark, sepia, forest, slate, arctic, noir, blush, midnight, matcha }

// ─── Theme Provider ──────────────────────────────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeType> {
  ThemeNotifier() : super(AppThemeType.system) { // default system (Paper light / Dusk dark)
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('themeType') ?? 0; // default system
    state = AppThemeType.values[idx];
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeType', type.index);
    AnalyticsService.logEvent('change_theme', parameters: {
      'theme': type.name,
    });
  }
}

// ─── Color Palette Class ───────────────────────────────────────────────────────
class AppThemePalette {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color error;
  final Color secondary;
  final Color tertiary;

  const AppThemePalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.error,
    required this.secondary,
    required this.tertiary,
  });

  // ─── Preset Theme Palettes ───

  // Dusk (dark default) - Warm near-black with terracotta glow
  static const AppThemePalette dark = AppThemePalette(
    brightness: Brightness.dark,
    background: Color(0xFF1C1C1E),
    surface: Color(0xFF262628),
    surfaceVariant: Color(0xFF2C2C2E),
    border: Color(0xFF3A3A3C),
    primary: Color(0xFFE07A5F), // Signature Terracotta
    primaryContainer: Color(0xFF46251B), // Burnt terracotta shadow
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFFF2F2F7),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF636366),
    error: Color(0xFFE07A5F), // darkAccentRose
    secondary: Color(0xFF81B29A), // darkAccentGreen
    tertiary: Color(0xFFF2CC8F), // darkAccentAmber
  );

  // Clean Paper (light default) - Premium Prism Light Theme
  static const AppThemePalette light = AppThemePalette(
    brightness: Brightness.light,
    background: Color(0xFFFAF8F4),
    surface: Color(0xFFF3EFE8),
    surfaceVariant: Color(0xFFECE7DE),
    border: Color(0xFFE6DFD5),
    primary: Color(0xFFC8A97E), // Warm gold/sand accent
    primaryContainer: Color(0xFFF5EFE6), // Light sand/cream container
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF2D2A26),
    textSecondary: Color(0xFF7A746B),
    textTertiary: Color(0xFFAFA79D),
    error: Color(0xFFE07A5F), // lightAccentRose
    secondary: Color(0xFF81B29A), // lightAccentGreen
    tertiary: Color(0xFFC8A97E), // lightAccentAmber
  );

  // Warm Editorial (Sepia Theme) - Parchment Cream & Espresso Editorial
  static const AppThemePalette sepia = AppThemePalette(
    brightness: Brightness.light,
    background: Color(0xFFFAF6EE), // Warm parchment cream
    surface: Color(0xFFFDFBFA), // Bright soft cream
    surfaceVariant: Color(0xFFEFEAE2), // Warm neutral grey
    border: Color(0xFFE5DEC9), // Parchment border clay
    primary: Color(0xFF5C3D2E), // Espresso chocolate accent
    primaryContainer: Color(0xFFF9ECE6), // Light terracotta Container
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF2A1F19), // Dark charcoal brown
    textSecondary: Color(0xFF60524C), // Warm sepia slate
    textTertiary: Color(0xFFA59890), // Light clay
    error: Color(0xFFE07A5F), // sepiaAccentRose
    secondary: Color(0xFF81B29A), // sepiaAccentGreen
    tertiary: Color(0xFFC8A97E), // sepiaAccentAmber
  );

  // Forest (dark) - Deep pine green with sage accents, moody & organic
  static const AppThemePalette forest = AppThemePalette(
    brightness: Brightness.dark,
    background: Color(0xFF141C18), // Deep pine black-green
    surface: Color(0xFF1C2820), // Dark moss surface
    surfaceVariant: Color(0xFF223028), // Slightly lighter moss
    border: Color(0xFF2E3E34), // Muted forest border
    primary: Color(0xFF81B29A), // Sage green accent
    primaryContainer: Color(0xFF1A3327), // Deep forest container
    onPrimary: Color(0xFF0D1F17),
    text: Color(0xFFDEEDE5), // Soft moonlit green-white
    textSecondary: Color(0xFF7FA892), // Muted sage
    textTertiary: Color(0xFF4E6A5B), // Deep forest grey-green
    error: Color(0xFFB06060), // forestAccentRose
    secondary: Color(0xFF81B29A), // forestPrimary
    tertiary: Color(0xFFD4A853), // forestAccentGold
  );

  // Slate (dark) - Deep navy-indigo with soft cyan accents, developer-inspired
  static const AppThemePalette slate = AppThemePalette(
    brightness: Brightness.dark,
    background: Color(0xFF0F1117), // Near-black navy
    surface: Color(0xFF171C26), // Dark indigo surface
    surfaceVariant: Color(0xFF1E2535), // Deeper indigo panel
    border: Color(0xFF2A3347), // Navy-steel border
    primary: Color(0xFF7DAFE8), // Soft steel blue accent
    primaryContainer: Color(0xFF152040), // Deep navy container
    onPrimary: Color(0xFF0A1428),
    text: Color(0xFFE4EAF5), // Cool blue-white
    textSecondary: Color(0xFF7D90B2), // Muted steel blue-grey
    textTertiary: Color(0xFF4A5A74), // Deep navy tertiary
    error: Color(0xFF9B8ED6), // slateAccentIndigo
    secondary: Color(0xFF56CCF2), // slateAccentCyan
    tertiary: Color(0xFF7DAFE8), // slatePrimary
  );

  // Arctic (light) - Icy near-white surfaces with pale cyan-mint accent, crisp & minimal
  static const AppThemePalette arctic = AppThemePalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F8FB), // Crisp icy white-blue
    surface: Color(0xFFEBF2F7), // Soft frost surface
    surfaceVariant: Color(0xFFDEEBF2), // Cool pale blue panel
    border: Color(0xFFCADDE9), // Icy steel border
    primary: Color(0xFF3A8FA8), // Calm teal-cyan accent
    primaryContainer: Color(0xFFD6EEF5), // Pale ice container
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF152632), // Deep arctic navy
    textSecondary: Color(0xFF4E7080), // Muted teal-slate
    textTertiary: Color(0xFF8AAAB8), // Light ice-grey
    error: Color(0xFF6B9BBF), // arcticAccentSteel
    secondary: Color(0xFF56CCF2), // arcticAccentMint
    tertiary: Color(0xFF6B9BBF), // arcticAccentSteel
  );

  // Noir (dark) - Near-black with muted gold accents, cinematic editorial
  static const AppThemePalette noir = AppThemePalette(
    brightness: Brightness.dark,
    background: Color(0xFF111110), // Near-black warm
    surface: Color(0xFF1A1917), // Dark warm charcoal
    surfaceVariant: Color(0xFF201F1D), // Slightly lifted charcoal
    border: Color(0xFF302E2B), // Warm dark border
    primary: Color(0xFFC9A84C), // Muted cinematic gold
    primaryContainer: Color(0xFF2A2318), // Deep gold shadow
    onPrimary: Color(0xFF100E08),
    text: Color(0xFFF0EDE6), // Warm off-white
    textSecondary: Color(0xFF8A8578), // Muted warm grey
    textTertiary: Color(0xFF504D47), // Deep warm charcoal
    error: Color(0xFFB07070), // noirAccentRose
    secondary: Color(0xFFC9A84C), // noirPrimary
    tertiary: Color(0xFFC9A84C), // noirAccentGold
  );

  // Blush (light) - Soft pinkish-white surfaces with dusty rose accents, refined
  static const AppThemePalette blush = AppThemePalette(
    brightness: Brightness.light,
    background: Color(0xFFFDF8F8), // Petal white
    surface: Color(0xFFF7EFF0), // Soft blush surface
    surfaceVariant: Color(0xFFF0E4E6), // Warm pinkish panel
    border: Color(0xFFE8D5D8), // Dusty rose border
    primary: Color(0xFFB0637A), // Dusty rose accent
    primaryContainer: Color(0xFFF9E8EC), // Light blush container
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF2E1F24), // Deep rose-brown text
    textSecondary: Color(0xFF7A5460), // Warm dusty mauve
    textTertiary: Color(0xFFB89AA0), // Light blush grey
    error: Color(0xFFB0637A), // blushAccentRose
    secondary: Color(0xFFB0637A), // blushPrimary
    tertiary: Color(0xFFC8966E), // blushAccentGold
  );

  // Midnight OLED (stealth black)
  static const AppThemePalette midnight = AppThemePalette(
    brightness: Brightness.dark,
    background: Color(0xFF000000),
    surface: Color(0xFF0C0C0C),
    surfaceVariant: Color(0xFF141414),
    border: Color(0xFF1E1E1E),
    primary: Color(0xFF6E7681), // Muted Slate-Graphite
    primaryContainer: Color(0xFF1C1E22),
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFFE5E7EB),
    textSecondary: Color(0xFF8E95A0),
    textTertiary: Color(0xFF4B525D),
    error: Color(0xFFB85C5C), // midnightAccentRose
    secondary: Color(0xFF5C8F73), // midnightAccentGreen
    tertiary: Color(0xFF9E7E4E), // midnightAccentAmber
  );

  // Matcha Latte (cream light green)
  static const AppThemePalette matcha = AppThemePalette(
    brightness: Brightness.light,
    background: Color(0xFFF4F7F4),
    surface: Color(0xFFFAFCFA),
    surfaceVariant: Color(0xFFE6EFE6),
    border: Color(0xFFD5E2D5),
    primary: Color(0xFF3D6146), // Matcha Green
    primaryContainer: Color(0xFFE2EDE4),
    onPrimary: Color(0xFFFFFFFF),
    text: Color(0xFF1D2E22),
    textSecondary: Color(0xFF5B7863),
    textTertiary: Color(0xFF96AC9C),
    error: Color(0xFFD97706), // matchaAccentRose
    secondary: Color(0xFF3D6146), // matchaAccentGreen
    tertiary: Color(0xFFC29B38), // matchaAccentAmber
  );
}

// ─── Theme Type Extensions ───────────────────────────────────────────────────
extension AppThemeTypeExtension on AppThemeType {
  bool get isDark {
    switch (this) {
      case AppThemeType.dark:
      case AppThemeType.forest:
      case AppThemeType.slate:
      case AppThemeType.noir:
      case AppThemeType.midnight:
        return true;
      default:
        return false;
    }
  }

  AppThemePalette get palette {
    switch (this) {
      case AppThemeType.light:
      case AppThemeType.system:
        return AppThemePalette.light;
      case AppThemeType.dark:
        return AppThemePalette.dark;
      case AppThemeType.sepia:
        return AppThemePalette.sepia;
      case AppThemeType.forest:
        return AppThemePalette.forest;
      case AppThemeType.slate:
        return AppThemePalette.slate;
      case AppThemeType.arctic:
        return AppThemePalette.arctic;
      case AppThemeType.noir:
        return AppThemePalette.noir;
      case AppThemeType.blush:
        return AppThemePalette.blush;
      case AppThemeType.midnight:
        return AppThemePalette.midnight;
      case AppThemeType.matcha:
        return AppThemePalette.matcha;
    }
  }
}

// ─── Resolved Theme Container ──────────────────────────────────────────────────
class ThemeResolution {
  final ThemeData themeData;
  final ThemeData darkThemeData;
  final ThemeMode mode;

  ThemeResolution({
    required this.themeData,
    required this.darkThemeData,
    required this.mode,
  });
}

// ─── Theme Builder ────────────────────────────────────────────────────────────
class AppTheme {
  // Central build method that accepts an AppThemePalette and font family
  static ThemeData build(AppThemeType type, [String fontFamily = 'Inter (Sans)']) {
    return _buildTheme(type.palette, fontFamily);
  }

  // Centralized theme and mode resolver helper
  static ThemeResolution resolve(AppThemeType type, [String fontFamily = 'Inter (Sans)']) {
    ThemeMode mode;
    ThemeData themeData;
    ThemeData darkThemeData;

    switch (type) {
      case AppThemeType.light:
        themeData = AppTheme.light(fontFamily);
        darkThemeData = AppTheme.dark(fontFamily);
        mode = ThemeMode.light;
        break;
      case AppThemeType.dark:
        themeData = AppTheme.light(fontFamily);
        darkThemeData = AppTheme.dark(fontFamily);
        mode = ThemeMode.dark;
        break;
      case AppThemeType.system:
        themeData = AppTheme.light(fontFamily);
        darkThemeData = AppTheme.dark(fontFamily);
        mode = ThemeMode.system;
        break;
      default:
        // For custom unified themes, we use the same theme for both dark & light modes
        final customTheme = AppTheme.build(type, fontFamily);
        themeData = customTheme;
        darkThemeData = customTheme;
        mode = type.isDark ? ThemeMode.dark : ThemeMode.light;
        break;
    }

    return ThemeResolution(
      themeData: themeData,
      darkThemeData: darkThemeData,
      mode: mode,
    );
  }

  static ThemeData _buildTheme(AppThemePalette palette, String fontFamily) {
    final isDark = palette.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: palette.brightness,
        surface: palette.surface,
        surfaceContainerHighest: palette.surfaceVariant,
        primary: palette.primary,
        primaryContainer: palette.primaryContainer,
        onPrimary: palette.onPrimary,
        onSurface: palette.text,
        outline: palette.border,
        error: palette.error,
        secondary: palette.secondary,
        tertiary: palette.tertiary,
      ),
      scaffoldBackgroundColor: palette.background,
      cardColor: palette.surface,
      dividerColor: palette.border,
      textTheme: _buildTextTheme(palette.text, palette.textSecondary, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: palette.background,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: _getThemeFont(
          fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: palette.text,
        ),
        iconTheme: IconThemeData(color: palette.textSecondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        hintStyle: _getThemeFont(
          fontFamily,
          color: palette.textTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        elevation: 4,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary, String fontFamily) {
    TextStyle getStyle(double fontSize, FontWeight fontWeight, Color color) {
      return _getThemeFont(fontFamily, fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
    return TextTheme(
      displayLarge: getStyle(32, FontWeight.w700, primary),
      displayMedium: getStyle(26, FontWeight.w600, primary),
      headlineLarge: getStyle(22, FontWeight.w600, primary),
      headlineMedium: getStyle(18, FontWeight.w600, primary),
      headlineSmall: getStyle(16, FontWeight.w600, primary),
      titleLarge: getStyle(16, FontWeight.w500, primary),
      titleMedium: getStyle(14, FontWeight.w500, primary),
      titleSmall: getStyle(13, FontWeight.w500, secondary),
      bodyLarge: getStyle(16, FontWeight.w400, primary),
      bodyMedium: getStyle(14, FontWeight.w400, primary),
      bodySmall: getStyle(12, FontWeight.w400, secondary),
      labelLarge: getStyle(13, FontWeight.w600, primary),
      labelMedium: getStyle(12, FontWeight.w500, secondary),
      labelSmall: getStyle(11, FontWeight.w500, secondary),
    );
  }

  static TextStyle _getThemeFont(String family, {double? fontSize, FontWeight? fontWeight, Color? color, double? height}) {
    switch (family) {
      case 'Roboto Mono (Mono)':
        return GoogleFonts.robotoMono(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case 'Lora (Serif)':
        return GoogleFonts.lora(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case 'Merriweather (Serif)':
        return GoogleFonts.merriweather(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
      case 'Inter (Sans)':
      default:
        return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
    }
  }

  // ─── Theme Shortcuts (For Backwards Compatibility) ───
  static ThemeData light([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.light, fontFamily);
  static ThemeData dark([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.dark, fontFamily);
  static ThemeData sepia([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.sepia, fontFamily);
  static ThemeData forest([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.forest, fontFamily);
  static ThemeData slate([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.slate, fontFamily);
  static ThemeData arctic([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.arctic, fontFamily);
  static ThemeData noir([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.noir, fontFamily);
  static ThemeData blush([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.blush, fontFamily);
  static ThemeData midnight([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.midnight, fontFamily);
  static ThemeData matcha([String fontFamily = 'Inter (Sans)']) => build(AppThemeType.matcha, fontFamily);

  static ThemeData applyFontFamily(ThemeData baseTheme, String fontFamily) {
    // Deprecated: We now construct themes directly with the chosen fontFamily.
    return baseTheme;
  }
}

// ─── Backward Compatible Colors Interface (For Safety) ────────────────────────
class PrismColors {
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF262628);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkPrimary = Color(0xFFE07A5F);
  static const Color darkPrimaryContainer = Color(0xFF46251B);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFFF2F2F7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);
  static const Color darkAccentGreen = Color(0xFF81B29A);
  static const Color darkAccentAmber = Color(0xFFF2CC8F);
  static const Color darkAccentRose = Color(0xFFE07A5F);

  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color lightSurface = Color(0xFFF3EFE8);
  static const Color lightSurfaceVariant = Color(0xFFECE7DE);
  static const Color lightBorder = Color(0xFFE6DFD5);
  static const Color lightPrimary = Color(0xFFC8A97E);
  static const Color lightPrimaryContainer = Color(0xFFF5EFE6);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D2A26);
  static const Color lightTextSecondary = Color(0xFF7A746B);
  static const Color lightTextTertiary = Color(0xFFAFA79D);
  static const Color lightAccentGreen = Color(0xFF81B29A);
  static const Color lightAccentAmber = Color(0xFFC8A97E);
  static const Color lightAccentRose = Color(0xFFE07A5F);

  static const Color sepiaBackground = Color(0xFFFAF6EE);
  static const Color sepiaSurface = Color(0xFFFDFBFA);
  static const Color sepiaSurfaceVariant = Color(0xFFEFEAE2);
  static const Color sepiaBorder = Color(0xFFE5DEC9);
  static const Color sepiaPrimary = Color(0xFF5C3D2E);
  static const Color sepiaPrimaryContainer = Color(0xFFF9ECE6);
  static const Color sepiaOnPrimary = Color(0xFFFFFFFF);
  static const Color sepiaText = Color(0xFF2A1F19);
  static const Color sepiaTextSecondary = Color(0xFF60524C);
  static const Color sepiaTextTertiary = Color(0xFFA59890);
  static const Color sepiaAccentGreen = Color(0xFF81B29A);
  static const Color sepiaAccentAmber = Color(0xFFC8A97E);
  static const Color sepiaAccentRose = Color(0xFFE07A5F);

  static const Color forestBackground = Color(0xFF141C18);
  static const Color forestSurface = Color(0xFF1C2820);
  static const Color forestSurfaceVariant = Color(0xFF223028);
  static const Color forestBorder = Color(0xFF2E3E34);
  static const Color forestPrimary = Color(0xFF81B29A);
  static const Color forestPrimaryContainer = Color(0xFF1A3327);
  static const Color forestOnPrimary = Color(0xFF0D1F17);
  static const Color forestText = Color(0xFFDEEDE5);
  static const Color forestTextSecondary = Color(0xFF7FA892);
  static const Color forestTextTertiary = Color(0xFF4E6A5B);
  static const Color forestAccentGold = Color(0xFFD4A853);
  static const Color forestAccentRose = Color(0xFFB06060);

  static const Color slateBackground = Color(0xFF0F1117);
  static const Color slateSurface = Color(0xFF171C26);
  static const Color slateSurfaceVariant = Color(0xFF1E2535);
  static const Color slateBorder = Color(0xFF2A3347);
  static const Color slatePrimary = Color(0xFF7DAFE8);
  static const Color slatePrimaryContainer = Color(0xFF152040);
  static const Color slateOnPrimary = Color(0xFF0A1428);
  static const Color slateText = Color(0xFFE4EAF5);
  static const Color slateTextSecondary = Color(0xFF7D90B2);
  static const Color slateTextTertiary = Color(0xFF4A5A74);
  static const Color slateAccentCyan = Color(0xFF56CCF2);
  static const Color slateAccentIndigo = Color(0xFF9B8ED6);

  static const Color arcticBackground = Color(0xFFF4F8FB);
  static const Color arcticSurface = Color(0xFFEBF2F7);
  static const Color arcticSurfaceVariant = Color(0xFFDEEBF2);
  static const Color arcticBorder = Color(0xFFCADDE9);
  static const Color arcticPrimary = Color(0xFF3A8FA8);
  static const Color arcticPrimaryContainer = Color(0xFFD6EEF5);
  static const Color arcticOnPrimary = Color(0xFFFFFFFF);
  static const Color arcticText = Color(0xFF152632);
  static const Color arcticTextSecondary = Color(0xFF4E7080);
  static const Color arcticTextTertiary = Color(0xFF8AAAB8);
  static const Color arcticAccentMint = Color(0xFF56CCF2);
  static const Color arcticAccentSteel = Color(0xFF6B9BBF);

  static const Color noirBackground = Color(0xFF111110);
  static const Color noirSurface = Color(0xFF1A1917);
  static const Color noirSurfaceVariant = Color(0xFF201F1D);
  static const Color noirBorder = Color(0xFF302E2B);
  static const Color noirPrimary = Color(0xFFC9A84C);
  static const Color noirPrimaryContainer = Color(0xFF2A2318);
  static const Color noirOnPrimary = Color(0xFF100E08);
  static const Color noirText = Color(0xFFF0EDE6);
  static const Color noirTextSecondary = Color(0xFF8A8578);
  static const Color noirTextTertiary = Color(0xFF504D47);
  static const Color noirAccentGold = Color(0xFFC9A84C);
  static const Color noirAccentRose = Color(0xFFB07070);

  static const Color blushBackground = Color(0xFFFDF8F8);
  static const Color blushSurface = Color(0xFFF7EFF0);
  static const Color blushSurfaceVariant = Color(0xFFF0E4E6);
  static const Color blushBorder = Color(0xFFE8D5D8);
  static const Color blushPrimary = Color(0xFFB0637A);
  static const Color blushPrimaryContainer = Color(0xFFF9E8EC);
  static const Color blushOnPrimary = Color(0xFFFFFFFF);
  static const Color blushText = Color(0xFF2E1F24);
  static const Color blushTextSecondary = Color(0xFF7A5460);
  static const Color blushTextTertiary = Color(0xFFB89AA0);
  static const Color blushAccentRose = Color(0xFFB0637A);
  static const Color blushAccentGold = Color(0xFFC8966E);

  static const Color midnightBackground = Color(0xFF000000);
  static const Color midnightSurface = Color(0xFF0C0C0C);
  static const Color midnightSurfaceVariant = Color(0xFF141414);
  static const Color midnightBorder = Color(0xFF1E1E1E);
  static const Color midnightPrimary = Color(0xFF6E7681);
  static const Color midnightPrimaryContainer = Color(0xFF1C1E22);
  static const Color midnightOnPrimary = Color(0xFFFFFFFF);
  static const Color midnightText = Color(0xFFE5E7EB);
  static const Color midnightTextSecondary = Color(0xFF8E95A0);
  static const Color midnightTextTertiary = Color(0xFF4B525D);
  static const Color midnightAccentRose = Color(0xFFB85C5C);
  static const Color midnightAccentGreen = Color(0xFF5C8F73);
  static const Color midnightAccentAmber = Color(0xFF9E7E4E);

  static const Color matchaBackground = Color(0xFFF4F7F4);
  static const Color matchaSurface = Color(0xFFFAFCFA);
  static const Color matchaSurfaceVariant = Color(0xFFE6EFE6);
  static const Color matchaBorder = Color(0xFFD5E2D5);
  static const Color matchaPrimary = Color(0xFF3D6146);
  static const Color matchaPrimaryContainer = Color(0xFFE2EDE4);
  static const Color matchaOnPrimary = Color(0xFFFFFFFF);
  static const Color matchaText = Color(0xFF1D2E22);
  static const Color matchaTextSecondary = Color(0xFF5B7863);
  static const Color matchaTextTertiary = Color(0xFF96AC9C);
  static const Color matchaAccentRose = Color(0xFFD97706);
  static const Color matchaAccentGreen = Color(0xFF3D6146);
  static const Color matchaAccentAmber = Color(0xFFC29B38);
}
