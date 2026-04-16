// lib/providers/venue_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';
import '../services/venue_service.dart';

// ── Service singleton ──────────────────────────────────────────

final _venueServiceProvider = Provider<VenueService>((_) => VenueService());

// ── Nearby venues ──────────────────────────────────────────────

class NearbyVenuesParams {
  const NearbyVenuesParams(this.lat, this.lng, {this.sport, this.radiusKm = 5.0});
  final double lat;
  final double lng;
  final String? sport;
  final double radiusKm;

  @override
  bool operator ==(Object other) =>
      other is NearbyVenuesParams &&
      lat == other.lat &&
      lng == other.lng &&
      sport == other.sport &&
      radiusKm == other.radiusKm;

  @override
  int get hashCode => Object.hash(lat, lng, sport, radiusKm);
}

final nearbyVenuesProvider =
    FutureProvider.family<List<Venue>, NearbyVenuesParams>(
  (ref, params) => ref
      .read(_venueServiceProvider)
      .getNearbyVenues(params.lat, params.lng, params.radiusKm,
          sport: params.sport),
);

// ── Venue detail ───────────────────────────────────────────────

final venueDetailProvider = FutureProvider.family<Venue?, String>(
  (ref, id) => ref.read(_venueServiceProvider).getVenueById(id),
);

// ── Venue courts ───────────────────────────────────────────────

class VenueCourtsParams {
  const VenueCourtsParams(this.venueId, {this.sport});
  final String venueId;
  final String? sport;

  @override
  bool operator ==(Object other) =>
      other is VenueCourtsParams && venueId == other.venueId && sport == other.sport;

  @override
  int get hashCode => Object.hash(venueId, sport);
}

final venueCourtsProvider = FutureProvider.family<List<Court>, VenueCourtsParams>(
  (ref, params) => ref
      .read(_venueServiceProvider)
      .getCourtsForVenue(params.venueId, sport: params.sport),
);

// ── Explore (search + sport filter) ───────────────────────────

class ExploreState {
  const ExploreState({this.sport, this.query = ''});
  final String? sport;
  final String query;

  ExploreState copyWith({String? sport, bool clearSport = false, String? query}) =>
      ExploreState(
        sport: clearSport ? null : (sport ?? this.sport),
        query: query ?? this.query,
      );
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  ExploreNotifier() : super(const ExploreState());

  void setSport(String? sport) =>
      state = state.copyWith(sport: sport, clearSport: sport == null);

  void setQuery(String q) => state = state.copyWith(query: q);

  void clear() => state = const ExploreState();
}

final exploreStateProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>(
  (_) => ExploreNotifier(),
);

final exploreVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final state = ref.watch(exploreStateProvider);
  final service = ref.read(_venueServiceProvider);

  if (state.query.isNotEmpty) {
    final results = await service.searchVenues(state.query);
    if (state.sport != null) {
      return results.where((v) => v.sports.contains(state.sport)).toList();
    }
    return results;
  }

  // No query — fetch all active venues and filter by sport client-side
  final all = await service.getNearbyVenues(12.9716, 77.5946, 50.0,
      sport: state.sport);
  return all;
});
