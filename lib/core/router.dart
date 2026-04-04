// courtside/lib/core/router.dart
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
import '../screens/explore/explore_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/bookings/bookings_screen.dart';
import '../widgets/common/app_shell.dart';
import 'constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    redirect: (context, state) {
      if (authAsync.isLoading) return null;
      final isLoggedIn  = authAsync.asData?.value != null;
      final loc         = state.matchedLocation;
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
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, _) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, _) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, _) => const OnboardingScreen(),
      ),

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
                const NoTransitionPage(child: BookingsScreen()),
          ),
        ],
      ),

      GoRoute(path: AppRoutes.profile,     builder: (context, _) => const _Soon('Profile')),
      GoRoute(path: AppRoutes.wallet,      builder: (context, _) => const _Soon('Wallet')),
      GoRoute(path: AppRoutes.settings,    builder: (context, _) => const _Soon('Settings')),
      GoRoute(path: AppRoutes.leaderboard, builder: (context, _) => const _Soon('Leaderboard')),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class _Soon extends StatelessWidget {
  const _Soon(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(child: Text('$name — coming soon')),
      );
}