// lib/services/venue_service.dart
//
// Reads venue + court data from Supabase.
// RLS: public read — no auth required.

import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fake_data.dart';

class VenueService {
  VenueService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ── Public API ─────────────────────────────────────────────────

  /// Returns venues within [radiusKm] of [lat]/[lng], optionally filtered by sport.
  Future<List<Venue>> getNearbyVenues(
    double lat,
    double lng,
    double radiusKm, {
    String? sport,
  }) async {
    var query = _client
        .from('venues')
        .select()
        .eq('is_active', true);

    if (sport != null) {
      query = query.contains('sports', [sport]);
    }

    final rows = await query;
    final venues = rows.map(_rowToVenue).toList();

    return venues
        .where((v) => _distanceKm(lat, lng, v.lat, v.lng) <= radiusKm)
        .toList()
      ..sort((a, b) =>
          _distanceKm(lat, lng, a.lat, a.lng)
              .compareTo(_distanceKm(lat, lng, b.lat, b.lng)));
  }

  /// Returns a single venue by ID with its courts.
  Future<Venue?> getVenueById(String id) async {
    final row = await _client
        .from('venues')
        .select()
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : _rowToVenue(row);
  }

  /// Full-text search across venue name and area.
  Future<List<Venue>> searchVenues(String query) async {
    final rows = await _client
        .from('venues')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$query%,area.ilike.%$query%');

    return rows.map(_rowToVenue).toList();
  }

  /// Returns courts for a given venue, optionally filtered by sport.
  Future<List<Court>> getCourtsForVenue(String venueId, {String? sport}) async {
    var query = _client
        .from('courts')
        .select()
        .eq('venue_id', venueId)
        .eq('is_active', true);

    if (sport != null) {
      query = query.eq('sport', sport);
    }

    final rows = await query;
    return rows.map(_rowToCourt).toList();
  }

  // ── Converters ─────────────────────────────────────────────────

  Venue _rowToVenue(Map<String, dynamic> row) => Venue(
        id: row['id'] as String,
        name: row['name'] as String,
        address: row['address'] as String,
        area: row['area'] as String,
        lat: (row['lat'] as num).toDouble(),
        lng: (row['lng'] as num).toDouble(),
        sports: List<String>.from(row['sports'] as List),
        rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (row['review_count'] as int?) ?? 0,
        closingTime: (row['closing_time'] as String?) ?? '',
        photoUrl: (row['photo_url'] as String?) ?? '',
        amenities: List<String>.from((row['amenities'] as List?) ?? []),
        isIndoor: false, // venues don't have isIndoor — individual courts do
        hasTheBox: (row['has_the_box'] as bool?) ?? false,
      );

  Court _rowToCourt(Map<String, dynamic> row) => Court(
        id: row['id'] as String,
        venueId: row['venue_id'] as String,
        sport: row['sport'] as String,
        name: row['name'] as String,
        surface: (row['surface'] as String?) ?? '',
        isIndoor: (row['is_indoor'] as bool?) ?? false,
        pricePerSlot: (row['price_per_slot'] as int?) ?? 0,
        slotDurationMin: (row['slot_duration_min'] as int?) ?? 60,
        hasTheBox: (row['has_the_box'] as bool?) ?? false,
        slotsAvailableToday: 0, // populated separately when needed
      );

  // ── Helpers ────────────────────────────────────────────────────

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;
}
