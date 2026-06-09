// lib/providers/game_provider.dart
//
// Records a finished game and refreshes the stats passport on success.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/scoring/basketball/game_result.dart';
import '../services/game_service.dart';
import 'app_mode_provider.dart';
import 'demo_store_provider.dart';
import 'stats_provider.dart';

final gameServiceProvider = Provider<GameService>((_) => GameService());

/// Records [result] (verified → Supabase, unverified → device) and, when a
/// verified game lands, invalidates the stats providers so the Stats screen
/// reflects the new game immediately.
final recordGameProvider =
    Provider<Future<GameSubmitResult> Function(BballGameResult)>((ref) {
  return (BballGameResult result) async {
    // DEMO mode: fold the game into the local sandbox instead of Supabase.
    if (ref.read(appModeProvider) == AppMode.demo) {
      ref.read(demoStoreProvider.notifier).applyGameResult(
            sport: result.sport,
            won: result.won,
            scoreFor: result.scoreFor,
            scoreAgainst: result.scoreAgainst,
            line: result.myLine,
            bookingId: result.bookingId,
            venueName: result.venueName,
          );
      return GameSubmitVerified(gameId: 'demo');
    }

    final outcome = await ref.read(gameServiceProvider).record(result);
    if (outcome is GameSubmitVerified) {
      ref.invalidate(myStatsProvider);
      ref.invalidate(myStatsBySportProvider);
      ref.invalidate(myGamesProvider);
    }
    return outcome;
  };
});
