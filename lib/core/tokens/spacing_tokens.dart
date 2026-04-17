// lib/core/tokens/spacing_tokens.dart
//
// Spacing, radius, duration, and shadow design tokens.
// These are theme-invariant — same in dark and light.

import 'package:flutter/material.dart';

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
// Dark mode shadows need real depth — light mode shadows are subtle.
// Use cardElevated for primary cards, accentGlow for CTA elements.
// The red glow (accentGlow) is the Strava move — used sparingly on
// hero cards and FAB to give the accent color energy + presence.

class AppShadow {
  AppShadow._();

  // Standard card lift — dark: black depth; light: gentle drop shadow
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.30),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Elevated card — primary content cards (venue cards, stat cards)
  static List<BoxShadow> get cardElevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.50),
      blurRadius: 28,
      offset: const Offset(0, 10),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: const Color(0xFFE8112D).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // Accent glow — hero CTA buttons, active chips, stat ring containers
  // Use sparingly — only on the ONE most important element per screen
  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: const Color(0xFFE8112D).withValues(alpha: 0.40),
      blurRadius: 24,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Nav bar — upward dark veil for floating pill nav
  static List<BoxShadow> get navBar => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.70),
      blurRadius: 32,
      offset: const Offset(0, -4),
    ),
  ];

  // FAB — ruby glow, strong enough to read on dark backgrounds
  static List<BoxShadow> get fab => [
    BoxShadow(
      color: const Color(0xFFE8112D).withValues(alpha: 0.50),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Light mode drop shadow for search bar / input
  static List<BoxShadow> get searchLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Light mode card shadow — for light-background screens (e.g., ModeGate)
  static List<BoxShadow> get lightCard => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> cardFor(BuildContext context) => card;
  static List<BoxShadow> navFor(BuildContext context) => navBar;
}

// ── Component sizes — use these instead of magic numbers ──────────
//
// Canonical sizes for recurring UI elements. If you find yourself
// writing a raw pixel size for an avatar, icon, chart, or button,
// check here first.

class AppComponentSizes {
  AppComponentSizes._();

  // Avatars
  static const double avatarSm = 32;  // small avatar in lists / leaderboard
  static const double avatarMd = 42;  // header / nav context
  static const double avatarLg = 72;  // profile hero / stats screen

  // Touch targets — minimum 44pt per HIG
  static const double touchMin = 44;

  // Buttons
  static const double buttonPrimary   = 54;  // full-width CTA
  static const double buttonSecondary = 48;  // secondary / ghost

  // Charts
  static const double winRateRing = 120;  // animated ring chart diameter
  static const double statGlow    = 180;  // background glow circle

  // Navigation
  static const double navPill = 56;  // floating pill nav height
  static const double fab     = 48;  // floating action button

  // Icons
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // Cards
  static const double courtCardWidth  = 160;
  static const double courtCardHeight = 178;
  static const double venueCardHeight =  90;  // list row height

  // Bottom sheet
  static const double sheetHandleW = 36;
  static const double sheetHandleH =  4;
}
