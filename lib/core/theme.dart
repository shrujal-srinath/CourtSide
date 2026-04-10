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
  static const Color black        = Color(0xFF080808); // scaffold
  static const Color surface      = Color(0xFF101010); // card bg
  static const Color surfaceHigh  = Color(0xFF1A1A1A); // elevated card
  static const Color overlay      = Color(0xFF242424); // modals / sheets

  // ── Borders ───────────────────────────────────────────────────
  static const Color border       = Color(0xFF1F1F1F);
  static const Color borderMuted  = Color(0xFF2A2A2A);

  // ── Legacy light aliases (kept for existing usage) ───────────
  static const Color white        = Color(0xFFFFFFFF);
  static const Color cream        = Color(0xFFFAF7F2);
  static const Color creamSurface = Color(0xFFF5EFE6);
  static const Color creamHigh    = Color(0xFFEDE3D7);
  static const Color creamOverlay = Color(0xFFE8DDD1);
  static const Color creamBorder  = Color(0xFFDDD0C4);
  static const Color surfaceLight = Color(0xFFF5EFE6);
  static const Color borderLight  = Color(0xFFDDD0C4);

  // ── Brand ─────────────────────────────────────────────────────
  static const Color red          = Color(0xFFB91C3A); // Ruby Red (canonical)
  static const Color redGlow      = Color(0xFFD42045);
  static const Color redDark      = Color(0xFF8E1229);
  static const Color redMuted     = Color(0xFF280010);

  // ── Blue accent ───────────────────────────────────────────────
  static const Color blue         = Color(0xFF3B82F6);
  static const Color blueMuted    = Color(0xFF1E3A5F);
  static const Color blueDark     = Color(0xFF1D4ED8);

  // ── Sport (theme-invariant) ───────────────────────────────────
  static const Color basketball   = Color(0xFFFF6B35);
  static const Color cricket      = Color(0xFF00C9A7);
  static const Color badminton    = Color(0xFFFFC107);
  static const Color football     = Color(0xFF4CAF50);

  // ── Text — dark theme ─────────────────────────────────────────
  static const Color textPrimaryDark    = Color(0xFFFFFFFF);
  static const Color textSecondaryDark  = Color(0xFFCCCCCC);
  static const Color textTertiaryDark   = Color(0xFF888888);

  // ── Text — light theme ───────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1C120A);
  static const Color textSecondaryLight = Color(0xFF7A6455);
  static const Color textTertiaryLight  = Color(0xFFA89380);

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Legacy aliases ─────────────────────────────────────────────
  static const Color statAccent = red;
  static const Color teamBlue   = blue;
  static const Color teamRed    = red;
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
  final Color onBrand;
  final bool  isDark;

  LinearGradient get gradBrand => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF080808), Color(0xFF0D1010)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFAF7F2), Color(0xFFF0E6D8)],
        );

  LinearGradient get gradProfile => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D1010), Color(0xFF1A0A12)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFF5EFE6), Color(0xFFEDE3D7)],
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
        'basketball': [Color(0xFFFFF1EB), Color(0xFFF5EFE6)],
        'cricket':    [Color(0xFFE8FAF7), Color(0xFFF5EFE6)],
        'badminton':  [Color(0xFFFFF8E0), Color(0xFFF5EFE6)],
        'football':   [Color(0xFFECF8EE), Color(0xFFF5EFE6)],
      };
      final c = light[sport.toLowerCase()];
      if (c != null) {
        return LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c);
      }
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppColors.creamHigh, AppColors.creamSurface],
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
