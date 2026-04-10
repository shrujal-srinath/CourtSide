// lib/core/tokens/spacing_tokens.dart
//
// Spacing, radius, duration, and shadow design tokens.
// These are theme-invariant — same in dark and light.

import 'package:flutter/material.dart';
import 'color_tokens.dart';

// ── Spacing — 8pt grid with 4pt subdivisions ──────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs      =  4;
  static const double sm      =  8;
  static const double md      = 12;
  static const double lg      = 16;
  static const double xl      = 20;
  static const double xxl     = 24;
  static const double xxxl    = 32;
  static const double section = 40;
}

// ── Border radius ─────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double sm   =   8;
  static const double md   =  12;
  static const double lg   =  16;
  static const double xl   =  20;
  static const double xxl  =  24;
  static const double card =  16;
  static const double pill = 100;
}

// ── Animation durations ───────────────────────────────────────────

class AppDuration {
  AppDuration._();

  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 400);
  static const Duration page   = Duration(milliseconds: 320);
}

// ── Shadow system ─────────────────────────────────────────────────
//
// cardElevated: deep black lift + subtle ruby glow
// navBar:       upward dark veil for floating pill
// fab:          ruby glow matching accent

class AppShadow {
  AppShadow._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardElevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get navBar => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: ColorTokens.accentPrimary.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get searchLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> cardFor(BuildContext context) => card;
  static List<BoxShadow> navFor(BuildContext context) => navBar;
}
