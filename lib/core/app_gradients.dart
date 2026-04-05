import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  /// Main brand background — near-black with navy undertone
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080A0F), Color(0xFF0D1829)],
  );

  /// Stat story card base (for Instagram share card)
  static const LinearGradient storyCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0D14), Color(0xFF1A0005)],
  );

  /// Red fade overlay — transparent to red, used on hero sections
  static const LinearGradient redFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99E8112D)],
  );

  /// Profile stats banner background
  static const LinearGradient profileBanner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1829), Color(0xFF1A0A12)],
  );

  /// Sport-specific card tint overlays
  static LinearGradient forSport(String sport) {
    final colors = _sportColors[sport.toLowerCase()];
    if (colors != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF161B24), Color(0xFF0F1117)],
    );
  }

  static const Map<String, List<Color>> _sportColors = {
    'basketball': [Color(0xFF1A0F00), Color(0xFF0F1117)],
    'cricket':    [Color(0xFF001A16), Color(0xFF0F1117)],
    'badminton':  [Color(0xFF1A1500), Color(0xFF0F1117)],
    'football':   [Color(0xFF001A08), Color(0xFF0F1117)],
  };
}
