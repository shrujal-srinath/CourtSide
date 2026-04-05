// courtside/lib/core/constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName    = 'COURTSIDE';
  static const String company    = 'THE BOX';
  static const String appTagline = 'Book the Court. Own the Stats.';

  static String get supabaseUrl     => dotenv.env['SUPABASE_URL']     ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']?? '';
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

  static const String home     = '/home';
  static const String explore  = '/explore';
  static const String stats    = '/stats';
  static const String bookings = '/bookings';

  static const String profile     = '/profile';
  static const String wallet      = '/wallet';
  static const String settings    = '/settings';
  static const String leaderboard = '/leaderboard';
  static const String scoreBasketball = '/score/basketball';
  static const String scoreCricket = '/score/cricket';

  static String venueById(String id) => '/venue/$id';
  static String sportById(String id) => '/sport/$id';
  static String bookCourt(String id) => '/book/$id';
  static String gameById(String id) => '/game/$id';
  static String playerById(String id) => '/player/$id';
}