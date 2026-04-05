// lib/screens/scoring/basketball/basketball_scorer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/app_spacing.dart';

// ═══════════════════════════════════════════════════════════════
//  STATE MODEL
// ═══════════════════════════════════════════════════════════════

enum BballEvent {
  onePoint, twoPoint, threePoint,
  freeThrow, rebound, assist,
  steal, block, turnover, foul,
}

extension BballEventLabel on BballEvent {
  String get label {
    switch (this) {
      case BballEvent.onePoint:   return '+1';
      case BballEvent.twoPoint:   return '+2';
      case BballEvent.threePoint: return '+3';
      case BballEvent.freeThrow:  return 'FT';
      case BballEvent.rebound:    return 'REB';
      case BballEvent.assist:     return 'AST';
      case BballEvent.steal:      return 'STL';
      case BballEvent.block:      return 'BLK';
      case BballEvent.turnover:   return 'TO';
      case BballEvent.foul:       return 'FOUL';
    }
  }

  int get points {
    switch (this) {
      case BballEvent.onePoint:   return 1;
      case BballEvent.twoPoint:   return 2;
      case BballEvent.threePoint: return 3;
      case BballEvent.freeThrow:  return 1;
      default:                    return 0;
    }
  }
}

class GameEventEntry {
  const GameEventEntry({
    required this.event,
    required this.team, // 'A' or 'B'
    required this.timestamp,
  });
  final BballEvent event;
  final String team;
  final DateTime timestamp;
}

class BasketballGameState {
  const BasketballGameState({
    required this.teamAName,
    required this.teamBName,
    required this.scoreA,
    required this.scoreB,
    required this.quarter,
    required this.clockSeconds,
    required this.isClockRunning,
    required this.events,
    required this.foulsA,
    required this.foulsB,
    required this.isGameOver,
  });

  final String teamAName;
  final String teamBName;
  final int scoreA;
  final int scoreB;
  final int quarter;
  final int clockSeconds;
  final bool isClockRunning;
  final List<GameEventEntry> events;
  final int foulsA;
  final int foulsB;
  final bool isGameOver;

  static BasketballGameState initial({
    String teamA = 'Team A',
    String teamB = 'Team B',
  }) => BasketballGameState(
    teamAName: teamA, teamBName: teamB,
    scoreA: 0, scoreB: 0,
    quarter: 1, clockSeconds: 10 * 60,
    isClockRunning: false,
    events: const [],
    foulsA: 0, foulsB: 0,
    isGameOver: false,
  );

  BasketballGameState copyWith({
    int? scoreA, int? scoreB,
    int? quarter, int? clockSeconds,
    bool? isClockRunning,
    List<GameEventEntry>? events,
    int? foulsA, int? foulsB,
    bool? isGameOver,
  }) => BasketballGameState(
    teamAName: teamAName, teamBName: teamBName,
    scoreA: scoreA ?? this.scoreA,
    scoreB: scoreB ?? this.scoreB,
    quarter: quarter ?? this.quarter,
    clockSeconds: clockSeconds ?? this.clockSeconds,
    isClockRunning: isClockRunning ?? this.isClockRunning,
    events: events ?? this.events,
    foulsA: foulsA ?? this.foulsA,
    foulsB: foulsB ?? this.foulsB,
    isGameOver: isGameOver ?? this.isGameOver,
  );

  String get clockDisplay {
    final m = clockSeconds ~/ 60;
    final s = clockSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get quarterLabel {
    switch (quarter) {
      case 1: return 'Q1';
      case 2: return 'Q2';
      case 3: return 'Q3';
      case 4: return 'Q4';
      default: return 'OT';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════════

class BasketballNotifier extends StateNotifier<BasketballGameState> {
  BasketballNotifier() : super(BasketballGameState.initial());

  // ignore: cancel_subscriptions
  late final _ticker = Stream.periodic(const Duration(seconds: 1));
  // ignore: cancel_subscriptions
  late final _sub = _ticker.listen((_) => _tick());

  void _tick() {
    if (!state.isClockRunning) return;
    if (state.clockSeconds <= 0) {
      state = state.copyWith(isClockRunning: false);
      return;
    }
    state = state.copyWith(clockSeconds: state.clockSeconds - 1);
  }

  void startGame({String teamA = 'Team A', String teamB = 'Team B'}) {
    state = BasketballGameState.initial(teamA: teamA, teamB: teamB);
  }

  void toggleClock() {
    state = state.copyWith(isClockRunning: !state.isClockRunning);
  }

  void recordEvent(BballEvent event, String team) {
    if (state.isGameOver) return;
    HapticFeedback.mediumImpact();

    final entry = GameEventEntry(
      event: event, team: team,
      timestamp: DateTime.now(),
    );
    final newEvents = [...state.events, entry];
    final pts = event.points;

    int scoreA = state.scoreA;
    int scoreB = state.scoreB;
    int foulsA = state.foulsA;
    int foulsB = state.foulsB;

    if (team == 'A') {
      scoreA += pts;
      if (event == BballEvent.foul) foulsA++;
    } else {
      scoreB += pts;
      if (event == BballEvent.foul) foulsB++;
    }

    state = state.copyWith(
      scoreA: scoreA, scoreB: scoreB,
      events: newEvents,
      foulsA: foulsA, foulsB: foulsB,
    );
  }

  void undoLast() {
    if (state.events.isEmpty) return;
    HapticFeedback.lightImpact();
    final last = state.events.last;
    final newEvents = state.events.sublist(0, state.events.length - 1);
    final pts = last.event.points;

    int scoreA = state.scoreA;
    int scoreB = state.scoreB;
    int foulsA = state.foulsA;
    int foulsB = state.foulsB;

    if (last.team == 'A') {
      scoreA = (scoreA - pts).clamp(0, 999);
      if (last.event == BballEvent.foul) foulsA = (foulsA - 1).clamp(0, 99);
    } else {
      scoreB = (scoreB - pts).clamp(0, 999);
      if (last.event == BballEvent.foul) foulsB = (foulsB - 1).clamp(0, 99);
    }

    state = state.copyWith(
      scoreA: scoreA, scoreB: scoreB,
      events: newEvents, foulsA: foulsA, foulsB: foulsB,
    );
  }

  void nextQuarter() {
    if (state.quarter >= 4) {
      state = state.copyWith(isGameOver: true, isClockRunning: false);
      return;
    }
    state = state.copyWith(
      quarter: state.quarter + 1,
      clockSeconds: 10 * 60,
      isClockRunning: false,
    );
  }

  void resetClock() {
    state = state.copyWith(
      clockSeconds: 10 * 60,
      isClockRunning: false,
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final basketballProvider =
    StateNotifierProvider<BasketballNotifier, BasketballGameState>(
  (_) => BasketballNotifier(),
);

// ═══════════════════════════════════════════════════════════════
//  SCORER SCREEN
// ═══════════════════════════════════════════════════════════════

class BasketballScorerScreen extends ConsumerStatefulWidget {
  const BasketballScorerScreen({super.key});

  @override
  ConsumerState<BasketballScorerScreen> createState() =>
      _BasketballScorerScreenState();
}

class _BasketballScorerScreenState
    extends ConsumerState<BasketballScorerScreen> {
  String _activeTeam = 'A';

  static const _scoringEvents = [
    BballEvent.twoPoint,
    BballEvent.threePoint,
    BballEvent.onePoint,
    BballEvent.freeThrow,
  ];

  static const _statEvents = [
    BballEvent.rebound,
    BballEvent.assist,
    BballEvent.steal,
    BballEvent.block,
    BballEvent.turnover,
    BballEvent.foul,
  ];

  @override
  void initState() {
    super.initState();
    // Start game with default teams
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(basketballProvider.notifier).startGame(
        teamA: 'Team A', teamB: 'Team B',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basketballProvider);
    final notifier = ref.read(basketballProvider.notifier);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Scoreboard ─────────────────────────────────────
          _Scoreboard(
            state: state,
            onBack: () => context.pop(),
            onToggleClock: notifier.toggleClock,
            onNextQuarter: notifier.nextQuarter,
            onUndo: notifier.undoLast,
          ),

          Container(height: 0.5, color: AppColors.border),

          // ── Team selector ───────────────────────────────────
          _TeamSelector(
            state: state,
            activeTeam: _activeTeam,
            onTeamChanged: (t) => setState(() => _activeTeam = t),
          ),

          Container(height: 0.5, color: AppColors.border),

          // ── Event buttons ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Scoring row
                  _EventGrid(
                    events: _scoringEvents,
                    label: 'Score',
                    primaryColor: _activeTeam == 'A'
                        ? const Color(0xFF3B82F6)
                        : AppColors.red,
                    onEvent: (e) => notifier.recordEvent(e, _activeTeam),
                  ),

                  const SizedBox(height: 12),

                  // Stats row
                  _EventGrid(
                    events: _statEvents,
                    label: 'Stats',
                    primaryColor: AppColors.surfaceHigh,
                    onEvent: (e) => notifier.recordEvent(e, _activeTeam),
                    isStats: true,
                  ),

                  const SizedBox(height: 16),

                  // Event log
                  _EventLog(events: state.events, state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCOREBOARD
// ═══════════════════════════════════════════════════════════════

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.state,
    required this.onBack,
    required this.onToggleClock,
    required this.onNextQuarter,
    required this.onUndo,
  });

  final BasketballGameState state;
  final VoidCallback onBack;
  final VoidCallback onToggleClock;
  final VoidCallback onNextQuarter;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080A0F), Color(0xFF0D1829)],
        ),
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white, size: 14),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '🏀 Basketball',
                    style: AppTextStyles.headingS(AppColors.textPrimaryDark),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onUndo,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.undo_rounded,
                      color: AppColors.white, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Score display — the crown jewel
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team A
              Expanded(
                child: Column(
                  children: [
                    Text(
                      state.teamAName.toUpperCase(),
                      style: AppTextStyles.overline(AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.scoreA}',
                      style: AppTextStyles.scoreXXL(AppColors.teamBlue),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fouls: ${state.foulsA}',
                      style: AppTextStyles.bodyS(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),

              // Center: quarter + clock + next Q
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      state.quarterLabel,
                      style: AppTextStyles.overline(AppColors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Clock — pulsing border when running
                  GestureDetector(
                    onTap: onToggleClock,
                    child: AnimatedContainer(
                      duration: AppDuration.normal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: state.isClockRunning
                            ? AppColors.red.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: state.isClockRunning
                              ? AppColors.red.withValues(alpha: 0.6)
                              : AppColors.border,
                          width: state.isClockRunning ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        state.clockDisplay,
                        style: AppTextStyles.statM(
                          state.isClockRunning
                              ? AppColors.white
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onNextQuarter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: state.quarter >= 4
                            ? AppColors.red.withValues(alpha: 0.12)
                            : AppColors.surfaceHigh,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: state.quarter >= 4
                              ? AppColors.red.withValues(alpha: 0.3)
                              : AppColors.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        state.quarter >= 4 ? 'End game' : 'Next Q →',
                        style: AppTextStyles.overline(
                          state.quarter >= 4
                              ? AppColors.red
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Team B
              Expanded(
                child: Column(
                  children: [
                    Text(
                      state.teamBName.toUpperCase(),
                      style: AppTextStyles.overline(AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.scoreB}',
                      style: AppTextStyles.scoreXXL(AppColors.teamRed),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fouls: ${state.foulsB}',
                      style: AppTextStyles.bodyS(AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TEAM SELECTOR
// ═══════════════════════════════════════════════════════════════

class _TeamSelector extends StatelessWidget {
  const _TeamSelector({
    required this.state,
    required this.activeTeam,
    required this.onTeamChanged,
  });

  final BasketballGameState state;
  final String activeTeam;
  final ValueChanged<String> onTeamChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'SCORING FOR',
            style: AppTextStyles.overline(AppColors.textSecondaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TeamBtn(
              label: state.teamAName,
              active: activeTeam == 'A',
              color: AppColors.teamBlue,
              onTap: () => onTeamChanged('A'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TeamBtn(
              label: state.teamBName,
              active: activeTeam == 'B',
              color: AppColors.teamRed,
              onTap: () => onTeamChanged('B'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBtn extends StatelessWidget {
  const _TeamBtn({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        height: 44,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : AppColors.border,
            width: active ? 1.5 : 0.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.headingS(
              active ? AppColors.white : AppColors.textSecondaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EVENT GRID
// ═══════════════════════════════════════════════════════════════

class _EventGrid extends StatelessWidget {
  const _EventGrid({
    required this.events,
    required this.label,
    required this.primaryColor,
    required this.onEvent,
    this.isStats = false,
  });

  final List<BballEvent> events;
  final String label;
  final Color primaryColor;
  final ValueChanged<BballEvent> onEvent;
  final bool isStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline(AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isStats ? 3 : 2,
            childAspectRatio: isStats ? 2.0 : 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: events.length,
          itemBuilder: (c, i) {
            final event = events[i];
            return GestureDetector(
              onTap: () => onEvent(event),
              child: Container(
                decoration: BoxDecoration(
                  color: isStats
                      ? AppColors.surfaceHigh
                      : primaryColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    event.label,
                    style: isStats
                        ? AppTextStyles.headingS(AppColors.textSecondaryDark)
                        : AppTextStyles.statM(AppColors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EVENT LOG
// ═══════════════════════════════════════════════════════════════

class _EventLog extends StatelessWidget {
  const _EventLog({required this.events, required this.state});
  final List<GameEventEntry> events;
  final BasketballGameState state;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Center(
          child: Text(
            'No events yet — tap to score',
            style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
          ),
        ),
      );
    }

    final recent = events.reversed.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT EVENTS',
          style: AppTextStyles.overline(AppColors.textSecondaryDark),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: recent.asMap().entries.map((entry) {
              final e = entry.value;
              final isA = e.team == 'A';
              final color = isA ? AppColors.teamBlue : AppColors.teamRed;
              final teamName =
                  isA ? state.teamAName : state.teamBName;
              final isFirst = entry.key == 0;
              final isLast = entry.key == recent.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isFirst
                      ? color.withValues(alpha: 0.06)
                      : Colors.transparent,
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                              color: AppColors.borderMuted, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$teamName — ${e.event.label}',
                        style: AppTextStyles.bodyS(
                          isFirst
                              ? AppColors.textPrimaryDark
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                    if (e.event.points > 0)
                      Text(
                        '+${e.event.points}',
                        style: AppTextStyles.headingS(color),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}