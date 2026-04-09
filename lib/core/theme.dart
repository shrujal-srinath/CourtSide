import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
//  APP COLORS — static constants only
//  Use context.col for theme-aware surface/text/border values.
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Dark backgrounds (4-level hierarchy) ─────────────────────
  static const Color black        = Color(0xFF080A0F); // scaffold
  static const Color surface      = Color(0xFF0F1117); // card bg
  static const Color surfaceHigh  = Color(0xFF161B24); // elevated card
  static const Color overlay      = Color(0xFF1E2535); // modals / sheets

  // ── Light backgrounds — "Oat Latte" (warm cream hierarchy) ───
  static const Color cream        = Color(0xFFFAF7F2); // scaffold
  static const Color creamSurface = Color(0xFFF5EFE6); // card bg
  static const Color creamHigh    = Color(0xFFEDE3D7); // elevated card
  static const Color creamOverlay = Color(0xFFE8DDD1); // modals / sheets

  // ── Borders ───────────────────────────────────────────────────
  static const Color border       = Color(0xFF1A2030); // dark border
  static const Color borderMuted  = Color(0xFF111520); // dark muted
  static const Color creamBorder  = Color(0xFFDDD0C4); // light warm border

  // ── Legacy light aliases (kept for existing usage) ───────────
  static const Color white        = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFF5EFE6); // → creamSurface
  static const Color borderLight  = Color(0xFFDDD0C4); // → creamBorder

  // ── Brand ─────────────────────────────────────────────────────
  static const Color red          = Color(0xFFE8112D);
  static const Color redGlow      = Color(0xFFFF1F3D);
  static const Color redDark      = Color(0xFFB50022);
  static const Color redMuted     = Color(0xFF3D000A);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color statAccent   = Color(0xFFE8112D);
  static const Color teamBlue     = Color(0xFF3B82F6);
  static const Color teamRed      = Color(0xFFE8112D);

  // ── Sport (unchanged across themes) ──────────────────────────
  static const Color basketball   = Color(0xFFFF6B35);
  static const Color cricket      = Color(0xFF00C9A7);
  static const Color badminton    = Color(0xFFFFC107);
  static const Color football     = Color(0xFF4CAF50);

  // ── Text — dark theme ─────────────────────────────────────────
  static const Color textPrimaryDark    = Color(0xFFF8F9FA);
  static const Color textSecondaryDark  = Color(0xFF6B7280);
  static const Color textTertiaryDark   = Color(0xFF374151);

  // ── Text — light theme (warm espresso tones) ─────────────────
  static const Color textPrimaryLight   = Color(0xFF1C120A); // espresso
  static const Color textSecondaryLight = Color(0xFF7A6455); // warm taupe
  static const Color textTertiaryLight  = Color(0xFFA89380); // muted warm

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
}

// ═══════════════════════════════════════════════════════════════
//  THEME-AWARE COLORS — use via context.col
//
//  Only surface / border / text values differ per theme.
//  Brand, sport, and semantic colors are always AppColors.*
// ═══════════════════════════════════════════════════════════════

class ThemeColors {
  const ThemeColors._dark()
      : bg          = AppColors.black,
        surface     = AppColors.surface,
        surfaceHigh = AppColors.surfaceHigh,
        overlay     = AppColors.overlay,
        border      = AppColors.border,
        borderMuted = AppColors.borderMuted,
        text        = AppColors.textPrimaryDark,
        textSec     = AppColors.textSecondaryDark,
        textTer     = AppColors.textTertiaryDark,
        onBrand     = AppColors.white,
        isDark      = true;

  const ThemeColors._light()
      : bg          = AppColors.cream,
        surface     = AppColors.creamSurface,
        surfaceHigh = AppColors.creamHigh,
        overlay     = AppColors.creamOverlay,
        border      = AppColors.creamBorder,
        borderMuted = AppColors.creamBorder,
        text        = AppColors.textPrimaryLight,
        textSec     = AppColors.textSecondaryLight,
        textTer     = AppColors.textTertiaryLight,
        onBrand     = AppColors.white,
        isDark      = false;

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color overlay;
  final Color border;
  final Color borderMuted;
  final Color text;
  final Color textSec;
  final Color textTer;
  final Color onBrand; // always white — readable on red/sport elements
  final bool  isDark;

  /// Header background gradient — pure cream or deep navy
  LinearGradient get gradBrand => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080A0F), Color(0xFF0D1829)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFAF7F2), Color(0xFFF0E6D8)], // cream → warm amber
        );

  /// Profile banner gradient
  LinearGradient get gradProfile => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1829), Color(0xFF1A0A12)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5EFE6), Color(0xFFEDE3D7)],
        );

  /// Sport tint gradients
  LinearGradient gradSport(String sport) {
    if (isDark) {
      const Map<String, List<Color>> dark = {
        'basketball': [Color(0xFF1A0F00), Color(0xFF0F1117)],
        'cricket':    [Color(0xFF001A16), Color(0xFF0F1117)],
        'badminton':  [Color(0xFF1A1500), Color(0xFF0F1117)],
        'football':   [Color(0xFF001A08), Color(0xFF0F1117)],
      };
      final c = dark[sport.toLowerCase()];
      if (c != null) {
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c);
      }
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF161B24), Color(0xFF0F1117)],
      );
    } else {
      const Map<String, List<Color>> light = {
        'basketball': [Color(0xFFFFF1EB), Color(0xFFF5EFE6)],
        'cricket':    [Color(0xFFE8FAF7), Color(0xFFF5EFE6)],
        'badminton':  [Color(0xFFFFF8E0), Color(0xFFF5EFE6)],
        'football':   [Color(0xFFECF8EE), Color(0xFFF5EFE6)],
      };
      final c = light[sport.toLowerCase()];
      if (c != null) {
        return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c);
      }
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.creamHigh, AppColors.creamSurface],
      );
    }
  }
}

/// Convenient accessor — use as `context.col` anywhere in the widget tree.
extension ColorsX on BuildContext {
  ThemeColors get col => Theme.of(this).brightness == Brightness.dark
      ? const ThemeColors._dark()
      : const ThemeColors._light();
}

// ═══════════════════════════════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 48, fontWeight: FontWeight.w700,
        letterSpacing: -1.9, color: color, height: 1.0);

  static TextStyle displayL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 36, fontWeight: FontWeight.w700,
        letterSpacing: -1.1, color: color, height: 1.1);

  static TextStyle displayM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 28, fontWeight: FontWeight.w700,
        letterSpacing: -0.6, color: color, height: 1.15);

  static TextStyle displayS(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 22, fontWeight: FontWeight.w600,
        letterSpacing: -0.2, color: color, height: 1.2);

  static TextStyle headingL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 18, fontWeight: FontWeight.w600,
        letterSpacing: -0.2, color: color, height: 1.3);

  static TextStyle headingM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: color, height: 1.3);

  static TextStyle headingS(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: -0.1, color: color, height: 1.3);

  static TextStyle bodyL(Color color) => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: color, height: 1.6);

  static TextStyle bodyM(Color color) => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: color, height: 1.5);

  static TextStyle bodyS(Color color) => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: color, height: 1.4);

  static TextStyle labelM(Color color) => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 1.1, color: color);

  static TextStyle labelS(Color color) => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        letterSpacing: 1.0, color: color);

  static TextStyle overline(Color color) => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700,
        letterSpacing: 1.4, color: color);

  static TextStyle scoreXXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 72, fontWeight: FontWeight.w800,
        letterSpacing: -3, color: color, height: 1.0,
        fontFeatures: [const FontFeature.tabularFigures()]);

  static TextStyle statXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 42, fontWeight: FontWeight.w800,
        letterSpacing: -1.7, color: color,
        fontFeatures: [const FontFeature.tabularFigures()]);

  static TextStyle statL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 32, fontWeight: FontWeight.w800,
        letterSpacing: -1.0, color: color,
        fontFeatures: [const FontFeature.tabularFigures()]);

  static TextStyle statM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 24, fontWeight: FontWeight.w800,
        letterSpacing: -0.8, color: color,
        fontFeatures: [const FontFeature.tabularFigures()]);
}

// ═══════════════════════════════════════════════════════════════
//  THEME DATA
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

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
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red, foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryDark, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderMuted, thickness: 0.5, space: 0),
    pageTransitionsTheme: _pageTransitions,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: const ColorScheme.light(
      surface:                 AppColors.cream,
      primary:                 AppColors.red,
      onPrimary:               AppColors.white,
      secondary:               AppColors.creamSurface,
      onSecondary:             AppColors.textPrimaryLight,
      error:                   AppColors.error,
      onSurface:               AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.creamHigh,
    ),
    textTheme: _buildTextTheme(isDark: false),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.creamSurface, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.creamBorder, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red, foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.creamBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.creamSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.creamBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.creamBorder, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryLight, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.creamBorder, thickness: 0.5, space: 0),
    pageTransitionsTheme: _pageTransitions,
  );

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return TextTheme(
      displayLarge:   GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w700, color: primary, letterSpacing: -2),
      displayMedium:  GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
      displaySmall:   GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      headlineLarge:  GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      headlineSmall:  GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
      bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.1),
      labelMedium:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.0),
    );
  }

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    },
  );
}
