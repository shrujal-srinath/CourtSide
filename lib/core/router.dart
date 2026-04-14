// lib/core/router.dart

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/fake_data.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/landing_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/sport/sport_screen.dart';
import '../screens/venue/venue_detail_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/booking/booking_summary_screen.dart';
import '../screens/venue/venue_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/scoring/basketball/basketball_scorer.dart';
import '../screens/scoring/basketball/basketball_mode_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scoring/basketball/basketball_setup_screen.dart';
import '../screens/scoring/basketball/basketball_players_screen.dart';
import '../screens/scoring/cricket/cricket_scorer.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/marketplace/product_detail_screen.dart';
import '../screens/marketplace/cart_screen.dart';
import '../screens/marketplace/checkout_screen.dart';
import '../widgets/common/app_shell.dart';
import '../widgets/stat_share/stat_share_preview_screen.dart';
import 'constants.dart';
import 'theme.dart';
import 'app_transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final isDevAccess = ref.watch(devAccessProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    redirect: (context, state) {
      if (kDebugMode && isDevAccess) {
        final publicRoutes = [
          AppRoutes.landing,
          AppRoutes.login,
          AppRoutes.phoneAuth,
          AppRoutes.splash,
        ];
        if (publicRoutes.contains(state.matchedLocation)) {
          return AppRoutes.home;
        }
        return null;
      }
      
      if (authAsync.isLoading) return null;
      final isLoggedIn = authAsync.asData?.value != null;
      final loc = state.matchedLocation;
      if (loc == AppRoutes.splash) return null;

      final publicRoutes = [
        AppRoutes.landing,
        AppRoutes.login,
        AppRoutes.phoneAuth,
      ];
      if (publicRoutes.contains(loc)) {
        if (isLoggedIn) return AppRoutes.home;
        return null;
      }
      if (!isLoggedIn) return AppRoutes.landing;
      return null;
    },

    routes: [
      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (c, s) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (c, s) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (c, s) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (c, s) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (c, s) => const OnboardingScreen(),
      ),

      // ── Sport screen ─────────────────────────────────────────
      GoRoute(
        path: '/sport/:sportId',
        pageBuilder: (context, state) {
          final sportId = state.pathParameters['sportId'] ?? 'basketball';
          return slideUpPage(
            key: state.pageKey,
            child: SportScreen(sportId: sportId),
          );
        },
      ),

      // ── Venue detail ─────────────────────────────────────────
      GoRoute(
        path: '/venue/:venueId',
        pageBuilder: (context, state) {
          final venueId = state.pathParameters['venueId'] ?? '';
          return slideUpPage(
            key: state.pageKey,
            child: VenueDetailScreen(venueId: venueId),
          );
        },
      ),

      // ── Booking ──────────────────────────────────────────────
      GoRoute(
        path: '/book/:venueId',
        pageBuilder: (context, state) {
          final venueId = state.pathParameters['venueId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final sport = extra?['sport'] as String? ?? '';
          final venue = extra?['venue'] as Venue?;
          return slideUpPage(
            key: state.pageKey,
            child: BookingScreen(venueId: venueId, sport: sport, venue: venue),
          );
        },
      ),

      // ── Booking Summary ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.bookingSummary,
        pageBuilder: (context, state) => slideUpPage(
          key: state.pageKey,
          child: const BookingSummaryScreen(),
        ),
      ),

      // ── Stat Share ───────────────────────────────────────────
      GoRoute(
        path: '/stats/share',
        pageBuilder: (context, state) {
          return bottomSheetPage(
            key: state.pageKey,
            child: StatSharePreviewScreen(extra: state.extra),
          );
        },
      ),

      // ── Scoring ──────────────────────────────────────────────

      // Basketball flow (4 screens)
      GoRoute(
        path: AppRoutes.bballMode,
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const BasketballModeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.bballSetup,
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: BasketballSetupScreen(mode: state.extra as BballMode),
        ),
      ),
      GoRoute(
        path: AppRoutes.bballPlayers,
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: BasketballPlayersScreen(
              config: state.extra as BballGameConfig),
        ),
      ),
      GoRoute(
        path: AppRoutes.bballScorer,
        pageBuilder: (_, state) => fadeScalePage(
          key: state.pageKey,
          child: BasketballScorerScreen(
              config: state.extra as BballGameConfig),
        ),
      ),
      // Legacy redirect
      GoRoute(
        path: AppRoutes.scoreBasketball,
        redirect: (context, state) => AppRoutes.bballMode,
      ),

      GoRoute(
        path: '/score/cricket',
        pageBuilder: (_, state) => fadeScalePage(
          key: state.pageKey,
          child: const CricketScorerScreen(),
        ),
      ),

      // ── Shell with bottom nav ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.explore,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: VenueScreen()),
          ),
          GoRoute(
            path: AppRoutes.stats,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: AppRoutes.marketplace,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: MarketplaceScreen()),
          ),
        ],
      ),

      // ── Marketplace Details & Checkout ───────────────────────
      GoRoute(
        path: '/product/:productId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['productId'] ?? '';
          return slideUpPage(
            key: state.pageKey,
            child: ProductDetailScreen(productId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        pageBuilder: (context, state) => bottomSheetPage(
          key: state.pageKey,
          child: const CartScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (context, state) => slideUpPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
        ),
      ),

      // ── Bookings (Moved out of shell) ────────────────────────
      GoRoute(
        path: AppRoutes.bookings,
        pageBuilder: (context, state) => slideUpPage(
          key: state.pageKey,
          child: const MyBookingsScreen(),
        ),
      ),

      // ── Stub routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, s) =>
            slideUpPage(child: const ProfileScreen(), key: s.pageKey),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (c, s) => const _Soon('Wallet'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (c, s) => const _Soon('Settings'),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (c, s) => const _Soon('Leaderboard'),
      ),
    ],

    errorBuilder: (context, state) {
      final colors = Theme.of(context).extension<AppColorScheme>()!;
      return Scaffold(
        backgroundColor: colors.colorBackgroundPrimary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colors.colorTextTertiary),
              const SizedBox(height: 16),
              Text('Page not found',
                  style: TextStyle(
                      color: colors.colorTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(state.matchedLocation,
                  style: TextStyle(
                      color: colors.colorTextTertiary, fontSize: 12)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('Go Home',
                      style: TextStyle(
                          color: colors.colorTextOnAccent,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
});

// ── Coming soon stub ─────────────────────────────────────────────

class _Soon extends StatelessWidget {
  const _Soon(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text(name, style: TextStyle(color: colors.colorTextPrimary)),
        backgroundColor: colors.colorBackgroundPrimary,
        iconTheme: IconThemeData(color: colors.colorTextPrimary),
      ),
      body: Center(
        child: Text(
          '$name — coming soon',
          style: TextStyle(color: colors.colorTextSecondary),
        ),
      ),
    );
  }
}
