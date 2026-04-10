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
    const BoxShadow(
      color: Color(0xB3000000), // 70% black
      blurRadius: 16,
      offset: Offset(0, 6),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: ColorTokens.accentPrimary.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get cardElevated => [
    const BoxShadow(
      color: Color(0xCC000000), // 80% black
      blurRadius: 24,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: ColorTokens.accentPrimary.withValues(alpha: 0.12),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get navBar => [
    const BoxShadow(
      color: Color(0xCC000000),
      blurRadius: 32,
      offset: Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: ColorTokens.accentPrimary.withValues(alpha: 0.5),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  /// Backward-compat aliases (context param ignored — always dark).
  /// Migrate call sites to AppShadow.card / AppShadow.navBar.
  // ignore: avoid_unused_parameters
  static List<BoxShadow> cardFor(BuildContext context) => card;
  // ignore: avoid_unused_parameters
  static List<BoxShadow> navFor(BuildContext context) => navBar;
}
