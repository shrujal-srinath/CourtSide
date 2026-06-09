// lib/services/game_service.dart
//
// Writes a finished Courtside phone-scored game.
//
//   VERIFIED games  → submit_game_result RPC (SECURITY DEFINER). The DB
//                     re-checks ownership + the scoring window, so the
//                     client cannot fabricate a verified stat.
//   UNVERIFIED games → device-local store (LocalGamesStore). Never touch
//                      player_stats; never appear in the career passport.
//
// Mirrors BookingService's RPC pattern (book_slot). A PostgrestException
// with code 'P0001' means the server rejected the result — usually the
// scoring window closed or the booking wasn't the caller's.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/scoring/basketball/game_result.dart';
import 'local_games_store.dart';

sealed class GameSubmitResult {}

final class GameSubmitVerified extends GameSubmitResult {
  GameSubmitVerified({required this.gameId});
  final String gameId;
}

/// Recorded locally — either because it was free-play (unverified) or because
/// the verified submit failed and we kept the game so it isn't lost.
final class GameSubmitLocal extends GameSubmitResult {
  GameSubmitLocal({this.reason});
  final String? reason; // null = expected (free-play); set = verified fallback
}

class GameService {
  GameService({LocalGamesStore? localStore})
      : _client = Supabase.instance.client,
        _local = localStore ?? LocalGamesStore();

  final SupabaseClient _client;
  final LocalGamesStore _local;

  /// Records the game on the correct surface based on [result.isVerified].
  Future<GameSubmitResult> record(BballGameResult result) async {
    if (!result.isVerified || result.bookingId == null) {
      await _local.save(result);
      return GameSubmitLocal();
    }

    try {
      final gameId = await _client.rpc('submit_game_result', params: {
        'p_booking_id': result.bookingId,
        'p_sport': result.sport,
        'p_won': result.won,
        'p_score_for': result.scoreFor,
        'p_score_against': result.scoreAgainst,
        'p_my_line': result.myLine,
        'p_player_lines': result.playerLines,
      });
      return GameSubmitVerified(gameId: gameId as String);
    } on PostgrestException catch (e) {
      // Server rejected (window closed / not owner). Don't lose the game.
      await _local.save(result);
      return GameSubmitLocal(reason: e.message);
    } catch (e) {
      await _local.save(result);
      return GameSubmitLocal(reason: e.toString());
    }
  }
}
