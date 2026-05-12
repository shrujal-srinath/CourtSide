// lib/models/fake_data.dart
//
// Barrel re-export for all model classes.
// Static seed data in FakeData is being phased out — do not add new call-sites.
// All screens will be migrated to real Supabase providers in Phase 1.

import 'venue.dart';
import 'court.dart';
import 'booking_record.dart';
import 'player_stat.dart';
import 'pickup_game.dart';
import 'shop_item.dart';
import 'hardware_option.dart';
import 'friend.dart';
import 'product.dart';

export 'venue.dart';
export 'court.dart';          // Court, Slot, SlotStatus
export 'booking_record.dart'; // BookingRecord, BookingStatus
export 'player_stat.dart';
export 'pickup_game.dart';
export 'product.dart';        // Product, ProductReview
export 'shop_item.dart';
export 'hardware_option.dart';
export 'friend.dart';
export 'address.dart';
export 'order.dart';          // ShopOrder, OrderLineItem, OrderStatus

// ═══════════════════════════════════════════════════════════════
//  STATIC SEED DATA — being deleted screen by screen as each
//  screen is wired to a real Supabase provider.
//  When the last call-site is removed, delete this entire section.
// ═══════════════════════════════════════════════════════════════

class FakeData {
  FakeData._();

  static const venues = [
    Venue(
      id: 'v1', name: 'Game Theory',
      address: '5th Block, Koramangala, Bengaluru', area: 'Koramangala',
      lat: 12.9310, lng: 77.6276,
      sports: ['basketball', 'badminton'], rating: 4.9, reviewCount: 312,
      closingTime: '11 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights', 'AC'],
      isIndoor: true, hasTheBox: true,
    ),
    Venue(
      id: 'v2', name: 'Game Theory',
      address: '12th Main, Indiranagar, Bengaluru', area: 'Indiranagar',
      lat: 12.9795, lng: 77.6390,
      sports: ['basketball', 'badminton'], rating: 4.8, reviewCount: 278,
      closingTime: '11 PM', photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights', 'AC'],
      isIndoor: true, hasTheBox: true,
    ),
    Venue(
      id: 'v3', name: 'Game Theory',
      address: 'Sector 6, HSR Layout, Bengaluru', area: 'HSR Layout',
      lat: 12.9150, lng: 77.6410,
      sports: ['basketball', 'badminton'], rating: 4.8, reviewCount: 195,
      closingTime: '11 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights', 'AC'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v4', name: 'Game Theory',
      address: '7th Phase, JP Nagar, Bengaluru', area: 'JP Nagar',
      lat: 12.9020, lng: 77.5866,
      sports: ['basketball', 'badminton', 'cricket'], rating: 4.9, reviewCount: 401,
      closingTime: '11 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water', 'Floodlights', 'AC'],
      isIndoor: true, hasTheBox: true,
    ),
    Venue(
      id: 'v5', name: 'Sporthood',
      address: 'Sarjapur - Marathahalli Rd, Bengaluru', area: 'Sarjapur Road',
      lat: 12.9035, lng: 77.6872,
      sports: ['basketball', 'badminton', 'football'], rating: 4.7, reviewCount: 143,
      closingTime: '11:59 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v6', name: 'Sree Kanteerava Stadium',
      address: 'Kasturba Rd, Sampangi Rama Nagar, Bengaluru', area: 'Central Bengaluru',
      lat: 12.9747, lng: 77.5838,
      sports: ['basketball', 'cricket', 'football'], rating: 4.3, reviewCount: 89,
      closingTime: '8 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water'],
      isIndoor: false, hasTheBox: false,
    ),
    Venue(
      id: 'v7', name: 'Koramangala Indoor Stadium',
      address: '80 Feet Rd, Koramangala 4th Block, Bengaluru', area: 'Koramangala',
      lat: 12.9271, lng: 77.6224,
      sports: ['basketball', 'badminton'], rating: 4.2, reviewCount: 67,
      closingTime: '9 PM', photoUrl: '',
      amenities: ['Parking', 'Water', 'Floodlights'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v8', name: 'Madhavan Park Court',
      address: 'Jayanagar 3rd Block, Bengaluru', area: 'Jayanagar',
      lat: 12.9252, lng: 77.5934,
      sports: ['basketball'], rating: 4.0, reviewCount: 34,
      closingTime: '9 PM', photoUrl: '',
      amenities: ['Water'],
      isIndoor: false, hasTheBox: false,
    ),
    Venue(
      id: 'v9', name: 'AVA Multi-Sport Court',
      address: '1st Main Rd, Abbaiah Reddy Layout, Kaggadasapura', area: 'Kaggadasapura',
      lat: 13.0079, lng: 77.6576,
      sports: ['basketball', 'badminton', 'football'], rating: 4.5, reviewCount: 112,
      closingTime: '9 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v10', name: 'Active Arena',
      address: 'Marathahalli, Bengaluru', area: 'Marathahalli',
      lat: 12.9568, lng: 77.7014,
      sports: ['basketball', 'badminton'], rating: 4.4, reviewCount: 88,
      closingTime: '10 PM', photoUrl: '',
      amenities: ['Parking', 'Changing Rooms', 'Water', 'Floodlights'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v11', name: 'Tiger 5',
      address: 'Dairy Circle, Bannerghatta Rd, Bengaluru', area: 'Bannerghatta Road',
      lat: 12.8883, lng: 77.6012,
      sports: ['basketball', 'cricket'], rating: 3.9, reviewCount: 52,
      closingTime: '10 PM', photoUrl: '',
      amenities: ['Parking', 'Water'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v12', name: 'Basecamp by Push Sports',
      address: 'Palace Road, Bengaluru City University Campus', area: 'Palace Road',
      lat: 13.0064, lng: 77.5848,
      sports: ['basketball', 'football'], rating: 4.6, reviewCount: 134,
      closingTime: '10 PM',
      photoUrl: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
      amenities: ['Parking', 'Changing Rooms', 'Cafeteria', 'Water'],
      isIndoor: true, hasTheBox: true,
    ),
    Venue(
      id: 'v13', name: 'Indiranagar Sports Club',
      address: 'Near ESI Hospital, Indiranagar', area: 'Indiranagar',
      lat: 12.9780, lng: 77.6440,
      sports: ['badminton', 'gym'], rating: 4.5, reviewCount: 210,
      closingTime: '10 PM',
      photoUrl: 'https://images.unsplash.com/photo-1626224580195-f23912418175?w=800&q=80',
      amenities: ['Parking', 'Shower', 'AC', 'Locker'],
      isIndoor: true, hasTheBox: false,
    ),
    Venue(
      id: 'v14', name: 'Whitefield Stadium',
      address: 'ITPL Main Rd, Whitefield', area: 'Whitefield',
      lat: 12.9840, lng: 77.7280,
      sports: ['cricket', 'football'], rating: 4.7, reviewCount: 540,
      closingTime: '11 PM',
      photoUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&q=80',
      amenities: ['Ample Parking', 'Floodlights', 'Medical Support'],
      isIndoor: false, hasTheBox: false,
    ),
    Venue(
      id: 'v15', name: 'Bannerghatta Sports Hub',
      address: 'Hulimavu, Bannerghatta Rd', area: 'Bannerghatta Road',
      lat: 12.8750, lng: 77.5950,
      sports: ['basketball', 'football', 'badminton'], rating: 4.4, reviewCount: 165,
      closingTime: '11 PM',
      photoUrl: 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=800&q=80',
      amenities: ['Parking', 'Floodlights', 'Water'],
      isIndoor: true, hasTheBox: true,
    ),
  ];

  static const courts = [
    Court(id: 'c1',  venueId: 'v1', sport: 'basketball', name: 'Court 1',   surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 400, slotDurationMin: 45, hasTheBox: true,  slotsAvailableToday: 5),
    Court(id: 'c1b', venueId: 'v1', sport: 'basketball', name: 'Court 2',   surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 400, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c2',  venueId: 'v1', sport: 'badminton',  name: 'Court A',   surface: 'Synthetic',       isIndoor: true,  pricePerSlot: 250, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c3',  venueId: 'v2', sport: 'basketball', name: 'Court 1',   surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 450, slotDurationMin: 45, hasTheBox: true,  slotsAvailableToday: 4),
    Court(id: 'c4',  venueId: 'v2', sport: 'badminton',  name: 'Court A',   surface: 'Synthetic',       isIndoor: true,  pricePerSlot: 280, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 6),
    Court(id: 'c5',  venueId: 'v3', sport: 'basketball', name: 'Court 1',   surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 400, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 7),
    Court(id: 'c6',  venueId: 'v4', sport: 'basketball', name: 'Court 1',   surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 380, slotDurationMin: 45, hasTheBox: true,  slotsAvailableToday: 8),
    Court(id: 'c7',  venueId: 'v4', sport: 'cricket',    name: 'Turf A',    surface: 'Artificial Turf', isIndoor: true,  pricePerSlot: 600, slotDurationMin: 60, hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c8',  venueId: 'v5', sport: 'basketball', name: 'Full Court',surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 500, slotDurationMin: 60, hasTheBox: false, slotsAvailableToday: 4),
    Court(id: 'c9',  venueId: 'v5', sport: 'football',   name: 'Turf A',    surface: 'Artificial Turf', isIndoor: true,  pricePerSlot: 800, slotDurationMin: 60, hasTheBox: false, slotsAvailableToday: 2),
    Court(id: 'c10', venueId: 'v6', sport: 'basketball', name: 'Court 1',   surface: 'Concrete',        isIndoor: false, pricePerSlot: 200, slotDurationMin: 60, hasTheBox: false, slotsAvailableToday: 2),
    Court(id: 'c11', venueId: 'v7', sport: 'basketball', name: 'Court 1',   surface: 'Concrete',        isIndoor: true,  pricePerSlot: 300, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c12', venueId: 'v8', sport: 'basketball', name: 'Outdoor Court', surface: 'Concrete',    isIndoor: false, pricePerSlot: 0,   slotDurationMin: 60, hasTheBox: false, slotsAvailableToday: 10),
    Court(id: 'c13', venueId: 'v9', sport: 'basketball', name: 'Court 1',   surface: 'Rubber',          isIndoor: true,  pricePerSlot: 350, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 5),
    Court(id: 'c14', venueId: 'v10', sport: 'basketball', name: 'Court 1',  surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 420, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 3),
    Court(id: 'c15', venueId: 'v11', sport: 'basketball', name: 'Court 1',  surface: 'Rubber',          isIndoor: true,  pricePerSlot: 300, slotDurationMin: 45, hasTheBox: false, slotsAvailableToday: 4),
    Court(id: 'c16', venueId: 'v12', sport: 'basketball', name: 'Court 1',  surface: 'Hardwood',        isIndoor: true,  pricePerSlot: 450, slotDurationMin: 45, hasTheBox: true,  slotsAvailableToday: 6),
  ];

  static const slotsC1 = [
    Slot(id: 's1',  courtId: 'c1', startTime: '6:00 AM',  endTime: '6:45 AM',  status: SlotStatus.available),
    Slot(id: 's2',  courtId: 'c1', startTime: '7:00 AM',  endTime: '7:45 AM',  status: SlotStatus.booked),
    Slot(id: 's3',  courtId: 'c1', startTime: '8:00 AM',  endTime: '8:45 AM',  status: SlotStatus.booked),
    Slot(id: 's4',  courtId: 'c1', startTime: '9:00 AM',  endTime: '9:45 AM',  status: SlotStatus.available),
    Slot(id: 's5',  courtId: 'c1', startTime: '10:00 AM', endTime: '10:45 AM', status: SlotStatus.available),
    Slot(id: 's6',  courtId: 'c1', startTime: '5:00 PM',  endTime: '5:45 PM',  status: SlotStatus.available),
    Slot(id: 's7',  courtId: 'c1', startTime: '6:00 PM',  endTime: '6:45 PM',  status: SlotStatus.booked),
    Slot(id: 's8',  courtId: 'c1', startTime: '7:00 PM',  endTime: '7:45 PM',  status: SlotStatus.available),
    Slot(id: 's9',  courtId: 'c1', startTime: '8:00 PM',  endTime: '8:45 PM',  status: SlotStatus.blocked),
    Slot(id: 's10', courtId: 'c1', startTime: '9:00 PM',  endTime: '9:45 PM',  status: SlotStatus.available),
  ];

  static const pickupGames = [
    PickupGame(id: 'p1', venueId: 'v1',  venueName: 'Game Theory Koramangala', sport: 'basketball', title: '3v3 Pickup',    time: '5:00 PM', spotsTotal: 6,  spotsFilled: 4),
    PickupGame(id: 'p2', venueId: 'v4',  venueName: 'Game Theory JP Nagar',    sport: 'basketball', title: 'Full Court Run', time: '7:00 PM', spotsTotal: 10, spotsFilled: 9),
    PickupGame(id: 'p3', venueId: 'v12', venueName: 'Basecamp by Push Sports', sport: 'basketball', title: '5v5 Open Run',  time: '6:00 PM', spotsTotal: 10, spotsFilled: 7),
  ];

  static final List<BookingRecord> bookingHistory = [
    const BookingRecord(id: 'b1', venueName: 'Game Theory Koramangala', sport: 'basketball', date: 'Today',     timeSlot: '7:00 PM', amount: 400, status: BookingStatus.upcoming,   hasStats: false),
    const BookingRecord(id: 'b2', venueName: 'Sporthood',               sport: 'basketball', date: 'Yesterday', timeSlot: '5:00 PM', amount: 500, status: BookingStatus.completed,  hasStats: true),
    const BookingRecord(id: 'b3', venueName: 'Game Theory Indiranagar',  sport: 'basketball', date: '2 days ago',timeSlot: '8:00 AM', amount: 450, status: BookingStatus.completed,  hasStats: true),
    const BookingRecord(id: 'b4', venueName: 'Koramangala Indoor Stadium',sport: 'basketball',date: '5 days ago',timeSlot: '6:00 PM', amount: 300, status: BookingStatus.cancelled,  hasStats: false),
  ];

  static const playerStats = [
    PlayerGameStat(sport: 'basketball', gamesPlayed: 24, wins: 16, stats: {
      'ppg': 18.4, 'rpg': 6.2, 'apg': 4.1, 'spg': 1.8, 'fg_pct': 0.48, 'three_pct': 0.38,
    }),
    PlayerGameStat(sport: 'cricket', gamesPlayed: 12, wins: 8, stats: {
      'batting_avg': 34.5, 'highest_score': 67, 'wickets': 18, 'economy': 6.4, 'strike_rate': 112.3,
    }),
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

  static void completeBooking(String? bookingId) {
    // TODO(phase-2): replace with record_game_result RPC call.
    // This no-ops intentionally — real stat persistence comes in Phase 2.
  }

  // parseBookingTime moved to lib/core/time_utils.dart — forwarded for compat.
  static DateTime? parseBookingTime(String dateStr, String timeSlot) {
    // ignore: prefer_const_constructors — kept for call-site compat during migration
    from(dateStr, timeSlot);
    return _parseBookingTimeImpl(dateStr, timeSlot);
  }

  static DateTime? _parseBookingTimeImpl(String dateStr, String timeSlot) {
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
        final days = int.parse(cleanDate.split(' ')[0]);
        final ago = now.subtract(Duration(days: days));
        cleanDate = '${ago.day} ${months[ago.month - 1]}';
      }
      final dateParts = cleanDate.split(' ');
      if (dateParts.length < 2) return null;
      final day = int.parse(dateParts[0]);
      final month = months.indexWhere((m) => dateParts[1].startsWith(m)) + 1;
      if (month == 0) return null;
      final timeParts = timeSlot.split(' - ');
      final parts = timeParts[0].trim().split(' ');
      if (parts.length < 2) return null;
      final hhmm = parts[0].split(':');
      int h = int.parse(hhmm[0]);
      final m = hhmm.length > 1 ? int.parse(hhmm[1]) : 0;
      if (parts[1].toUpperCase() == 'PM' && h != 12) h += 12;
      if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
      return DateTime(now.year, month, day, h, m);
    } catch (_) {
      return null;
    }
  }
}

// ── Top-level constants (used by booking + hardware screens) ──────

const shopItems = <ShopItem>[
  ShopItem(id: 'si1', name: 'Basketball (Size 7)',  price: 299, category: 'equipment',  icon: '🏀', sport: 'basketball', description: 'Spalding rubber outdoor ball'),
  ShopItem(id: 'si2', name: 'Basketball (Premium)', price: 599, category: 'equipment',  icon: '🏀', sport: 'basketball', description: 'Molten leather indoor game ball'),
  ShopItem(id: 'si3', name: 'Cricket Ball',         price: 149, category: 'equipment',  icon: '🏏', sport: 'cricket',    description: 'SG leather practice ball'),
  ShopItem(id: 'si4', name: 'Training Bib Set (10)',price: 399, category: 'equipment',  icon: '🦺', description: '10 mesh training bibs, 2 colours'),
  ShopItem(id: 'si5', name: 'Grip Socks',           price: 199, category: 'apparel',    icon: '🧦', description: 'Anti-slip performance socks'),
  ShopItem(id: 'si6', name: 'Wristband Pair',       price: 99,  category: 'accessories',icon: '💪', description: 'Sweat-absorbing cotton wristbands'),
  ShopItem(id: 'si7', name: 'Water Bottle (1L)',    price: 149, category: 'accessories',icon: '💧', description: 'Stainless steel insulated bottle'),
  ShopItem(id: 'si8', name: 'Sports Tape Roll',     price: 79,  category: 'accessories',icon: '🩹', description: 'Rigid athletic support tape'),
];

const hardwareOptions = <HardwareOption>[
  HardwareOption(id: 'hw1', name: 'THE BOX Scorer Pro',       pricePerGame: 99,  icon: '📟', isPopular: true,  description: 'Tabletop scoring device with live stats sync. Delivers player heat maps, shot charts, and full performance analysis after the game.'),
  HardwareOption(id: 'hw4', name: 'CCTV Highlight Clip',       pricePerGame: 49,  icon: '📷', description: 'Court-mounted camera captures your full game. Get a 5-minute edited highlight reel delivered to your profile post-match.'),
  HardwareOption(id: 'hw2', name: '1080p Camera Mount',        pricePerGame: 149, icon: '📹', description: 'Clip-on 1080p camera with automatic post-game highlight reel synced to your stats.'),
  HardwareOption(id: 'hw3', name: 'Scorer + Camera Bundle',    pricePerGame: 199, icon: '🎬', isBundle: true, originalPrice: 248, description: 'THE BOX Scorer Pro + 1080p Camera Mount. Best value — save ₹49 vs individual rental.'),
];

const fakeFriends = <FriendProfile>[
  FriendProfile(id: 'f1', name: 'Arjun Mehta',  username: '@arjunm',   sport: 'basketball', gamesPlayed: 31, avatarInitials: 'AM'),
  FriendProfile(id: 'f2', name: 'Priya Sharma', username: '@priyasb',  sport: 'basketball', gamesPlayed: 18, avatarInitials: 'PS'),
  FriendProfile(id: 'f3', name: 'Karan Nair',   username: '@knair99',  sport: 'cricket',    gamesPlayed: 24, avatarInitials: 'KN'),
  FriendProfile(id: 'f4', name: 'Rohan Kapoor', username: '@rohanK',   sport: 'basketball', gamesPlayed: 45, avatarInitials: 'RK'),
  FriendProfile(id: 'f5', name: 'Sneha Pillai', username: '@snehap',   sport: 'badminton',  gamesPlayed: 12, avatarInitials: 'SP'),
  FriendProfile(id: 'f6', name: 'Dev Krishnan', username: '@devkr',    sport: 'basketball', gamesPlayed: 27, avatarInitials: 'DK'),
  FriendProfile(id: 'f7', name: 'Aisha Iyer',   username: '@aishaiyr', sport: 'cricket',    gamesPlayed: 9,  avatarInitials: 'AI'),
  FriendProfile(id: 'f8', name: 'Vikram Bose',  username: '@vikramb',  sport: 'football',   gamesPlayed: 38, avatarInitials: 'VB'),
];

// ignore: unused_element
void from(String a, String b) {} // stub to avoid dead-code warnings during migration
