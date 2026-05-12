// lib/providers/pickup_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pickup_game.dart';
import '../services/pickup_service.dart';

final _pickupServiceProvider =
    Provider<PickupService>((_) => PickupService());

// ── Active pickup games (home Live Now + play_home) ────────────

final pickupGamesProvider =
    FutureProvider.family<List<PickupGame>, String?>(
  (ref, sport) =>
      ref.read(_pickupServiceProvider).listActivePickups(sport: sport),
);

// Convenience: all sports
final allPickupGamesProvider = FutureProvider<List<PickupGame>>(
  (ref) => ref.read(_pickupServiceProvider).listActivePickups(),
);
