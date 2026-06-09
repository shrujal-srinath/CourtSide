// lib/services/stats_service.dart
//
// Reads player stats from Supabase.
// RLS: public read — stats are written only by the hardware/service role.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fake_data.dart';
import '../models/completed_game.dart';

class StatsService {
  StatsService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns stats for the current user for a specific sport.
  Future<PlayerGameStat?> getMyStats(String sport) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('player_stats')
        .select()
        .eq('user_id', userId)
        .eq('sport', sport)
        .maybeSingle();

    return row == null ? null : _rowToStat(row);
  }

  /// Returns all sport stats for the current user.
  Future<List<PlayerGameStat>> getAllMyStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('player_stats')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows.map(_rowToStat).toList();
  }

  /// Returns the current user's completed games (verified), newest first.
  /// Joins the originating booking for its venue name.
  Future<List<CompletedGame>> getMyGames() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('courtside_games')
        .select(
            'id, sport, won, score_for, score_against, is_verified, played_at, bookings(venue_name)')
        .eq('user_id', userId)
        .order('played_at', ascending: false);

    return rows.map(CompletedGame.fromRow).toList();
  }

  // ── Converter ──────────────────────────────────────────────────

  PlayerGameStat _rowToStat(Map<String, dynamic> row) => PlayerGameStat(
        sport: row['sport'] as String,
        gamesPlayed: (row['games_played'] as int?) ?? 0,
        wins: (row['wins'] as int?) ?? 0,
        stats: Map<String, dynamic>.from(
          (row['stats'] as Map<String, dynamic>?) ?? {},
        ),
      );
}
