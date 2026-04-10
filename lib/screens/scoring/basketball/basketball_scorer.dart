// lib/screens/scoring/basketball/basketball_scorer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import 'models/basketball_models.dart';

export 'models/basketball_models.dart';

// ═══════════════════════════════════════════════════════════════
//  NOTIFIER
// ═══════════════════════════════════════════════════════════════

class BasketballNotifier extends StateNotifier<BasketballGameState> {
  BasketballNotifier() : super(_placeholder());

  static BasketballGameState _placeholder() => BasketballGameState.fromConfig(
        const BballGameConfig(
          mode: BballMode.quick,
          format: BballFormat.fiveVsFive,
          clockFormat: BballClockFormat.quarters,
          periodMinutes: 10,
          hasShotClock: true,
          teamA: BballTeamConfig(name: 'Team A', color: Color(0xFF3B82F6)),
          teamB: BballTeamConfig(name: 'Team B', color: Color(0xFFE8112D)),
          extraStats: false,
          timeoutsPerTeam: 2,
          shotClockDuration: 24,
        ),
      );

  // Game clock ticker
  // ignore: cancel_subscriptions
  late final _gameTicker = Stream.periodic(const Duration(seconds: 1));
  // ignore: cancel_subscriptions
  late final _gameSub = _gameTicker.listen((_) => _gameTick());

  // Shot clock ticker
  // ignore: cancel_subscriptions
  late final _shotTicker = Stream.periodic(const Duration(seconds: 1));
  // ignore: cancel_subscriptions
  late final _shotSub = _shotTicker.listen((_) => _shotTick());

  void _gameTick() {
    if (!state.isClockRunning) return;
    if (state.clockSeconds <= 0) {
      state = state.copyWith(isClockRunning: false);
      return;
    }
    state = state.copyWith(clockSeconds: state.clockSeconds - 1);
  }

  void _shotTick() {
    if (!state.isShotClockRunning || !state.config.hasShotClock) return;
    if (state.shotClockSeconds <= 0) {
      HapticFeedback.vibrate();
      state = state.copyWith(isShotClockRunning: false);
      return;
    }
    state = state.copyWith(shotClockSeconds: state.shotClockSeconds - 1);
  }

  void startGame(BballGameConfig config) {
    state = BasketballGameState.fromConfig(config);
  }

  void toggleClock() {
    state = state.copyWith(isClockRunning: !state.isClockRunning);
  }

  void toggleShotClock() {
    state = state.copyWith(isShotClockRunning: !state.isShotClockRunning);
  }

  void resetShotClock({bool toFourteen = false}) {
    state = state.copyWith(
      shotClockSeconds: toFourteen ? 14 : state.config.shotClockDuration,
      isShotClockRunning: false,
    );
  }

  void recordEventWithPlayer(
    BballEvent event,
    String teamId,
    String? playerId,
  ) {
    if (state.isGameOver) return;
    HapticFeedback.mediumImpact();

    // Find player info if provided
    String? playerName;
    int? playerNumber;
    if (playerId != null) {
      final allPlayers = teamId == 'A'
          ? state.config.teamA.players
          : state.config.teamB.players;
      final match = allPlayers.where((p) => p.id == playerId);
      if (match.isNotEmpty) {
        playerName = match.first.name;
        playerNumber = match.first.number;
      }
    }

    final entry = BballEventEntry(
      event: event,
      teamId: teamId,
      timestamp: DateTime.now(),
      clockSnapshot: state.clockSeconds,
      playerId: playerId,
      playerName: playerName,
      playerNumber: playerNumber,
    );

    final newEvents = [...state.events, entry];
    final pts = event.points;

    int scoreA = state.scoreA;
    int scoreB = state.scoreB;
    int foulsA = state.foulsA;
    int foulsB = state.foulsB;

    if (teamId == 'A') {
      scoreA += pts;
      if (event == BballEvent.foul) foulsA++;
    } else {
      scoreB += pts;
      if (event == BballEvent.foul) foulsB++;
    }

    // Update per-player stats
    BballGameConfig updatedConfig = state.config;
    if (playerId != null) {
      updatedConfig = _applyPlayerStat(state.config, teamId, playerId, event, delta: 1);
    }

    // Reset shot clock on scoring events (if auto-reset is on)
    int shotClock = state.shotClockSeconds;
    bool shotRunning = state.isShotClockRunning;
    if (event.isScoring && state.config.hasShotClock && state.config.autoResetShotClock) {
      shotClock = state.config.shotClockDuration;
      shotRunning = false;
    }

    // 3v3 FIBA: alert when a team reaches 21
    String? twentyOneTeam;
    if (state.config.format == BballFormat.threeVsThree && event.isScoring) {
      if (scoreA >= 21 && state.scoreA < 21) {
        twentyOneTeam = state.config.teamA.name;
      } else if (scoreB >= 21 && state.scoreB < 21) {
        twentyOneTeam = state.config.teamB.name;
      }
    }

    state = state.copyWith(
      config: updatedConfig,
      scoreA: scoreA,
      scoreB: scoreB,
      events: newEvents,
      foulsA: foulsA,
      foulsB: foulsB,
      shotClockSeconds: shotClock,
      isShotClockRunning: shotRunning,
      twentyOneTeam: twentyOneTeam,
    );
  }

  void clearTwentyOneAlert() {
    state = state.copyWith(twentyOneTeam: null);
  }

  void callTimeout(String teamId) {
    HapticFeedback.lightImpact();
    if (teamId == 'A' && state.timeoutsUsedA < state.config.timeoutsPerTeam) {
      state = state.copyWith(
        timeoutsUsedA: state.timeoutsUsedA + 1,
        isClockRunning: false,
      );
    } else if (teamId == 'B' && state.timeoutsUsedB < state.config.timeoutsPerTeam) {
      state = state.copyWith(
        timeoutsUsedB: state.timeoutsUsedB + 1,
        isClockRunning: false,
      );
    }
  }

  void updateAutoResetShotClock(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(autoResetShotClock: value),
    );
  }

  void updatePlayerName(String teamId, String playerId, String name) {
    List<BballPlayer> update(List<BballPlayer> players) =>
        players.map((p) => p.id == playerId ? p.copyWith(name: name) : p).toList();

    if (teamId == 'A') {
      state = state.copyWith(
        config: state.config.copyWith(
          teamA: state.config.teamA.copyWith(players: update(state.config.teamA.players)),
        ),
        onCourtA: update(state.onCourtA),
      );
    } else {
      state = state.copyWith(
        config: state.config.copyWith(
          teamB: state.config.teamB.copyWith(players: update(state.config.teamB.players)),
        ),
        onCourtB: update(state.onCourtB),
      );
    }
  }

  BballGameConfig _applyPlayerStat(
    BballGameConfig config,
    String teamId,
    String playerId,
    BballEvent event, {
    required int delta,
  }) {
    List<BballPlayer> updatePlayer(List<BballPlayer> players) {
      return players.map((p) {
        if (p.id != playerId) return p;
        return p.copyWith(
          points: (p.points + event.points * delta).clamp(0, 999),
          rebounds: event == BballEvent.rebound
              ? (p.rebounds + delta).clamp(0, 999)
              : p.rebounds,
          assists: event == BballEvent.assist
              ? (p.assists + delta).clamp(0, 999)
              : p.assists,
          steals: event == BballEvent.steal
              ? (p.steals + delta).clamp(0, 999)
              : p.steals,
          blocks: event == BballEvent.block
              ? (p.blocks + delta).clamp(0, 999)
              : p.blocks,
          turnovers: event == BballEvent.turnover
              ? (p.turnovers + delta).clamp(0, 999)
              : p.turnovers,
          fouls: event == BballEvent.foul
              ? (p.fouls + delta).clamp(0, 6)
              : p.fouls,
        );
      }).toList();
    }

    if (teamId == 'A') {
      return config.copyWith(
          teamA: config.teamA.copyWith(
              players: updatePlayer(config.teamA.players)));
    } else {
      return config.copyWith(
          teamB: config.teamB.copyWith(
              players: updatePlayer(config.teamB.players)));
    }
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

    if (last.teamId == 'A') {
      scoreA = (scoreA - pts).clamp(0, 999);
      if (last.event == BballEvent.foul) foulsA = (foulsA - 1).clamp(0, 99);
    } else {
      scoreB = (scoreB - pts).clamp(0, 999);
      if (last.event == BballEvent.foul) foulsB = (foulsB - 1).clamp(0, 99);
    }

    // Reverse per-player stats
    BballGameConfig updatedConfig = state.config;
    if (last.playerId != null) {
      updatedConfig = _applyPlayerStat(
        state.config,
        last.teamId,
        last.playerId!,
        last.event,
        delta: -1,
      );
    }

    state = state.copyWith(
      config: updatedConfig,
      scoreA: scoreA,
      scoreB: scoreB,
      events: newEvents,
      foulsA: foulsA,
      foulsB: foulsB,
    );
  }

  void nextPeriod() {
    if (state.isLastPeriod) {
      state = state.copyWith(isGameOver: true, isClockRunning: false);
      return;
    }
    // FIBA 5v5: team fouls reset every quarter
    final is5v5 = state.config.format == BballFormat.fiveVsFive;
    state = state.copyWith(
      period: state.period + 1,
      clockSeconds: state.config.clockSeconds,
      isClockRunning: false,
      shotClockSeconds: state.config.shotClockDuration,
      isShotClockRunning: false,
      foulsA: is5v5 ? 0 : state.foulsA,
      foulsB: is5v5 ? 0 : state.foulsB,
    );
  }

  void performSubstitution(
    String teamId,
    String incomingPlayerId,
    String outgoingPlayerId,
  ) {
    HapticFeedback.lightImpact();

    List<BballPlayer> swapPlayers(List<BballPlayer> players) {
      return players.map((p) {
        if (p.id == incomingPlayerId) return p.copyWith(isOnCourt: true);
        if (p.id == outgoingPlayerId) return p.copyWith(isOnCourt: false);
        return p;
      }).toList();
    }

    BballGameConfig updatedConfig;
    List<BballPlayer> newOnCourtA = state.onCourtA;
    List<BballPlayer> newOnCourtB = state.onCourtB;

    if (teamId == 'A') {
      final newPlayers = swapPlayers(state.config.teamA.players);
      updatedConfig = state.config.copyWith(
        teamA: state.config.teamA.copyWith(players: newPlayers),
      );
      newOnCourtA = newPlayers.where((p) => p.isOnCourt).toList();
    } else {
      final newPlayers = swapPlayers(state.config.teamB.players);
      updatedConfig = state.config.copyWith(
        teamB: state.config.teamB.copyWith(players: newPlayers),
      );
      newOnCourtB = newPlayers.where((p) => p.isOnCourt).toList();
    }

    state = state.copyWith(
      config: updatedConfig,
      onCourtA: newOnCourtA,
      onCourtB: newOnCourtB,
    );
  }

  @override
  void dispose() {
    _gameSub.cancel();
    _shotSub.cancel();
    super.dispose();
  }
}

final basketballProvider =
    StateNotifierProvider<BasketballNotifier, BasketballGameState>(
  (_) => BasketballNotifier(),
);

// ═══════════════════════════════════════════════════════════════
//  SCORER SCREEN — LANDSCAPE
// ═══════════════════════════════════════════════════════════════

class BasketballScorerScreen extends ConsumerStatefulWidget {
  const BasketballScorerScreen({super.key, required this.config});
  final BballGameConfig config;

  @override
  ConsumerState<BasketballScorerScreen> createState() =>
      _BasketballScorerScreenState();
}

class _BasketballScorerScreenState
    extends ConsumerState<BasketballScorerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(basketballProvider.notifier).startGame(widget.config);
    });
  }

  void _handle21Alert(String teamName) {
    showDialog<_TwentyOneAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.8),
      builder: (_) => _TwentyOneDialog(teamName: teamName),
    ).then((action) {
      if (!mounted) return;
      ref.read(basketballProvider.notifier).clearTwentyOneAlert();
      if (action == _TwentyOneAction.endGame) {
        ref.read(basketballProvider.notifier).nextPeriod();
      }
      // .keepPlaying — do nothing, game continues
    });
  }

  Future<void> _onBackPressed() async {
    // Pause clock while dialog is open
    final notifier = ref.read(basketballProvider.notifier);
    final wasRunning = ref.read(basketballProvider).isClockRunning;
    if (wasRunning) notifier.toggleClock();

    final quit = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.8),
      builder: (_) => _QuitGameDialog(),
    );

    if (!mounted) return;
    if (quit == true) {
      context.pop();
    } else {
      // Resume clock if it was running
      if (wasRunning) notifier.toggleClock();
    }
  }

  void _showInGameSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GameSettingsSheet(
        state: ref.read(basketballProvider),
        onAutoResetChanged: (v) =>
            ref.read(basketballProvider.notifier).updateAutoResetShotClock(v),
        onEditPlayer: (teamId, playerId, name) =>
            ref.read(basketballProvider.notifier).updatePlayerName(teamId, playerId, name),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onScoringEvent(BballEvent event, String teamId) {
    final state = ref.read(basketballProvider);
    final notifier = ref.read(basketballProvider.notifier);

    if (state.config.mode == BballMode.quick) {
      notifier.recordEventWithPlayer(event, teamId, null);
      return;
    }

    final onCourt = teamId == 'A' ? state.onCourtA : state.onCourtB;
    final teamColor =
        teamId == 'A' ? state.config.teamA.color : state.config.teamB.color;

    showDialog<String?>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.75),
      builder: (_) => _AttributionDialog(
        event: event,
        players: onCourt,
        teamColor: teamColor,
      ),
    ).then((playerId) {
      if (!mounted) return;
      // null = dismissed or unknown — still record without attribution
      notifier.recordEventWithPlayer(event, teamId, playerId);
    });
  }

  void _onStatTapped(BballEvent event) {
    final state = ref.read(basketballProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeamPickerSheet(
        teamAName: state.config.teamA.name,
        teamBName: state.config.teamB.name,
        teamAColor: state.config.teamA.color,
        teamBColor: state.config.teamB.color,
        eventLabel: event.label,
        onTeamSelected: (teamId) {
          Navigator.pop(context);
          _onScoringEvent(event, teamId);
        },
      ),
    );
  }

  void _showSubPanel(String teamId) {
    final state = ref.read(basketballProvider);
    final onCourt = teamId == 'A' ? state.onCourtA : state.onCourtB;
    final allPlayers = teamId == 'A'
        ? state.config.teamA.players
        : state.config.teamB.players;
    final bench = allPlayers.where((p) => !p.isOnCourt).toList();
    final teamColor =
        teamId == 'A' ? state.config.teamA.color : state.config.teamB.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubstitutionSheet(
        teamId: teamId,
        onCourt: onCourt,
        bench: bench,
        teamColor: teamColor,
        onConfirm: (inId, outId) {
          Navigator.pop(context);
          ref
              .read(basketballProvider.notifier)
              .performSubstitution(teamId, inId, outId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(basketballProvider);
    final notifier = ref.read(basketballProvider.notifier);

    // Listen for 21-point milestone in 3v3
    ref.listen<BasketballGameState>(basketballProvider, (prev, next) {
      if (next.twentyOneTeam != null &&
          next.twentyOneTeam != prev?.twentyOneTeam) {
        _handle21Alert(next.twentyOneTeam!);
      }
    });

    return Scaffold(
      backgroundColor: context.colors.colorBackgroundPrimary,
      body: SafeArea(
        child: state.isGameOver
            ? _GameOverPanel(state: state, onBack: () => context.go(AppRoutes.home))
            : Row(
                children: [
                  // Team A panel
                  Expanded(
                    flex: 2,
                    child: _TeamPanel(
                      teamId: 'A',
                      state: state,
                      onScoringEvent: _onScoringEvent,
                      onSubTap: () => _showSubPanel('A'),
                      onTimeout: () => notifier.callTimeout('A'),
                    ),
                  ),
                  Container(width: 0.5, color: context.colors.colorBorderSubtle),
                  // Center control panel
                  Expanded(
                    flex: 3,
                    child: _CenterPanel(
                      state: state,
                      onBack: _onBackPressed,
                      onToggleClock: notifier.toggleClock,
                      onUndo: notifier.undoLast,
                      onNextPeriod: notifier.nextPeriod,
                      onStatTapped: _onStatTapped,
                      onToggleShotClock: notifier.toggleShotClock,
                      onResetShotClock: notifier.resetShotClock,
                      onSettings: _showInGameSettings,
                    ),
                  ),
                  Container(width: 0.5, color: context.colors.colorBorderSubtle),
                  // Team B panel
                  Expanded(
                    flex: 2,
                    child: _TeamPanel(
                      teamId: 'B',
                      state: state,
                      onScoringEvent: _onScoringEvent,
                      onSubTap: () => _showSubPanel('B'),
                      onTimeout: () => notifier.callTimeout('B'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TEAM PANEL
// ═══════════════════════════════════════════════════════════════

class _TeamPanel extends StatelessWidget {
  const _TeamPanel({
    required this.teamId,
    required this.state,
    required this.onScoringEvent,
    required this.onSubTap,
    required this.onTimeout,
  });

  final String teamId;
  final BasketballGameState state;
  final void Function(BballEvent, String) onScoringEvent;
  final VoidCallback onSubTap;
  final VoidCallback onTimeout;

  bool get isA => teamId == 'A';

  String get teamName =>
      isA ? state.config.teamA.name : state.config.teamB.name;

  Color get teamColor =>
      isA ? state.config.teamA.color : state.config.teamB.color;

  int get score => isA ? state.scoreA : state.scoreB;
  int get fouls => isA ? state.foulsA : state.foulsB;
  int get timeoutsLeft => isA ? state.timeoutsLeftA : state.timeoutsLeftB;

  List<BballPlayer> get onCourt =>
      isA ? state.onCourtA : state.onCourtB;

  /// 3v3: +1 (inside arc) and +2 (outside arc)  — FIBA 3x3 scoring
  /// 5v5: +2 field goal, +3 three-pointer, FT
  List<BballEvent> get _scoringEvents =>
      state.config.format == BballFormat.threeVsThree
          ? [BballEvent.onePoint, BballEvent.twoPoint, BballEvent.freeThrow, BballEvent.foul]
          : [BballEvent.twoPoint, BballEvent.threePoint, BballEvent.freeThrow, BballEvent.foul];

  @override
  Widget build(BuildContext context) {
    final isDetailed = state.config.mode == BballMode.detailed;
    final is5v5 = state.config.format == BballFormat.fiveVsFive;

    return Container(
      color: AppColors.black,
      child: Column(
        children: [
          // Team header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              mainAxisAlignment: isA
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (!isA) const Spacer(),
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: teamColor,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    teamName.toUpperCase(),
                    style: AppTextStyles.headingS(context.colors.colorTextPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isA) const Spacer(),
              ],
            ),
          ),

          // Score
          Expanded(
            child: Center(
              child: Text(
                '$score',
                style: AppTextStyles.scoreXXL(teamColor),
              ),
            ),
          ),

          // Foul dots
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FoulDots(
              fouls: fouls,
              teamColor: teamColor,
              foulBonus: state.config.teamFoulBonus,
            ),
          ),

          // Timeout dots
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _TimeoutDots(
              timeoutsLeft: timeoutsLeft,
              total: state.config.timeoutsPerTeam,
              teamColor: teamColor,
              onTimeout: onTimeout,
            ),
          ),

          // Scoring grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: _ScoringGrid(
              events: _scoringEvents,
              teamColor: teamColor,
              is3v3: state.config.format == BballFormat.threeVsThree,
              onEvent: (e) => onScoringEvent(e, teamId),
            ),
          ),

          // On-court players (detailed mode)
          if (isDetailed && onCourt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
              child: _OnCourtList(
                  players: onCourt, teamColor: teamColor),
            ),

          // Sub button (5v5 + detailed)
          if (isDetailed && is5v5)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: GestureDetector(
                onTap: onSubTap,
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: teamColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: teamColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'SUB',
                      style: AppTextStyles.labelM(teamColor),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOUL DOTS
// ═══════════════════════════════════════════════════════════════

class _FoulDots extends StatelessWidget {
  const _FoulDots({
    required this.fouls,
    required this.teamColor,
    required this.foulBonus,
  });
  final int fouls;
  final Color teamColor;
  final int foulBonus;

  @override
  Widget build(BuildContext context) {
    final isBonus = fouls >= foulBonus;

    if (fouls > foulBonus) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: teamColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: teamColor.withValues(alpha: 0.4)),
        ),
        child: Text(
          'FOULS: $fouls — BONUS',
          style: AppTextStyles.labelS(teamColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(foulBonus, (i) {
          final filled = i < fouls;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (isBonus ? AppColors.warning : teamColor)
                    : context.colors.colorSurfaceElevated,
                border: Border.all(
                  color: filled
                      ? (isBonus ? AppColors.warning : teamColor)
                      : context.colors.colorBorderSubtle,
                  width: 0.5,
                ),
              ),
            ),
          );
        }),
        if (isBonus) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            'BONUS',
            style: AppTextStyles.overline(AppColors.warning),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCORING GRID
// ═══════════════════════════════════════════════════════════════

class _ScoringGrid extends StatelessWidget {
  const _ScoringGrid({
    required this.events,
    required this.teamColor,
    required this.onEvent,
    this.is3v3 = false,
  });

  final List<BballEvent> events;
  final Color teamColor;
  final ValueChanged<BballEvent> onEvent;
  final bool is3v3;

  String _labelFor(BballEvent e) {
    if (is3v3) {
      if (e == BballEvent.onePoint) return 'PAINT\n+1';
      if (e == BballEvent.twoPoint) return 'ARC\n+2';
    }
    return e.label;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
      ),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final event = events[i];
        final isFoul = event == BballEvent.foul;
        final color = isFoul ? AppColors.warning : teamColor;
        return GestureDetector(
          onTap: () => onEvent(event),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: isFoul ? 0.1 : 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: color.withValues(alpha: isFoul ? 0.4 : 0.35),
                width: isFoul ? 1 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                _labelFor(event),
                textAlign: TextAlign.center,
                style: AppTextStyles.statM(color),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ON-COURT PLAYER LIST
// ═══════════════════════════════════════════════════════════════

class _OnCourtList extends StatelessWidget {
  const _OnCourtList({required this.players, required this.teamColor});
  final List<BballPlayer> players;
  final Color teamColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: players.map((p) {
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: teamColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: teamColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            '#${p.number} ${p.name}',
            style: AppTextStyles.labelS(teamColor),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CENTER PANEL
// ═══════════════════════════════════════════════════════════════

class _CenterPanel extends StatelessWidget {
  const _CenterPanel({
    required this.state,
    required this.onBack,
    required this.onToggleClock,
    required this.onUndo,
    required this.onNextPeriod,
    required this.onStatTapped,
    required this.onToggleShotClock,
    required this.onResetShotClock,
    required this.onSettings,
  });

  final BasketballGameState state;
  final VoidCallback onBack;
  final VoidCallback onToggleClock;
  final VoidCallback onUndo;
  final VoidCallback onNextPeriod;
  final ValueChanged<BballEvent> onStatTapped;
  final VoidCallback onToggleShotClock;
  final void Function({bool toFourteen}) onResetShotClock;
  final VoidCallback onSettings;

  static const _statEvents = [
    BballEvent.rebound,
    BballEvent.assist,
    BballEvent.steal,
    BballEvent.block,
    BballEvent.turnover,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.colorSurfacePrimary,
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                _IconCircleBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack),
                const Spacer(),
                Flexible(
                  child: Text(
                    '🏀  BASKETBALL',
                    style: AppTextStyles.overline(context.colors.colorTextSecondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const Spacer(),
                // Settings — small, unobtrusive
                GestureDetector(
                  onTap: onSettings,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      Icons.tune_rounded,
                      color: context.colors.colorTextTertiary,
                      size: 16,
                    ),
                  ),
                ),
                _IconCircleBtn(
                    icon: Icons.undo_rounded, onTap: onUndo),
              ],
            ),
          ),

          // Period badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: context.colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border:
                  Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
            ),
            child: Text(
              state.periodFullLabel,
              style: AppTextStyles.overline(AppColors.white),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Game clock — bigger tap target with play/pause icon
          GestureDetector(
            onTap: onToggleClock,
            child: AnimatedContainer(
              duration: AppDuration.normal,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: state.isClockRunning
                    ? AppColors.red.withValues(alpha: 0.08)
                    : context.colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: state.isClockRunning
                      ? AppColors.red.withValues(alpha: 0.5)
                      : context.colors.colorBorderSubtle,
                  width: state.isClockRunning ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isClockRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: state.isClockRunning
                        ? AppColors.white
                        : context.colors.colorTextSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    state.clockDisplay,
                    style: AppTextStyles.statL(
                      state.isClockRunning
                          ? AppColors.white
                          : context.colors.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Shot clock row
          if (state.config.hasShotClock) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SHOT',
                  style: AppTextStyles.overline(context.colors.colorTextSecondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onToggleShotClock,
                  child: _ShotClockDisplay(
                    seconds: state.shotClockSeconds,
                    isRunning: state.isShotClockRunning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 5v5: show both 24 and 14; 3v3: show only 14
                if (state.config.format == BballFormat.fiveVsFive) ...[
                  _ClockResetBtn(
                    label: '24',
                    onTap: () => onResetShotClock(),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                _ClockResetBtn(
                  label: '14',
                  onTap: () => onResetShotClock(toFourteen: true),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Stat buttons — only if extraStats enabled
          if (state.config.extraStats)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: _statEvents
                    .map(
                      (e) => GestureDetector(
                        onTap: () => onStatTapped(e),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: context.colors.colorSurfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: context.colors.colorBorderSubtle, width: 0.5),
                          ),
                          child: Text(
                            e.label,
                            style: AppTextStyles.headingS(
                                context.colors.colorTextSecondary),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: AppSpacing.sm),

          // Event log
          Expanded(
            child: _CompactEventLog(state: state),
          ),

          // Next period / End game
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: GestureDetector(
              onTap: onNextPeriod,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: state.isLastPeriod
                      ? AppColors.red.withValues(alpha: 0.12)
                      : context.colors.colorSurfaceElevated,
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: state.isLastPeriod
                        ? AppColors.red.withValues(alpha: 0.4)
                        : context.colors.colorBorderSubtle,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    state.isLastPeriod ? 'END GAME' : 'NEXT ${state.periodLabel[0]} →',
                    style: AppTextStyles.overline(
                      state.isLastPeriod
                          ? AppColors.red
                          : context.colors.colorTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHOT CLOCK DISPLAY
// ═══════════════════════════════════════════════════════════════

class _ShotClockDisplay extends StatelessWidget {
  const _ShotClockDisplay({
    required this.seconds,
    required this.isRunning,
  });
  final int seconds;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final isWarning = seconds <= 5 && seconds > 0;
    final isExpired = seconds <= 0;

    final borderColor = isExpired
        ? AppColors.red.withValues(alpha: 0.8)
        : isWarning
            ? AppColors.warning.withValues(alpha: 0.6)
            : isRunning
                ? AppColors.info.withValues(alpha: 0.5)
                : context.colors.colorBorderSubtle;

    final bgColor = isExpired
        ? AppColors.red.withValues(alpha: 0.12)
        : isWarning
            ? AppColors.warning.withValues(alpha: 0.08)
            : isRunning
                ? AppColors.info.withValues(alpha: 0.06)
                : context.colors.colorSurfaceElevated;

    final textColor = isExpired
        ? AppColors.red
        : isWarning
            ? AppColors.warning
            : isRunning
                ? AppColors.white
                : context.colors.colorTextSecondary;

    return AnimatedContainer(
      duration: AppDuration.fast,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: borderColor,
            width: isWarning || isExpired || isRunning ? 1.5 : 0.5),
      ),
      child: Center(
        child: Text(
          '$seconds',
          style: AppTextStyles.statM(textColor),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CLOCK RESET BUTTON
// ═══════════════════════════════════════════════════════════════

class _ClockResetBtn extends StatelessWidget {
  const _ClockResetBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.labelM(context.colors.colorTextSecondary)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COMPACT EVENT LOG
// ═══════════════════════════════════════════════════════════════

class _CompactEventLog extends StatelessWidget {
  const _CompactEventLog({required this.state});
  final BasketballGameState state;

  @override
  Widget build(BuildContext context) {
    if (state.events.isEmpty) {
      return Center(
        child: Text(
          'Tap to score',
          style: AppTextStyles.bodyS(context.colors.colorTextSecondary),
        ),
      );
    }

    final events = state.events;
    final count = events.length > 12 ? 12 : events.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
      ),
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.zero,
        itemCount: count,
        itemBuilder: (_, i) {
          final e = events[events.length - 1 - i];
          final isA = e.teamId == 'A';
          final color = isA
              ? state.config.teamA.color
              : state.config.teamB.color;
          final teamName =
              isA ? state.config.teamA.name : state.config.teamB.name;
          final isFirst = i == 0;

          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: isFirst
                  ? color.withValues(alpha: 0.06)
                  : Colors.transparent,
              border: i < count - 1
                  ? Border(
                      bottom: BorderSide(
                          color: context.colors.colorBorderSubtle, width: 0.5))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${e.displayLabel}  $teamName',
                    style: AppTextStyles.bodyS(
                      isFirst
                          ? context.colors.colorTextPrimary
                          : context.colors.colorTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GAME OVER PANEL
// ═══════════════════════════════════════════════════════════════

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({required this.state, required this.onBack});
  final BasketballGameState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final aWon = state.scoreA > state.scoreB;
    final tied = state.scoreA == state.scoreB;
    final winnerName = tied
        ? 'TIE'
        : (aWon ? state.config.teamA.name : state.config.teamB.name);
    final winnerColor = tied
        ? context.colors.colorTextSecondary
        : (aWon ? state.config.teamA.color : state.config.teamB.color);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GAME OVER',
              style: AppTextStyles.overline(context.colors.colorTextSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tied ? 'TIE GAME' : '$winnerName WINS',
              style: AppTextStyles.displayL(winnerColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  Text(state.config.teamA.name,
                      style: AppTextStyles.overline(state.config.teamA.color)),
                  Text('${state.scoreA}',
                      style: AppTextStyles.scoreXXL(state.config.teamA.color)),
                ]),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text('—',
                      style: AppTextStyles.displayM(context.colors.colorTextSecondary)),
                ),
                Column(children: [
                  Text(state.config.teamB.name,
                      style: AppTextStyles.overline(state.config.teamB.color)),
                  Text('${state.scoreB}',
                      style: AppTextStyles.scoreXXL(state.config.teamB.color)),
                ]),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'DONE',
                  style: AppTextStyles.headingM(AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ATTRIBUTION DIALOG  (center popup with jersey boxes)
// ═══════════════════════════════════════════════════════════════

class _AttributionDialog extends StatelessWidget {
  const _AttributionDialog({
    required this.event,
    required this.players,
    required this.teamColor,
  });

  final BballEvent event;
  final List<BballPlayer> players;
  final Color teamColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.overlay,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clock header — live via Consumer
            Consumer(
              builder: (context, ref, child) {
                final s = ref.watch(basketballProvider);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.colorSurfaceElevated,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl)),
                    border: Border(
                      bottom: BorderSide(
                          color: context.colors.colorBorderSubtle, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Game clock
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: s.isClockRunning
                              ? AppColors.red.withValues(alpha: 0.12)
                              : context.colors.colorSurfacePrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: s.isClockRunning
                                ? AppColors.red.withValues(alpha: 0.4)
                                : context.colors.colorBorderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.periodLabel,
                                style: AppTextStyles.overline(
                                    context.colors.colorTextSecondary)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(s.clockDisplay,
                                style: AppTextStyles.labelM(
                                    context.colors.colorTextPrimary)),
                          ],
                        ),
                      ),
                      // Shot clock
                      if (s.config.hasShotClock) ...[
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: s.shotClockSeconds <= 5
                                ? AppColors.warning.withValues(alpha: 0.12)
                                : context.colors.colorSurfacePrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: s.shotClockSeconds <= 5
                                  ? AppColors.warning.withValues(alpha: 0.4)
                                  : context.colors.colorBorderSubtle,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('SHOT',
                                  style: AppTextStyles.overline(
                                      context.colors.colorTextSecondary)),
                              const SizedBox(width: AppSpacing.xs),
                              Text('${s.shotClockSeconds}',
                                  style: AppTextStyles.labelM(
                                    s.shotClockSeconds <= 5
                                        ? AppColors.warning
                                        : context.colors.colorTextPrimary,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'WHO GOT THE ${event.label}?',
              style: AppTextStyles.overline(context.colors.colorTextSecondary),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Jersey boxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  ...players.map(
                    (p) => _JerseyBox(
                      number: '${p.number}',
                      name: p.name,
                      color: teamColor,
                      onTap: () => Navigator.pop(context, p.id),
                    ),
                  ),
                  _JerseyBox(
                    number: '?',
                    name: 'Unknown',
                    color: context.colors.colorTextSecondary,
                    onTap: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _JerseyBox extends StatelessWidget {
  const _JerseyBox({
    required this.number,
    required this.name,
    required this.color,
    required this.onTap,
  });

  final String number;
  final String name;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: AppTextStyles.statL(color),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: AppTextStyles.labelS(
                  context.colors.colorTextSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TEAM PICKER SHEET
// ═══════════════════════════════════════════════════════════════

class _TeamPickerSheet extends StatelessWidget {
  const _TeamPickerSheet({
    required this.teamAName,
    required this.teamBName,
    required this.teamAColor,
    required this.teamBColor,
    required this.eventLabel,
    required this.onTeamSelected,
  });

  final String teamAName;
  final String teamBName;
  final Color teamAColor;
  final Color teamBColor;
  final String eventLabel;
  final ValueChanged<String> onTeamSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.colorBorderSubtle,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'WHICH TEAM — $eventLabel?',
            style: AppTextStyles.overline(context.colors.colorTextSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: _PlayerChip(
                    label: teamAName,
                    color: teamAColor,
                    onTap: () => onTeamSelected('A'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PlayerChip(
                    label: teamBName,
                    color: teamBColor,
                    onTap: () => onTeamSelected('B'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUBSTITUTION SHEET
// ═══════════════════════════════════════════════════════════════

class _SubstitutionSheet extends StatefulWidget {
  const _SubstitutionSheet({
    required this.teamId,
    required this.onCourt,
    required this.bench,
    required this.teamColor,
    required this.onConfirm,
  });

  final String teamId;
  final List<BballPlayer> onCourt;
  final List<BballPlayer> bench;
  final Color teamColor;
  final void Function(String inId, String outId) onConfirm;

  @override
  State<_SubstitutionSheet> createState() => _SubstitutionSheetState();
}

class _SubstitutionSheetState extends State<_SubstitutionSheet> {
  String? _incomingId;
  String? _outgoingId;

  bool get _canConfirm =>
      _incomingId != null && _outgoingId != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.colorBorderSubtle,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'SUBSTITUTION',
            style: AppTextStyles.headingS(context.colors.colorTextPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bench (incoming)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BENCH — SELECT INCOMING',
                    style: AppTextStyles.overline(
                        context.colors.colorTextSecondary)),
                const SizedBox(height: AppSpacing.sm),
                if (widget.bench.isEmpty)
                  Text('No bench players',
                      style: AppTextStyles.bodyS(
                          context.colors.colorTextSecondary))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.bench.map((p) {
                        final selected = p.id == _incomingId;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _SubPlayerChip(
                            player: p,
                            selected: selected,
                            color: widget.teamColor,
                            onTap: () =>
                                setState(() => _incomingId = p.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // On-court (outgoing)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ON COURT — SELECT OUTGOING',
                    style: AppTextStyles.overline(
                        context.colors.colorTextSecondary)),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.onCourt.map((p) {
                      final selected = p.id == _outgoingId;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _SubPlayerChip(
                          player: p,
                          selected: selected,
                          color: widget.teamColor
                              .withValues(alpha: 0.5),
                          onTap: () =>
                              setState(() => _outgoingId = p.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Confirm CTA
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AnimatedOpacity(
              duration: AppDuration.fast,
              opacity: _canConfirm ? 1.0 : 0.35,
              child: GestureDetector(
                onTap: _canConfirm
                    ? () => widget.onConfirm(_incomingId!, _outgoingId!)
                    : null,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.teamColor,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Center(
                    child: Text(
                      'CONFIRM SUB',
                      style: AppTextStyles.headingS(AppColors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 52),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.headingS(color),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SubPlayerChip extends StatelessWidget {
  const _SubPlayerChip({
    required this.player,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final BballPlayer player;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        constraints: const BoxConstraints(minWidth: 80, minHeight: 52),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.25)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.25),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${player.number}',
              style: AppTextStyles.labelM(color),
            ),
            Text(
              player.name,
              style: AppTextStyles.bodyS(context.colors.colorTextPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircleBtn extends StatelessWidget {
  const _IconCircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.colorSurfaceElevated,
          border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.white, size: 14),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TIMEOUT DOTS
// ═══════════════════════════════════════════════════════════════

class _TimeoutDots extends StatelessWidget {
  const _TimeoutDots({
    required this.timeoutsLeft,
    required this.total,
    required this.teamColor,
    required this.onTimeout,
  });

  final int timeoutsLeft;
  final int total;
  final Color teamColor;
  final VoidCallback onTimeout;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: timeoutsLeft > 0 ? onTimeout : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('T/O', style: AppTextStyles.overline(context.colors.colorTextTertiary)),
          const SizedBox(width: AppSpacing.xs),
          ...List.generate(total, (i) {
            final used = i >= timeoutsLeft;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: used
                      ? context.colors.colorSurfaceElevated
                      : teamColor.withValues(alpha: 0.7),
                  border: Border.all(
                    color: used ? context.colors.colorBorderSubtle : teamColor.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  21-POINT DIALOG (3v3)
// ═══════════════════════════════════════════════════════════════

enum _TwentyOneAction { endGame, keepPlaying }

class _TwentyOneDialog extends StatelessWidget {
  const _TwentyOneDialog({required this.teamName});
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.overlay,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.basketball.withValues(alpha: 0.3), width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.basketball.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.basketball.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: Text('21', style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.basketball,
                )),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '$teamName reached 21',
              style: AppTextStyles.headingM(context.colors.colorTextPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'End the game and declare the winner, or keep playing.',
              style: AppTextStyles.bodyS(context.colors.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => Navigator.pop(context, _TwentyOneAction.endGame),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.basketball,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text('DECLARE WINNER', style: AppTextStyles.headingS(AppColors.white)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => Navigator.pop(context, _TwentyOneAction.keepPlaying),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
                ),
                child: Center(
                  child: Text('KEEP PLAYING', style: AppTextStyles.headingS(context.colors.colorTextSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  QUIT GAME DIALOG
// ═══════════════════════════════════════════════════════════════

class _QuitGameDialog extends StatelessWidget {
  const _QuitGameDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.overlay,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Leave Game?', style: AppTextStyles.headingM(context.colors.colorTextPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your current game progress will be lost.',
              style: AppTextStyles.bodyS(context.colors.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text('QUIT GAME', style: AppTextStyles.headingS(AppColors.red)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
                ),
                child: Center(
                  child: Text('KEEP PLAYING', style: AppTextStyles.headingS(context.colors.colorTextSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  IN-GAME SETTINGS SHEET
// ═══════════════════════════════════════════════════════════════

class _GameSettingsSheet extends StatefulWidget {
  const _GameSettingsSheet({
    required this.state,
    required this.onAutoResetChanged,
    required this.onEditPlayer,
  });

  final BasketballGameState state;
  final ValueChanged<bool> onAutoResetChanged;
  final void Function(String teamId, String playerId, String name) onEditPlayer;

  @override
  State<_GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends State<_GameSettingsSheet> {
  late bool _autoReset;

  @override
  void initState() {
    super.initState();
    _autoReset = widget.state.config.autoResetShotClock;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final allPlayers = [
      ...widget.state.config.teamA.players.map((p) => (teamId: 'A', player: p)),
      ...widget.state.config.teamB.players.map((p) => (teamId: 'B', player: p)),
    ];
    final hasPlayers = allPlayers.isNotEmpty;

    return Container(
      margin: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, bottomPad + AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + title
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.colorBorderSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: context.colors.colorTextSecondary, size: 14),
                const SizedBox(width: AppSpacing.sm),
                Text('GAME SETTINGS', style: AppTextStyles.overline(context.colors.colorTextSecondary)),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Container(height: 0.5, color: context.colors.colorBorderSubtle),
          const SizedBox(height: AppSpacing.md),

          // Shot clock auto-reset toggle
          if (widget.state.config.hasShotClock)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Auto-reset shot clock on score',
                            style: AppTextStyles.bodyS(context.colors.colorTextPrimary)),
                        const SizedBox(height: 2),
                        Text('Resets to ${widget.state.config.shotClockDuration}s on every basket',
                            style: AppTextStyles.labelS(context.colors.colorTextSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoReset,
                    onChanged: (v) {
                      setState(() => _autoReset = v);
                      widget.onAutoResetChanged(v);
                    },
                    activeThumbColor: AppColors.basketball,
                    activeTrackColor: AppColors.basketball.withValues(alpha: 0.3),
                    inactiveTrackColor: context.colors.colorSurfaceElevated,
                    inactiveThumbColor: context.colors.colorTextSecondary,
                  ),
                ],
              ),
            ),

          // Player name editor (if detailed mode with players)
          if (hasPlayers) ...[
            const SizedBox(height: AppSpacing.md),
            Container(height: 0.5, color: context.colors.colorBorderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Text('EDIT PLAYERS', style: AppTextStyles.overline(context.colors.colorTextSecondary)),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: allPlayers.length,
                itemBuilder: (_, i) {
                  final entry = allPlayers[i];
                  final color = entry.teamId == 'A'
                      ? widget.state.config.teamA.color
                      : widget.state.config.teamB.color;
                  return _InlinePlayerEditor(
                    player: entry.player,
                    teamColor: color,
                    onNameChanged: (name) =>
                        widget.onEditPlayer(entry.teamId, entry.player.id, name),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _InlinePlayerEditor extends StatefulWidget {
  const _InlinePlayerEditor({
    required this.player,
    required this.teamColor,
    required this.onNameChanged,
  });

  final BballPlayer player;
  final Color teamColor;
  final ValueChanged<String> onNameChanged;

  @override
  State<_InlinePlayerEditor> createState() => _InlinePlayerEditorState();
}

class _InlinePlayerEditorState extends State<_InlinePlayerEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.player.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.teamColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: widget.teamColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Center(
              child: Text(
                '#${widget.player.number}',
                style: AppTextStyles.labelS(widget.teamColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: widget.onNameChanged,
                style: AppTextStyles.bodyS(context.colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Player name',
                  hintStyle: AppTextStyles.bodyS(context.colors.colorTextSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

