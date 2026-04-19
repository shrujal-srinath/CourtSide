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
    this.openingTime = '6 AM',
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
  final String openingTime;
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
    this.brand = '',
    this.reviewCount = 0,
    this.inStock = true,
    this.specifications = const {},
    this.tags = const [],
  });

  final String id;
  final String name;
  final int price;
  final int originalPrice;
  final double rating;
  final String image;
  final String category;
  final String description;
  final String brand;
  final int reviewCount;
  final bool inStock;
  final Map<String, String> specifications;
  final List<String> tags;

  int get discountPercent => ((originalPrice - price) / originalPrice * 100).round();
}

// ═══════════════════════════════════════════════════════════════
//  PRODUCT REVIEW
// ═══════════════════════════════════════════════════════════════

class ProductReview {
  const ProductReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.date,
    this.helpfulCount = 0,
    this.verified = true,
  });

  final String id;
  final String userName;
  final double rating;
  final String title;
  final String comment;
  final String date;
  final int helpfulCount;
  final bool verified;
}

// ═══════════════════════════════════════════════════════════════
//  DELIVERY ADDRESS
// ═══════════════════════════════════════════════════════════════

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final bool isDefault;

  String get fullAddress => '$street, $area, $city - $pincode';

  DeliveryAddress copyWith({bool? isDefault}) => DeliveryAddress(
    id: id, label: label, name: name, phone: phone,
    street: street, area: area, city: city, pincode: pincode,
    isDefault: isDefault ?? this.isDefault,
  );
}

// ═══════════════════════════════════════════════════════════════
//  SHOP ORDER
// ═══════════════════════════════════════════════════════════════

class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  final String name;
  final int quantity;
  final int price;
  final String category;

  int get total => price * quantity;
}

enum OrderStatus { placed, confirmed, shipped, outForDelivery, delivered, cancelled }

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.items,
    required this.status,
    required this.placedDate,
    required this.address,
    required this.total,
    this.deliveryDate,
    this.trackingId,
  });

  final String id;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String placedDate;
  final String address;
  final int total;
  final String? deliveryDate;
  final String? trackingId;

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed: return 'Order Placed';
      case OrderStatus.confirmed: return 'Confirmed';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
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
    // ── HYDRATION ─────────────────────────────────────────────────
    Product(
      id: 'p1', name: 'Gatorade Blue Bolt 500ml', price: 120, originalPrice: 150,
      rating: 4.5, image: 'hydration', category: 'Hydration', brand: 'Gatorade',
      reviewCount: 2847,
      description: 'Isotonic sports drink for rapid rehydration. Packed with electrolytes to help you perform at your best during intense sessions.',
      specifications: {'Volume': '500ml', 'Calories': '90kcal', 'Sodium': '110mg', 'Potassium': '30mg', 'Carbs': '22g'},
      tags: ['sports drink', 'electrolytes', 'hydration'],
    ),
    Product(
      id: 'p2', name: 'Pocari Sweat Ion Drink 500ml', price: 65, originalPrice: 80,
      rating: 4.3, image: 'hydration', category: 'Hydration', brand: 'Pocari Sweat',
      reviewCount: 1243,
      description: 'Smooth ion balance drink that replaces water and ions lost through sweat. Gentle on the stomach.',
      specifications: {'Volume': '500ml', 'Calories': '25kcal', 'Sodium': '49mg', 'Potassium': '20mg'},
      tags: ['ion drink', 'hydration', 'recovery'],
    ),
    Product(
      id: 'p3', name: 'Electral ORS Sachets (10 pack)', price: 149, originalPrice: 199,
      rating: 4.7, image: 'hydration', category: 'Hydration', brand: 'Electral',
      reviewCount: 3102,
      description: 'WHO-formulated oral rehydration salts. Ideal for rapid recovery from dehydration during intense sports.',
      specifications: {'Pack': '10 sachets', 'Net Weight': '21.8g each', 'Flavor': 'Lemon', 'Electrolytes': '5 key'},
      tags: ['ORS', 'electrolytes', 'recovery'],
    ),
    Product(
      id: 'p4', name: 'Red Bull Energy Drink 250ml', price: 125, originalPrice: 150,
      rating: 4.4, image: 'hydration', category: 'Hydration', brand: 'Red Bull',
      reviewCount: 5620,
      description: 'Vitalizes body and mind. 80mg caffeine per can for sustained focus and energy during competition.',
      specifications: {'Volume': '250ml', 'Caffeine': '80mg', 'Niacin (B3)': '22mg', 'B6': '5mg', 'B12': '5.5mcg'},
      tags: ['energy drink', 'caffeine', 'focus'],
    ),
    Product(
      id: 'p5', name: 'Fast&Up Reload Electrolyte (20 tabs)', price: 349, originalPrice: 499,
      rating: 4.6, image: 'hydration', category: 'Hydration', brand: 'Fast&Up',
      reviewCount: 1876,
      description: 'Effervescent electrolyte tablets with 5 key electrolytes. Drop in water for instant isotonic sports fuel.',
      specifications: {'Tablets': '20', 'Flavor': 'Orange', 'Serving': '1 tab per 300ml', 'Sodium': '200mg', 'Sugar-free': 'Yes'},
      tags: ['electrolyte tabs', 'effervescent', 'sugar-free'],
    ),
    Product(
      id: 'p6', name: 'Decathlon Sports Bottle 1.5L', price: 499, originalPrice: 799,
      rating: 4.8, image: 'hydration', category: 'Hydration', brand: 'Decathlon',
      reviewCount: 4391,
      description: 'BPA-free Tritan bottle with one-click flip cap. Wide mouth for ice. Dishwasher safe and leak-proof.',
      specifications: {'Capacity': '1.5L', 'Material': 'Tritan BPA-Free', 'Leak-proof': 'Yes', 'Dishwasher Safe': 'Yes', 'Weight': '195g'},
      tags: ['water bottle', 'BPA-free', 'tritan'],
    ),
    // ── NUTRITION ─────────────────────────────────────────────────
    Product(
      id: 'p7', name: 'ON Gold Standard Whey 1kg', price: 2499, originalPrice: 3499,
      rating: 4.8, image: 'nutrition', category: 'Nutrition', brand: 'Optimum Nutrition',
      reviewCount: 8932,
      description: "World's #1 whey protein. 24g of protein per serving with BCAAs and glutamine for muscle recovery and growth.",
      specifications: {'Protein': '24g/serving', 'Servings': '29', 'Calories': '120kcal', 'Fat': '1.5g', 'Flavor': 'Double Chocolate'},
      tags: ['whey protein', 'muscle recovery', 'BCAAs'],
    ),
    Product(
      id: 'p8', name: 'MyProtein Impact Whey 1kg', price: 1799, originalPrice: 2499,
      rating: 4.6, image: 'nutrition', category: 'Nutrition', brand: 'MyProtein',
      reviewCount: 4521,
      description: 'High-quality whey concentrate from grass-fed cows. Clean macro profile for lean gains. 21g protein per serving.',
      specifications: {'Protein': '21g/serving', 'Servings': '40', 'Calories': '103kcal', 'Carbs': '4.5g', 'Fat': '1.9g'},
      tags: ['whey', 'lean gains', 'grass-fed'],
    ),
    Product(
      id: 'p9', name: 'MuscleBlaze Energy Bar (6 pack)', price: 349, originalPrice: 499,
      rating: 4.4, image: 'nutrition', category: 'Nutrition', brand: 'MuscleBlaze',
      reviewCount: 2134,
      description: 'High-energy bars for sustained performance. No added sugar, natural oats base with chocolate coating.',
      specifications: {'Pack': '6 bars', 'Protein': '10g/bar', 'Calories': '160kcal', 'Carbs': '22g', 'Sugar': 'None added'},
      tags: ['energy bar', 'pre-workout', 'no added sugar'],
    ),
    Product(
      id: 'p10', name: 'Ritebite Max Protein Bar', price: 99, originalPrice: 130,
      rating: 4.3, image: 'nutrition', category: 'Nutrition', brand: 'Ritebite',
      reviewCount: 3287,
      description: 'Delicious protein bar with 20g protein. Perfect post-game recovery snack. Available in chocolate fudge.',
      specifications: {'Protein': '20g', 'Weight': '67g', 'Calories': '230kcal', 'Sugar': '5g', 'Fiber': '2g'},
      tags: ['protein bar', 'post-workout', 'recovery'],
    ),
    Product(
      id: 'p11', name: 'Unived RRUNN Energy Gels (5 pack)', price: 599, originalPrice: 799,
      rating: 4.5, image: 'nutrition', category: 'Nutrition', brand: 'Unived',
      reviewCount: 987,
      description: 'Natural energy gels for endurance sports. Maltodextrin + fructose for sustained energy release without crashes.',
      specifications: {'Pack': '5 gels', 'Carbs': '22g/gel', 'Sodium': '50mg', 'Flavor': 'Orange Mango', 'Caffeine-free': 'Yes'},
      tags: ['energy gel', 'endurance', 'natural'],
    ),
    // ── EQUIPMENT ─────────────────────────────────────────────────
    Product(
      id: 'p12', name: 'NIVIA Storm Football Size 5', price: 699, originalPrice: 999,
      rating: 4.5, image: 'equipment', category: 'Equipment', brand: 'NIVIA',
      reviewCount: 3412,
      description: 'Match-grade synthetic leather football. 32 hand-stitched panels for shape retention and consistent flight.',
      specifications: {'Size': '5', 'Material': 'Synthetic Leather', 'Panels': '32', 'Weight': '410-450g', 'Surface': 'All weather'},
      tags: ['football', 'match ball', 'size 5'],
    ),
    Product(
      id: 'p13', name: 'NIVIA Basketball Size 7', price: 899, originalPrice: 1299,
      rating: 4.6, image: 'equipment', category: 'Equipment', brand: 'NIVIA',
      reviewCount: 2678,
      description: 'Pro-grade basketball with deep channel design for enhanced grip. Consistent bounce on indoor and outdoor courts.',
      specifications: {'Size': '7', 'Circumference': '75-76cm', 'Material': 'Composite Leather', 'Surface': 'Indoor/Outdoor'},
      tags: ['basketball', 'size 7', 'composite leather'],
    ),
    Product(
      id: 'p14', name: 'Yonex Arcsaber 7 Play Racket', price: 2999, originalPrice: 4499,
      rating: 4.7, image: 'equipment', category: 'Equipment', brand: 'Yonex',
      reviewCount: 1892,
      description: 'Graphite shaft with integrated T-joint. Balanced flex for maximum repulsion power and control.',
      specifications: {'Weight': '85g ±2g', 'Flex': 'Medium', 'Frame': 'Graphite', 'Max Tension': '25 lbs', 'Balance': 'Even'},
      tags: ['badminton racket', 'graphite', 'intermediate'],
    ),
    Product(
      id: 'p15', name: 'SG KLR Xtreme Cricket Bat', price: 3499, originalPrice: 4999,
      rating: 4.6, image: 'equipment', category: 'Equipment', brand: 'SG',
      reviewCount: 1245,
      description: 'English Willow Grade 2. Ready-to-play, oil-treated. Reinforced toe and cane handle for power hitting.',
      specifications: {'Grade': 'English Willow G2', 'Handle': 'Cane', 'Weight': '1100-1200g', 'Edges': '38mm', 'Spine': '60mm'},
      tags: ['cricket bat', 'english willow', 'SG'],
    ),
    Product(
      id: 'p16', name: 'Kookaburra Cricket Balls (3 pack)', price: 799, originalPrice: 999,
      rating: 4.5, image: 'equipment', category: 'Equipment', brand: 'Kookaburra',
      reviewCount: 876,
      description: 'Practice-grade leather cricket balls with 4-piece construction. Used in club cricket across India.',
      specifications: {'Pack': '3 balls', 'Weight': '155.9-163g', 'Seam': '6-row stitched', 'Type': 'Practice/Club'},
      tags: ['cricket ball', 'leather', 'practice'],
    ),
    Product(
      id: 'p17', name: 'Cosco Cricket Batting Gloves', price: 699, originalPrice: 999,
      rating: 4.3, image: 'equipment', category: 'Equipment', brand: 'Cosco',
      reviewCount: 654,
      description: 'Reinforced palm with scatter foam knuckle protection. Breathable back for extended innings.',
      specifications: {'Size': 'Adult', 'Palm': 'PU/Rubber', 'Fingers': 'Scatter Foam', 'Wrist': 'Velcro strap'},
      tags: ['batting gloves', 'cricket', 'knuckle protection'],
    ),
    Product(
      id: 'p18', name: 'Yonex Mavis 350 Shuttlecocks (6 pack)', price: 799, originalPrice: 1099,
      rating: 4.8, image: 'equipment', category: 'Equipment', brand: 'Yonex',
      reviewCount: 5231,
      description: 'Nylon shuttlecocks with real-feather feel and consistent flight. Long-lasting for training and club play.',
      specifications: {'Pack': '6 shuttles', 'Material': 'Nylon', 'Speed': 'Medium (Yellow)', 'Grade': 'Club/Training'},
      tags: ['shuttlecock', 'nylon', 'consistent flight'],
    ),
    Product(
      id: 'p19', name: 'Wilson Pro Grip Tape (3 pack)', price: 299, originalPrice: 399,
      rating: 4.6, image: 'equipment', category: 'Equipment', brand: 'Wilson',
      reviewCount: 2134,
      description: 'Tacky feel with high moisture absorption. 110cm per tape. Fits all racket handle sizes.',
      specifications: {'Pack': '3 tapes', 'Length': '110cm each', 'Thickness': '0.6mm', 'Absorption': 'High'},
      tags: ['grip tape', 'racket', 'badminton', 'tennis'],
    ),
    Product(
      id: 'p20', name: 'Cosco Ball Pump with Needle Kit', price: 199, originalPrice: 299,
      rating: 4.2, image: 'equipment', category: 'Equipment', brand: 'Cosco',
      reviewCount: 1678,
      description: 'Dual-action pump for fast inflation. Compatible with all sports balls. Includes pressure gauge and 2 needles.',
      specifications: {'Type': 'Dual Action', 'Max PSI': '15 PSI', 'Needles': '2 included', 'Gauge': 'Built-in'},
      tags: ['ball pump', 'inflation', 'dual action'],
    ),
    // ── FOOTWEAR ──────────────────────────────────────────────────
    Product(
      id: 'p21', name: 'Nike Court Vision Low Basketball', price: 3999, originalPrice: 5999,
      rating: 4.7, image: 'footwear', category: 'Footwear', brand: 'Nike',
      reviewCount: 3421,
      description: 'Classic low-top with perforated leather upper. Waffle-pattern outsole for court traction. Sizes 6-13.',
      specifications: {'Upper': 'Perforated Leather', 'Sole': 'Rubber Waffle', 'Fit': 'True to Size', 'Sizes': 'UK 6-13'},
      tags: ['basketball shoes', 'Nike', 'low-top court'],
    ),
    Product(
      id: 'p22', name: 'Adidas Predator 24 Football Cleats', price: 3499, originalPrice: 5499,
      rating: 4.5, image: 'footwear', category: 'Footwear', brand: 'Adidas',
      reviewCount: 2187,
      description: 'Control Zone upper for enhanced ball contact. Firm ground rubber studs for natural grass play.',
      specifications: {'Upper': 'Synthetic', 'Sole': 'Firm Ground', 'Studs': 'Rubber', 'Sizes': 'UK 6-12'},
      tags: ['football cleats', 'adidas', 'firm ground'],
    ),
    Product(
      id: 'p23', name: 'Yonex Power Cushion Badminton Shoes', price: 2999, originalPrice: 4499,
      rating: 4.7, image: 'footwear', category: 'Footwear', brand: 'Yonex',
      reviewCount: 1654,
      description: 'Power Cushion+ technology for superior impact absorption. 3D Power Carbon sole for explosive lateral movement.',
      specifications: {'Upper': 'Mesh + Synthetic', 'Sole': 'Gum Rubber', 'Cushion': 'Power Cushion+', 'Sizes': 'UK 6-12'},
      tags: ['badminton shoes', 'Yonex', 'court shoes'],
    ),
    Product(
      id: 'p24', name: 'Decathlon Sports Socks (3 pack)', price: 199, originalPrice: 299,
      rating: 4.4, image: 'footwear', category: 'Footwear', brand: 'Decathlon',
      reviewCount: 7823,
      description: 'Cushioned arch compression for all-day comfort. Anti-blister terry loop construction. Machine washable.',
      specifications: {'Pack': '3 pairs', 'Material': '80% Cotton', 'Cushion': 'Full terry foot', 'Sizes': 'S / M / L / XL'},
      tags: ['sports socks', 'cushioned', 'anti-blister'],
    ),
    // ── APPAREL ───────────────────────────────────────────────────
    Product(
      id: 'p25', name: 'Jordan Dri-FIT Basketball Jersey', price: 1299, originalPrice: 1999,
      rating: 4.6, image: 'apparel', category: 'Apparel', brand: 'Jordan / Nike',
      reviewCount: 2341,
      description: 'Nike Dri-FIT technology moves sweat away fast. Mesh side panels for breathability. Classic Jordan drop.',
      specifications: {'Material': 'Polyester Dri-FIT', 'Fit': 'Regular', 'Sizes': 'XS-3XL', 'Care': 'Machine Wash Cold'},
      tags: ['basketball jersey', 'Jordan', 'Dri-FIT'],
    ),
    Product(
      id: 'p26', name: 'Cricket Performance Tee SPF50', price: 799, originalPrice: 1099,
      rating: 4.5, image: 'apparel', category: 'Apparel', brand: 'Decathlon',
      reviewCount: 1897,
      description: 'Quick-dry polyester with SPF50+ sun protection. Built for long innings in the Indian summer sun.',
      specifications: {'Material': 'Polyester', 'SPF': '50+', 'Fit': 'Regular', 'Sizes': 'S-2XL', 'Drying': 'Quick-dry'},
      tags: ['cricket tee', 'SPF protection', 'quick-dry'],
    ),
    Product(
      id: 'p27', name: 'Nike Pro Compression Tights', price: 1499, originalPrice: 2499,
      rating: 4.7, image: 'apparel', category: 'Apparel', brand: 'Nike',
      reviewCount: 3102,
      description: 'Nike Pro Dri-FIT fabric with 4-way stretch. Flatlock seams for zero irritation. Muscle stability under any kit.',
      specifications: {'Material': '85% Polyester / 15% Elastane', 'Fit': 'Tight', 'Length': 'Full', 'Sizes': 'XS-2XL'},
      tags: ['compression tights', 'Nike', 'muscle support'],
    ),
    Product(
      id: 'p28', name: 'Adidas Training Mesh Shorts', price: 599, originalPrice: 899,
      rating: 4.4, image: 'apparel', category: 'Apparel', brand: 'Adidas',
      reviewCount: 2654,
      description: 'Aeroready moisture-absorbing fabric. Side pockets, internal drawstring, 4-way stretch for full range of motion.',
      specifications: {'Material': 'Polyester Aeroready', 'Length': '7 inch', 'Pockets': '2 side + 1 back', 'Sizes': 'XS-2XL'},
      tags: ['training shorts', 'adidas', 'aeroready'],
    ),
    // ── PROTECTION ────────────────────────────────────────────────
    Product(
      id: 'p29', name: 'Tynor Knee Sleeves (pair)', price: 599, originalPrice: 899,
      rating: 4.7, image: 'protection', category: 'Protection', brand: 'Tynor',
      reviewCount: 4231,
      description: 'Medical-grade neoprene with anatomical design. Provides warmth and graduated compression for injury prevention.',
      specifications: {'Material': 'Neoprene', 'Pack': 'Pair', 'Sizes': 'S / M / L / XL', 'Compression': 'Medium', 'Thickness': '3mm'},
      tags: ['knee sleeve', 'neoprene', 'compression'],
    ),
    Product(
      id: 'p30', name: 'McDavid Ankle Support Brace', price: 449, originalPrice: 699,
      rating: 4.6, image: 'protection', category: 'Protection', brand: 'McDavid',
      reviewCount: 2876,
      description: 'Figure-8 strap system for lateral ankle stability. Open-heel design fits all footwear. Reduces re-injury risk.',
      specifications: {'Material': 'Nylon Elastic', 'Straps': 'Figure-8', 'Heel': 'Open heel', 'Size': 'One Size Fits Most'},
      tags: ['ankle brace', 'ankle support', 'lateral stability'],
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

  // ── Reviews ──────────────────────────────────────────────────

  static const _reviewPool = [
    ProductReview(id: 'r1', userName: 'Arjun S.', rating: 5.0, title: 'Excellent quality!', comment: "Been using this for 3 months and it's held up great. Exactly what I needed for my weekly basketball sessions at Game Theory.", date: '2 weeks ago', helpfulCount: 24),
    ProductReview(id: 'r2', userName: 'Priya M.', rating: 4.0, title: 'Good value for money', comment: 'Does exactly what it says. Delivery was super quick, packaging was solid. Would recommend to any sports enthusiast.', date: '1 month ago', helpfulCount: 18),
    ProductReview(id: 'r3', userName: 'Rahul K.', rating: 5.0, title: 'Game changer', comment: "This has genuinely improved my game. The quality is top-notch and it feels premium. Worth every rupee — don't hesitate.", date: '3 weeks ago', helpfulCount: 31),
    ProductReview(id: 'r4', userName: 'Sneha R.', rating: 3.0, title: 'Average, could be better', comment: "It's okay but I expected a bit more at this price. Quality is fine but nothing extraordinary. Will try the competition next time.", date: '5 days ago', helpfulCount: 7),
    ProductReview(id: 'r5', userName: 'Vikram P.', rating: 4.0, title: 'Solid purchase', comment: "Used it in 5+ games already. Durable and consistent performance. Fast delivery to Koramangala — was at my door in 25 mins.", date: '2 months ago', helpfulCount: 15),
    ProductReview(id: 'r6', userName: 'Ananya B.', rating: 5.0, title: 'Love it!', comment: "Perfect for what I need. The quality surprised me — much better than expected. Already recommended it to my entire squad.", date: '1 week ago', helpfulCount: 42),
    ProductReview(id: 'r7', userName: 'Kiran T.', rating: 4.5, title: 'Near perfect', comment: "Really satisfied with this. Minor packaging issue but the product itself is great. Would definitely buy again.", date: '3 days ago', helpfulCount: 11),
    ProductReview(id: 'r8', userName: 'Dev A.', rating: 5.0, title: 'Exactly as described', comment: "No surprises — what you see is what you get. Material quality is excellent for the sport. My go-to shop now.", date: '6 weeks ago', helpfulCount: 28),
    ProductReview(id: 'r9', userName: 'Meera N.', rating: 4.0, title: 'Good product, fast delivery', comment: 'Arrived in 28 mins as promised! Quality is great for the price. Courtside marketplace is my go-to for sports gear now.', date: '2 weeks ago', helpfulCount: 16),
    ProductReview(id: 'r10', userName: 'Rohit C.', rating: 3.5, title: 'Decent but pricey', comment: 'Product is decent. You can find alternatives at lower prices elsewhere. But the convenience of quick delivery makes it worth it.', date: '1 month ago', helpfulCount: 9),
    ProductReview(id: 'r11', userName: 'Pooja L.', rating: 5.0, title: 'Absolute must-have', comment: "Can't imagine playing without this now. The performance difference is very noticeable. Quality is genuinely top tier.", date: '4 days ago', helpfulCount: 37),
    ProductReview(id: 'r12', userName: 'Suresh G.', rating: 4.5, title: 'Highly recommend', comment: "Been buying sports gear for years and this is one of my best purchases. Durable, well-made, and looks great on court.", date: '5 weeks ago', helpfulCount: 22),
    ProductReview(id: 'r13', userName: 'Nita V.', rating: 4.0, title: 'Good for the price', comment: "Quality is on par with what you'd find at a sports store — delivered in minutes. Amazing convenience, can't complain!", date: '3 months ago', helpfulCount: 14),
    ProductReview(id: 'r14', userName: 'Aakash J.', rating: 5.0, title: 'Outstanding!', comment: "The moment I used it I knew it was worth every rupee. Premium feel, perfect for competitive play at Game Theory Koramangala.", date: '1 week ago', helpfulCount: 45),
    ProductReview(id: 'r15', userName: 'Tara S.', rating: 4.5, title: 'Really pleased', comment: "Couldn't ask for more. Quality exceeded my expectations and it arrived before my training session started. Brilliant service.", date: '2 weeks ago', helpfulCount: 19),
  ];

  static List<ProductReview> reviewsByProductId(String productId) {
    final hash = productId.codeUnits.reduce((a, b) => a + b);
    final offset = hash % (_reviewPool.length - 4);
    return _reviewPool.sublist(offset, offset + 4);
  }

  // ── Addresses ────────────────────────────────────────────────

  static final List<DeliveryAddress> addresses = [
    const DeliveryAddress(
      id: 'addr1', label: 'HOME', name: 'Shrujal Srinath',
      phone: '+91 98765 43210', street: '14, 5th Cross, 8th Main',
      area: 'Koramangala 4th Block', city: 'Bengaluru', pincode: '560034',
      isDefault: true,
    ),
    const DeliveryAddress(
      id: 'addr2', label: 'COLLEGE', name: 'Shrujal Srinath',
      phone: '+91 98765 43210', street: 'Bull Temple Road, BMSCE Campus',
      area: 'Basavanagudi', city: 'Bengaluru', pincode: '560004',
      isDefault: false,
    ),
  ];

  // ── Order history ─────────────────────────────────────────────

  static final List<ShopOrder> shopOrderHistory = [
    const ShopOrder(
      id: 'ORD-7842', status: OrderStatus.delivered,
      placedDate: '14 Apr 2026', deliveryDate: '14 Apr 2026',
      address: '14, 5th Cross, Koramangala, Bengaluru - 560034',
      total: 1627, trackingId: 'CS-TRK-78421',
      items: [
        OrderLineItem(name: 'NIVIA Basketball Size 7', quantity: 1, price: 899, category: 'Equipment'),
        OrderLineItem(name: 'Fast&Up Reload Electrolyte (20 tabs)', quantity: 2, price: 349, category: 'Hydration'),
      ],
    ),
    const ShopOrder(
      id: 'ORD-7103', status: OrderStatus.delivered,
      placedDate: '8 Apr 2026', deliveryDate: '8 Apr 2026',
      address: '14, 5th Cross, Koramangala, Bengaluru - 560034',
      total: 559, trackingId: 'CS-TRK-78103',
      items: [
        OrderLineItem(name: 'Gatorade Blue Bolt 500ml', quantity: 3, price: 120, category: 'Hydration'),
        OrderLineItem(name: 'Decathlon Sports Socks (3 pack)', quantity: 1, price: 199, category: 'Footwear'),
      ],
    ),
    const ShopOrder(
      id: 'ORD-6891', status: OrderStatus.delivered,
      placedDate: '28 Mar 2026', deliveryDate: '29 Mar 2026',
      address: '14, 5th Cross, Koramangala, Bengaluru - 560034',
      total: 4998, trackingId: 'CS-TRK-76891',
      items: [
        OrderLineItem(name: 'Yonex Arcsaber 7 Play Racket', quantity: 1, price: 2999, category: 'Equipment'),
        OrderLineItem(name: 'Yonex Mavis 350 Shuttlecocks (6 pack)', quantity: 2, price: 799, category: 'Equipment'),
        OrderLineItem(name: 'Wilson Pro Grip Tape (3 pack)', quantity: 1, price: 299, category: 'Equipment'),
      ],
    ),
  ];

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

// ═══════════════════════════════════════════════════════════════
//  SHOP ITEM
// ═══════════════════════════════════════════════════════════════

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    this.description = '',
    this.sport,
  });

  final String id;
  final String name;
  final int price;
  final String category; // 'equipment' | 'apparel' | 'accessories'
  final String icon;     // emoji fallback until real images exist
  final String description;
  final String? sport;   // null = any sport
}

// ═══════════════════════════════════════════════════════════════
//  HARDWARE OPTION
// ═══════════════════════════════════════════════════════════════

class HardwareOption {
  const HardwareOption({
    required this.id,
    required this.name,
    required this.pricePerGame,
    required this.description,
    required this.icon,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final int pricePerGame;
  final String description;
  final String icon;
  final bool isPopular;
}

// ═══════════════════════════════════════════════════════════════
//  FRIEND (for invite step)
// ═══════════════════════════════════════════════════════════════

class FriendProfile {
  const FriendProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.sport,
    required this.gamesPlayed,
    this.avatarInitials = '',
  });

  final String id;
  final String name;
  final String username;
  final String sport;
  final int gamesPlayed;
  final String avatarInitials;
}

// ═══════════════════════════════════════════════════════════════
//  SHOP + HARDWARE + FRIENDS FAKE DATA
// ═══════════════════════════════════════════════════════════════

const shopItems = <ShopItem>[
  ShopItem(id: 'si1', name: 'Basketball (Size 7)', price: 299,
    category: 'equipment', icon: '🏀', sport: 'basketball',
    description: 'Spalding rubber outdoor ball'),
  ShopItem(id: 'si2', name: 'Basketball (Premium)', price: 599,
    category: 'equipment', icon: '🏀', sport: 'basketball',
    description: 'Molten leather indoor game ball'),
  ShopItem(id: 'si3', name: 'Cricket Ball', price: 149,
    category: 'equipment', icon: '🏏', sport: 'cricket',
    description: 'SG leather practice ball'),
  ShopItem(id: 'si4', name: 'Training Bib Set (10)', price: 399,
    category: 'equipment', icon: '🦺',
    description: '10 mesh training bibs, 2 colours'),
  ShopItem(id: 'si5', name: 'Grip Socks', price: 199,
    category: 'apparel', icon: '🧦',
    description: 'Anti-slip performance socks'),
  ShopItem(id: 'si6', name: 'Wristband Pair', price: 99,
    category: 'accessories', icon: '💪',
    description: 'Sweat-absorbing cotton wristbands'),
  ShopItem(id: 'si7', name: 'Water Bottle (1L)', price: 149,
    category: 'accessories', icon: '💧',
    description: 'Stainless steel insulated bottle'),
  ShopItem(id: 'si8', name: 'Sports Tape Roll', price: 79,
    category: 'accessories', icon: '🩹',
    description: 'Rigid athletic support tape'),
];

const hardwareOptions = <HardwareOption>[
  HardwareOption(
    id: 'hw1',
    name: 'THE BOX Scorer Pro',
    pricePerGame: 99,
    description: 'Tabletop scoring device with live stats sync. Delivers player heat maps, shot charts, and full performance analysis after the game.',
    icon: '📟',
    isPopular: true,
  ),
  HardwareOption(
    id: 'hw4',
    name: 'CCTV Highlight Clip',
    pricePerGame: 49,
    description: 'Court-mounted camera captures your full game. Get a 5-minute edited highlight reel delivered to your profile post-match.',
    icon: '📷',
  ),
  HardwareOption(
    id: 'hw2',
    name: '1080p Camera Mount',
    pricePerGame: 149,
    description: 'Clip-on 1080p camera with automatic post-game highlight reel synced to your stats.',
    icon: '📹',
  ),
  HardwareOption(
    id: 'hw3',
    name: 'Scorer + Camera Bundle',
    pricePerGame: 199,
    description: 'THE BOX Scorer Pro + 1080p Camera Mount. Best value — save ₹49 vs individual rental.',
    icon: '🎬',
  ),
];

const fakeFriends = <FriendProfile>[
  FriendProfile(id: 'f1', name: 'Arjun Mehta',    username: '@arjunm',   sport: 'basketball', gamesPlayed: 31, avatarInitials: 'AM'),
  FriendProfile(id: 'f2', name: 'Priya Sharma',   username: '@priyasb',  sport: 'basketball', gamesPlayed: 18, avatarInitials: 'PS'),
  FriendProfile(id: 'f3', name: 'Karan Nair',     username: '@knair99',  sport: 'cricket',    gamesPlayed: 24, avatarInitials: 'KN'),
  FriendProfile(id: 'f4', name: 'Rohan Kapoor',   username: '@rohanK',   sport: 'basketball', gamesPlayed: 45, avatarInitials: 'RK'),
  FriendProfile(id: 'f5', name: 'Sneha Pillai',   username: '@snehap',   sport: 'badminton',  gamesPlayed: 12, avatarInitials: 'SP'),
  FriendProfile(id: 'f6', name: 'Dev Krishnan',   username: '@devkr',    sport: 'basketball', gamesPlayed: 27, avatarInitials: 'DK'),
  FriendProfile(id: 'f7', name: 'Aisha Iyer',     username: '@aishaiyr', sport: 'cricket',    gamesPlayed: 9,  avatarInitials: 'AI'),
  FriendProfile(id: 'f8', name: 'Vikram Bose',    username: '@vikramb',  sport: 'football',   gamesPlayed: 38, avatarInitials: 'VB'),
];
