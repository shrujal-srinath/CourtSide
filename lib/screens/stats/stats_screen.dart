// lib/screens/stats/stats_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../models/fake_data.dart';
import '../../providers/auth_provider.dart';

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

  final _sportStats = FakeData.playerStats;

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
    final c = context.col;
    final topPad = MediaQuery.of(context).padding.top;
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['full_name'] as String? ?? 'Player';
    final activeStat = _sportStats[_activeSportIdx];

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/stats/share', extra: activeStat),
        backgroundColor: AppColors.red,
        icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
        label: Text(
          'Share Stats',
          style: AppTextStyles.labelM(AppColors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad + 8)),

          // ── Profile Hero Banner ──────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeroBanner(name: name, stats: _sportStats),
          ),

          // ── Win Rate Ring ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
              child: _WinRateRing(
                winRate: activeStat.winRate,
                animation: _ringAnimation,
                trackColor: c.surfaceHigh,
                surfaceColor: c.surface,
                borderColor: c.border,
                textColor: c.text,
                textSecColor: c.textSec,
              ),
            ),
          ),

          // ── Sport Segmented Control ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _SportSegmentedControl(
                stats: _sportStats,
                activeIdx: _activeSportIdx,
                onChanged: _changeSport,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Stat Grid ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _StatGrid(stat: activeStat),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Performance section header ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                'PERFORMANCE',
                style: AppTextStyles.overline(c.textSec),
              ),
            ),
          ),

          // ── Performance Stats Card ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _PerformanceStatsCard(stat: activeStat),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Career Timeline ──────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Text(
                    'CAREER TIMELINE',
                    style: AppTextStyles.overline(c.textSec),
                  ),
                ),
                _CareerTimeline(
                  games: _recentGames(activeStat.sport),
                  sport: activeStat.sport,
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Streak Card ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: const _StreakCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Recent Games header ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                'RECENT GAMES',
                style: AppTextStyles.overline(c.textSec),
              ),
            ),
          ),

          // ── Recent Games list ────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final games = _recentGames(activeStat.sport);
                if (i >= games.length) return null;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: _RecentGameCard(
                    booking: games[i],
                    onShare: () =>
                        context.push('/stats/share', extra: activeStat),
                  ),
                );
              },
              childCount: _recentGames(activeStat.sport).length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<BookingRecord> _recentGames(String sport) =>
      FakeData.bookingHistory
          .where((b) =>
              b.sport == sport && b.status == BookingStatus.completed)
          .toList();
}

// ── Profile Hero Banner ────────────────────────────────────────

class _ProfileHeroBanner extends StatelessWidget {
  const _ProfileHeroBanner({required this.name, required this.stats});
  final String name;
  final List<PlayerGameStat> stats;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 200,
      decoration: BoxDecoration(
        gradient: c.gradProfile,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Stack(
        children: [
          // Subtle red glow at bottom-left
          Positioned(
            bottom: -30,
            left: -30,
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
            padding: const EdgeInsets.all(20),
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
                        color: AppColors.red.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.red, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: AppTextStyles.displayM(AppColors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: AppTextStyles.displayS(c.text).copyWith(
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // THE BOX VERIFIED badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.red.withValues(alpha: 0.4),
                                  width: 0.5),
                            ),
                            child: Text(
                              'THE BOX VERIFIED',
                              style: AppTextStyles.overline(AppColors.red),
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
                      final color = _sportColor(s.sport);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          '${_sportEmoji(s.sport)} ${_capitalize(s.sport)}',
                          style: AppTextStyles.labelS(color),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket': return AppColors.cricket;
      case 'badminton': return AppColors.badminton;
      default: return AppColors.football;
    }
  }

  String _sportEmoji(String sport) {
    switch (sport) {
      case 'basketball': return '🏀';
      case 'cricket': return '🏏';
      case 'badminton': return '🏸';
      default: return '⚽';
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
    required this.trackColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.textSecColor,
  });
  final double winRate;
  final Animation<double> animation;
  final Color trackColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color textSecColor;

  @override
  Widget build(BuildContext context) {
    final pct = (winRate * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: AppShadow.cardFor(context),
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
                    trackColor: trackColor,
                    arcColor: AppColors.red,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: AppTextStyles.statL(textColor),
                        ),
                        Text(
                          'WIN RATE',
                          style: AppTextStyles.overline(textSecColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Rating', style: AppTextStyles.headingS(textSecColor)),
                const SizedBox(height: 8),
                Text(
                  winRate >= 0.7 ? 'Elite' : winRate >= 0.5 ? 'Good' : 'Developing',
                  style: AppTextStyles.displayS(textColor),
                ),
                const SizedBox(height: 12),
                Text(
                  winRate >= 0.7
                      ? 'Top tier performance. Keep dominating.'
                      : 'Keep playing to improve your record.',
                  style: AppTextStyles.bodyS(textSecColor),
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

  static const _icons = {
    'basketball': '🏀',
    'cricket': '🏏',
    'badminton': '🏸',
    'football': '⚽',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Stack(
        children: [
          // Sliding active pill
          AnimatedPositioned(
            duration: AppDuration.fast,
            curve: Curves.easeInOutCubic,
            left: activeIdx * (MediaQuery.of(context).size.width - 36) /
                stats.length,
            top: 4,
            bottom: 4,
            width: (MediaQuery.of(context).size.width - 36) / stats.length,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.red,
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
                    child: Text(
                      '${_icons[s.sport] ?? ''} ${_capitalize(s.sport)}',
                      style: AppTextStyles.labelM(
                        active ? AppColors.white : c.textSec,
                      ),
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
          child: _StatCell(
            value: '${stat.gamesPlayed}',
            label: 'GAMES',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            value: '${stat.wins}',
            label: 'WINS',
            accent: true,
          ),
        ),
        const SizedBox(width: 10),
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
    final c = context.col;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.red.withValues(alpha: 0.1)
            : c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: accent
              ? AppColors.red.withValues(alpha: 0.3)
              : c.border,
          width: 0.5,
        ),
        boxShadow: accent ? [] : AppShadow.cardFor(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.statL(
              accent ? AppColors.red : c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.overline(c.textSec),
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
    final c = context.col;
    final rows = _buildRows(stat);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final row = rows[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: c.border, width: 0.5),
            boxShadow: AppShadow.cardFor(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                row.value,
                style: AppTextStyles.statM(c.text),
              ),
              const SizedBox(height: 4),
              Text(
                row.key.toUpperCase(),
                style: AppTextStyles.overline(c.textSec),
              ),
            ],
          ),
        );
      },
    );
  }

  List<MapEntry<String, String>> _buildRows(PlayerGameStat s) {
    if (s.sport == 'basketball') {
      return [
        MapEntry('Points / game', '${s.stats['ppg']}'),
        MapEntry('Rebounds / game', '${s.stats['rpg']}'),
        MapEntry('Assists / game', '${s.stats['apg']}'),
        MapEntry('Steals / game', '${s.stats['spg']}'),
        MapEntry('FG %', '${((s.stats['fg_pct'] as double) * 100).toStringAsFixed(1)}%'),
        MapEntry('3PT %', '${((s.stats['three_pct'] as double) * 100).toStringAsFixed(1)}%'),
      ];
    } else if (s.sport == 'cricket') {
      return [
        MapEntry('Batting avg', '${s.stats['batting_avg']}'),
        MapEntry('Highest score', '${s.stats['highest_score']}'),
        MapEntry('Wickets', '${s.stats['wickets']}'),
        MapEntry('Economy', '${s.stats['economy']}'),
        MapEntry('Strike rate', '${s.stats['strike_rate']}'),
      ];
    }
    return [];
  }
}

// ── Career Timeline ────────────────────────────────────────────

class _CareerTimeline extends StatelessWidget {
  const _CareerTimeline({required this.games, required this.sport});
  final List<BookingRecord> games;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    if (games.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Text('No games yet',
            style: AppTextStyles.bodyM(c.textSec)),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: games.length,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final b = games[i];
          final isWin = i % 2 == 0;
          return Container(
            width: 80,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isWin
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sport == 'basketball' ? '🏀' : '🏏',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWin ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  b.date.split(' ').take(2).join(' '),
                  style: AppTextStyles.overline(c.textSec),
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
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    const heights = [0.4, 0.7, 0.5, 1.0, 0.8, 0.6, 0.9];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7 Week Streak',
                  style: AppTextStyles.displayS(c.text),
                ),
                const SizedBox(height: 4),
                Text(
                  'Played every week for 7 weeks.',
                  style: AppTextStyles.bodyS(c.textSec),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(7, (i) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 24 * heights[i],
                        decoration: BoxDecoration(
                          color: AppColors.warning
                              .withValues(alpha: 0.3 + heights[i] * 0.5),
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
  const _RecentGameCard({required this.booking, required this.onShare});
  final BookingRecord booking;
  final VoidCallback onShare;

  Color _sportColor(String sport) {
    switch (sport) {
      case 'basketball': return AppColors.basketball;
      case 'cricket': return AppColors.cricket;
      default: return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final color = _sportColor(booking.sport);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.border, width: 0.5),
        boxShadow: AppShadow.cardFor(context),
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
            const SizedBox(width: 14),
            // Sport icon
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  booking.sport == 'basketball' ? '🏀' : '🏏',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.venueName,
                      style: AppTextStyles.headingS(c.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.date,
                      style: AppTextStyles.bodyS(c.textSec),
                    ),
                  ],
                ),
              ),
            ),
            // Share button
            if (booking.hasStats)
              GestureDetector(
                onTap: onShare,
                child: Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ios_share_rounded,
                          size: 12, color: AppColors.red),
                      const SizedBox(width: 4),
                      Text('Share',
                          style: AppTextStyles.labelS(AppColors.red)),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
