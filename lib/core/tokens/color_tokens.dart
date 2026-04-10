// lib/core/tokens/color_tokens.dart
//
// PRIMITIVE color constants (raw hex).
// Only import this inside theme definition files.
// Widget files NEVER reference ColorTokens directly — use context.colors instead.

import 'package:flutter/material.dart';

class ColorTokens {
  ColorTokens._();

  // ── Backgrounds — 4 elevation levels ─────────────────────────
  static const Color backgroundPrimary = Color(0xFF080808); // scaffold, deepest black
  static const Color surfacePrimary    = Color(0xFF101010); // cards, default surface
  static const Color surfaceElevated   = Color(0xFF1A1A1A); // elevated cards, inputs
  static const Color surfaceOverlay    = Color(0xFF242424); // modals, sheets, dialogs

  // ── Brand accent — Ruby Red, used SPARINGLY ───────────────────
  // Rule: accentPrimary appears on CTAs, active states, brand mark ONLY.
  // Never use red as a background. Never on text blocks.
  static const Color accentPrimary   = Color(0xFFB91C3A); // Ruby — primary CTA, active
  static const Color accentSecondary = Color(0xFF8E1229); // pressed / dark variant
  static const Color accentMuted     = Color(0xFF280010); // subtle tint (badges, chips)

  // ── Text — 4 levels, white dominant ──────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF); // headings, key numbers, names
  static const Color textSecondary = Color(0xFFCCCCCC); // body, supporting text
  static const Color textTertiary  = Color(0xFF888888); // captions, meta, timestamps
  static const Color textDisabled  = Color(0xFF444444); // disabled states

  // ── Borders — prefer elevation contrast over visible borders ──
  static const Color borderSubtle = Color(0xFF1F1F1F); // only when same-color surfaces adjacent
  static const Color borderMuted  = Color(0xFF2A2A2A); // focused inputs, active containers

  // ── Semantic ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ── Sport accents — only for sport-specific chips/badges ──────
  // NEVER bleed into general UI. These live on sport elements only.
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
