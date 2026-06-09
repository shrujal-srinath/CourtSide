// lib/screens/scoring/basketball/game_result.dart
//
// Pure mapping from a finished BasketballGameState to:
//   1. a submission payload for submit_game_result (verified path), and
//   2. a PlayerGameStat for the post-game stat card.
//
// No Supabase / no I/O here — GameService owns the network call.
//
// Convention: Team A is the scorer's (booker's) team. `won` is from Team A's
// perspective. `my_line` defaults to Team A's combined totals, or to a single
// chosen player when the user picks "which player am I" at submit time.

import '../../../models/player_stat.dart';
import 'models/basketball_models.dart';

/// Canonical stat keys — these become the career-total keys folded into
/// player_stats.stats by cs_accumulate_stats(), so they must stay stable.
class BballStatKeys {
  static const points = 'points';
  static const rebounds = 'rebounds';
  static const assists = 'assists';
  static const steals = 'steals';
  static const blocks = 'blocks';
  static const turnovers = 'turnovers';
  static const fouls = 'fouls';
}

class BballGameResult {
  BballGameResult({
    required this.sport,
    required this.won,
    required this.scoreFor,
    required this.scoreAgainst,
    required this.myLine,
    required this.playerLines,
    required this.bookingId,
    required this.venueName,
    required this.isVerified,
  });

  final String sport;
  final bool won;
  final int scoreFor;
  final int scoreAgainst;

  /// The submitter's own stat line (canonical keys → int).
  final Map<String, int> myLine;

  /// Full box score: one map per player, including team + name for display.
  final List<Map<String, dynamic>> playerLines;

  final String? bookingId;
  final String? venueName;
  final bool isVerified;

  /// Build from final game state. [myPlayerId] selects the user's player; if
  /// null (or not found, e.g. quick mode), Team A's combined totals are used.
  factory BballGameResult.fromState(
    BasketballGameState state, {
    String? myPlayerId,
  }) {
    final config = state.config;
    final won = state.scoreA > state.scoreB;

    List<Map<String, dynamic>> linesFor(BballTeamConfig team, String side) =>
        team.players
            .map((p) => <String, dynamic>{
                  'team': side,
                  'name': p.name,
                  'number': p.number,
                  BballStatKeys.points: p.points,
                  BballStatKeys.rebounds: p.rebounds,
                  BballStatKeys.assists: p.assists,
                  BballStatKeys.steals: p.steals,
                  BballStatKeys.blocks: p.blocks,
                  BballStatKeys.turnovers: p.turnovers,
                  BballStatKeys.fouls: p.fouls,
                })
            .toList();

    final playerLines = [
      ...linesFor(config.teamA, 'A'),
      ...linesFor(config.teamB, 'B'),
    ];

    Map<String, int> lineOf(BballPlayer p) => {
          BballStatKeys.points: p.points,
          BballStatKeys.rebounds: p.rebounds,
          BballStatKeys.assists: p.assists,
          BballStatKeys.steals: p.steals,
          BballStatKeys.blocks: p.blocks,
          BballStatKeys.turnovers: p.turnovers,
          BballStatKeys.fouls: p.fouls,
        };

    Map<String, int> teamTotals(BballTeamConfig team) {
      final totals = <String, int>{
        BballStatKeys.points: 0,
        BballStatKeys.rebounds: 0,
        BballStatKeys.assists: 0,
        BballStatKeys.steals: 0,
        BballStatKeys.blocks: 0,
        BballStatKeys.turnovers: 0,
        BballStatKeys.fouls: 0,
      };
      for (final p in team.players) {
        lineOf(p).forEach((k, v) => totals[k] = totals[k]! + v);
      }
      return totals;
    }

    // Resolve the user's line: chosen player, else Team A combined totals.
    BballPlayer? mine;
    if (myPlayerId != null) {
      for (final p in config.teamA.players) {
        if (p.id == myPlayerId) mine = p;
      }
      for (final p in config.teamB.players) {
        if (p.id == myPlayerId) mine = p;
      }
    }
    final myLine = mine != null ? lineOf(mine) : teamTotals(config.teamA);

    return BballGameResult(
      sport: 'basketball',
      won: won,
      scoreFor: state.scoreA,
      scoreAgainst: state.scoreB,
      myLine: myLine,
      playerLines: playerLines,
      bookingId: config.bookingId,
      venueName: config.venueName,
      isVerified: config.isVerified,
    );
  }

  /// Single-game stat card payload. Career totals are derived server-side;
  /// this represents just this game's line.
  PlayerGameStat toStatCard() => PlayerGameStat(
        sport: sport,
        gamesPlayed: 1,
        wins: won ? 1 : 0,
        stats: Map<String, dynamic>.from(myLine),
      );
}
