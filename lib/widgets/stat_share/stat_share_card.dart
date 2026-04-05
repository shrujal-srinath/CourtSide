// lib/widgets/stat_share/stat_share_card.dart

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatShareCard extends StatelessWidget {
  const StatShareCard({
    super.key,
    required this.playerName,
    required this.sport,
    required this.gameDate,
    required this.venueName,
    required this.stats,
    required this.isExporting,
  });

  final String playerName;
  final String sport;
  final String gameDate;
  final String venueName;
  final Map<String, String> stats;
  /// When true: renders static (no animations) for RepaintBoundary capture.
  /// When false: animated entrance for in-app preview.
  final bool isExporting;

  Color get _sportColor {
    switch (sport.toLowerCase()) {
      case 'basketball': return AppColors.basketball;
      case 'cricket': return AppColors.cricket;
      default: return AppColors.red;
    }
  }

  String get _sportEmoji {
    switch (sport.toLowerCase()) {
      case 'basketball': return '🏀';
      case 'cricket': return '🏏';
      case 'badminton': return '🏸';
      default: return '⚽';
    }
  }

  Widget _wrap(Widget child, {int delay = 0}) {
    if (isExporting) return child;
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 400),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _sportColor;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D14), Color(0xFF1A0005)],
          ),
        ),
        child: Stack(
          children: [
            // Sport accent radial glow — top right
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom left subtle glow
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x33E8112D), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Wordmark
                  _wrap(
                    Row(
                      children: [
                        Text(
                          'COURTSIDE',
                          style: AppTextStyles.overline(AppColors.red),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 2. Player name
                  _wrap(
                    Text(
                      playerName,
                      style: AppTextStyles.displayL(AppColors.white),
                    ),
                    delay: 100,
                  ),

                  const SizedBox(height: 8),

                  // 3. Sport + date
                  _wrap(
                    Row(
                      children: [
                        Text(_sportEmoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          sport[0].toUpperCase() + sport.substring(1),
                          style: AppTextStyles.headingS(
                              AppColors.textSecondaryDark),
                        ),
                        const Spacer(),
                        Text(
                          gameDate,
                          style: AppTextStyles.bodyS(
                              AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                    delay: 150,
                  ),

                  const SizedBox(height: 6),

                  // 4. Venue
                  _wrap(
                    Text(
                      venueName,
                      style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
                    ),
                    delay: 180,
                  ),

                  const SizedBox(height: 40),

                  // 5. Stats grid
                  _wrap(
                    _ShareStatsGrid(stats: stats, sport: sport),
                    delay: 280,
                  ),

                  const Spacer(),

                  // 6. Bottom brand bar
                  _wrap(
                    Column(
                      children: [
                        Container(
                          height: 1.5,
                          color: AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'courtsideapp.in',
                              style: AppTextStyles.labelS(
                                  AppColors.textTertiaryDark),
                            ),
                            Text(
                              '#PlayMore',
                              style: AppTextStyles.labelS(
                                  AppColors.textTertiaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                    delay: 350,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Grid ─────────────────────────────────────────────────

class _ShareStatsGrid extends StatelessWidget {
  const _ShareStatsGrid({required this.stats, required this.sport});
  final Map<String, String> stats;
  final String sport;

  List<MapEntry<String, String>> _statEntries() {
    if (sport.toLowerCase() == 'basketball') {
      return [
        MapEntry('PPG', stats['ppg'] ?? '—'),
        MapEntry('REB', stats['rpg'] ?? '—'),
        MapEntry('AST', stats['apg'] ?? '—'),
        MapEntry('FG%', stats['fg_pct'] ?? '—'),
      ];
    } else {
      // cricket
      return [
        MapEntry('RUNS', stats['batting_avg'] ?? '—'),
        MapEntry('SR', stats['strike_rate'] ?? '—'),
        MapEntry('WKT', stats['wickets'] ?? '—'),
        MapEntry('ECO', stats['economy'] ?? '—'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _statEntries();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: entries.map((e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              e.value,
              style: AppTextStyles.statXL(AppColors.white),
            ),
            const SizedBox(height: 4),
            Text(
              e.key,
              style: AppTextStyles.overline(AppColors.textSecondaryDark),
            ),
          ],
        );
      }).toList(),
    );
  }
}
