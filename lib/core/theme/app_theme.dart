// lib/core/theme/app_theme.dart
//
// ThemeData factories for Courtside.
// Registers VoidFireTheme as the ThemeExtension for token access.
// All surface/color decisions for Material widgets source from AppColorScheme.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'void_fire_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark  => _build(VoidFireTheme.scheme);
  /// Light mode not yet designed — Void Fire dark is canonical.
  static ThemeData get light => _build(VoidFireTheme.scheme);

  static ThemeData _build(AppColorScheme scheme) {
    final bg      = scheme.colorBackgroundPrimary;
    final surface = scheme.colorSurfacePrimary;
    final accent  = scheme.colorAccentPrimary;
    final text    = scheme.colorTextPrimary;
    final textSec = scheme.colorTextSecondary;
    final border  = scheme.colorBorderSubtle;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      extensions: <ThemeExtension<dynamic>>[scheme],

      colorScheme: ColorScheme.dark(
        surface:                 bg,
        primary:                 accent,
        onPrimary:               scheme.colorTextOnAccent,
        secondary:               surface,
        onSecondary:             text,
        error:                   scheme.colorError,
        onSurface:               text,
        surfaceContainerHighest: scheme.colorSurfaceElevated,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: scheme.colorTextOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill)),
          textStyle: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.colorSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.colorBorderMedium, width: 1.0),
        ),
        hintStyle: GoogleFonts.inter(
            color: scheme.colorTextTertiary, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),

      dividerTheme: DividerThemeData(
          color: border, thickness: 0.5, space: 0),

      textTheme: _buildTextTheme(text, textSec),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:   GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w800, color: primary, letterSpacing: -2.0),
      displayMedium:  GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w800, color: primary, letterSpacing: -1.2),
      displaySmall:   GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.6),
      headlineLarge:  GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.2),
      headlineSmall:  GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.1),
      bodyLarge:      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary),
      bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 0.8),
      labelMedium:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 1.2),
    );
  }
}
