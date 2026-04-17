// lib/providers/sport_cycle_provider.dart
//
// Riverpod provider for sport pictogram cycling.
// Emits a new sport every 2 seconds: BASKETBALL → CRICKET → FOOTBALL → repeat
//
// Usage:
//   final sport = ref.watch(sportCycleProvider);
//   sport.when(
//     data: (s) => _SportPictogram(sport: s),
//     loading: () => SizedBox.shrink(),
//     error: (_, __) => SizedBox.shrink(),
//   )

import 'package:flutter_riverpod/flutter_riverpod.dart';

final sportCycleProvider = StreamProvider<String>((ref) async* {
  const sports = ['BASKETBALL', 'CRICKET', 'FOOTBALL'];
  int index = 0;

  while (true) {
    yield sports[index];
    await Future.delayed(const Duration(seconds: 2));
    index = (index + 1) % sports.length;
  }
});
