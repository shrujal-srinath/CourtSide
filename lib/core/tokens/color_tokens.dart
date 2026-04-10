// lib/core/tokens/color_tokens.dart
//
// PRIMITIVE color constants (raw hex).
// Only import this inside theme definition files.
// Widget files NEVER reference ColorTokens directly — use context.colors instead.

import 'package:flutter/material.dart';

class ColorTokens {
  ColorTokens._();

  // ── Backgrounds & Surfaces ─────────────────────────────────────
  static const Color backgroundPrimary = Color(0xFFF6F7F9); // Light gray background
  static const Color surfacePrimary    = Color(0xFFFFFFFF); // White cards
  static const Color surfaceElevated   = Color(0xFFFFFFFF); // elevated cards
  static const Color surfaceOverlay    = Color(0xFFFFFFFF); // modals, sheets

  // ── Brand accent — CourtSide Red ───────────────────────────────
  static const Color accentPrimary   = Color(0xFFFF2D2D); // Vibrant red CTA
  static const Color accentSecondary = Color(0xFFE52E2E); // Pressed variant
  static const Color accentSubtle    = Color(0x14FF2D2D); // 8% alpha red

  // ── Text — Light mode hierarchy ───────────────────────────────
  static const Color textPrimary   = Color(0xFF111827); // Charcoal dark
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textTertiary  = Color(0xFF9CA3AF); // Light gray / Disabled
  static const Color textOnAccent  = Color(0xFFFFFFFF); // White text on red

  // ── Borders & Dividers ────────────────────────────────────────
  static const Color borderSubtle = Color(0xFFE5E7EB); // Dividers, light borders
  static const Color borderMedium  = Color(0xFFD1D5DB); // Focused states

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Sport accents ─────────────────────────────────────────────
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
