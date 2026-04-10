// lib/screens/scoring/cricket/cricket_scorer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/app_gradients.dart';

// ═══════════════════════════════════════════════════════════════
//  DELIVERY MODEL
// ═══════════════════════════════════════════════════════════════

enum DeliveryType {
  dot, one, two, three, four, six,
  wicket, wide, noBall, legBye, bye,
}

extension DeliveryLabel on DeliveryType {
  String get label {
    switch (this) {
      case DeliveryType.dot:    return '•';
      case DeliveryType.one:    return '1';
      case DeliveryType.two:    return '2';
      case DeliveryType.three:  return '3';
      case DeliveryType.four:   return '4';
      case DeliveryType.six:    return '6';
      case DeliveryType.wicket: return 'W';
      case DeliveryType.wide:   return 'Wd';
      case DeliveryType.noBall: return 'Nb';
      case DeliveryType.legBye: return 'Lb';
      case DeliveryType.bye:    return 'B';
    }
  }

  int get runs {
    switch (this) {
      case DeliveryType.one:    return 1;
      case DeliveryType.two:    return 2;
      case DeliveryType.three:  return 3;
      case DeliveryType.four:   return 4;
      case DeliveryType.six:    return 6;
      case DeliveryType.wide:   return 1;
      case DeliveryType.noBall: return 1;
      default:                  return 0;
    }
  }

  // Does this delivery count as a legal ball?
  bool get isLegalBall =>
      this != DeliveryType.wide && this != DeliveryType.noBall;

  bool get isWicket => this == DeliveryType.wicket;

  Color get displayColor {
    switch (this) {
      case DeliveryType.four:   return const Color(0xFF3B82F6);
      case DeliveryType.six:    return const Color(0xFF8B5CF6);
      case DeliveryType.wicket: return AppColors.red;
      case DeliveryType.wide:   return AppColors.warning;
      case DeliveryType.noBall: return AppColors.warning;
      default:                  return AppColors.textSecondaryDark;
    }
  }
}

class Delivery {
  const Delivery({
    required this.type,
    required this.over,
    required this.ball,
    required this.timestamp,
  });
  final DeliveryType type;
  final int over;
  final int ball;
  final DateTime timestamp;
}

// ═══════════════════════════════════════════════════════════════
//  INNINGS STATE
// ═══════════════════════════════════════════════════════════════

class InningsState {
  const InningsState({
    required this.battingTeam,
    required this.bowlingTeam,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
    required this.deliveries,
    required this.target,
  });

  final String battingTeam;
  final String bowlingTeam;
  final int runs;
  final int wickets;
  final int overs;
  final int balls; // balls in current over (0-5)
  final List<Delivery> deliveries;
  final int? target; // set after 1st innings

  static InningsState initial({
    required String batting,
    required String bowling,
    int? target,
  }) => InningsState(
    battingTeam: batting,
    bowlingTeam: bowling,
    runs: 0, wickets: 0,
    overs: 0, balls: 0,
    deliveries: const [],
    target: target,
  );

  InningsState copyWith({
    int? runs, int? wickets,
    int? overs, int? balls,
    List<Delivery>? deliveries,
  }) => InningsState(
    battingTeam: battingTeam,
    bowlingTeam: bowlingTeam,
    runs: runs ?? this.runs,
    wickets: wickets ?? this.wickets,
    overs: overs ?? this.overs,
    balls: balls ?? this.balls,
    deliveries: deliveries ?? this.deliveries,
    target: target,
  );

  String get overDisplay => '$overs.$balls';

  double get runRate {
    final totalBalls = overs * 6 + balls;
    if (totalBalls == 0) return 0;
    return (runs / totalBalls) * 6;
  }

  int? get requiredRuns => target != null ? target! - runs : null;
  int get totalOvers => 8; // default 8-over box cricket

  bool get isAllOut => wickets >= 10;
  bool get isOverLimit => overs >= totalOvers;

  List<Delivery> get currentOverDeliveries {
    return deliveries.where((d) => d.over == overs).toList();
  }

  // Summary for current over as short codes
  String get overSummary {
    final d = currentOverDeliveries;
    if (d.isEmpty) return '';
    return d.map((e) => e.type.label).join(' ');
  }
}

// ═══════════════════════════════════════════════════════════════
//  CRICKET STATE
// ═══════════════════════════════════════════════════════════════

class CricketGameState {
  const CricketGameState({
    required this.innings,
    required this.currentInnings,
    required this.teamA,
    required this.teamB,
    required this.isGameOver,
    required this.winner,
  });

  final List<InningsState> innings;
  final int currentInnings; // 0 or 1
  final String teamA;
  final String teamB;
  final bool isGameOver;
  final String? winner;

  static CricketGameState initial({
    String teamA = 'Team A',
    String teamB = 'Team B',
  }) => CricketGameState(
    innings: [
      InningsState.initial(batting: teamA, bowling: teamB),
    ],
    currentInnings: 0,
    teamA: teamA, teamB: teamB,
    isGameOver: false, winner: null,
  );

  InningsState get current => innings[currentInnings];

  CricketGameState copyWithCurrentInnings(InningsState updated) {
    final newInnings = [...innings];
    newInnings[currentInnings] = updated;
    return CricketGameState(
      innings: newInnings,
      currentInnings: currentInnings,
      teamA: teamA, teamB: teamB,
      isGameOver: isGameOver, winner: winner,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════════

class CricketNotifier extends StateNotifier<CricketGameState> {
  CricketNotifier() : super(CricketGameState.initial());

  void startGame({String teamA = 'Team A', String teamB = 'Team B'}) {
    state = CricketGameState.initial(teamA: teamA, teamB: teamB);
  }

  void recordDelivery(DeliveryType type) {
    if (state.isGameOver) return;
    HapticFeedback.mediumImpact();

    final curr = state.current;
    final delivery = Delivery(
      type: type,
      over: curr.overs,
      ball: curr.balls,
      timestamp: DateTime.now(),
    );

    int runs = curr.runs + type.runs;
    int wickets = curr.wickets + (type.isWicket ? 1 : 0);
    int overs = curr.overs;
    int balls = curr.balls;

    if (type.isLegalBall) {
      balls++;
      if (balls >= 6) {
        balls = 0;
        overs++;
      }
    }

    final updated = curr.copyWith(
      runs: runs, wickets: wickets,
      overs: overs, balls: balls,
      deliveries: [...curr.deliveries, delivery],
    );

    state = state.copyWithCurrentInnings(updated);

    // Check innings end
    _checkInningsEnd(updated);
  }

  void _checkInningsEnd(InningsState innings) {
    final ended = innings.isAllOut || innings.isOverLimit ||
        (innings.target != null && innings.runs >= innings.target!);

    if (!ended) return;

    if (state.currentInnings == 0) {
      // Start second innings
      final target = innings.runs + 1;
      final secondInnings = InningsState.initial(
        batting: state.teamB,
        bowling: state.teamA,
        target: target,
      );
      state = CricketGameState(
        innings: [...state.innings, secondInnings],
        currentInnings: 1,
        teamA: state.teamA, teamB: state.teamB,
        isGameOver: false, winner: null,
      );
    } else {
      // Game over
      final first = state.innings[0];
      final second = state.innings[1];
      String winner;
      if (second.runs >= second.target!) {
        winner = second.battingTeam;
      } else {
        winner = first.battingTeam;
      }
      state = CricketGameState(
        innings: state.innings,
        currentInnings: state.currentInnings,
        teamA: state.teamA, teamB: state.teamB,
        isGameOver: true, winner: winner,
      );
    }
  }

  void undoLast() {
    final curr = state.current;
    if (curr.deliveries.isEmpty) return;
    HapticFeedback.lightImpact();

    final newDeliveries = curr.deliveries.sublist(
      0, curr.deliveries.length - 1);

    // Recalculate from scratch
    int runs = 0, wickets = 0, overs = 0, balls = 0;
    for (final d in newDeliveries) {
      runs += d.type.runs;
      if (d.type.isWicket) wickets++;
      if (d.type.isLegalBall) {
        balls++;
        if (balls >= 6) { balls = 0; overs++; }
      }
    }

    state = state.copyWithCurrentInnings(curr.copyWith(
      runs: runs, wickets: wickets,
      overs: overs, balls: balls,
      deliveries: newDeliveries,
    ));
  }
}

final cricketProvider =
    StateNotifierProvider<CricketNotifier, CricketGameState>(
  (_) => CricketNotifier(),
);

// ═══════════════════════════════════════════════════════════════
//  SCORER SCREEN
// ═══════════════════════════════════════════════════════════════

class CricketScorerScreen extends ConsumerStatefulWidget {
  const CricketScorerScreen({super.key});

  @override
  ConsumerState<CricketScorerScreen> createState() =>
      _CricketScorerScreenState();
}

class _CricketScorerScreenState extends ConsumerState<CricketScorerScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cricketProvider.notifier).startGame(
        teamA: 'Team A', teamB: 'Team B',
      );
    });
  }

  // Primary scoring buttons — 3-column grid top row
  static const _primaryDeliveries = [
    DeliveryType.one,
    DeliveryType.two,
    DeliveryType.three,
    DeliveryType.four,
    DeliveryType.six,
    DeliveryType.wicket,
  ];

  static const _extras = [
    DeliveryType.wide,
    DeliveryType.noBall,
    DeliveryType.legBye,
    DeliveryType.bye,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cricketProvider);
    final notifier = ref.read(cricketProvider.notifier);
    final topPad = MediaQuery.of(context).padding.top;
    final curr = state.current;

    if (state.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverSheet(context, state);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Scoreboard ─────────────────────────────────────
          _CricketScoreboard(
            state: state,
            onBack: () => context.pop(),
            onUndo: notifier.undoLast,
          ),

          Container(height: 0.5, color: AppColors.border),

          // ── Current over display ───────────────────────────
          _OverDisplay(innings: curr),

          Container(height: 0.5, color: AppColors.border),

          // ── Delivery buttons ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label
                  Text(
                    'RUNS & WICKET',
                    style: AppTextStyles.overline(AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 3-column primary grid (1/2/3/4/6/W)
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _primaryDeliveries.map((d) {
                      final isWicket = d == DeliveryType.wicket;
                      final color = d.displayColor == AppColors.textSecondaryDark
                          ? AppColors.white
                          : d.displayColor;
                      return GestureDetector(
                        onTap: () => notifier.recordDelivery(d),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isWicket
                                ? AppColors.red.withValues(alpha: 0.15)
                                : d.displayColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isWicket
                                  ? AppColors.red.withValues(alpha: 0.5)
                                  : d.displayColor.withValues(alpha: 0.25),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              d.label,
                              style: AppTextStyles.statM(color),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Full-width dot ball
                  GestureDetector(
                    onTap: () => notifier.recordDelivery(DeliveryType.dot),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          '•  Dot Ball',
                          style: AppTextStyles.headingS(AppColors.textSecondaryDark),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Extras row
                  Text(
                    'EXTRAS',
                    style: AppTextStyles.overline(AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: _extras.map((d) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => notifier.recordDelivery(d),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: AppColors.warning.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  d.label,
                                  style: AppTextStyles.headingS(AppColors.warning),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Ball-by-ball log
                  _BallLog(innings: curr),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverSheet(BuildContext context, CricketGameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _GameOverSheet(state: state),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CRICKET SCOREBOARD
// ═══════════════════════════════════════════════════════════════

class _CricketScoreboard extends StatelessWidget {
  const _CricketScoreboard({
    required this.state,
    required this.onBack,
    required this.onUndo,
  });

  final CricketGameState state;
  final VoidCallback onBack;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final curr = state.current;
    final isSecond = state.currentInnings == 1;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.brand),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withValues(alpha: 0.6),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white, size: 14),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text('🏏 BOX CRICKET',
                        style: AppTextStyles.overline(AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${curr.battingTeam} batting',
                        style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: onUndo,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface.withValues(alpha: 0.6),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.undo_rounded,
                    color: AppColors.white, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Big score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${curr.runs}',
                style: AppTextStyles.scoreXXL(AppColors.cricket),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/${curr.wickets}',
                  style: AppTextStyles.statL(AppColors.textSecondaryDark),
                ),
              ),
            ],
          ),

          // Overs + run rate row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Text(
                  '${curr.overDisplay} ov  ·  RR ${curr.runRate.toStringAsFixed(2)}',
                  style: AppTextStyles.labelM(AppColors.textSecondaryDark),
                ),
              ),
            ],
          ),

          // Target (2nd innings)
          if (isSecond && curr.target != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Text(
                'Target ${curr.target}  ·  Need ${curr.requiredRuns} from ${(curr.totalOvers - curr.overs) * 6 - curr.balls} balls',
                style: AppTextStyles.bodyS(AppColors.warning),
              ),
            ),
          ],

          if (state.isGameOver) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                '🏆 ${state.winner} wins!',
                style: AppTextStyles.headingM(AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OVER DISPLAY
// ═══════════════════════════════════════════════════════════════

class _OverDisplay extends StatelessWidget {
  const _OverDisplay({required this.innings});
  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    final overBalls = innings.currentOverDeliveries;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Text(
            'Over ${innings.overs + 1}',
            style: AppTextStyles.overline(AppColors.textSecondaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(6, (i) {
                if (i < overBalls.length) {
                  final d = overBalls[i];
                  final color = d.type.displayColor == AppColors.textSecondaryDark
                      ? AppColors.white
                      : d.type.displayColor;
                  return Container(
                    width: 30, height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: d.type.displayColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: d.type.displayColor.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        d.type.label,
                        style: AppTextStyles.labelS(color),
                      ),
                    ),
                  );
                }
                return Container(
                  width: 30, height: 30,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BALL LOG
// ═══════════════════════════════════════════════════════════════

class _BallLog extends StatelessWidget {
  const _BallLog({required this.innings});
  final InningsState innings;

  @override
  Widget build(BuildContext context) {
    if (innings.deliveries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Center(
          child: Text(
            'No balls bowled yet',
            style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
          ),
        ),
      );
    }

    final Map<int, List<Delivery>> byOver = {};
    for (final d in innings.deliveries) {
      byOver.putIfAbsent(d.over, () => []).add(d);
    }
    final overNums = byOver.keys.toList().reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT OVERS',
          style: AppTextStyles.overline(AppColors.textSecondaryDark)),
        const SizedBox(height: AppSpacing.sm),
        ...overNums.map((overNum) {
          final balls = byOver[overNum]!;
          final overRuns = balls.fold(0, (sum, d) => sum + d.type.runs);
          final overWickets = balls.where((d) => d.type.isWicket).length;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Text(
                  'Ov ${overNum + 1}',
                  style: AppTextStyles.labelM(AppColors.textSecondaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: balls.map((d) {
                      final color = d.type.displayColor == AppColors.textSecondaryDark
                          ? AppColors.white
                          : d.type.displayColor;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: d.type.displayColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: d.type.displayColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(d.type.label,
                          style: AppTextStyles.labelS(color)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$overRuns${overWickets > 0 ? '/$overWickets' : ''}',
                  style: AppTextStyles.statM(AppColors.white),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GAME OVER SHEET
// ═══════════════════════════════════════════════════════════════

class _GameOverSheet extends StatelessWidget {
  const _GameOverSheet({required this.state});
  final CricketGameState state;

  @override
  Widget build(BuildContext context) {
    final first = state.innings[0];
    final second = state.innings.length > 1 ? state.innings[1] : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '${state.winner} Wins!',
            style: AppTextStyles.displayS(AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            '${first.battingTeam}: ${first.runs}/${first.wickets} (${first.overDisplay} ov)',
            style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
          ),
          if (second != null) ...[
            const SizedBox(height: 4),
            Text(
              '${second.battingTeam}: ${second.runs}/${second.wickets} (${second.overDisplay} ov)',
              style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/stats/share');
              },
              icon: const Icon(Icons.ios_share_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                'Share Stats',
                style: AppTextStyles.headingS(AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}