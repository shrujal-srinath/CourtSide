// lib/core/tokens/typography_tokens.dart
//
// Typography design tokens.
// SpaceGrotesk → ALL display, heading, score, stat text
// Inter        → ALL body, label, caption, metadata text
//
// RULES:
// - Never call GoogleFonts directly in widget files.
// - Always use AppTextStyles.*
// - Score/stat styles MUST use tabular figures to prevent width shifts.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display — SpaceGrotesk ─────────────────────────────────────

  static TextStyle displayXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        color: color,
        height: 1.0,
      );

  static TextStyle displayL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: color,
        height: 1.05,
      );

  static TextStyle displayM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: color,
        height: 1.1,
      );

  // ── Headings — SpaceGrotesk ────────────────────────────────────

  static TextStyle headingL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
        height: 1.2,
      );

  static TextStyle headingM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color,
        height: 1.25,
      );

  static TextStyle headingS(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: color,
        height: 1.3,
      );

  // ── Body — Inter ───────────────────────────────────────────────

  static TextStyle bodyL(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.6,
      );

  static TextStyle bodyM(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyS(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.4,
      );

  // ── Labels — Inter ─────────────────────────────────────────────

  static TextStyle labelM(Color color) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color,
      );

  static TextStyle labelS(Color color) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: color,
      );

  /// Section headers — always textTertiary in widget usage.
  /// Never red. Never white.
  static TextStyle overline(Color color) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color,
      );

  // ── Scores & Stats — SpaceGrotesk, tabular figures REQUIRED ───
  // tabularFigures prevents score displays from shifting width
  // when digits change during live updates.

  static TextStyle scoreXXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        letterSpacing: -3.0,
        color: color,
        height: 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle statXL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle statL(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle statM(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── Legacy alias (for displayS calls remaining in older screens)
  static TextStyle displayS(Color color) => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color,
        height: 1.2,
      );
}
