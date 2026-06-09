// lib/providers/app_mode_provider.dart
//
// The single switch that decides where every screen reads its data from.
//
//   • DEMO  — entered via dev-access bypass. 100% FakeData, fully mutable
//             and Hive-persisted. A self-contained investor sandbox: book a
//             court, score a game, watch stats change. No real venues.
//   • LIVE  — a genuinely authenticated user. 100% Supabase, no fake data.
//             Empty until real (public) venues are onboarded.
//
// Every data provider branches on this. Screens should NEVER read FakeData
// directly anymore — go through a mode-aware provider so LIVE users never
// see demo content.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

enum AppMode { demo, live }

final appModeProvider = Provider<AppMode>((ref) {
  final isDevAccess = ref.watch(devAccessProvider);
  return isDevAccess ? AppMode.demo : AppMode.live;
});

/// Convenience: true when the demo sandbox is active.
final isDemoProvider = Provider<bool>(
  (ref) => ref.watch(appModeProvider) == AppMode.demo,
);
