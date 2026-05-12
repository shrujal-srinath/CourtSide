class PlayerGameStat {
  const PlayerGameStat({
    required this.sport,
    required this.gamesPlayed,
    required this.wins,
    required this.stats,
  });

  final String sport;
  final int gamesPlayed;
  final int wins;
  final Map<String, dynamic> stats;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
}
