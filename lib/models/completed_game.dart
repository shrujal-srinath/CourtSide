// lib/models/completed_game.dart
//
// A single finished game read back from `courtside_games`. This is the
// per-game record the Stats screen's timeline + recent-games list render.
// Career aggregates live in PlayerGameStat (player_stats); this is one game.

class CompletedGame {
  const CompletedGame({
    required this.id,
    required this.sport,
    required this.won,
    required this.scoreFor,
    required this.scoreAgainst,
    required this.isVerified,
    required this.playedAt,
    this.venueName,
  });

  final String id;
  final String sport;
  final bool won;
  final int scoreFor;
  final int scoreAgainst;
  final bool isVerified;
  final DateTime playedAt;

  /// Venue of the booking this game came from; null for free-play games.
  final String? venueName;

  String get scoreline => '$scoreFor–$scoreAgainst';

  factory CompletedGame.fromRow(Map<String, dynamic> row) {
    // venue_name arrives nested under the joined `bookings` relation.
    final booking = row['bookings'] as Map<String, dynamic>?;
    return CompletedGame(
      id: row['id'] as String,
      sport: row['sport'] as String,
      won: (row['won'] as bool?) ?? false,
      scoreFor: (row['score_for'] as int?) ?? 0,
      scoreAgainst: (row['score_against'] as int?) ?? 0,
      isVerified: (row['is_verified'] as bool?) ?? false,
      playedAt: DateTime.parse(row['played_at'] as String).toLocal(),
      venueName: booking?['venue_name'] as String?,
    );
  }
}
