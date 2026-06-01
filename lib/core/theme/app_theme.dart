import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Type Enum ─────────────────────────────────────────────────────────
enum AppThemeType { system, light, dark, sepia, forest, slate, arctic, noir, blush }

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
  }
}

// ─── Color Tokens ────────────────────────────────────────────────────────────
class MeridianColors {
  // Dusk (dark default) - Warm near-black with terracotta glow
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF262628);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2E);
  static const Color darkBorder = Color(0xFF3A3A3C);
  static const Color darkPrimary = Color(0xFFE07A5F); // Signature Terracotta
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

  // Forest (dark) - Deep pine green with sage accents, moody & organic
  static const Color forestBackground = Color(0xFF141C18); // Deep pine black-green
  static const Color forestSurface = Color(0xFF1C2820); // Dark moss surface
  static const Color forestSurfaceVariant = Color(0xFF223028); // Slightly lighter moss
  static const Color forestBorder = Color(0xFF2E3E34); // Muted forest border
  static const Color forestPrimary = Color(0xFF81B29A); // Sage green accent
  static const Color forestPrimaryContainer = Color(0xFF1A3327); // Deep forest container
  static const Color forestOnPrimary = Color(0xFF0D1F17);
  static const Color forestText = Color(0xFFDEEDE5); // Soft moonlit green-white
  static const Color forestTextSecondary = Color(0xFF7FA892); // Muted sage
  static const Color forestTextTertiary = Color(0xFF4E6A5B); // Deep forest grey-green
  static const Color forestAccentGold = Color(0xFFD4A853); // Earthy amber
  static const Color forestAccentRose = Color(0xFFB06060); // Muted forest red

  // Slate (dark) - Deep navy-indigo with soft cyan accents, developer-inspired
  static const Color slateBackground = Color(0xFF0F1117); // Near-black navy
  static const Color slateSurface = Color(0xFF171C26); // Dark indigo surface
  static const Color slateSurfaceVariant = Color(0xFF1E2535); // Deeper indigo panel
  static const Color slateBorder = Color(0xFF2A3347); // Navy-steel border
  static const Color slatePrimary = Color(0xFF7DAFE8); // Soft steel blue accent
  static const Color slatePrimaryContainer = Color(0xFF152040); // Deep navy container
  static const Color slateOnPrimary = Color(0xFF0A1428);
  static const Color slateText = Color(0xFFE4EAF5); // Cool blue-white
  static const Color slateTextSecondary = Color(0xFF7D90B2); // Muted steel blue-grey
  static const Color slateTextTertiary = Color(0xFF4A5A74); // Deep navy tertiary
  static const Color slateAccentCyan = Color(0xFF56CCF2); // Soft cyan highlight
  static const Color slateAccentIndigo = Color(0xFF9B8ED6); // Soft indigo-violet

  // Arctic (light) - Icy near-white surfaces with pale cyan-mint accent, crisp & minimal
  static const Color arcticBackground = Color(0xFFF4F8FB); // Crisp icy white-blue
  static const Color arcticSurface = Color(0xFFEBF2F7); // Soft frost surface
  static const Color arcticSurfaceVariant = Color(0xFFDEEBF2); // Cool pale blue panel
  static const Color arcticBorder = Color(0xFFCADDE9); // Icy steel border
  static const Color arcticPrimary = Color(0xFF3A8FA8); // Calm teal-cyan accent
  static const Color arcticPrimaryContainer = Color(0xFFD6EEF5); // Pale ice container
  static const Color arcticOnPrimary = Color(0xFFFFFFFF);
  static const Color arcticText = Color(0xFF152632); // Deep arctic navy
  static const Color arcticTextSecondary = Color(0xFF4E7080); // Muted teal-slate
  static const Color arcticTextTertiary = Color(0xFF8AAAB8); // Light ice-grey
  static const Color arcticAccentMint = Color(0xFF56CCF2); // Bright cyan-mint pop
  static const Color arcticAccentSteel = Color(0xFF6B9BBF); // Steel blue

  // Noir (dark) - Near-black with muted gold accents, cinematic editorial
  static const Color noirBackground = Color(0xFF111110); // Near-black warm
  static const Color noirSurface = Color(0xFF1A1917); // Dark warm charcoal
  static const Color noirSurfaceVariant = Color(0xFF201F1D); // Slightly lifted charcoal
  static const Color noirBorder = Color(0xFF302E2B); // Warm dark border
  static const Color noirPrimary = Color(0xFFC9A84C); // Muted cinematic gold
  static const Color noirPrimaryContainer = Color(0xFF2A2318); // Deep gold shadow
  static const Color noirOnPrimary = Color(0xFF100E08);
  static const Color noirText = Color(0xFFF0EDE6); // Warm off-white
  static const Color noirTextSecondary = Color(0xFF8A8578); // Muted warm grey
  static const Color noirTextTertiary = Color(0xFF504D47); // Deep warm charcoal
  static const Color noirAccentGold = Color(0xFFC9A84C); // Same gold
  static const Color noirAccentRose = Color(0xFFB07070); // Muted editorial rose

  // Blush (light) - Soft pinkish-white surfaces with dusty rose accents, refined
  static const Color blushBackground = Color(0xFFFDF8F8); // Petal white
  static const Color blushSurface = Color(0xFFF7EFF0); // Soft blush surface
  static const Color blushSurfaceVariant = Color(0xFFF0E4E6); // Warm pinkish panel
  static const Color blushBorder = Color(0xFFE8D5D8); // Dusty rose border
  static const Color blushPrimary = Color(0xFFB0637A); // Dusty rose accent
  static const Color blushPrimaryContainer = Color(0xFFF9E8EC); // Light blush container
  static const Color blushOnPrimary = Color(0xFFFFFFFF);
  static const Color blushText = Color(0xFF2E1F24); // Deep rose-brown text
  static const Color blushTextSecondary = Color(0xFF7A5460); // Warm dusty mauve
  static const Color blushTextTertiary = Color(0xFFB89AA0); // Light blush grey
  static const Color blushAccentRose = Color(0xFFB0637A); // Same dusty rose
  static const Color blushAccentGold = Color(0xFFC8966E); // Warm apricot complement
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
      textTheme: _buildTextTheme(MeridianColors.sepiaText, MeridianColors.sepiaTextSecondary),
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

  // ─── Forest Theme ────────────────────────────────────────────────────────────
  static ThemeData forest() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: MeridianColors.forestSurface,
        surfaceContainerHighest: MeridianColors.forestSurfaceVariant,
        primary: MeridianColors.forestPrimary,
        primaryContainer: MeridianColors.forestPrimaryContainer,
        onPrimary: MeridianColors.forestOnPrimary,
        onSurface: MeridianColors.forestText,
        outline: MeridianColors.forestBorder,
        error: MeridianColors.forestAccentRose,
      ),
      scaffoldBackgroundColor: MeridianColors.forestBackground,
      cardColor: MeridianColors.forestSurface,
      dividerColor: MeridianColors.forestBorder,
      textTheme: _buildTextTheme(MeridianColors.forestText, MeridianColors.forestTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.forestBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.forestText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.forestTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.forestSurface,
        selectedItemColor: MeridianColors.forestPrimary,
        unselectedItemColor: MeridianColors.forestTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.forestSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.forestBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.forestBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.forestPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.forestTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.forestPrimary,
        foregroundColor: MeridianColors.forestOnPrimary,
        elevation: 4,
      ),
    );
  }

  // ─── Slate Theme ─────────────────────────────────────────────────────────────
  static ThemeData slate() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: MeridianColors.slateSurface,
        surfaceContainerHighest: MeridianColors.slateSurfaceVariant,
        primary: MeridianColors.slatePrimary,
        primaryContainer: MeridianColors.slatePrimaryContainer,
        onPrimary: MeridianColors.slateOnPrimary,
        onSurface: MeridianColors.slateText,
        outline: MeridianColors.slateBorder,
        error: MeridianColors.slateAccentCyan,
      ),
      scaffoldBackgroundColor: MeridianColors.slateBackground,
      cardColor: MeridianColors.slateSurface,
      dividerColor: MeridianColors.slateBorder,
      textTheme: _buildTextTheme(MeridianColors.slateText, MeridianColors.slateTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.slateBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.slateText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.slateTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.slateSurface,
        selectedItemColor: MeridianColors.slatePrimary,
        unselectedItemColor: MeridianColors.slateTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.slateSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.slateBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.slateBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.slatePrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.slateTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.slatePrimary,
        foregroundColor: MeridianColors.slateOnPrimary,
        elevation: 4,
      ),
    );
  }

  // ─── Arctic Theme ─────────────────────────────────────────────────────────────
  static ThemeData arctic() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: MeridianColors.arcticSurface,
        surfaceContainerHighest: MeridianColors.arcticSurfaceVariant,
        primary: MeridianColors.arcticPrimary,
        primaryContainer: MeridianColors.arcticPrimaryContainer,
        onPrimary: MeridianColors.arcticOnPrimary,
        onSurface: MeridianColors.arcticText,
        outline: MeridianColors.arcticBorder,
        error: Color(0xFFB85C5C),
      ),
      scaffoldBackgroundColor: MeridianColors.arcticBackground,
      cardColor: MeridianColors.arcticSurface,
      dividerColor: MeridianColors.arcticBorder,
      textTheme: _buildTextTheme(MeridianColors.arcticText, MeridianColors.arcticTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.arcticBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.arcticText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.arcticTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.arcticSurface,
        selectedItemColor: MeridianColors.arcticPrimary,
        unselectedItemColor: MeridianColors.arcticTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.arcticSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.arcticBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.arcticBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.arcticPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.arcticTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.arcticPrimary,
        foregroundColor: MeridianColors.arcticOnPrimary,
        elevation: 4,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary, [String fontFamily = 'Inter (Sans)']) {
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

  static ThemeData applyFontFamily(ThemeData baseTheme, String fontFamily) {
    final textTheme = _buildTextTheme(
      baseTheme.colorScheme.onSurface,
      baseTheme.colorScheme.onSurface.withValues(alpha: 0.7),
      fontFamily,
    );
    return baseTheme.copyWith(
      textTheme: textTheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: _getThemeFont(
          fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: baseTheme.appBarTheme.titleTextStyle?.color ?? baseTheme.colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        hintStyle: _getThemeFont(
          fontFamily,
          color: baseTheme.inputDecorationTheme.hintStyle?.color ?? baseTheme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }

  // ─── Noir Theme ───────────────────────────────────────────────────────────────
  static ThemeData noir() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: MeridianColors.noirSurface,
        surfaceContainerHighest: MeridianColors.noirSurfaceVariant,
        primary: MeridianColors.noirPrimary,
        primaryContainer: MeridianColors.noirPrimaryContainer,
        onPrimary: MeridianColors.noirOnPrimary,
        onSurface: MeridianColors.noirText,
        outline: MeridianColors.noirBorder,
        error: MeridianColors.noirAccentRose,
      ),
      scaffoldBackgroundColor: MeridianColors.noirBackground,
      cardColor: MeridianColors.noirSurface,
      dividerColor: MeridianColors.noirBorder,
      textTheme: _buildTextTheme(MeridianColors.noirText, MeridianColors.noirTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.noirBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.noirText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.noirTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.noirSurface,
        selectedItemColor: MeridianColors.noirPrimary,
        unselectedItemColor: MeridianColors.noirTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.noirSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.noirBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.noirBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.noirPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.noirTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.noirPrimary,
        foregroundColor: MeridianColors.noirOnPrimary,
        elevation: 4,
      ),
    );
  }

  // ─── Blush Theme ──────────────────────────────────────────────────────────────
  static ThemeData blush() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        surface: MeridianColors.blushSurface,
        surfaceContainerHighest: MeridianColors.blushSurfaceVariant,
        primary: MeridianColors.blushPrimary,
        primaryContainer: MeridianColors.blushPrimaryContainer,
        onPrimary: MeridianColors.blushOnPrimary,
        onSurface: MeridianColors.blushText,
        outline: MeridianColors.blushBorder,
        error: Color(0xFFB85C5C),
      ),
      scaffoldBackgroundColor: MeridianColors.blushBackground,
      cardColor: MeridianColors.blushSurface,
      dividerColor: MeridianColors.blushBorder,
      textTheme: _buildTextTheme(MeridianColors.blushText, MeridianColors.blushTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: MeridianColors.blushBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeridianColors.blushText,
        ),
        iconTheme: const IconThemeData(color: MeridianColors.blushTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: MeridianColors.blushSurface,
        selectedItemColor: MeridianColors.blushPrimary,
        unselectedItemColor: MeridianColors.blushTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeridianColors.blushSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.blushBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.blushBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MeridianColors.blushPrimary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: MeridianColors.blushTextTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MeridianColors.blushPrimary,
        foregroundColor: MeridianColors.blushOnPrimary,
        elevation: 4,
      ),
    );
  }
}

