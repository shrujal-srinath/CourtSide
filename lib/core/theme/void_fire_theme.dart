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

  // Light scheme — clean white / light-gray surfaces
  static AppColorScheme get lightScheme => const AppColorScheme(
    colorBackgroundPrimary: ColorTokens.backgroundPrimary,
    colorSurfacePrimary:    ColorTokens.surfacePrimary,
    colorSurfaceElevated:   ColorTokens.surfaceElevated,
    colorSurfaceOverlay:    ColorTokens.surfaceOverlay,
    colorAccentPrimary:     ColorTokens.accentPrimary,
    colorAccentPressed:     ColorTokens.accentSecondary,
    colorAccentSubtle:      ColorTokens.accentSubtle,
    colorTextPrimary:       ColorTokens.textPrimary,
    colorTextSecondary:     ColorTokens.textSecondary,
    colorTextTertiary:      ColorTokens.textTertiary,
    colorTextOnAccent:      ColorTokens.textOnAccent,
    colorBorderSubtle:      ColorTokens.borderSubtle,
    colorBorderMedium:      ColorTokens.borderMedium,
    colorSuccess:           ColorTokens.success,
    colorWarning:           ColorTokens.warning,
    colorError:             ColorTokens.error,
    colorInfo:              ColorTokens.info,
    colorSportBasketball:   ColorTokens.sportBasketball,
    colorSportCricket:      ColorTokens.sportCricket,
    colorSportBadminton:    ColorTokens.sportBadminton,
    colorSportFootball:     ColorTokens.sportFootball,
  );

  // Dark scheme — Void Fire: deep black, ruby red, white typography
  static AppColorScheme get darkScheme => const AppColorScheme(
    colorBackgroundPrimary: DarkColorTokens.backgroundPrimary,
    colorSurfacePrimary:    DarkColorTokens.surfacePrimary,
    colorSurfaceElevated:   DarkColorTokens.surfaceElevated,
    colorSurfaceOverlay:    DarkColorTokens.surfaceOverlay,
    colorAccentPrimary:     DarkColorTokens.accentPrimary,
    colorAccentPressed:     DarkColorTokens.accentSecondary,
    colorAccentSubtle:      DarkColorTokens.accentSubtle,
    colorTextPrimary:       DarkColorTokens.textPrimary,
    colorTextSecondary:     DarkColorTokens.textSecondary,
    colorTextTertiary:      DarkColorTokens.textTertiary,
    colorTextOnAccent:      DarkColorTokens.textOnAccent,
    colorBorderSubtle:      DarkColorTokens.borderSubtle,
    colorBorderMedium:      DarkColorTokens.borderMedium,
    colorSuccess:           DarkColorTokens.success,
    colorWarning:           DarkColorTokens.warning,
    colorError:             DarkColorTokens.error,
    colorInfo:              DarkColorTokens.info,
    colorSportBasketball:   DarkColorTokens.sportBasketball,
    colorSportCricket:      DarkColorTokens.sportCricket,
    colorSportBadminton:    DarkColorTokens.sportBadminton,
    colorSportFootball:     DarkColorTokens.sportFootball,
  );

  // Keep legacy alias pointing to light for any existing references
  static AppColorScheme get scheme => lightScheme;
}
