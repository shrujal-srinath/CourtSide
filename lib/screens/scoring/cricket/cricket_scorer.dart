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

  bool get isLegalBall =>
      this != DeliveryType.wide && this != DeliveryType.noBall;

  bool get isWicket => this == DeliveryType.wicket;

  Color displayColor(AppColorScheme colors) {
    switch (this) {
      case DeliveryType.four:   return colors.colorInfo;
      case DeliveryType.six:    return const Color(0xFF8B5CF6);
      case DeliveryType.wicket: return colors.colorError;
      case DeliveryType.wide:   return colors.colorWarning;
      case DeliveryType.noBall: return colors.colorWarning;
      default:                  return colors.colorTextSecondary;
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
  final int balls; 
  final List<Delivery> deliveries;
  final int? target;

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
  int get totalOvers => 8;

  bool get isAllOut => wickets >= 10;
  bool get isOverLimit => overs >= totalOvers;

  List<Delivery> get currentOverDeliveries {
    return deliveries.where((d) => d.over == overs).toList();
  }

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
  final int currentInnings;
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
    _checkInningsEnd(updated);
  }

  void _checkInningsEnd(InningsState innings) {
    final ended = innings.isAllOut || innings.isOverLimit ||
        (innings.target != null && innings.runs >= innings.target!);

    if (!ended) return;

    if (state.currentInnings == 0) {
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
      final first = state.innings[0];
      final second = state.innings[1];
      String winner;
      if (second.runs >= (second.target ?? 0)) {
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

    final newDeliveries = curr.deliveries.sublist(0, curr.deliveries.length - 1);

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

final cricketProvider = StateNotifierProvider<CricketNotifier, CricketGameState>((_) => CricketNotifier());

// ═══════════════════════════════════════════════════════════════
//  SCORER SCREEN
// ═══════════════════════════════════════════════════════════════

class CricketScorerScreen extends ConsumerStatefulWidget {
  const CricketScorerScreen({super.key});

  @override
  ConsumerState<CricketScorerScreen> createState() => _CricketScorerScreenState();
}

class _CricketScorerScreenState extends ConsumerState<CricketScorerScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cricketProvider.notifier).startGame(teamA: 'Team A', teamB: 'Team B');
    });
  }

  static const _primaryDeliveries = [
    DeliveryType.one, DeliveryType.two, DeliveryType.three,
    DeliveryType.four, DeliveryType.six, DeliveryType.wicket,
  ];

  static const _extras = [
    DeliveryType.wide, DeliveryType.noBall, DeliveryType.legBye, DeliveryType.bye,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          SizedBox(height: topPad),
          _CricketScoreboard(
            state: state,
            onBack: () => context.pop(),
            onUndo: notifier.undoLast,
          ),
          Container(height: 0.5, color: colors.colorBorderSubtle),
          _OverDisplay(innings: curr),
          Container(height: 0.5, color: colors.colorBorderSubtle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RUNS & WICKET', style: AppTextStyles.overline(colors.colorTextSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _primaryDeliveries.map((d) {
                      final dColor = d.displayColor(colors);
                      return GestureDetector(
                        onTap: () => notifier.recordDelivery(d),
                        child: Container(
                          decoration: BoxDecoration(
                            color: dColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: dColor.withValues(alpha: 0.25), width: 0.5),
                          ),
                          child: Center(
                            child: Text(d.label, style: AppTextStyles.statM(dColor)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () => notifier.recordDelivery(DeliveryType.dot),
                    child: Container(
                      width: double.infinity, height: 44,
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                        boxShadow: AppShadow.card,
                      ),
                      child: Center(child: Text('•  Dot Ball', style: AppTextStyles.headingS(colors.colorTextSecondary))),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('EXTRAS', style: AppTextStyles.overline(colors.colorTextSecondary)),
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
                                color: colors.colorSurfacePrimary,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: colors.colorWarning.withValues(alpha: 0.3), width: 0.5),
                              ),
                              child: Center(child: Text(d.label, style: AppTextStyles.headingS(colors.colorWarning))),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
      backgroundColor: context.colors.colorSurfacePrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (_) => _GameOverSheet(state: state),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CRICKET SCOREBOARD
// ═══════════════════════════════════════════════════════════════

class _CricketScoreboard extends StatelessWidget {
  const _CricketScoreboard({required this.state, required this.onBack, required this.onUndo});
  final CricketGameState state;
  final VoidCallback onBack;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final curr = state.current;
    final isSecond = state.currentInnings == 1;

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.brand),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.colorSurfacePrimary.withValues(alpha: 0.6),
                    border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    children: [
                      Text('🏏 BOX CRICKET', style: AppTextStyles.overline(colors.colorTextSecondary)),
                      const SizedBox(height: 2),
                      Text('${curr.battingTeam} batting', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
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
                    color: colors.colorSurfacePrimary.withValues(alpha: 0.6),
                    border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: const Icon(Icons.undo_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${curr.runs}', style: AppTextStyles.scoreXXL(AppColors.cricket)),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('/${curr.wickets}', style: AppTextStyles.statL(colors.colorTextSecondary)),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
                ),
                child: Text('${curr.overDisplay} ov  ·  RR ${curr.runRate.toStringAsFixed(2)}', 
                    style: AppTextStyles.labelM(colors.colorTextSecondary)),
              ),
            ],
          ),
          if (isSecond && curr.target != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: colors.colorWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.colorWarning.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Text(
                'Target ${curr.target}  ·  Need ${curr.requiredRuns} from ${(curr.totalOvers - curr.overs) * 6 - curr.balls} balls',
                style: AppTextStyles.bodyS(colors.colorWarning),
              ),
            ),
          ],
          if (state.isGameOver) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.colorSuccess.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text('🏆 ${state.winner} wins!', style: AppTextStyles.headingM(colors.colorSuccess)),
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
    final colors = context.colors;
    final overBalls = innings.currentOverDeliveries;

    return Container(
      color: colors.colorSurfacePrimary,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Text('Over ${innings.overs + 1}', style: AppTextStyles.overline(colors.colorTextSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: List.generate(6, (i) {
                if (i < overBalls.length) {
                  final d = overBalls[i];
                  final dColor = d.type.displayColor(colors);
                  return Container(
                    width: 30, height: 30,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: dColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: dColor.withValues(alpha: 0.4), width: 0.5),
                    ),
                    child: Center(child: Text(d.type.label, style: AppTextStyles.labelS(dColor))),
                  );
                }
                return Container(
                  width: 30, height: 30, margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.colorSurfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
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
    final colors = context.colors;
    if (innings.deliveries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
          boxShadow: AppShadow.card,
        ),
        child: Center(child: Text('No balls bowled yet', style: AppTextStyles.bodyM(colors.colorTextSecondary))),
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
        Text('RECENT OVERS', style: AppTextStyles.overline(colors.colorTextSecondary)),
        const SizedBox(height: AppSpacing.sm),
        ...overNums.map((overNum) {
          final balls = byOver[overNum]!;
          final overRuns = balls.fold(0, (sum, d) => sum + d.type.runs);
          final overWickets = balls.where((d) => d.type.isWicket).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
              boxShadow: AppShadow.card,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Over $overNum', style: AppTextStyles.labelM(colors.colorTextSecondary)),
                    Text('$overRuns Runs ${overWickets > 0 ? '· $overWickets Wkts' : ''}', 
                        style: AppTextStyles.labelS(colors.colorTextSecondary)),
                  ],
                ),
                Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 0.5, color: colors.colorBorderSubtle),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: balls.map((d) {
                    final dColor = d.type.displayColor(colors);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: dColor.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(d.type.label, style: AppTextStyles.labelS(dColor)),
                    );
                  }).toList(),
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
    final colors = context.colors;
    final first = state.innings[0];
    final second = state.innings.length > 1 ? state.innings[1] : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: colors.colorBorderSubtle, borderRadius: BorderRadius.circular(AppRadius.pill)),
          ),
          const SizedBox(height: 24),
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('${state.winner} Wins!', style: AppTextStyles.displayS(colors.colorTextPrimary)),
          const SizedBox(height: 8),
          Text('${first.battingTeam}: ${first.runs}/${first.wickets} (${first.overDisplay} ov)', 
              style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          if (second != null) ...[
            const SizedBox(height: 4),
            Text('${second.battingTeam}: ${second.runs}/${second.wickets} (${second.overDisplay} ov)', 
                style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/stats/share');
              },
              icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
              label: Text('Share Stats', style: AppTextStyles.headingS(Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}