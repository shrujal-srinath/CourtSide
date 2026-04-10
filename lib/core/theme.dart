// lib/core/theme.dart
//
// Compatibility shim — keeps AppColors + ThemeColors/ColorsX alive
// while screens are migrated to context.colors (AppColorScheme).
//
// AppTextStyles now delegates to typography_tokens.dart
// (SpaceGrotesk + Inter — Barlow/DM Sans fully reverted).
//
// New code should import from:
//   core/tokens/color_tokens.dart    → AppColorScheme, context.colors
//   core/tokens/typography_tokens.dart → AppTextStyles
//   core/tokens/spacing_tokens.dart  → AppSpacing, AppRadius, AppShadow
//   core/theme/app_theme.dart        → AppTheme

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Re-export new token system ────────────────────────────────────
export 'tokens/color_tokens.dart' show AppColorScheme, AppColorsX;
export 'tokens/typography_tokens.dart' show AppTextStyles;
export 'tokens/spacing_tokens.dart' show AppSpacing, AppRadius, AppDuration, AppShadow;
export 'theme/app_theme.dart' show AppTheme;

// ═══════════════════════════════════════════════════════════════
//  APP COLORS — kept for backward compat only
//  New screens: use context.colors.colorXxx instead.
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Dark backgrounds (4-level hierarchy) ─────────────────────
  static const Color black        = Color(0xFF0B0F1A); // scaffold
  static const Color surface      = Color(0xFF0F1524); // card bg
  static const Color surfaceHigh  = Color(0xFF161B24); // elevated card
  static const Color overlay      = Color(0xFF1E2535); // modals / sheets

  // ── Light backgrounds (clean neutral) ────────────────────────
  static const Color lightBg      = Color(0xFFF5F6F8); // scaffold
  static const Color lightCard    = Color(0xFFFFFFFF); // card bg
  static const Color lightHigh    = Color(0xFFF3F4F6); // elevated / muted bg
  static const Color lightOverlay = Color(0xFFFFFFFF); // modals / sheets

  static const Color border       = Color(0xFF1A2030); // dark border
  static const Color borderMuted  = Color(0xFF111520); // dark muted
  static const Color lightBorder  = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color lightBorderMuted = Color(0x0F000000); // rgba(0,0,0,0.06)

  static const Color white        = Color(0xFFF8F9FA);

  // ── Brand ─────────────────────────────────────────────────────
  static const Color red          = Color(0xFFFF3B3B);
  static const Color redGlow      = Color(0xFFFF1F3D);
  static const Color redDark      = Color(0xFFE52E2E);

  // ── Sport (theme-invariant) ───────────────────────────────────
  static const Color basketball   = Color(0xFFFF6B35);
  static const Color cricket      = Color(0xFF00C9A7);
  static const Color badminton    = Color(0xFFFFC107);
  static const Color football     = Color(0xFF4CAF50);

  // ── Text — dark theme ─────────────────────────────────────────
  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFFCCCCCC);
  static const Color textTertiaryDark   = Color(0xFF888888);

  // ── Text — light theme (clean neutral) ────────────────────────
  static const Color textPrimaryLight   = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight  = Color(0xFF9CA3AF);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successText = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningText = Color(0xFFD97706);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Divider ───────────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
}

// ═══════════════════════════════════════════════════════════════
//  THEME-AWARE COLORS — kept for backward compat (context.col)
//  Migrate to: context.colors.colorXxx
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
      : bg          = AppColors.lightBg,
        surface     = AppColors.lightCard,
        surfaceHigh = AppColors.lightHigh,
        overlay     = AppColors.lightOverlay,
        border      = AppColors.lightBorder,
        borderMuted = AppColors.lightBorderMuted,
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
  final Color onBrand;
  final bool  isDark;

  /// Header background gradient
  LinearGradient get gradBrand => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B0F1A), Color(0xFF0F1524)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F6F8), Color(0xFFF5F6F8)],
        );

  LinearGradient get gradProfile => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D1010), Color(0xFF1A0A12)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F6F8), Color(0xFFFFFFFF)],
        );

  LinearGradient gradSport(String sport) {
    if (isDark) {
      const Map<String, List<Color>> dark = {
        'basketball': [Color(0xFF1A0F00), Color(0xFF101010)],
        'cricket':    [Color(0xFF001A16), Color(0xFF101010)],
        'badminton':  [Color(0xFF1A1500), Color(0xFF101010)],
        'football':   [Color(0xFF001A08), Color(0xFF101010)],
      };
      final c = dark[sport.toLowerCase()];
      if (c != null) {
        return LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
      }
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A1A1A), Color(0xFF101010)],
      );
    } else {
      const Map<String, List<Color>> light = {
        'basketball': [Color(0xFFFFF5F0), Color(0xFFF5F6F8)],
        'cricket':    [Color(0xFFF0FAF8), Color(0xFFF5F6F8)],
        'badminton':  [Color(0xFFFFFCF0), Color(0xFFF5F6F8)],
        'football':   [Color(0xFFF0F8F2), Color(0xFFF5F6F8)],
      };
      final c = light[sport.toLowerCase()];
      if (c != null) {
        return LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
      }
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F4F6), Color(0xFFF5F6F8)],
      );
    }
  }
}

/// Backward-compat accessor — use context.col in screens not yet migrated.
/// Migrate to: context.colors (AppColorScheme via AppColorsX).
extension ColorsX on BuildContext {
  ThemeColors get col => Theme.of(this).brightness == Brightness.dark
      ? const ThemeColors._dark()
      : const ThemeColors._light();
}

// ═══════════════════════════════════════════════════════════════
//  TEXT STYLES — Inter throughout for clean consistency
// ═══════════════════════════════════════════════════════════════



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
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red, foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryDark, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.borderMuted, thickness: 0.5, space: 0),
    pageTransitionsTheme: _pageTransitions,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      surface:                 AppColors.lightBg,
      primary:                 AppColors.red,
      onPrimary:               AppColors.white,
      secondary:               AppColors.lightCard,
      onSecondary:             AppColors.textPrimaryLight,
      error:                   AppColors.error,
      onSurface:               AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.lightHigh,
    ),
    textTheme: _buildTextTheme(isDark: false),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard, elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red, foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryLight,
        side: BorderSide(color: AppColors.lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.lightCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
      hintStyle: GoogleFonts.inter(color: AppColors.textTertiaryLight, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 0.5, space: 0),
    pageTransitionsTheme: _pageTransitions,
  );

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return TextTheme(
      displayLarge:   GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w700, color: primary, letterSpacing: -2),
      displayMedium:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1),
      displaySmall:   GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      headlineLarge:  GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      headlineSmall:  GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
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
