// lib/models/fake_data.dart
//
// Single source of fake data for ALL screens.
// When Supabase is ready, delete this file and replace
// with real provider queries — nothing else changes.

// ═══════════════════════════════════════════════════════════════
//  VENUE
// ═══════════════════════════════════════════════════════════════

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.lat,
    required this.lng,
    required this.sports,
    required this.rating,
    required this.reviewCount,
    required this.closingTime,
    required this.photoUrl,
    required this.amenities,
    this.hasTheBox = false,
  });

  final String id;
  final String name;
  final String address;
  final String area;
  final double lat;
  final double lng;
  final List<String> sports;
  final double rating;
  final int reviewCount;
  final String closingTime;
  final String photoUrl;
  final List<String> amenities;
  final bool hasTheBox;

  double distanceFromKm(double userLat, double userLng) {
    // Simple approximation for fake data
    final dlat = (lat - userLat).abs();
    final dlng = (lng - userLng).abs();
    return ((dlat + dlng) * 111).clamp(0.3, 20.0);
  }
}

// ═══════════════════════════════════════════════════════════════
//  COURT
// ═══════════════════════════════════════════════════════════════

class Court {
  const Court({
    required this.id,
    required this.venueId,
    required this.sport,
    required this.name,
    required this.surface,
    required this.isIndoor,
    required this.pricePerSlot,
    required this.slotDurationMin,
    required this.hasTheBox,
    required this.slotsAvailableToday,
  });

  final String id;
  final String venueId;
  final String sport;
  final String name;
  final String surface;
  final bool isIndoor;
  final int pricePerSlot;
  final int slotDurationMin;
  final bool hasTheBox;
  final int slotsAvailableToday;
}

// ═══════════════════════════════════════════════════════════════
//  SLOT
// ═══════════════════════════════════════════════════════════════

enum SlotStatus { available, booked, blocked }

class Slot {
  const Slot({
    required this.id,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final String id;
  final String courtId;
  final String startTime;
  final String endTime;
  final SlotStatus status;
}

// ═══════════════════════════════════════════════════════════════
//  PICKUP GAME
// ═══════════════════════════════════════════════════════════════

class PickupGame {
  const PickupGame({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.sport,
    required this.title,
    required this.time,
    required this.spotsTotal,
    required this.spotsFilled,
  });

  final String id;
  final String venueId;
  final String venueName;
  final String sport;
  final String title;
  final String time;
  final int spotsTotal;
  final int spotsFilled;

  int get spotsLeft => spotsTotal - spotsFilled;
}

// ═══════════════════════════════════════════════════════════════
//  PLAYER STATS
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
//  BOOKING HISTORY
// ═══════════════════════════════════════════════════════════════

enum BookingStatus { upcoming, completed, cancelled }

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.venueName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.amount,
    required this.status,
    this.hasStats = false,
  });

  final String id;
  final String venueName;
  final String sport;
  final String date;
  final String timeSlot;
  final int amount;
  final BookingStatus status;
  final bool hasStats;
}

// ═══════════════════════════════════════════════════════════════
//  SEED DATA
// ═══════════════════════════════════════════════════════════════

class FakeData {
  FakeData._();

  // ── Venues ────────────────────────────────────────────────────

  static const venues = [
    Venue(
      id: 'v1',
      name: 'Koramangala Sports Hub',
      address: '5th Block, Koramangala, Bengaluru',
      area: 'Koramangala',
      lat: 12.9352, lng: 77.6245,
      sports: ['basketball', 'cricket'],
      rating: 4.7, reviewCount: 142,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      hasTheBox: true,
    ),
    Venue(
      id: 'v2',
      name: 'Indiranagar Sports Court',
      address: '12th Main, Indiranagar, Bengaluru',
      area: 'Indiranagar',
      lat: 12.9784, lng: 77.6408,
      sports: ['basketball', 'badminton'],
      rating: 4.5, reviewCount: 89,
      closingTime: '9 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights'],
      hasTheBox: false,
    ),
    Venue(
      id: 'v3',
      name: 'HSR Sports Arena',
      address: 'Sector 6, HSR Layout, Bengaluru',
      area: 'HSR Layout',
      lat: 12.9116, lng: 77.6473,
      sports: ['cricket', 'football'],
      rating: 4.8, reviewCount: 203,
      closingTime: '11 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water', 'Floodlights'],
      hasTheBox: true,
    ),
    Venue(
      id: 'v4',
      name: 'Whitefield Box Arena',
      address: 'ITPL Main Rd, Whitefield, Bengaluru',
      area: 'Whitefield',
      lat: 12.9698, lng: 77.7499,
      sports: ['cricket', 'basketball'],
      rating: 4.3, reviewCount: 67,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights'],
      hasTheBox: true,
    ),
    Venue(
      id: 'v5',
      name: 'BTM Sports Complex',
      address: 'BTM 2nd Stage, Bengaluru',
      area: 'BTM Layout',
      lat: 12.9166, lng: 77.6101,
      sports: ['football', 'badminton'],
      rating: 4.2, reviewCount: 54,
      closingTime: '9 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water'],
      hasTheBox: false,
    ),
    Venue(
      id: 'v6',
      name: 'JP Nagar Sports Club',
      address: '7th Phase, JP Nagar, Bengaluru',
      area: 'JP Nagar',
      lat: 12.9063, lng: 77.5857,
      sports: ['basketball', 'badminton', 'football'],
      rating: 4.6, reviewCount: 118,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      hasTheBox: false,
    ),
  ];

  // ── Courts ─────────────────────────────────────────────────────

  static const courts = [
    // Koramangala
    Court(id: 'c1', venueId: 'v1', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 400, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 5),
    Court(id: 'c2', venueId: 'v1', sport: 'cricket',
      name: 'Turf A', surface: 'Artificial Turf', isIndoor: false,
      pricePerSlot: 600, slotDurationMin: 60,
      hasTheBox: true, slotsAvailableToday: 3),

    // Indiranagar
    Court(id: 'c3', venueId: 'v2', sport: 'basketball',
      name: 'Court 1', surface: 'Concrete', isIndoor: false,
      pricePerSlot: 350, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 8),
    Court(id: 'c4', venueId: 'v2', sport: 'badminton',
      name: 'Court 1', surface: 'Synthetic', isIndoor: true,
      pricePerSlot: 250, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 2),

    // HSR
    Court(id: 'c5', venueId: 'v3', sport: 'cricket',
      name: 'Turf A', surface: 'Artificial Turf', isIndoor: false,
      pricePerSlot: 700, slotDurationMin: 60,
      hasTheBox: true, slotsAvailableToday: 4),
    Court(id: 'c6', venueId: 'v3', sport: 'football',
      name: 'Main Turf', surface: 'Artificial Turf', isIndoor: false,
      pricePerSlot: 800, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 2),

    // Whitefield
    Court(id: 'c7', venueId: 'v4', sport: 'cricket',
      name: 'Turf A', surface: 'Artificial Turf', isIndoor: false,
      pricePerSlot: 500, slotDurationMin: 60,
      hasTheBox: true, slotsAvailableToday: 6),
    Court(id: 'c8', venueId: 'v4', sport: 'basketball',
      name: 'Court 1', surface: 'Rubber', isIndoor: true,
      pricePerSlot: 450, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 1),
  ];

  // ── Slots (for venue v1 court c1) ──────────────────────────────

  static const slotsC1 = [
    Slot(id: 's1', courtId: 'c1', startTime: '6:00 AM',  endTime: '6:45 AM',  status: SlotStatus.available),
    Slot(id: 's2', courtId: 'c1', startTime: '7:00 AM',  endTime: '7:45 AM',  status: SlotStatus.booked),
    Slot(id: 's3', courtId: 'c1', startTime: '8:00 AM',  endTime: '8:45 AM',  status: SlotStatus.booked),
    Slot(id: 's4', courtId: 'c1', startTime: '9:00 AM',  endTime: '9:45 AM',  status: SlotStatus.available),
    Slot(id: 's5', courtId: 'c1', startTime: '10:00 AM', endTime: '10:45 AM', status: SlotStatus.available),
    Slot(id: 's6', courtId: 'c1', startTime: '5:00 PM',  endTime: '5:45 PM',  status: SlotStatus.available),
    Slot(id: 's7', courtId: 'c1', startTime: '6:00 PM',  endTime: '6:45 PM',  status: SlotStatus.booked),
    Slot(id: 's8', courtId: 'c1', startTime: '7:00 PM',  endTime: '7:45 PM',  status: SlotStatus.available),
    Slot(id: 's9', courtId: 'c1', startTime: '8:00 PM',  endTime: '8:45 PM',  status: SlotStatus.blocked),
    Slot(id: 's10',courtId: 'c1', startTime: '9:00 PM',  endTime: '9:45 PM',  status: SlotStatus.available),
  ];

  // ── Pickup games ───────────────────────────────────────────────

  static const pickupGames = [
    PickupGame(id: 'p1', venueId: 'v1', venueName: 'Koramangala Sports Hub',
      sport: 'basketball', title: '3v3 Pickup',
      time: '5:00 PM', spotsTotal: 6, spotsFilled: 4),
    PickupGame(id: 'p2', venueId: 'v3', venueName: 'HSR Sports Arena',
      sport: 'basketball', title: 'Full Court Run',
      time: '7:00 PM', spotsTotal: 10, spotsFilled: 9),
    PickupGame(id: 'p3', venueId: 'v1', venueName: 'Koramangala Sports Hub',
      sport: 'cricket', title: '8-over game',
      time: '6:00 PM', spotsTotal: 12, spotsFilled: 10),
  ];

  // ── Booking history ────────────────────────────────────────────

  static const bookingHistory = [
    BookingRecord(id: 'b1', venueName: 'Koramangala Sports Hub',
      sport: 'basketball', date: 'Today', timeSlot: '7:00 PM',
      amount: 400, status: BookingStatus.upcoming, hasStats: false),
    BookingRecord(id: 'b2', venueName: 'HSR Sports Arena',
      sport: 'cricket', date: 'Yesterday', timeSlot: '5:00 PM',
      amount: 700, status: BookingStatus.completed, hasStats: true),
    BookingRecord(id: 'b3', venueName: 'Indiranagar Sports Court',
      sport: 'basketball', date: '2 days ago', timeSlot: '8:00 AM',
      amount: 350, status: BookingStatus.completed, hasStats: true),
    BookingRecord(id: 'b4', venueName: 'BTM Sports Complex',
      sport: 'football', date: '5 days ago', timeSlot: '6:00 PM',
      amount: 500, status: BookingStatus.cancelled, hasStats: false),
  ];

  // ── Player stats ───────────────────────────────────────────────

  static const playerStats = [
    PlayerGameStat(
      sport: 'basketball',
      gamesPlayed: 24,
      wins: 16,
      stats: {
        'ppg': 18.4,
        'rpg': 6.2,
        'apg': 4.1,
        'spg': 1.8,
        'fg_pct': 0.48,
        'three_pct': 0.38,
      },
    ),
    PlayerGameStat(
      sport: 'cricket',
      gamesPlayed: 12,
      wins: 8,
      stats: {
        'batting_avg': 34.5,
        'highest_score': 67,
        'wickets': 18,
        'economy': 6.4,
        'strike_rate': 112.3,
      },
    ),
  ];

  // ── Helpers ────────────────────────────────────────────────────

  static List<Venue> venuesBySport(String sport) =>
      venues.where((v) => v.sports.contains(sport)).toList();

  static List<Court> courtsByVenue(String venueId) =>
      courts.where((c) => c.venueId == venueId).toList();

  static Court? courtByVenueAndSport(String venueId, String sport) =>
      courts.where((c) => c.venueId == venueId && c.sport == sport).firstOrNull;

  static List<PickupGame> pickupGamesBySport(String sport) =>
      pickupGames.where((g) => g.sport == sport).toList();
}