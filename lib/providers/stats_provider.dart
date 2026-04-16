// lib/providers/stats_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';
import '../services/stats_service.dart';

// ── Service singleton ──────────────────────────────────────────

final _statsServiceProvider = Provider<StatsService>((_) => StatsService());

// ── All stats for current user ─────────────────────────────────

final myStatsProvider = FutureProvider<List<PlayerGameStat>>(
  (ref) => ref.read(_statsServiceProvider).getAllMyStats(),
);

// ── Stats for a specific sport ─────────────────────────────────

final myStatsBySportProvider = FutureProvider.family<PlayerGameStat?, String>(
  (ref, sport) => ref.read(_statsServiceProvider).getMyStats(sport),
);
