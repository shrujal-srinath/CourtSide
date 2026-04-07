// lib/core/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../screens/explore/explore_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/bookings/my_bookings_screen.dart';
import '../screens/scoring/basketball/basketball_scorer.dart';
import '../screens/scoring/basketball/basketball_mode_screen.dart';
import '../screens/scoring/basketball/basketball_setup_screen.dart';
import '../screens/scoring/basketball/basketball_players_screen.dart';
import '../screens/scoring/cricket/cricket_scorer.dart';
import '../widgets/common/app_shell.dart';
import '../widgets/stat_share/stat_share_preview_screen.dart';
import 'constants.dart';
import 'theme.dart';
import 'app_transitions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    redirect: (context, state) {
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
        path: '/book/:courtId',
        pageBuilder: (context, state) {
          final courtId = state.pathParameters['courtId'] ?? '';
          return bottomSheetPage(
            key: state.pageKey,
            child: BookingScreen(courtId: courtId),
          );
        },
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
                const NoTransitionPage(child: ExploreScreen()),
          ),
          GoRoute(
            path: AppRoutes.stats,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            pageBuilder: (context, _) =>
                const NoTransitionPage(child: MyBookingsScreen()),
          ),
        ],
      ),

      // ── Stub routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, s) => const _Soon('Profile'),
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

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Text(
          'Page not found',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    ),
  );
});

// ── Coming soon stub ─────────────────────────────────────────────

class _Soon extends StatelessWidget {
  const _Soon(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(name, style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Center(
        child: Text(
          '$name — coming soon',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }
}
