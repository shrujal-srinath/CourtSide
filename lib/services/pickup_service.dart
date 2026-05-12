// lib/services/pickup_service.dart
//
// Reads pickup_games from Supabase.
// Used by: home "Live Now" section, play_home_screen, host_game_screen.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pickup_game.dart';

class PickupService {
  PickupService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns active pickup games, optionally filtered by sport.
  /// Ordered by start_time ascending so soonest games appear first.
  Future<List<PickupGame>> listActivePickups({String? sport}) async {
    var query = _client
        .from('pickup_games')
        .select('id, venue_id, sport, title, start_time, spots_total, spots_filled, '
                'venues(name)')
        .eq('is_active', true)
        .gte('start_time', DateTime.now().toIso8601String());

    if (sport != null) {
      query = query.eq('sport', sport);
    }

    final rows = await query.order('start_time').limit(20);
    return rows.map(_rowToPickupGame).toList();
  }

  /// Increments spots_filled for a pickup game (join request).
  Future<void> joinPickup(String pickupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.rpc('join_pickup_game', params: {
      'p_pickup_id': pickupId,
      'p_user_id':   userId,
    });
  }

  // ── Converter ─────────────────────────────────────────────────

  PickupGame _rowToPickupGame(Map<String, dynamic> row) {
    final venueData = row['venues'] as Map<String, dynamic>?;
    final venueName = (venueData?['name'] as String?) ?? '';

    final startTimeStr = row['start_time'] as String? ?? '';
    String timeLabel = '';
    if (startTimeStr.isNotEmpty) {
      final dt = DateTime.tryParse(startTimeStr);
      if (dt != null) {
        final local = dt.toLocal();
        final h = local.hour > 12
            ? local.hour - 12
            : (local.hour == 0 ? 12 : local.hour);
        final m = local.minute.toString().padLeft(2, '0');
        final period = local.hour >= 12 ? 'PM' : 'AM';
        timeLabel = '$h:$m $period';
      }
    }

    return PickupGame(
      id:          row['id'] as String,
      venueId:     row['venue_id'] as String,
      venueName:   venueName,
      sport:       row['sport'] as String,
      title:       row['title'] as String,
      time:        timeLabel,
      spotsTotal:  (row['spots_total'] as int?) ?? 10,
      spotsFilled: (row['spots_filled'] as int?) ?? 0,
    );
  }
}
