import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Type Enum ─────────────────────────────────────────────────────────
enum AppThemeType { system, light, dark, sepia }

// ─── Theme Provider ──────────────────────────────────────────────────────────
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeType> {
  ThemeNotifier() : super(AppThemeType.dark) { // default dark
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('themeType') ?? 2; // default dark
    state = AppThemeType.values[idx];
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeType', type.index);
  }
}

// ─── Color Tokens ────────────────────────────────────────────────────────────
class MeridianColors {
  // Midnight OLED (dark default) - Premium Bear-inspired Dark Theme
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF262628);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkPrimary = Color(0xFFE07A5F); // Signature Bear Terracotta
  static const Color darkPrimaryContainer = Color(0xFF46251B); // Burnt terracotta shadow
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFFF2F2F7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkTextTertiary = Color(0xFF636366);
  static const Color darkAccentGreen = Color(0xFF81B29A); // Soft sage green
  static const Color darkAccentAmber = Color(0xFFF2CC8F); // Soft cream yellow
  static const Color darkAccentRose = Color(0xFFE07A5F);

  // Clean Paper (light default) - Premium Meridian Light Theme
  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color lightSurface = Color(0xFFF3EFE8);
  static const Color lightSurfaceVariant = Color(0xFFECE7DE);
  static const Color lightBorder = Color(0xFFE6DFD5);
  static const Color lightPrimary = Color(0xFFC8A97E); // Warm gold/sand accent
  static const Color lightPrimaryContainer = Color(0xFFF5EFE6); // Light sand/cream container
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D2A26);
  static const Color lightTextSecondary = Color(0xFF7A746B);
  static const Color lightTextTertiary = Color(0xFFAFA79D);
  static const Color lightAccentGreen = Color(0xFF81B29A);
  static const Color lightAccentAmber = Color(0xFFC8A97E);
  static const Color lightAccentRose = Color(0xFFE07A5F);

  // Warm Editorial (Sepia Theme) - Parchment Cream & Espresso Editorial
  static const Color sepiaBackground = Color(0xFFFAF6EE); // Warm parchment cream
  static const Color sepiaSurface = Color(0xFFFDFBFA); // Bright soft cream
  static const Color sepiaSurfaceVariant = Color(0xFFEFEAE2); // Warm neutral grey
  static const Color sepiaBorder = Color(0xFFE5DEC9); // Parchment border clay
  static const Color sepiaPrimary = Color(0xFF5C3D2E); // Espresso chocolate accent
  static const Color sepiaPrimaryContainer = Color(0xFFF9ECE6); // Light terracotta Container
  static const Color sepiaOnPrimary = Color(0xFFFFFFFF);
  static const Color sepiaText = Color(0xFF2A1F19); // Dark charcoal brown
  static const Color sepiaTextSecondary = Color(0xFF60524C); // Warm sepia slate
  static const Color sepiaTextTertiary = Color(0xFFA59890); // Light clay
  static const Color sepiaAccentGreen = Color(0xFF81B29A);
  static const Color sepiaAccentAmber = Color(0xFFC8A97E);
  static const Color sepiaAccentRose = Color(0xFFE07A5F);
}

// ─── Theme Builder ────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: MeridianColors.darkSurface,
        surfaceContainerHighest: MeridianColors.darkSurfaceVariant,
        primary: MeridianColors.darkPrimary,
        primaryContainer: MeridianColors.darkPrimaryContainer,
        onPrimary: MeridianColors.darkOnPrimary,
        onSurface: MeridianColors.darkText,
        outline: MeridianColors.darkBorder,
        error: MeridianColors.darkAccentRose,
      ),
      scaffoldBackgroundColor: MeridianColors.darkBackground,
      cardColor: MeridianColors.darkSurface,
      dividerColor: MeridianColors.darkBorder,
      textTheme: _buildTextTheme(MeridianColors.darkText, MeridianColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.darkText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.darkTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.darkSurface,
        selectedItemColor: MeridianColors.darkPrimary,
        unselectedItemColor: MeridianColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.darkPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.darkTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.darkPrimary,
        foregroundColor: MeridianColors.darkOnPrimary,
        elevation: 4,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: MeridianColors.lightSurface,
        surfaceContainerHighest: MeridianColors.lightSurfaceVariant,
        primary: MeridianColors.lightPrimary,
        primaryContainer: MeridianColors.lightPrimaryContainer,
        onPrimary: MeridianColors.lightOnPrimary,
        onSurface: MeridianColors.lightText,
        outline: MeridianColors.lightBorder,
        error: MeridianColors.lightAccentRose,
      ),
      scaffoldBackgroundColor: MeridianColors.lightBackground,
      cardColor: MeridianColors.lightSurface,
      dividerColor: MeridianColors.lightBorder,
      textTheme: _buildTextTheme(MeridianColors.lightText, MeridianColors.lightTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.lightText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.lightTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.lightSurface,
        selectedItemColor: MeridianColors.lightPrimary,
        unselectedItemColor: MeridianColors.lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.lightPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.lightTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.lightPrimary,
        foregroundColor: MeridianColors.lightOnPrimary,
        elevation: 4,
      ),
    );
  }

  static ThemeData sepia() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: MeridianColors.sepiaSurface,
        surfaceContainerHighest: MeridianColors.sepiaSurfaceVariant,
        primary: MeridianColors.sepiaPrimary,
        primaryContainer: MeridianColors.sepiaPrimaryContainer,
        onPrimary: MeridianColors.sepiaOnPrimary,
        onSurface: MeridianColors.sepiaText,
        outline: MeridianColors.sepiaBorder,
        error: MeridianColors.sepiaAccentRose,
      ),
      scaffoldBackgroundColor: MeridianColors.sepiaBackground,
      cardColor: MeridianColors.sepiaSurface,
      dividerColor: MeridianColors.sepiaBorder,
      textTheme: _buildSepiaTextTheme(MeridianColors.sepiaText, MeridianColors.sepiaTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.sepiaBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.sepiaText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.sepiaTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.sepiaSurface,
        selectedItemColor: MeridianColors.sepiaPrimary,
        unselectedItemColor: MeridianColors.sepiaTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.sepiaSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.sepiaBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.sepiaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.sepiaPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.lora(
          color: MeridianColors.sepiaTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.sepiaPrimary,
        foregroundColor: MeridianColors.sepiaOnPrimary,
        elevation: 4,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
      headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
      titleSmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  static TextTheme _buildSepiaTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w600, color: primary),
      headlineLarge: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
      titleMedium: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
      titleSmall: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      bodyLarge: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.merriweather(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.merriweather(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.merriweather(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.merriweather(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.merriweather(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
