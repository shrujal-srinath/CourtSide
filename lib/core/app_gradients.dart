import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  /// Main brand background — light neutral
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F6F8), Color(0xFFF5F6F8)],
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
    colors: [Colors.transparent, Color(0x47FF3B3B)],
  );

  /// Profile stats banner background
  static const LinearGradient profileBanner = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F6F8), Color(0xFFFFFFFF)],
  );

  /// Live section gradient (from HTML: rgba(255,59,59,0.05) to white)
  static const LinearGradient liveSection = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0DFF3B3B), Color(0x05FF3B3B), Color(0x99FFFFFF)],
  );

  /// Recommended section gradient
  static const LinearGradient recommended = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x0DFF3B3B), Color(0x05FF3B3B), Color(0xFFFFFFFF)],
  );

  /// Sport-specific card tint overlays (light mode)
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
      colors: [Color(0xFFF3F4F6), Color(0xFFF5F6F8)],
    );
  }

  static const Map<String, List<Color>> _sportColors = {
    'basketball': [Color(0xFFFFF5F0), Color(0xFFF5F6F8)],
    'cricket':    [Color(0xFFF0FAF8), Color(0xFFF5F6F8)],
    'badminton':  [Color(0xFFFFFCF0), Color(0xFFF5F6F8)],
    'football':   [Color(0xFFF0F8F2), Color(0xFFF5F6F8)],
  };
}
