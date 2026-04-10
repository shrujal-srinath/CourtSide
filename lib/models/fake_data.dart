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
    required this.isIndoor,
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
  final bool isIndoor;
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

  // ── Venues (real Bengaluru venues) ────────────────────────────

  static const venues = [
    Venue(
      id: 'v1',
      name: 'Game Theory',
      address: '5th Block, Koramangala, Bengaluru',
      area: 'Koramangala',
      lat: 12.9310, lng: 77.6276,
      sports: ['basketball', 'badminton'],
      rating: 4.9, reviewCount: 312,
      closingTime: '11 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights', 'AC'],
      isIndoor: true,
      hasTheBox: true,
    ),
    Venue(
      id: 'v2',
      name: 'Game Theory',
      address: '12th Main, Indiranagar, Bengaluru',
      area: 'Indiranagar',
      lat: 12.9795, lng: 77.6390,
      sports: ['basketball', 'badminton'],
      rating: 4.8, reviewCount: 278,
      closingTime: '11 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights', 'AC'],
      isIndoor: true,
      hasTheBox: true,
    ),
    Venue(
      id: 'v3',
      name: 'Game Theory',
      address: 'Sector 6, HSR Layout, Bengaluru',
      area: 'HSR Layout',
      lat: 12.9150, lng: 77.6410,
      sports: ['basketball', 'badminton'],
      rating: 4.8, reviewCount: 195,
      closingTime: '11 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights', 'AC'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v4',
      name: 'Game Theory',
      address: '7th Phase, JP Nagar, Bengaluru',
      area: 'JP Nagar',
      lat: 12.9020, lng: 77.5866,
      sports: ['basketball', 'badminton', 'cricket'],
      rating: 4.9, reviewCount: 401,
      closingTime: '11 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water', 'Floodlights', 'AC'],
      isIndoor: true,
      hasTheBox: true,
    ),
    Venue(
      id: 'v5',
      name: 'Sporthood',
      address: 'Sarjapur - Marathahalli Rd, Bengaluru',
      area: 'Sarjapur Road',
      lat: 12.9035, lng: 77.6872,
      sports: ['basketball', 'badminton', 'football'],
      rating: 4.7, reviewCount: 143,
      closingTime: '11:59 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v6',
      name: 'Sree Kanteerava Stadium',
      address: 'Kasturba Rd, Sampangi Rama Nagar, Bengaluru',
      area: 'Central Bengaluru',
      lat: 12.9747, lng: 77.5838,
      sports: ['basketball', 'cricket', 'football'],
      rating: 4.3, reviewCount: 89,
      closingTime: '8 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water'],
      isIndoor: false,
      hasTheBox: false,
    ),
    Venue(
      id: 'v7',
      name: 'Koramangala Indoor Stadium',
      address: '80 Feet Rd, Koramangala 4th Block, Bengaluru',
      area: 'Koramangala',
      lat: 12.9271, lng: 77.6224,
      sports: ['basketball', 'badminton'],
      rating: 4.2, reviewCount: 67,
      closingTime: '9 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v8',
      name: 'Madhavan Park Court',
      address: 'Jayanagar 3rd Block, Bengaluru',
      area: 'Jayanagar',
      lat: 12.9252, lng: 77.5934,
      sports: ['basketball'],
      rating: 4.0, reviewCount: 34,
      closingTime: '9 PM',
      photoUrl: '',
      amenities: ['Water'],
      isIndoor: false,
      hasTheBox: false,
    ),
    Venue(
      id: 'v9',
      name: 'AVA Multi-Sport Court',
      address: '1st Main Rd, Abbaiah Reddy Layout, Kaggadasapura',
      area: 'Kaggadasapura',
      lat: 13.0079, lng: 77.6576,
      sports: ['basketball', 'badminton', 'football'],
      rating: 4.5, reviewCount: 112,
      closingTime: '9 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v10',
      name: 'Active Arena',
      address: 'Marathahalli, Bengaluru',
      area: 'Marathahalli',
      lat: 12.9568, lng: 77.7014,
      sports: ['basketball', 'badminton'],
      rating: 4.4, reviewCount: 88,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v11',
      name: 'Tiger 5',
      address: 'Dairy Circle, Bannerghatta Rd, Bengaluru',
      area: 'Bannerghatta Road',
      lat: 12.8883, lng: 77.6012,
      sports: ['basketball', 'cricket'],
      rating: 3.9, reviewCount: 52,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Water'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v12',
      name: 'Basecamp by Push Sports',
      address: 'Palace Road, Bengaluru City University Campus',
      area: 'Palace Road',
      lat: 13.0064, lng: 77.5848,
      sports: ['basketball', 'football'],
      rating: 4.6, reviewCount: 134,
      closingTime: '10 PM',
      photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water'],
      isIndoor: true,
      hasTheBox: true,
    ),
  ];

  // ── Courts ─────────────────────────────────────────────────────

  static const courts = [
    // Game Theory Koramangala
    Court(id: 'c1', venueId: 'v1', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 400, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 5),
    Court(id: 'c1b', venueId: 'v1', sport: 'basketball',
      name: 'Court 2', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 400, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c2', venueId: 'v1', sport: 'badminton',
      name: 'Court A', surface: 'Synthetic', isIndoor: true,
      pricePerSlot: 250, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 3),

    // Game Theory Indiranagar
    Court(id: 'c3', venueId: 'v2', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 450, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 4),
    Court(id: 'c4', venueId: 'v2', sport: 'badminton',
      name: 'Court A', surface: 'Synthetic', isIndoor: true,
      pricePerSlot: 280, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 6),

    // Game Theory HSR
    Court(id: 'c5', venueId: 'v3', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 400, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 7),

    // Game Theory JP Nagar
    Court(id: 'c6', venueId: 'v4', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 380, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 8),
    Court(id: 'c7', venueId: 'v4', sport: 'cricket',
      name: 'Turf A', surface: 'Artificial Turf', isIndoor: true,
      pricePerSlot: 600, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 3),

    // Sporthood
    Court(id: 'c8', venueId: 'v5', sport: 'basketball',
      name: 'Full Court', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 500, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 4),
    Court(id: 'c9', venueId: 'v5', sport: 'football',
      name: 'Turf A', surface: 'Artificial Turf', isIndoor: true,
      pricePerSlot: 800, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 2),

    // Kanteerava Stadium
    Court(id: 'c10', venueId: 'v6', sport: 'basketball',
      name: 'Court 1', surface: 'Concrete', isIndoor: false,
      pricePerSlot: 200, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 2),

    // Koramangala Indoor Stadium
    Court(id: 'c11', venueId: 'v7', sport: 'basketball',
      name: 'Court 1', surface: 'Concrete', isIndoor: true,
      pricePerSlot: 300, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 3),

    // Madhavan Park
    Court(id: 'c12', venueId: 'v8', sport: 'basketball',
      name: 'Outdoor Court', surface: 'Concrete', isIndoor: false,
      pricePerSlot: 0, slotDurationMin: 60,
      hasTheBox: false, slotsAvailableToday: 10),

    // AVA Multi-Sport
    Court(id: 'c13', venueId: 'v9', sport: 'basketball',
      name: 'Court 1', surface: 'Rubber', isIndoor: true,
      pricePerSlot: 350, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 5),

    // Active Arena
    Court(id: 'c14', venueId: 'v10', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 420, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 3),

    // Tiger 5
    Court(id: 'c15', venueId: 'v11', sport: 'basketball',
      name: 'Court 1', surface: 'Rubber', isIndoor: true,
      pricePerSlot: 300, slotDurationMin: 45,
      hasTheBox: false, slotsAvailableToday: 4),

    // Basecamp
    Court(id: 'c16', venueId: 'v12', sport: 'basketball',
      name: 'Court 1', surface: 'Hardwood', isIndoor: true,
      pricePerSlot: 450, slotDurationMin: 45,
      hasTheBox: true, slotsAvailableToday: 6),
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
    PickupGame(id: 'p1', venueId: 'v1', venueName: 'Game Theory Koramangala',
      sport: 'basketball', title: '3v3 Pickup',
      time: '5:00 PM', spotsTotal: 6, spotsFilled: 4),
    PickupGame(id: 'p2', venueId: 'v4', venueName: 'Game Theory JP Nagar',
      sport: 'basketball', title: 'Full Court Run',
      time: '7:00 PM', spotsTotal: 10, spotsFilled: 9),
    PickupGame(id: 'p3', venueId: 'v12', venueName: 'Basecamp by Push Sports',
      sport: 'basketball', title: '5v5 Open Run',
      time: '6:00 PM', spotsTotal: 10, spotsFilled: 7),
  ];

  // ── Booking history ────────────────────────────────────────────

  static const bookingHistory = [
    BookingRecord(id: 'b1', venueName: 'Game Theory Koramangala',
      sport: 'basketball', date: 'Today', timeSlot: '7:00 PM',
      amount: 400, status: BookingStatus.upcoming, hasStats: false),
    BookingRecord(id: 'b2', venueName: 'Sporthood',
      sport: 'basketball', date: 'Yesterday', timeSlot: '5:00 PM',
      amount: 500, status: BookingStatus.completed, hasStats: true),
    BookingRecord(id: 'b3', venueName: 'Game Theory Indiranagar',
      sport: 'basketball', date: '2 days ago', timeSlot: '8:00 AM',
      amount: 450, status: BookingStatus.completed, hasStats: true),
    BookingRecord(id: 'b4', venueName: 'Koramangala Indoor Stadium',
      sport: 'basketball', date: '5 days ago', timeSlot: '6:00 PM',
      amount: 300, status: BookingStatus.cancelled, hasStats: false),
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

  static List<Court> courtsByVenueAndSport(String venueId, String sport) =>
      courts.where((c) => c.venueId == venueId && c.sport == sport).toList();

  static List<Slot> slotsByCourtId(String courtId) =>
      slotsC1.map((s) => Slot(
        id: '${s.id}_$courtId',
        courtId: courtId,
        startTime: s.startTime,
        endTime: s.endTime,
        status: s.status,
      )).toList();

  static List<PickupGame> pickupGamesBySport(String sport) =>
      pickupGames.where((g) => g.sport == sport).toList();
}
