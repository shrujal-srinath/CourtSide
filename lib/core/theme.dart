import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
//  APP COLORS
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  static const Color black         = Color(0xFF0D0D0D);
  static const Color surface       = Color(0xFF1A1A1A);
  static const Color surfaceHigh   = Color(0xFF242424);
  static const Color border        = Color(0xFF2A2A2A);
  static const Color white         = Color(0xFFFAFAFA);
  static const Color surfaceLight  = Color(0xFFF2F2F2);
  static const Color borderLight   = Color(0xFFE8E8E8);

  static const Color red           = Color(0xFFE8112D);
  static const Color redDark       = Color(0xFFC0001F);
  static const Color redMuted      = Color(0xFF4A0010);

  static const Color basketball    = Color(0xFFFF6B35);
  static const Color cricket       = Color(0xFF2DD4BF);

  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFF8A8A8A);
  static const Color textTertiaryDark   = Color(0xFF555555);
  static const Color textPrimaryLight   = Color(0xFF0D0D0D);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textTertiaryLight  = Color(0xFFAAAAAA);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
}

// ═══════════════════════════════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayXL(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 48, fontWeight: FontWeight.w700,
    letterSpacing: -1.9, color: color, height: 1.0,
  );

  static TextStyle displayL(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 36, fontWeight: FontWeight.w700,
    letterSpacing: -1.1, color: color, height: 1.1,
  );

  static TextStyle displayM(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 28, fontWeight: FontWeight.w700,
    letterSpacing: -0.6, color: color, height: 1.15,
  );

  static TextStyle displayS(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 22, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, color: color, height: 1.2,
  );

  static TextStyle headingL(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, color: color, height: 1.3,
  );

  static TextStyle headingM(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: color, height: 1.3,
  );

  static TextStyle bodyL(Color color) => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: color, height: 1.6,
  );

  static TextStyle bodyM(Color color) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: color, height: 1.5,
  );

  static TextStyle bodyS(Color color) => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: color, height: 1.4,
  );

  static TextStyle labelM(Color color) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 1.1, color: color,
  );

  static TextStyle labelS(Color color) => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w600,
    letterSpacing: 1.0, color: color,
  );

  static TextStyle statXL(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 42, fontWeight: FontWeight.w700,
    letterSpacing: -1.7, color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  static TextStyle statL(Color color) => GoogleFonts.spaceGrotesk(
    fontSize: 32, fontWeight: FontWeight.w700,
    letterSpacing: -1.0, color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );
}

// ═══════════════════════════════════════════════════════════════
//  THEME DATA
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── DARK ──────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      surface:                 AppColors.black,
      primary:                 AppColors.red,
      onPrimary:               AppColors.white,
      secondary:               AppColors.surface,
      onSecondary:             AppColors.textPrimaryDark,
      error:                   AppColors.error,
      onSurface:               AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceHigh,
    ),
    textTheme: _buildTextTheme(isDark: true),
    appBarTheme: const AppBarTheme(
      backgroundColor:     AppColors.black,
      foregroundColor:     AppColors.white,
      elevation:           0,
      scrolledUnderElevation: 0,
      centerTitle:         false,
      systemOverlayStyle:  SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.light,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:    AppColors.surface,
      selectedItemColor:  AppColors.red,
      unselectedItemColor:AppColors.textTertiaryDark,
      type:               BottomNavigationBarType.fixed,
      elevation:          0,
    ),
    cardTheme: CardThemeData(
      color:     AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        elevation:       0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryDark, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border, thickness: 0.5, space: 0,
    ),
    pageTransitionsTheme: _pageTransitions,
  );

  // ── LIGHT ─────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: const ColorScheme.light(
      surface:                 AppColors.white,
      primary:                 AppColors.redDark,
      onPrimary:               AppColors.white,
      secondary:               AppColors.surfaceLight,
      onSecondary:             AppColors.textPrimaryLight,
      error:                   AppColors.error,
      onSurface:               AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceLight,
    ),
    textTheme: _buildTextTheme(isDark: false),
    appBarTheme: const AppBarTheme(
      backgroundColor:     AppColors.white,
      foregroundColor:     AppColors.black,
      elevation:           0,
      scrolledUnderElevation: 0,
      centerTitle:         false,
      systemOverlayStyle:  SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.dark,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:    AppColors.white,
      selectedItemColor:  AppColors.redDark,
      unselectedItemColor:AppColors.textTertiaryLight,
      type:               BottomNavigationBarType.fixed,
      elevation:          0,
    ),
    cardTheme: CardThemeData(
      color:     AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.redDark,
        foregroundColor: AppColors.white,
        elevation:       0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:    true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.redDark, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryLight, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight, thickness: 0.5, space: 0,
    ),
    pageTransitionsTheme: _pageTransitions,
  );

  // ── Shared ────────────────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return TextTheme(
      displayLarge:  GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, color: primary, letterSpacing: -2),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
      displaySmall:  GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium:GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:    GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.1),
      labelMedium:   GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.0),
    );
  }

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}