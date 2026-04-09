import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;
  static const double section = 40;
}

class AppRadius {
  AppRadius._();

  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double card = 16;
  static const double pill = 100;
}

class AppDuration {
  AppDuration._();

  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 400);
  static const Duration page   = Duration(milliseconds: 320);
}

class AppShadow {
  AppShadow._();

  // ── Dark-mode shadows ─────────────────────────────────────────

  static List<BoxShadow> get cardElevated => [
    const BoxShadow(
      color: Color(0xFF000000),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    const BoxShadow(
      color: Color(0x1AE8112D),
      blurRadius: 12,
      offset: Offset(0, 4),
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
    const BoxShadow(
      color: Color(0x99E8112D),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  // ── Light-mode shadows (warm Oat Latte tones) ─────────────────

  /// Warm brown-tinted shadow for cards on cream backgrounds.
  static List<BoxShadow> get cardElevatedLight => [
    const BoxShadow(
      color: Color(0x14A0826D), // warm brown, very subtle
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    const BoxShadow(
      color: Color(0x0AE8112D), // red micro-glow
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Warm taupe shadow for the floating nav bar in light mode.
  static List<BoxShadow> get navBarLight => [
    const BoxShadow(
      color: Color(0x29A0826D), // warm taupe
      blurRadius: 24,
      offset: Offset(0, -2),
    ),
  ];

  // ── Context-aware helpers ─────────────────────────────────────

  static List<BoxShadow> cardFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? cardElevated
          : cardElevatedLight;

  static List<BoxShadow> navFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? navBar
          : navBarLight;
}
