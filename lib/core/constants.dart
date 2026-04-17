// courtside/lib/core/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName    = 'COURTSIDE';
  static const String company    = 'THE BOX';
  static const String appTagline = 'Book the Court. Own the Stats.';

  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    if (url.isEmpty) {
      throw Exception('SUPABASE_URL not set in .env file');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not set in .env file');
    }
    return key;
  }

  static const String redirectUrl = 'com.courtside.app://login-callback';

  static const String sportBasketball = 'basketball';
  static const String sportCricket    = 'cricket';

  static const String prefThemeMode = 'theme_mode';
  static const String prefOnboarded = 'onboarded';
  static const int    pageSize      = 20;
}

class AppRoutes {
  AppRoutes._();

  static const String splash     = '/';
  static const String landing    = '/landing';
  static const String login      = '/login';
  static const String phoneAuth  = '/phone-auth';
  static const String onboarding = '/onboarding';

  static const String modeGate = '/mode-gate';

  static const String home     = '/home';
  static const String explore  = '/explore';

  // ── Play shell ────────────────────────────────────────────────
  static const String playHome     = '/play';
  static const String playBookings = '/play/bookings';
  static const String hostGame     = '/host-game';
  static const String stats    = '/stats';
  static const String bookings = '/bookings';

  static const String profile     = '/profile';
  static const String marketplace = '/marketplace';
  static const String cart        = '/cart';
  static const String bookingSummary = '/booking-summary';
  static const String checkout    = '/checkout';
  static String productDetail(String id) => '/product/$id';

  static const String wallet      = '/wallet';
  static const String settings    = '/settings';
  static const String leaderboard = '/leaderboard';
  static const String scoreBasketball = '/score/basketball';
  static const String scoreCricket = '/score/cricket';

  // Basketball flow
  static const String bballMode    = '/score/basketball/mode';
  static const String bballSetup   = '/score/basketball/setup';
  static const String bballPlayers = '/score/basketball/players';
  static const String bballScorer  = '/score/basketball/game';

  static String venueById(String id)   => '/venue/$id';
  static String sportById(String id)   => '/sport/$id';
  static String bookCourt(String id)   => '/book/$id';
  static String bookVenue(String id)   => '/book/$id';
  static String bookInvite(String id)  => '/book/$id/invite';
  static String bookShop(String id)    => '/book/$id/shop';
  static String bookHardware(String id)=> '/book/$id/hardware';
  static String bookCart(String id)    => '/book/$id/cart';
  static String gameById(String id)    => '/game/$id';
  static String playerById(String id)  => '/player/$id';
}