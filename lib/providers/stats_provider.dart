// lib/providers/stats_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';
import '../models/completed_game.dart';
import '../services/stats_service.dart';
import 'app_mode_provider.dart';
import 'demo_store_provider.dart';

// ── Service singleton ──────────────────────────────────────────

final _statsServiceProvider = Provider<StatsService>((_) => StatsService());

// ── All stats for current user (mode-aware) ────────────────────

final myStatsProvider = FutureProvider<List<PlayerGameStat>>(
  (ref) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      return ref.watch(demoStoreProvider).stats;
    }
    return ref.read(_statsServiceProvider).getAllMyStats();
  },
);

// ── Stats for a specific sport ─────────────────────────────────

final myStatsBySportProvider = FutureProvider.family<PlayerGameStat?, String>(
  (ref, sport) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      final all = ref.watch(demoStoreProvider).stats;
      for (final s in all) {
        if (s.sport == sport) return s;
      }
      return null;
    }
    return ref.read(_statsServiceProvider).getMyStats(sport);
  },
);

// ── All completed games for current user (newest first) ────────

final myGamesProvider = FutureProvider<List<CompletedGame>>(
  (ref) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      return ref.watch(demoStoreProvider).games;
    }
    return ref.read(_statsServiceProvider).getMyGames();
  },
);
