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
    this.courtName,
    required this.sport,
    required this.date,
    required this.timeSlot,
    required this.amount,
    required this.status,
    this.hasStats = false,
    this.addons = const [],
  });

  final String id;
  final String venueName;
  final String? courtName;
  final String sport;
  final String date;
  final String timeSlot;
  final int amount;
  final BookingStatus status;
  final bool hasStats;
  final List<String> addons;
}

// ═══════════════════════════════════════════════════════════════
//  PRODUCT
// ═══════════════════════════════════════════════════════════════

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.image,
    required this.category,
    required this.description,
  });

  final String id;
  final String name;
  final int price;
  final int originalPrice;
  final double rating;
  final String image;
  final String category;
  final String description;

  int get discountPercent => ((originalPrice - price) / originalPrice * 100).round();
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
      photoUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water'],
      isIndoor: true,
      hasTheBox: true,
    ),
    Venue(
      id: 'v13',
      name: 'Indiranagar Sports Club',
      address: 'Near ESI Hospital, Indiranagar',
      area: 'Indiranagar',
      lat: 12.9780, lng: 77.6440,
      sports: ['badminton', 'gym'],
      rating: 4.5, reviewCount: 210,
      closingTime: '10 PM',
      photoUrl: 'https://images.unsplash.com/photo-1626224580195-f23912418175?w=800&q=80',
      amenities: ['Parking', 'Shower', 'AC', 'Locker'],
      isIndoor: true,
      hasTheBox: false,
    ),
    Venue(
      id: 'v14',
      name: 'Whitefield Stadium',
      address: 'ITPL Main Rd, Whitefield',
      area: 'Whitefield',
      lat: 12.9840, lng: 77.7280,
      sports: ['cricket', 'football'],
      rating: 4.7, reviewCount: 540,
      closingTime: '11 PM',
      photoUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&q=80',
      amenities: ['Ample Parking', 'Floodlights', 'Medical Support'],
      isIndoor: false,
      hasTheBox: false,
    ),
    Venue(
      id: 'v15',
      name: 'Bannerghatta Sports Hub',
      address: 'Hulimavu, Bannerghatta Rd',
      area: 'Bannerghatta Road',
      lat: 12.8750, lng: 77.5950,
      sports: ['basketball', 'football', 'badminton'],
      rating: 4.4, reviewCount: 165,
      closingTime: '11 PM',
      photoUrl: 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=800&q=80',
      amenities: ['Parking', 'Floodlights', 'Water'],
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

  static final List<BookingRecord> bookingHistory = [
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

  static const products = [
    Product(
      id: 'p1',
      name: 'NIVIA Storm Football',
      price: 899,
      originalPrice: 1200,
      rating: 4.5,
      image: 'sports_football', // identifier for local asset
      category: 'Football',
      description: 'High-quality synthetic leather football for all-weather play. Hand-stitched for durability and shape retention.',
    ),
    Product(
      id: 'p2',
      name: 'Gatorade Blue Bolt',
      price: 50,
      originalPrice: 60,
      rating: 4.8,
      image: 'nutrition_gatorade',
      category: 'Nutrition',
      description: 'Isotonic sports drink for rapid rehydration and carbohydrate energy. Stay hydrated during intense matches.',
    ),
    Product(
      id: 'p3',
      name: 'NIVIA Basketball',
      price: 999,
      originalPrice: 1499,
      rating: 4.7,
      image: 'sports_basketball',
      category: 'Basketball',
      description: 'Pro-grade basketball with enhanced grip and consistent bounce. Suitable for both indoor and outdoor courts.',
    ),
    Product(
      id: 'p4',
      name: 'Yonex Badminton Racket',
      price: 2499,
      originalPrice: 3500,
      rating: 4.9,
      image: 'sports_badminton',
      category: 'Badminton',
      description: 'Lightweight graphite frame for fast swings and powerful smashes. Perfect for intermediate to advanced players.',
    ),
    Product(
      id: 'p5',
      name: 'Optimum Nutrition Whey',
      price: 5999,
      originalPrice: 7500,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1593095199912-2d17bb46bd5a?w=400&q=80',
      category: 'Nutrition',
      description: 'Gold Standard 100% Whey protein for muscle recovery. 24g of protein per serving with BCAAs and glutamine.',
    ),
    Product(
      id: 'p6',
      name: 'Red Bull Energy Drink',
      price: 110,
      originalPrice: 125,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1622543953491-017a9435303b?w=400&q=80',
      category: 'Nutrition',
      description: 'Vitalizes body and mind. High caffeine content for increased focus and performance.',
    ),
    Product(
      id: 'p7',
      name: 'Raw Whey Protein',
      price: 1899,
      originalPrice: 2200,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1593095199912-2d17bb46bd5a?w=400&q=80',
      category: 'Nutrition',
      description: 'Zero carb whey protein for lean muscle building. No added flavors.',
    ),
    Product(
      id: 'p8',
      name: 'Premium Basketball Jersey',
      price: 1499,
      originalPrice: 2499,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1515523110800-9415d13b84a8?w=400&q=80',
      category: 'Clothing',
      description: 'Moisture-wicking fabric with athletic cut. Lightweight and breathable for summer games.',
    ),
    Product(
      id: 'p9',
      name: 'Cricket Performance Tee',
      price: 799,
      originalPrice: 1599,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400&q=80',
      category: 'Clothing',
      description: 'Built for long overs in the sun. SPF 50+ protection with quick-dry technology.',
    ),
    Product(
      id: 'p10',
      name: 'Nike Compression Pants',
      price: 2999,
      originalPrice: 3999,
      rating: 4.9,
      image: 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400&q=80',
      category: 'Clothing',
      description: 'Pro-level compression for muscle stability and recovery. Flatlock seams for zero irritation.',
    ),
    Product(
      id: 'p11',
      name: 'Training Gym Shorts',
      price: 499,
      originalPrice: 999,
      rating: 4.5,
      image: 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=400&q=80',
      category: 'Clothing',
      description: 'Lightweight mesh shorts with four-way stretch. Ideal for explosive movements.',
    ),
    Product(
      id: 'p12',
      name: 'Neoprene Shoulder Support',
      price: 1299,
      originalPrice: 1999,
      rating: 4.4,
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
      category: 'Accessories',
      description: 'Adjustable pressure plate for AC joint stability. Breathable neoprene for all-day comfort.',
    ),
    Product(
      id: 'p13',
      name: 'Pro Knee Sleeves (Pair)',
      price: 1800,
      originalPrice: 2500,
      rating: 4.8,
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
      category: 'Accessories',
      description: '7mm SBR/Neoprene for heavy lifting and impact protection. Anatomical fit.',
    ),
    Product(
      id: 'p14',
      name: 'Sports Water Bottle 1L',
      price: 299,
      originalPrice: 499,
      rating: 4.6,
      image: 'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400&q=80',
      category: 'Accessories',
      description: 'BPA-free tritan material with one-click opening. Leak-proof design.',
    ),
    Product(
      id: 'p15',
      name: 'Antigravity Wrist Bands',
      price: 199,
      originalPrice: 399,
      rating: 4.7,
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
      category: 'Accessories',
      description: 'Super absorbent cotton blend. Standard size for elite performance.',
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

  static List<Product> productsByCategory(String category) =>
      category == 'All' ? products : products.where((p) => p.category == category).toList();

  static Product? productById(String id) =>
      products.where((p) => p.id == id).firstOrNull;

  static DateTime? parseBookingTime(String dateStr, String timeSlot) {
    try {
      final now = DateTime.now();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      
      String cleanDate = dateStr.trim();
      if (cleanDate.toLowerCase() == 'today') {
        cleanDate = '${now.day} ${months[now.month - 1]}';
      } else if (cleanDate.toLowerCase() == 'yesterday') {
        final yest = now.subtract(const Duration(days: 1));
        cleanDate = '${yest.day} ${months[yest.month - 1]}';
      } else if (cleanDate.toLowerCase().contains('ago')) {
        int days = int.parse(cleanDate.split(' ')[0]);
        final ago = now.subtract(Duration(days: days));
        cleanDate = '${ago.day} ${months[ago.month - 1]}';
      }

      final dateParts = cleanDate.split(' ');
      if (dateParts.length < 2) return null;
      
      final day = int.parse(dateParts[0]);
      final month = months.indexWhere((m) => dateParts[1].startsWith(m)) + 1;
      if (month == 0) return null;
      
      final timeParts = timeSlot.split(' - ');
      final startTimePart = timeParts[0]; 
      
      final parts = startTimePart.split(' ');
      final hhmm = parts[0].split(':');
      int h = int.parse(hhmm[0]);
      int m = hhmm.length > 1 ? int.parse(hhmm[1]) : 0;
      if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
      if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
      
      return DateTime(now.year, month, day, h, m);
    } catch (_) {
      return null;
    }
  }

  static void completeBooking(String? bookingId) {
    final idx = bookingHistory.indexWhere((b) => 
      (bookingId != null && b.id == bookingId) || 
      (bookingId == null && b.status == BookingStatus.upcoming)
    );
    if (idx != -1) {
      final old = bookingHistory[idx];
      bookingHistory[idx] = BookingRecord(
        id: old.id,
        venueName: old.venueName,
        sport: old.sport,
        date: old.date,
        timeSlot: old.timeSlot,
        amount: old.amount,
        status: BookingStatus.completed,
        hasStats: true,
      );
    }
  }
}
