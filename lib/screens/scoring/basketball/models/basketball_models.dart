// lib/screens/scoring/basketball/models/basketball_models.dart

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════════════════════

enum BballEvent {
  onePoint,
  twoPoint,
  threePoint,
  freeThrow,
  rebound,
  assist,
  steal,
  block,
  turnover,
  foul,
}

extension BballEventLabel on BballEvent {
  String get label {
    switch (this) {
      case BballEvent.onePoint:
        return '+1';
      case BballEvent.twoPoint:
        return '+2';
      case BballEvent.threePoint:
        return '+3';
      case BballEvent.freeThrow:
        return 'FT';
      case BballEvent.rebound:
        return 'REB';
      case BballEvent.assist:
        return 'AST';
      case BballEvent.steal:
        return 'STL';
      case BballEvent.block:
        return 'BLK';
      case BballEvent.turnover:
        return 'TO';
      case BballEvent.foul:
        return 'FOUL';
    }
  }

  int get points {
    switch (this) {
      case BballEvent.onePoint:
        return 1;
      case BballEvent.twoPoint:
        return 2;
      case BballEvent.threePoint:
        return 3;
      case BballEvent.freeThrow:
        return 1;
      default:
        return 0;
    }
  }

  bool get isScoring =>
      this == BballEvent.onePoint ||
      this == BballEvent.twoPoint ||
      this == BballEvent.threePoint ||
      this == BballEvent.freeThrow;
}

enum BballFormat { threeVsThree, fiveVsFive }

enum BballMode { quick, detailed }

/// fullGame = single period (FIBA 3x3 standard)
/// quarters = 4 periods (5v5)
/// halves   = 2 periods
enum BballClockFormat { fullGame, quarters, halves }

// ═══════════════════════════════════════════════════════════════
//  PLAYER
// ═══════════════════════════════════════════════════════════════

class BballPlayer {
  BballPlayer({
    required this.id,
    required this.name,
    required this.number,
    this.isOnCourt = false,
    this.points = 0,
    this.rebounds = 0,
    this.assists = 0,
    this.steals = 0,
    this.blocks = 0,
    this.turnovers = 0,
    this.fouls = 0,
  });

  final String id;
  final String name;
  final int number;
  bool isOnCourt;

  // Per-player stats
  int points;
  int rebounds;
  int assists;
  int steals;
  int blocks;
  int turnovers;
  int fouls;

  BballPlayer copyWith({
    String? id,
    String? name,
    int? number,
    bool? isOnCourt,
    int? points,
    int? rebounds,
    int? assists,
    int? steals,
    int? blocks,
    int? turnovers,
    int? fouls,
  }) =>
      BballPlayer(
        id: id ?? this.id,
        name: name ?? this.name,
        number: number ?? this.number,
        isOnCourt: isOnCourt ?? this.isOnCourt,
        points: points ?? this.points,
        rebounds: rebounds ?? this.rebounds,
        assists: assists ?? this.assists,
        steals: steals ?? this.steals,
        blocks: blocks ?? this.blocks,
        turnovers: turnovers ?? this.turnovers,
        fouls: fouls ?? this.fouls,
      );

  static String generateId(String teamId, int index) =>
      '${DateTime.now().microsecondsSinceEpoch}_${teamId}_$index';
}

// ═══════════════════════════════════════════════════════════════
//  TEAM CONFIG
// ═══════════════════════════════════════════════════════════════

class BballTeamConfig {
  const BballTeamConfig({
    required this.name,
    required this.color,
    this.players = const [],
  });

  final String name;
  final Color color;
  final List<BballPlayer> players;

  BballTeamConfig copyWith({
    String? name,
    Color? color,
    List<BballPlayer>? players,
  }) =>
      BballTeamConfig(
        name: name ?? this.name,
        color: color ?? this.color,
        players: players ?? this.players,
      );
}

// ═══════════════════════════════════════════════════════════════
//  GAME CONFIG
// ═══════════════════════════════════════════════════════════════

class BballGameConfig {
  const BballGameConfig({
    required this.mode,
    required this.format,
    required this.clockFormat,
    required this.periodMinutes,
    required this.hasShotClock,
    required this.teamA,
    required this.teamB,
    this.extraStats = false,
    this.timeoutsPerTeam = 2,
    this.shotClockDuration = 24,
    this.autoResetShotClock = true,
  });

  final BballMode mode;
  final BballFormat format;
  final BballClockFormat clockFormat;
  final int periodMinutes;
  final bool hasShotClock;
  final BballTeamConfig teamA;
  final BballTeamConfig teamB;
  final bool extraStats;
  final int timeoutsPerTeam;
  final int shotClockDuration;

  /// Auto-reset the shot clock when a scoring event is recorded.
  /// Default true; can be toggled from in-game settings.
  final bool autoResetShotClock;

  int get totalPeriods {
    switch (clockFormat) {
      case BballClockFormat.fullGame:
        return 1;
      case BballClockFormat.quarters:
        return 4;
      case BballClockFormat.halves:
        return 2;
    }
  }

  int get clockSeconds => periodMinutes * 60;

  int get startingCount =>
      format == BballFormat.threeVsThree ? 3 : 5;

  int get maxRosterSize =>
      format == BballFormat.threeVsThree ? 4 : 12;

  /// Team fouls before the bonus (free throws): 7 for 3v3, 5 per quarter for 5v5.
  int get teamFoulBonus =>
      format == BballFormat.threeVsThree ? 7 : 5;

  BballGameConfig copyWith({
    BballMode? mode,
    BballFormat? format,
    BballClockFormat? clockFormat,
    int? periodMinutes,
    bool? hasShotClock,
    BballTeamConfig? teamA,
    BballTeamConfig? teamB,
    bool? extraStats,
    int? timeoutsPerTeam,
    int? shotClockDuration,
    bool? autoResetShotClock,
  }) =>
      BballGameConfig(
        mode: mode ?? this.mode,
        format: format ?? this.format,
        clockFormat: clockFormat ?? this.clockFormat,
        periodMinutes: periodMinutes ?? this.periodMinutes,
        hasShotClock: hasShotClock ?? this.hasShotClock,
        teamA: teamA ?? this.teamA,
        teamB: teamB ?? this.teamB,
        extraStats: extraStats ?? this.extraStats,
        timeoutsPerTeam: timeoutsPerTeam ?? this.timeoutsPerTeam,
        shotClockDuration: shotClockDuration ?? this.shotClockDuration,
        autoResetShotClock: autoResetShotClock ?? this.autoResetShotClock,
      );
}

// ═══════════════════════════════════════════════════════════════
//  EVENT ENTRY
// ═══════════════════════════════════════════════════════════════

class BballEventEntry {
  const BballEventEntry({
    required this.event,
    required this.teamId,
    required this.timestamp,
    required this.clockSnapshot,
    this.playerId,
    this.playerName,
    this.playerNumber,
  });

  final BballEvent event;
  final String teamId; // 'A' or 'B'
  final DateTime timestamp;
  final int clockSnapshot;
  final String? playerId;
  final String? playerName;
  final int? playerNumber;

  String get displayLabel {
    if (playerNumber != null) {
      return '#$playerNumber ${event.label}';
    }
    return event.label;
  }
}

// ═══════════════════════════════════════════════════════════════
//  GAME STATE
// ═══════════════════════════════════════════════════════════════

class BasketballGameState {
  const BasketballGameState({
    required this.config,
    required this.scoreA,
    required this.scoreB,
    required this.period,
    required this.clockSeconds,
    required this.isClockRunning,
    required this.events,
    required this.foulsA,
    required this.foulsB,
    required this.isGameOver,
    required this.onCourtA,
    required this.onCourtB,
    required this.shotClockSeconds,
    required this.isShotClockRunning,
    required this.timeoutsUsedA,
    required this.timeoutsUsedB,
    this.twentyOneTeam,
  });

  final BballGameConfig config;
  final int scoreA;
  final int scoreB;
  final int period;
  final int clockSeconds;
  final bool isClockRunning;
  final List<BballEventEntry> events;
  final int foulsA;
  final int foulsB;
  final bool isGameOver;
  final List<BballPlayer> onCourtA;
  final List<BballPlayer> onCourtB;
  final int shotClockSeconds;
  final bool isShotClockRunning;
  final int timeoutsUsedA;
  final int timeoutsUsedB;

  /// Non-null when a team just crossed 21 in 3v3 — holds the team name.
  /// UI should show alert and call clearTwentyOneAlert() to reset.
  final String? twentyOneTeam;

  // Convenience getters
  String get teamAName => config.teamA.name;
  String get teamBName => config.teamB.name;

  int get timeoutsLeftA => (config.timeoutsPerTeam - timeoutsUsedA).clamp(0, 99);
  int get timeoutsLeftB => (config.timeoutsPerTeam - timeoutsUsedB).clamp(0, 99);

  static BasketballGameState fromConfig(BballGameConfig config) =>
      BasketballGameState(
        config: config,
        scoreA: 0,
        scoreB: 0,
        period: 1,
        clockSeconds: config.clockSeconds,
        isClockRunning: false,
        events: const [],
        foulsA: 0,
        foulsB: 0,
        isGameOver: false,
        onCourtA: config.teamA.players
            .where((p) => p.isOnCourt)
            .toList(),
        onCourtB: config.teamB.players
            .where((p) => p.isOnCourt)
            .toList(),
        shotClockSeconds: config.shotClockDuration,
        isShotClockRunning: false,
        timeoutsUsedA: 0,
        timeoutsUsedB: 0,
        twentyOneTeam: null,
      );

  BasketballGameState copyWith({
    BballGameConfig? config,
    int? scoreA,
    int? scoreB,
    int? period,
    int? clockSeconds,
    bool? isClockRunning,
    List<BballEventEntry>? events,
    int? foulsA,
    int? foulsB,
    bool? isGameOver,
    List<BballPlayer>? onCourtA,
    List<BballPlayer>? onCourtB,
    int? shotClockSeconds,
    bool? isShotClockRunning,
    int? timeoutsUsedA,
    int? timeoutsUsedB,
    Object? twentyOneTeam = _sentinel,
  }) =>
      BasketballGameState(
        config: config ?? this.config,
        scoreA: scoreA ?? this.scoreA,
        scoreB: scoreB ?? this.scoreB,
        period: period ?? this.period,
        clockSeconds: clockSeconds ?? this.clockSeconds,
        isClockRunning: isClockRunning ?? this.isClockRunning,
        events: events ?? this.events,
        foulsA: foulsA ?? this.foulsA,
        foulsB: foulsB ?? this.foulsB,
        isGameOver: isGameOver ?? this.isGameOver,
        onCourtA: onCourtA ?? this.onCourtA,
        onCourtB: onCourtB ?? this.onCourtB,
        shotClockSeconds: shotClockSeconds ?? this.shotClockSeconds,
        isShotClockRunning: isShotClockRunning ?? this.isShotClockRunning,
        timeoutsUsedA: timeoutsUsedA ?? this.timeoutsUsedA,
        timeoutsUsedB: timeoutsUsedB ?? this.timeoutsUsedB,
        twentyOneTeam: twentyOneTeam == _sentinel
            ? this.twentyOneTeam
            : twentyOneTeam as String?,
      );

  String get clockDisplay {
    final m = clockSeconds ~/ 60;
    final s = clockSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get periodLabel {
    switch (config.clockFormat) {
      case BballClockFormat.fullGame:
        return period == 1 ? 'GAME' : 'OT';
      case BballClockFormat.halves:
        switch (period) {
          case 1:
            return 'H1';
          case 2:
            return 'H2';
          default:
            return 'OT';
        }
      case BballClockFormat.quarters:
        switch (period) {
          case 1:
            return 'Q1';
          case 2:
            return 'Q2';
          case 3:
            return 'Q3';
          case 4:
            return 'Q4';
          default:
            return 'OT';
        }
    }
  }

  String get periodFullLabel {
    switch (config.clockFormat) {
      case BballClockFormat.fullGame:
        return period == 1 ? 'FULL GAME' : 'OVERTIME';
      case BballClockFormat.halves:
        switch (period) {
          case 1:
            return 'HALF 1';
          case 2:
            return 'HALF 2';
          default:
            return 'OVERTIME';
        }
      case BballClockFormat.quarters:
        switch (period) {
          case 1:
            return 'QUARTER 1';
          case 2:
            return 'QUARTER 2';
          case 3:
            return 'QUARTER 3';
          case 4:
            return 'QUARTER 4';
          default:
            return 'OVERTIME';
        }
    }
  }

  bool get isLastPeriod => period >= config.totalPeriods;
}

// Sentinel object used to distinguish "not passed" from explicit null in copyWith
const Object _sentinel = Object();
