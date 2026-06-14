// lib/core/haptics.dart
//
// Semantic haptic feedback. Use these names at call sites instead of raw
// HapticFeedback.* so the *meaning* (not the intensity) is what's expressed —
// intensities can be retuned in one place.

import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  /// A light tap — buttons, chips, generic tappable surfaces.
  static void tap() => HapticFeedback.lightImpact();

  /// Selecting an item from a set — sport pills, date cells, court picker.
  static void select() => HapticFeedback.selectionClick();

  /// A committed action with weight — confirm booking, score a point.
  static void impact() => HapticFeedback.mediumImpact();

  /// A meaningful success — booking confirmed, game saved, stat shared.
  static void success() => HapticFeedback.mediumImpact();

  /// A strong, deliberate event — game over, milestone reached.
  static void heavy() => HapticFeedback.heavyImpact();
}
