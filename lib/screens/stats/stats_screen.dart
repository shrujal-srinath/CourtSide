// lib/screens/stats/stats_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/sport_visuals.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../models/completed_game.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/common/cs_empty_state.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with TickerProviderStateMixin {
  int _activeSportIdx = 0;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );
    _ringAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic),
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _changeSport(int i) {
    setState(() => _activeSportIdx = i);
    _ringController.reset();
    _ringController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final colors     = context.colors;
    final topPad     = MediaQuery.of(context).padding.top;
    final user       = ref.watch(currentUserProvider);
    final name       = user?.userMetadata?['full_name'] as String? ?? 'Player';
    final statsAsync = ref.watch(myStatsProvider);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      floatingActionButton: statsAsync.maybeWhen(
        data: (stats) {
          if (stats.isEmpty) return null;
          final activeStat = stats[_activeSportIdx.clamp(0, stats.length - 1)];
          return FloatingActionButton.extended(
            onPressed: () => context.push('/stats/share', extra: activeStat),
            backgroundColor: colors.colorAccentPrimary,
            icon: Icon(Icons.ios_share_rounded,
                color: colors.colorTextOnAccent, size: 18),
            label: Text(
              'Share Stats',
              style: AppTextStyles.labelM(colors.colorTextOnAccent),
            ),
            elevation: 0,
          );
        },
        orElse: () => null,
      ),
      body: statsAsync.when(
        loading: () => _StatsStateScaffold(
          topPad: topPad,
          child: Center(
            child: CircularProgressIndicator(
                color: colors.colorAccentPrimary, strokeWidth: 2.5),
          ),
        ),
        error: (_, _) => _StatsStateScaffold(
          topPad: topPad,
          child: CsErrorState(
            message: "Couldn't load your stats.",
            onRetry: () => ref.invalidate(myStatsProvider),
          ),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return _StatsStateScaffold(
              topPad: topPad,
              child: const CsEmptyState(
                icon: Icons.sports_basketball_rounded,
                title: 'No verified stats yet',
                subtitle:
                    'Play a phone-scored game during a booking and your stats land here automatically.',
              ),
            );
          }
          final idx        = _activeSportIdx.clamp(0, stats.length - 1);
          final activeStat = stats[idx];
          final games = (ref.watch(myGamesProvider).valueOrNull ?? const [])
              .where((g) => g.sport == activeStat.sport)
              .toList();
          final streak = _winStreak(games);

          return _buildContent(
            context, colors, topPad, name, stats, idx, activeStat, games, streak);
        },
      ),
    );
  }

  /// Consecutive wins counting back from the most recent game.
  int _winStreak(List<CompletedGame> games) {
    var n = 0;
    for (final g in games) {
      if (g.won) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  Widget _buildContent(
    BuildContext context,
    AppColorScheme colors,
    double topPad,
    String name,
    List<PlayerGameStat> stats,
    int idx,
    PlayerGameStat activeStat,
    List<CompletedGame> games,
    int streak,
  ) {
    return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad + AppSpacing.sm)),

          // ── Profile Hero Banner ──────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeroBanner(name: name, stats: stats),
          ),

          // ── Win Rate Ring ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xxl,
                  AppSpacing.lg, AppSpacing.sm),
              child: _WinRateRing(
                winRate: activeStat.winRate,
                animation: _ringAnimation,
              ),
            ),
          ),

          // ── Sport Segmented Control ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl,
                  AppSpacing.lg, 0),
              child: _SportSegmentedControl(
                stats: stats,
                activeIdx: idx,
                onChanged: _changeSport,
              ),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl)),

          // ── Stat Grid ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: _StatGrid(stat: activeStat),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl)),

          // ── Performance section header ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Text(
                'PERFORMANCE',
                style: AppTextStyles.overline(colors.colorTextTertiary),
              ),
            ),
          ),

          // ── Performance Stats Card ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: _PerformanceStatsCard(stat: activeStat),
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl)),

          // ── Career Timeline ──────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Text(
                    'CAREER TIMELINE',
                    style:
                        AppTextStyles.overline(colors.colorTextTertiary),
                  ),
                ),
                _CareerTimeline(
                  games: games,
                  sport: activeStat.sport,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl)),

          // ── Streak Card (hidden until a real win streak exists) ──
          if (streak >= 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: _StreakCard(streak: streak),
              ),
            ),
          if (streak >= 2)
            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl)),

          // ── Recent Games header ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Text(
                'RECENT GAMES',
                style: AppTextStyles.overline(colors.colorTextTertiary),
              ),
            ),
          ),

          // ── Recent Games list ────────────────────────────────
          if (games.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Text('No games yet',
                    style: AppTextStyles.bodyM(colors.colorTextSecondary)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i >= games.length) return null;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm + 2),
                    child: _RecentGameCard(
                      game: games[i],
                      onShare: () => context.push(
                          '/stats/share',
                          extra: activeStat),
                    ),
                  );
                },
                childCount: games.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
  }
}

// ── Profile Hero Banner ────────────────────────────────────────

class _ProfileHeroBanner extends StatelessWidget {
  const _ProfileHeroBanner({required this.name, required this.stats});
  final String name;
  final List<PlayerGameStat> stats;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 200,
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        boxShadow: AppShadow.card,
      ),
      child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.colorAccentSubtle,
                        border: Border.all(
                            color: colors.colorAccentPrimary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: AppTextStyles.displayM(
                              colors.colorAccentPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            name,
                            style: AppTextStyles.displayS(
                                    colors.colorTextPrimary)
                                .copyWith(letterSpacing: -0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          // THE BOX VERIFIED badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: colors.colorAccentSubtle,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                  color: colors.colorAccentPrimary
                                      .withValues(alpha: 0.4),
                                  width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 12,
                                    color: colors.colorAccentPrimary),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'THE BOX VERIFIED',
                                  style: AppTextStyles.overline(
                                      colors.colorAccentPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Sport badges
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stats.map((s) {
                      final color = _sportColor(s.sport, colors);
                      return Container(
                        margin:
                            const EdgeInsets.only(right: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: AppSpacing.xs + 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sportIcon(s.sport), size: 13, color: color),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _capitalize(s.sport),
                              style: AppTextStyles.labelS(color),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Color _sportColor(String sport, AppColorScheme colors) {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      default:           return colors.colorSportFootball;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Win Rate Ring ──────────────────────────────────────────────

class _WinRateRing extends StatelessWidget {
  const _WinRateRing({
    required this.winRate,
    required this.animation,
  });
  final double winRate;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct    = (winRate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: animation.value * winRate,
                    trackColor: colors.colorSurfaceElevated,
                    arcColor: colors.colorAccentPrimary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: AppTextStyles.statL(
                              colors.colorTextPrimary),
                        ),
                        Text(
                          'WIN RATE',
                          style: AppTextStyles.overline(
                              colors.colorTextTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xxl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Rating',
                    style: AppTextStyles.headingS(
                        colors.colorTextSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  winRate >= 0.7
                      ? 'Elite'
                      : winRate >= 0.5
                          ? 'Good'
                          : 'Developing',
                  style: AppTextStyles.displayS(colors.colorTextPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  winRate >= 0.7
                      ? 'Top tier performance. Keep dominating.'
                      : 'Keep playing to improve your record.',
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 9.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Sport Segmented Control ────────────────────────────────────

class _SportSegmentedControl extends StatelessWidget {
  const _SportSegmentedControl({
    required this.stats,
    required this.activeIdx,
    required this.onChanged,
  });

  final List<PlayerGameStat> stats;
  final int activeIdx;
  final ValueChanged<int> onChanged;


  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Stack(
        children: [
          // Sliding active pill
          AnimatedPositioned(
            duration: AppDuration.fast,
            curve: Curves.easeInOutCubic,
            left: activeIdx *
                (MediaQuery.of(context).size.width - 36) /
                stats.length,
            top: 4,
            bottom: 4,
            width: (MediaQuery.of(context).size.width - 36) /
                stats.length,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          // Tab labels
          Row(
            children: List.generate(stats.length, (i) {
              final active = i == activeIdx;
              final s = stats[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sportIcon(s.sport),
                            size: 15,
                            color: active
                                ? colors.colorTextOnAccent
                                : colors.colorTextSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _capitalize(s.sport),
                          style: AppTextStyles.labelM(
                            active
                                ? colors.colorTextOnAccent
                                : colors.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Stat Grid ─────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stat});
  final PlayerGameStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(value: '${stat.gamesPlayed}', label: 'GAMES'),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _StatCell(
              value: '${stat.wins}', label: 'WINS', accent: true),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: _StatCell(
            value: '${(stat.winRate * 100).toStringAsFixed(0)}%',
            label: 'WIN RATE',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent
            ? colors.colorAccentSubtle
            : colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: accent
              ? colors.colorAccentPrimary.withValues(alpha: 0.3)
              : colors.colorBorderSubtle,
          width: 0.5,
        ),
        boxShadow: accent ? [] : AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.statL(
              accent
                  ? colors.colorAccentPrimary
                  : colors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Performance Stats Card ─────────────────────────────────────

class _PerformanceStatsCard extends StatelessWidget {
  const _PerformanceStatsCard({required this.stat});
  final PlayerGameStat stat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows   = _buildRows(stat);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm + 2,
        mainAxisSpacing: AppSpacing.sm + 2,
        childAspectRatio: 1.6,
      ),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
                color: colors.colorBorderSubtle, width: 0.5),
            boxShadow: AppShadow.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                row.value,
                style: AppTextStyles.statM(colors.colorTextPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                row.key.toUpperCase(),
                style:
                    AppTextStyles.overline(colors.colorTextTertiary),
              ),
            ],
          ),
        );
      },
    );
  }

  List<MapEntry<String, String>> _buildRows(PlayerGameStat s) {
    // player_stats.stats holds cumulative TOTALS; derive per-game averages.
    final gp = s.gamesPlayed;
    String avg(String key) {
      final total = (s.stats[key] as num?)?.toDouble() ?? 0;
      return gp == 0 ? '0.0' : (total / gp).toStringAsFixed(1);
    }

    if (s.sport == 'basketball') {
      return [
        MapEntry('Points / game', avg('points')),
        MapEntry('Rebounds / game', avg('rebounds')),
        MapEntry('Assists / game', avg('assists')),
        MapEntry('Steals / game', avg('steals')),
        MapEntry('Blocks / game', avg('blocks')),
        MapEntry('Turnovers / game', avg('turnovers')),
      ];
    } else if (s.sport == 'cricket') {
      return [
        MapEntry('Runs / game', avg('runs')),
        MapEntry('Wickets / game', avg('wickets')),
      ];
    }
    return [];
  }
}

// ── Career Timeline ────────────────────────────────────────────

class _CareerTimeline extends StatelessWidget {
  const _CareerTimeline({required this.games, required this.sport});
  final List<CompletedGame> games;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (games.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text('No games yet',
            style: AppTextStyles.bodyM(colors.colorTextSecondary)),
      );
    }
    // Timeline reads oldest → newest left-to-right (games arrive newest first).
    final ordered = games.reversed.toList();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: ordered.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpacing.sm + 2),
        itemBuilder: (_, i) {
          final b    = ordered[i];
          final isWin = b.won;
          return Container(
            width: 80,
            decoration: BoxDecoration(
              color: colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isWin
                    ? colors.colorSuccess.withValues(alpha: 0.3)
                    : colors.colorError.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(sportIcon(sport),
                    size: 20, color: sportColor(colors, sport)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWin
                        ? colors.colorSuccess
                        : colors.colorError,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _shortDate(b.playedAt),
                  style: AppTextStyles.overline(
                      colors.colorTextTertiary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Streak Card ────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.colorWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: colors.colorWarning.withValues(alpha: 0.2),
            width: 0.5),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 30, color: colors.colorWarning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak-Game Win Streak',
                  style: AppTextStyles.displayS(colors.colorTextPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Won your last $streak games. Keep it alive.',
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: List.generate(streak.clamp(0, 10), (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.colorWarning.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent Game Card ───────────────────────────────────────────

class _RecentGameCard extends StatelessWidget {
  const _RecentGameCard({required this.game, required this.onShare});
  final CompletedGame game;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color  = _sportColor(game.sport, colors);
    final resultColor = game.won ? colors.colorSuccess : colors.colorError;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
            color: colors.colorBorderSubtle, width: 0.5),
        boxShadow: AppShadow.card,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left sport color bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Sport icon
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(sportIcon(game.sport), size: 18, color: color),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // W / L badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 1),
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            game.won ? 'W' : 'L',
                            style: AppTextStyles.labelS(resultColor),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          game.scoreline,
                          style: AppTextStyles.headingS(colors.colorTextPrimary)
                              .copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      game.venueName == null
                          ? _shortDate(game.playedAt)
                          : '${game.venueName} · ${_shortDate(game.playedAt)}',
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Share button — verified games are always shareable
            GestureDetector(
                onTap: onShare,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.sm - 2),
                  decoration: BoxDecoration(
                    color: colors.colorAccentSubtle,
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ios_share_rounded,
                          size: 12,
                          color: colors.colorAccentPrimary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Share',
                          style: AppTextStyles.labelS(
                              colors.colorAccentPrimary)),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }

  Color _sportColor(String sport, AppColorScheme colors) {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      default:           return colors.colorAccentPrimary;
    }
  }
}

// ── Stats screen state wrapper (loading / error / empty) ───────────

/// Full-bleed scaffold body that centres a single state widget below the
/// status-bar inset — used for the loading, error and empty states.
class _StatsStateScaffold extends StatelessWidget {
  const _StatsStateScaffold({required this.topPad, required this.child});
  final double topPad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Center(child: child),
    );
  }
}

// ── Date helper ────────────────────────────────────────────────────

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime d) => '${d.day} ${_monthAbbr[d.month - 1]}';
