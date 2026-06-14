// lib/core/sport_visuals.dart
//
// Canonical sport iconography. Replaces emoji-as-icons (🏀🏏🏸⚽) app-wide with
// consistent Material rounded glyphs, so every surface draws a sport the same
// way. Sport *colours* live in the brand-locked colorSport* tokens — use
// context.colors.colorSport* for those; this file is icons only.

import 'package:flutter/material.dart';
import 'tokens/color_tokens.dart';

/// Brand-locked accent colour for a sport id (case-insensitive), read from the
/// active scheme's colorSport* tokens. Centralises the per-screen _sportColor
/// helpers that had drifted into duplicates.
Color sportColor(AppColorScheme colors, String sport) {
  switch (sport.toLowerCase()) {
    case 'basketball':
      return colors.colorSportBasketball;
    case 'cricket':
      return colors.colorSportCricket;
    case 'badminton':
      return colors.colorSportBadminton;
    case 'football':
    case 'soccer':
      return colors.colorSportFootball;
    default:
      return colors.colorSportFootball;
  }
}

/// Material rounded icon for a sport id (case-insensitive).
IconData sportIcon(String sport) {
  switch (sport.toLowerCase()) {
    case 'basketball':
      return Icons.sports_basketball_rounded;
    case 'cricket':
      return Icons.sports_cricket_rounded;
    case 'badminton':
      return Icons.sports_tennis_rounded; // closest racquet glyph
    case 'football':
    case 'soccer':
      return Icons.sports_soccer_rounded;
    default:
      return Icons.sports_rounded;
  }
}
