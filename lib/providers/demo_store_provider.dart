// lib/providers/demo_store_provider.dart
//
// The mutable, Hive-persisted state backing DEMO mode. This is what makes the
// investor sandbox feel alive: booking a court appends here, scoring a game
// updates the stats + game log here, and it all survives app restarts.
//
// LIVE mode never reads this — its data comes from Supabase. The mode-aware
// providers (slots, bookings, stats, games) pick the source.
//
// Seeded once from FakeData, then owned by the user's actions. Career stats
// are stored as cumulative TOTALS (points/rebounds/…), matching what the Stats
// screen expects (it derives per-game averages on read).

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/completed_game.dart';
import '../models/fake_data.dart';

// ── Persisted state ────────────────────────────────────────────────

class DemoState {
  const DemoState({
    required this.bookings,
    required this.stats,
    required this.games,
  });

  final List<BookingRecord> bookings;
  final List<PlayerGameStat> stats;
  final List<CompletedGame> games;

  DemoState copyWith({
    List<BookingRecord>? bookings,
    List<PlayerGameStat>? stats,
    List<CompletedGame>? games,
  }) =>
      DemoState(
        bookings: bookings ?? this.bookings,
        stats: stats ?? this.stats,
        games: games ?? this.games,
      );
}

// ── Store ──────────────────────────────────────────────────────────

class DemoStore extends Notifier<DemoState> {
  static const _boxName = 'demo_store';
  static late Box _box;

  /// Open the Hive box. Call once in main() after Hive.initFlutter().
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  @override
  DemoState build() => _load();

  // ── Mutations ────────────────────────────────────────────────

  /// Adds a freshly confirmed demo booking (newest first).
  void addBooking(BookingRecord booking) {
    state = state.copyWith(bookings: [booking, ...state.bookings]);
    _persist();
  }

  /// Folds a finished demo game into stats + game log, and marks the
  /// originating booking completed (if any).
  void applyGameResult({
    required String sport,
    required bool won,
    required int scoreFor,
    required int scoreAgainst,
    required Map<String, int> line,
    String? bookingId,
    String? venueName,
  }) {
    // 1. Update / create the career aggregate (cumulative totals).
    final stats = [...state.stats];
    final idx = stats.indexWhere((s) => s.sport == sport);
    if (idx == -1) {
      stats.add(PlayerGameStat(
        sport: sport,
        gamesPlayed: 1,
        wins: won ? 1 : 0,
        stats: {for (final e in line.entries) e.key: e.value},
      ));
    } else {
      final cur = stats[idx];
      final merged = Map<String, dynamic>.from(cur.stats);
      line.forEach((k, v) =>
          merged[k] = ((merged[k] as num?)?.toInt() ?? 0) + v);
      stats[idx] = PlayerGameStat(
        sport: sport,
        gamesPlayed: cur.gamesPlayed + 1,
        wins: cur.wins + (won ? 1 : 0),
        stats: merged,
      );
    }

    // 2. Prepend to the game log.
    final game = CompletedGame(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      sport: sport,
      won: won,
      scoreFor: scoreFor,
      scoreAgainst: scoreAgainst,
      isVerified: bookingId != null,
      playedAt: DateTime.now(),
      venueName: venueName,
    );

    // 3. Mark the booking completed.
    final bookings = bookingId == null
        ? state.bookings
        : state.bookings
            .map((b) => b.id == bookingId
                ? BookingRecord(
                    id: b.id,
                    venueName: b.venueName,
                    courtName: b.courtName,
                    sport: b.sport,
                    date: b.date,
                    timeSlot: b.timeSlot,
                    amount: b.amount,
                    status: BookingStatus.completed,
                    hasStats: true,
                    addons: b.addons,
                  )
                : b)
            .toList();

    state = state.copyWith(
      stats: stats,
      games: [game, ...state.games],
      bookings: bookings,
    );
    _persist();
  }

  /// Wipes demo state back to the seeded baseline (for a clean demo run).
  void reset() {
    _box.clear();
    state = _seed();
    _persist();
  }

  // ── Persistence ──────────────────────────────────────────────

  static DemoState _load() {
    if (!_box.containsKey('bookings')) return _seed();
    return DemoState(
      bookings: (jsonDecode(_box.get('bookings') as String) as List)
          .map((e) => _bookingFromJson(e as Map<String, dynamic>))
          .toList(),
      stats: (jsonDecode(_box.get('stats') as String) as List)
          .map((e) => _statFromJson(e as Map<String, dynamic>))
          .toList(),
      games: (jsonDecode(_box.get('games') as String) as List)
          .map((e) => _gameFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  void _persist() {
    _box.put('bookings',
        jsonEncode(state.bookings.map(_bookingToJson).toList()));
    _box.put('stats', jsonEncode(state.stats.map(_statToJson).toList()));
    _box.put('games', jsonEncode(state.games.map(_gameToJson).toList()));
  }

  // ── Seed (cumulative totals so derived averages look realistic) ──

  static DemoState _seed() {
    return DemoState(
      bookings: List<BookingRecord>.from(FakeData.bookingHistory),
      stats: const [
        // 24 games · derived: 18.4 ppg, 6.2 rpg, 4.1 apg, 1.8 spg, 0.9 bpg, 2.1 tov
        PlayerGameStat(sport: 'basketball', gamesPlayed: 24, wins: 16, stats: {
          'points': 442,
          'rebounds': 149,
          'assists': 98,
          'steals': 43,
          'blocks': 22,
          'turnovers': 50,
        }),
        // 12 games · derived: 28 runs, 1.5 wkts
        PlayerGameStat(sport: 'cricket', gamesPlayed: 12, wins: 8, stats: {
          'runs': 336,
          'wickets': 18,
        }),
      ],
      games: [
        CompletedGame(
          id: 'demo_seed_1',
          sport: 'basketball',
          won: true,
          scoreFor: 21,
          scoreAgainst: 17,
          isVerified: true,
          playedAt: DateTime.now().subtract(const Duration(days: 1)),
          venueName: 'Sporthood',
        ),
        CompletedGame(
          id: 'demo_seed_2',
          sport: 'basketball',
          won: false,
          scoreFor: 15,
          scoreAgainst: 21,
          isVerified: true,
          playedAt: DateTime.now().subtract(const Duration(days: 2)),
          venueName: 'Game Theory Indiranagar',
        ),
      ],
    );
  }

  // ── (De)serialization ────────────────────────────────────────

  static Map<String, dynamic> _bookingToJson(BookingRecord b) => {
        'id': b.id,
        'venueName': b.venueName,
        'courtName': b.courtName,
        'sport': b.sport,
        'date': b.date,
        'timeSlot': b.timeSlot,
        'amount': b.amount,
        'status': b.status.index,
        'hasStats': b.hasStats,
        'addons': b.addons,
      };

  static BookingRecord _bookingFromJson(Map<String, dynamic> j) => BookingRecord(
        id: j['id'] as String,
        venueName: j['venueName'] as String,
        courtName: j['courtName'] as String?,
        sport: j['sport'] as String,
        date: j['date'] as String,
        timeSlot: j['timeSlot'] as String,
        amount: j['amount'] as int,
        status: BookingStatus.values[j['status'] as int],
        hasStats: j['hasStats'] as bool? ?? false,
        addons: (j['addons'] as List?)?.cast<String>() ?? const [],
      );

  static Map<String, dynamic> _statToJson(PlayerGameStat s) => {
        'sport': s.sport,
        'gamesPlayed': s.gamesPlayed,
        'wins': s.wins,
        'stats': s.stats,
      };

  static PlayerGameStat _statFromJson(Map<String, dynamic> j) => PlayerGameStat(
        sport: j['sport'] as String,
        gamesPlayed: j['gamesPlayed'] as int,
        wins: j['wins'] as int,
        stats: Map<String, dynamic>.from(j['stats'] as Map),
      );

  static Map<String, dynamic> _gameToJson(CompletedGame g) => {
        'id': g.id,
        'sport': g.sport,
        'won': g.won,
        'scoreFor': g.scoreFor,
        'scoreAgainst': g.scoreAgainst,
        'isVerified': g.isVerified,
        'playedAt': g.playedAt.toIso8601String(),
        'venueName': g.venueName,
      };

  static CompletedGame _gameFromJson(Map<String, dynamic> j) => CompletedGame(
        id: j['id'] as String,
        sport: j['sport'] as String,
        won: j['won'] as bool,
        scoreFor: j['scoreFor'] as int,
        scoreAgainst: j['scoreAgainst'] as int,
        isVerified: j['isVerified'] as bool,
        playedAt: DateTime.parse(j['playedAt'] as String),
        venueName: j['venueName'] as String?,
      );
}

final demoStoreProvider =
    NotifierProvider<DemoStore, DemoState>(DemoStore.new);
