// lib/services/local_games_store.dart
//
// Device-local store for UNVERIFIED games (free-play, or verified submits
// that failed and shouldn't be lost). These never reach player_stats and
// never count toward the verified career passport — by product principle #1
// only time-gated, booking-backed games are verified.
//
// Stored as JSON strings in a Hive box (no codegen adapters needed).
// Hive is initialised once in main() via LocalGamesStore.init().

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/scoring/basketball/game_result.dart';

class LocalGamesStore {
  static const _boxName = 'unverified_games';

  /// Call once during app startup, after Hive.initFlutter().
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> save(BballGameResult result) async {
    final entry = jsonEncode({
      'sport': result.sport,
      'won': result.won,
      'score_for': result.scoreFor,
      'score_against': result.scoreAgainst,
      'my_line': result.myLine,
      'player_lines': result.playerLines,
      'venue_name': result.venueName,
      'played_at': DateTime.now().toIso8601String(),
    });
    await _box.add(entry);
  }

  /// All locally-stored unverified games, most recent first.
  List<Map<String, dynamic>> all() {
    return _box.values
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  int get count => _box.length;
}
