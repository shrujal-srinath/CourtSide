// lib/core/tokens/color_tokens.dart
//
// PRIMITIVE color constants (raw hex).
// Only import this inside theme definition files.
// Widget files NEVER reference ColorTokens directly — use context.colors instead.

import 'package:flutter/material.dart';

class ColorTokens {
  ColorTokens._();

  // ── LIGHT MODE ────────────────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF6F7F9);
  static const Color surfacePrimary    = Color(0xFFFFFFFF);
  static const Color surfaceElevated   = Color(0xFFF0F2F5);
  static const Color surfaceOverlay    = Color(0xFFE8EAED);

  static const Color accentPrimary   = Color(0xFFE8112D);
  static const Color accentSecondary = Color(0xFFB50022);
  static const Color accentSubtle    = Color(0x14E8112D);

  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color textOnAccent  = Color(0xFFFFFFFF);

  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  static const Color sportBasketball = Color(0xFFFF6B35);
  static const Color sportCricket    = Color(0xFF00C9A7);
  static const Color sportBadminton  = Color(0xFFFFC107);
  static const Color sportFootball   = Color(0xFF4CAF50);
}

// ── LIGHT MODE TOKEN CLASS (for light-mode only screens like ModeGate) ────
//
// Use this for screens that intentionally override to light mode.
// Provides semantic token names matching DarkColorTokens but with light values.
//
class LightModeColorTokens {
  LightModeColorTokens._();

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3F4F6);

  static const Color accentPrimary = Color(0xFFE8112D);
  static const Color accentSubtle  = Color(0xFFE8112D); // use with opacity

  static const Color textPrimary   = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color textOnAccent  = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
}

// ── DARK MODE primitives (Void Fire — UPGRADED) ───────────────────
//
// Overhaul goals:
//   1. Surface hierarchy: 4 levels clearly perceptible (was clustered in 8–30 range)
//   2. Text contrast: textTertiary was 0xFF374151 (WCAG fail ~2.8:1) — now readable
//   3. accentSubtle: was near-black maroon, now a visible red tint
//   4. borderSubtle: visible hairlines for card separation
//
class DarkColorTokens {
  DarkColorTokens._();

  // 4-level surface stack — each step clearly perceptible
  static const Color backgroundPrimary = Color(0xFF07090E); // deep black-navy
  static const Color surfacePrimary    = Color(0xFF0D1320); // card base  (+16/+15/+18 from bg)
  static const Color surfaceElevated   = Color(0xFF152032); // elevated cards (+8/+13/+18)
  static const Color surfaceOverlay    = Color(0xFF1C2B44); // modals/sheets (+7/+11/+12)

  // Accent — brand red preserved, subtle now actually visible
  static const Color accentPrimary   = Color(0xFFE8112D); // brand red (unchanged)
  static const Color accentSecondary = Color(0xFFB50022); // pressed state (unchanged)
  static const Color accentSubtle    = Color(0xFF2B0009); // visible red tint (was near-black)

  // Text — 4-level hierarchy, all readable on dark surfaces
  static const Color textPrimary   = Color(0xFFF0F4FF); // crisp cool white (was warm F8F9FA)
  static const Color textSecondary = Color(0xFF8D97AA); // clearly readable (was 6B7280, too dark)
  static const Color textTertiary  = Color(0xFF5E6B7D); // visible hints (was 374151, WCAG fail)
  static const Color textOnAccent  = Color(0xFFFFFFFF); // pure white (unchanged)

  // Borders — visible hairlines
  static const Color borderSubtle = Color(0xFF1B2640); // visible 0.5px lines (was 1A2030)
  static const Color borderMedium = Color(0xFF2B3E5A); // focus/active states (was 2A3040)

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  static const Color sportBasketball = Color(0xFFFF6B35);
  static const Color sportCricket    = Color(0xFF00C9A7);
  static const Color sportBadminton  = Color(0xFFFFC107);
  static const Color sportFootball   = Color(0xFF4CAF50);
}

// ══════════════════════════════════════════════════════════════════
//  AppColorScheme — ThemeExtension
//  Semantic token layer. Widgets read ONLY from this.
//  Access via: context.colors.colorSurfacePrimary
// ══════════════════════════════════════════════════════════════════

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.colorBackgroundPrimary,
    required this.colorSurfacePrimary,
    required this.colorSurfaceElevated,
    required this.colorSurfaceOverlay,
    required this.colorAccentPrimary,
    required this.colorAccentPressed,
    required this.colorAccentSubtle,
    required this.colorTextPrimary,
    required this.colorTextSecondary,
    required this.colorTextTertiary,
    required this.colorTextOnAccent,
    required this.colorBorderSubtle,
    required this.colorBorderMedium,
    required this.colorSuccess,
    required this.colorWarning,
    required this.colorError,
    required this.colorInfo,
    required this.colorSportBasketball,
    required this.colorSportCricket,
    required this.colorSportBadminton,
    required this.colorSportFootball,
  });

  // Backgrounds
  final Color colorBackgroundPrimary;
  final Color colorSurfacePrimary;
  final Color colorSurfaceElevated;
  final Color colorSurfaceOverlay;

  // Accent
  final Color colorAccentPrimary;
  final Color colorAccentPressed;
  final Color colorAccentSubtle;

  // Text
  final Color colorTextPrimary;
  final Color colorTextSecondary;
  final Color colorTextTertiary;
  final Color colorTextOnAccent;

  // Borders
  final Color colorBorderSubtle;
  final Color colorBorderMedium;

  // Semantic
  final Color colorSuccess;
  final Color colorWarning;
  final Color colorError;
  final Color colorInfo;

  // Sport
  final Color colorSportBasketball;
  final Color colorSportCricket;
  final Color colorSportBadminton;
  final Color colorSportFootball;

  @override
  AppColorScheme copyWith({
    Color? colorBackgroundPrimary,
    Color? colorSurfacePrimary,
    Color? colorSurfaceElevated,
    Color? colorSurfaceOverlay,
    Color? colorAccentPrimary,
    Color? colorAccentPressed,
    Color? colorAccentSubtle,
    Color? colorTextPrimary,
    Color? colorTextSecondary,
    Color? colorTextTertiary,
    Color? colorTextOnAccent,
    Color? colorBorderSubtle,
    Color? colorBorderMedium,
    Color? colorSuccess,
    Color? colorWarning,
    Color? colorError,
    Color? colorInfo,
    Color? colorSportBasketball,
    Color? colorSportCricket,
    Color? colorSportBadminton,
    Color? colorSportFootball,
  }) {
    return AppColorScheme(
      colorBackgroundPrimary: colorBackgroundPrimary ?? this.colorBackgroundPrimary,
      colorSurfacePrimary:    colorSurfacePrimary    ?? this.colorSurfacePrimary,
      colorSurfaceElevated:   colorSurfaceElevated   ?? this.colorSurfaceElevated,
      colorSurfaceOverlay:    colorSurfaceOverlay    ?? this.colorSurfaceOverlay,
      colorAccentPrimary:     colorAccentPrimary     ?? this.colorAccentPrimary,
      colorAccentPressed:     colorAccentPressed     ?? this.colorAccentPressed,
      colorAccentSubtle:      colorAccentSubtle      ?? this.colorAccentSubtle,
      colorTextPrimary:       colorTextPrimary       ?? this.colorTextPrimary,
      colorTextSecondary:     colorTextSecondary     ?? this.colorTextSecondary,
      colorTextTertiary:      colorTextTertiary      ?? this.colorTextTertiary,
      colorTextOnAccent:      colorTextOnAccent      ?? this.colorTextOnAccent,
      colorBorderSubtle:      colorBorderSubtle      ?? this.colorBorderSubtle,
      colorBorderMedium:      colorBorderMedium      ?? this.colorBorderMedium,
      colorSuccess:           colorSuccess           ?? this.colorSuccess,
      colorWarning:           colorWarning           ?? this.colorWarning,
      colorError:             colorError             ?? this.colorError,
      colorInfo:              colorInfo              ?? this.colorInfo,
      colorSportBasketball:   colorSportBasketball   ?? this.colorSportBasketball,
      colorSportCricket:      colorSportCricket      ?? this.colorSportCricket,
      colorSportBadminton:    colorSportBadminton    ?? this.colorSportBadminton,
      colorSportFootball:     colorSportFootball     ?? this.colorSportFootball,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      colorBackgroundPrimary: Color.lerp(colorBackgroundPrimary, other.colorBackgroundPrimary, t)!,
      colorSurfacePrimary:    Color.lerp(colorSurfacePrimary,    other.colorSurfacePrimary,    t)!,
      colorSurfaceElevated:   Color.lerp(colorSurfaceElevated,   other.colorSurfaceElevated,   t)!,
      colorSurfaceOverlay:    Color.lerp(colorSurfaceOverlay,    other.colorSurfaceOverlay,    t)!,
      colorAccentPrimary:     Color.lerp(colorAccentPrimary,     other.colorAccentPrimary,     t)!,
      colorAccentPressed:     Color.lerp(colorAccentPressed,     other.colorAccentPressed,     t)!,
      colorAccentSubtle:      Color.lerp(colorAccentSubtle,      other.colorAccentSubtle,      t)!,
      colorTextPrimary:       Color.lerp(colorTextPrimary,       other.colorTextPrimary,       t)!,
      colorTextSecondary:     Color.lerp(colorTextSecondary,     other.colorTextSecondary,     t)!,
      colorTextTertiary:      Color.lerp(colorTextTertiary,      other.colorTextTertiary,      t)!,
      colorTextOnAccent:      Color.lerp(colorTextOnAccent,      other.colorTextOnAccent,      t)!,
      colorBorderSubtle:      Color.lerp(colorBorderSubtle,      other.colorBorderSubtle,      t)!,
      colorBorderMedium:      Color.lerp(colorBorderMedium,      other.colorBorderMedium,      t)!,
      colorSuccess:           Color.lerp(colorSuccess,           other.colorSuccess,           t)!,
      colorWarning:           Color.lerp(colorWarning,           other.colorWarning,           t)!,
      colorError:             Color.lerp(colorError,             other.colorError,             t)!,
      colorInfo:              Color.lerp(colorInfo,              other.colorInfo,              t)!,
      colorSportBasketball:   Color.lerp(colorSportBasketball,   other.colorSportBasketball,   t)!,
      colorSportCricket:      Color.lerp(colorSportCricket,      other.colorSportCricket,      t)!,
      colorSportBadminton:    Color.lerp(colorSportBadminton,    other.colorSportBadminton,    t)!,
      colorSportFootball:     Color.lerp(colorSportFootball,     other.colorSportFootball,     t)!,
    );
  }
}

// ── Convenient accessor ────────────────────────────────────────────
extension AppColorsX on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>()!;
}
