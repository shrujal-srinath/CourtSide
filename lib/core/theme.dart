import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary
  static const Color red = Color(0xFFCC0000);
  static const Color redLight = Color(0xFFFF1A1A);

  // Backgrounds
  static const Color black = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color border = Color(0xFF2A2A2A);

  // Text
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFA1A1AA);
  static const Color darkGrey = Color(0xFF555555);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.black,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.red,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      );
}