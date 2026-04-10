// lib/core/theme/void_fire_theme.dart
//
// Void Fire — the default Courtside theme.
// Deep black backgrounds. Ruby red accent used sparingly.
// White-dominant typography. Premium dark sports aesthetic.
//
// Only this file (and future theme files) may reference ColorTokens primitives.
// All widget files must use AppColorScheme via context.colors.

import '../tokens/color_tokens.dart';

class VoidFireTheme {
  VoidFireTheme._();

  static AppColorScheme get scheme => const AppColorScheme(
    // Backgrounds
    colorBackgroundPrimary: ColorTokens.backgroundPrimary,
    colorSurfacePrimary:    ColorTokens.surfacePrimary,
    colorSurfaceElevated:   ColorTokens.surfaceElevated,
    colorSurfaceOverlay:    ColorTokens.surfaceOverlay,

    // Accent — Ruby Red
    colorAccentPrimary: ColorTokens.accentPrimary,
    colorAccentPressed: ColorTokens.accentSecondary,
    colorAccentSubtle:  ColorTokens.accentSubtle,

    // Text
    colorTextPrimary:   ColorTokens.textPrimary,
    colorTextSecondary: ColorTokens.textSecondary,
    colorTextTertiary:  ColorTokens.textTertiary,
    colorTextOnAccent:  ColorTokens.textPrimary, // white on red

    // Borders
    colorBorderSubtle: ColorTokens.borderSubtle,
    colorBorderMedium: ColorTokens.borderMedium,

    // Semantic
    colorSuccess: ColorTokens.success,
    colorWarning: ColorTokens.warning,
    colorError:   ColorTokens.error,
    colorInfo:    ColorTokens.info,

    // Sport
    colorSportBasketball: ColorTokens.sportBasketball,
    colorSportCricket:    ColorTokens.sportCricket,
    colorSportBadminton:  ColorTokens.sportBadminton,
    colorSportFootball:   ColorTokens.sportFootball,
  );
}
