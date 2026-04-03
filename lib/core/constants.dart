// ═══════════════════════════════════════════════════════════════
//  APP CONSTANTS
// ═══════════════════════════════════════════════════════════════

class AppConstants {
  AppConstants._();

  static const String appName    = 'THE BOX';
  static const String appTagline = 'Your stats. Your story.';

  // Supabase — replace with your actual keys
  static const String supabaseUrl    = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Sports
  static const String sportBasketball = 'basketball';
  static const String sportCricket    = 'cricket';

  // SharedPreferences keys
  static const String prefThemeMode   = 'theme_mode';  // 'dark' | 'light' | 'system'
  static const String prefOnboarded   = 'onboarded';

  // Pagination
  static const int pageSize = 20;
}

// ═══════════════════════════════════════════════════════════════
//  ROUTE PATHS — single source of truth for GoRouter
// ═══════════════════════════════════════════════════════════════

class AppRoutes {
  AppRoutes._();

  static const String splash    = '/';
  static const String login     = '/login';
  static const String register  = '/register';

  // Main shell (bottom nav)
  static const String home      = '/home';
  static const String explore   = '/explore';
  static const String stats     = '/stats';
  static const String bookings  = '/bookings';

  // Detail screens
  static const String venue     = '/venue/:id';
  static const String bookSlot  = '/book/:venueId';
  static const String profile   = '/profile';
  static const String wallet    = '/wallet';
  static const String settings  = '/settings';
  static const String gameDetail= '/game/:id';
  static const String playerProfile = '/player/:id';
  static const String leaderboard   = '/leaderboard';
  static const String achievements  = '/achievements';

  // helpers — build typed paths
  static String venueById(String id)       => '/venue/$id';
  static String bookVenue(String venueId)  => '/book/$venueId';
  static String gameById(String id)        => '/game/$id';
  static String playerById(String id)      => '/player/$id';
}