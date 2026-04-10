// lib/screens/scoring/basketball/basketball_players_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import 'models/basketball_models.dart';

class BasketballPlayersScreen extends ConsumerStatefulWidget {
  const BasketballPlayersScreen({super.key, required this.config});
  final BballGameConfig config;

  @override
  ConsumerState<BasketballPlayersScreen> createState() =>
      _BasketballPlayersScreenState();
}

class _BasketballPlayersScreenState
    extends ConsumerState<BasketballPlayersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<BballPlayer> _playersA;
  late List<BballPlayer> _playersB;

  bool get is5v5 => widget.config.format == BballFormat.fiveVsFive;
  int get startingCount => widget.config.startingCount;
  int get maxRoster => widget.config.maxRosterSize;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _playersA = [];
    _playersB = [];
    // Pre-populate with empty slots for starting lineup
    for (int i = 0; i < startingCount; i++) {
      _playersA.add(BballPlayer(
        id: BballPlayer.generateId('A', i),
        name: '',
        number: i + 1,
        isOnCourt: true,
      ));
      _playersB.add(BballPlayer(
        id: BballPlayer.generateId('B', i),
        name: '',
        number: i + 1,
        isOnCourt: true,
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addPlayer(String teamId) {
    setState(() {
      final list = teamId == 'A' ? _playersA : _playersB;
      final idx = list.length;
      final newPlayer = BballPlayer(
        id: BballPlayer.generateId(teamId, idx),
        name: '',
        number: idx + 1,
        isOnCourt: false,
      );
      if (teamId == 'A') {
        _playersA = [..._playersA, newPlayer];
      } else {
        _playersB = [..._playersB, newPlayer];
      }
    });
  }

  void _removePlayer(String teamId, int index) {
    setState(() {
      if (teamId == 'A') {
        _playersA = [..._playersA]..removeAt(index);
      } else {
        _playersB = [..._playersB]..removeAt(index);
      }
    });
  }

  void _toggleOnCourt(String teamId, int index) {
    if (!is5v5) return;
    setState(() {
      final list =
          (teamId == 'A' ? _playersA : _playersB).toList();
      final player = list[index];
      final onCourtCount = list.where((p) => p.isOnCourt).length;

      if (player.isOnCourt) {
        list[index] = player.copyWith(isOnCourt: false);
      } else {
        if (onCourtCount >= startingCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.overlay,
              content: Text(
                'Max $startingCount starters per team',
                style: AppTextStyles.bodyS(context.colors.colorTextPrimary),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        list[index] = player.copyWith(isOnCourt: true);
      }

      if (teamId == 'A') {
        _playersA = list;
      } else {
        _playersB = list;
      }
    });
  }

  String? _validate() {
    final aNames =
        _playersA.where((p) => p.name.trim().isNotEmpty).length;
    final bNames =
        _playersB.where((p) => p.name.trim().isNotEmpty).length;
    final aStarters =
        _playersA.where((p) => p.isOnCourt).length;
    final bStarters =
        _playersB.where((p) => p.isOnCourt).length;

    if (aNames < startingCount) {
      return 'Team A needs at least $startingCount players with names';
    }
    if (bNames < startingCount) {
      return 'Team B needs at least $startingCount players with names';
    }
    if (is5v5 && aStarters != startingCount) {
      return 'Select exactly $startingCount starters for Team A';
    }
    if (is5v5 && bStarters != startingCount) {
      return 'Select exactly $startingCount starters for Team B';
    }
    return null;
  }

  void _onStartGame() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.overlay,
          content: Text(
            error,
            style: AppTextStyles.bodyS(AppColors.red),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final updatedConfig = widget.config.copyWith(
      teamA: widget.config.teamA.copyWith(players: _playersA),
      teamB: widget.config.teamB.copyWith(players: _playersB),
    );

    context.push(AppRoutes.bballScorer, extra: updatedConfig);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.colorBackgroundPrimary,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.colorSurfacePrimary,
                      border: Border.all(
                          color: context.colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${is5v5 ? "5v5" : "3v3"} — $startingCount STARTERS',
                      style: AppTextStyles.overline(AppColors.info),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'ADD PLAYERS',
                      style: AppTextStyles.headingL(
                          context.colors.colorTextPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.colorSurfacePrimary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.all(4),
                labelStyle:
                    AppTextStyles.headingS(AppColors.white),
                unselectedLabelStyle:
                    AppTextStyles.headingS(context.colors.colorTextSecondary),
                tabs: [
                  Tab(text: widget.config.teamA.name),
                  Tab(text: widget.config.teamB.name),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TeamRoster(
                  teamId: 'A',
                  players: _playersA,
                  teamColor: widget.config.teamA.color,
                  is5v5: is5v5,
                  startingCount: startingCount,
                  maxRoster: maxRoster,
                  onAddPlayer: () => _addPlayer('A'),
                  onRemovePlayer: (i) => _removePlayer('A', i),
                  onToggleOnCourt: (i) => _toggleOnCourt('A', i),
                  onPlayerChanged: (i, name, number) {
                    setState(() {
                      final list = [..._playersA];
                      list[i] = list[i].copyWith(
                        name: name,
                        number: number,
                      );
                      _playersA = list;
                    });
                  },
                ),
                _TeamRoster(
                  teamId: 'B',
                  players: _playersB,
                  teamColor: widget.config.teamB.color,
                  is5v5: is5v5,
                  startingCount: startingCount,
                  maxRoster: maxRoster,
                  onAddPlayer: () => _addPlayer('B'),
                  onRemovePlayer: (i) => _removePlayer('B', i),
                  onToggleOnCourt: (i) => _toggleOnCourt('B', i),
                  onPlayerChanged: (i, name, number) {
                    setState(() {
                      final list = [..._playersB];
                      list[i] = list[i].copyWith(
                        name: name,
                        number: number,
                      );
                      _playersB = list;
                    });
                  },
                ),
              ],
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
                bottomPad + AppSpacing.lg),
            child: GestureDetector(
              onTap: _onStartGame,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    'START GAME',
                    style:
                        AppTextStyles.headingM(AppColors.white),
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
//  TEAM ROSTER
// ═══════════════════════════════════════════════════════════════

class _TeamRoster extends StatefulWidget {
  const _TeamRoster({
    required this.teamId,
    required this.players,
    required this.teamColor,
    required this.is5v5,
    required this.startingCount,
    required this.maxRoster,
    required this.onAddPlayer,
    required this.onRemovePlayer,
    required this.onToggleOnCourt,
    required this.onPlayerChanged,
  });

  final String teamId;
  final List<BballPlayer> players;
  final Color teamColor;
  final bool is5v5;
  final int startingCount;
  final int maxRoster;
  final VoidCallback onAddPlayer;
  final ValueChanged<int> onRemovePlayer;
  final ValueChanged<int> onToggleOnCourt;
  final void Function(int index, String name, int number) onPlayerChanged;

  @override
  State<_TeamRoster> createState() => _TeamRosterState();
}

class _TeamRosterState extends State<_TeamRoster> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_TeamRoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New player added — scroll to bottom so "Add Player" stays visible
    if (widget.players.length > oldWidget.players.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: AppDuration.normal,
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starters = widget.players.where((p) => p.isOnCourt).toList();
    final bench = widget.players.where((p) => !p.isOnCourt).toList();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // Starters section
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Text(
                'STARTING ${widget.startingCount}',
                style: AppTextStyles.overline(context.colors.colorTextSecondary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.teamColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${starters.length}/${widget.startingCount}',
                  style: AppTextStyles.labelS(widget.teamColor),
                ),
              ),
            ],
          ),
        ),

        ...widget.players.asMap().entries.where((e) => e.value.isOnCourt).map(
          (entry) => _PlayerRow(
            index: entry.key,
            player: entry.value,
            teamColor: widget.teamColor,
            is5v5: widget.is5v5,
            isOnCourt: true,
            onRemove: () => widget.onRemovePlayer(entry.key),
            onToggle: () => widget.onToggleOnCourt(entry.key),
            onChanged: (name, number) =>
                widget.onPlayerChanged(entry.key, name, number),
          ),
        ),

        // Bench section (5v5 only or if bench players exist)
        if (bench.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.lg, bottom: AppSpacing.sm),
            child: Text(
              'BENCH',
              style: AppTextStyles.overline(context.colors.colorTextSecondary),
            ),
          ),
          ...widget.players.asMap().entries
              .where((e) => !e.value.isOnCourt)
              .map(
                (entry) => _PlayerRow(
                  index: entry.key,
                  player: entry.value,
                  teamColor: widget.teamColor,
                  is5v5: widget.is5v5,
                  isOnCourt: false,
                  onRemove: () => widget.onRemovePlayer(entry.key),
                  onToggle: () => widget.onToggleOnCourt(entry.key),
                  onChanged: (name, number) =>
                      widget.onPlayerChanged(entry.key, name, number),
                ),
              ),
        ],

        // Add player button — always visible via auto-scroll
        if (widget.players.length < widget.maxRoster)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: GestureDetector(
              onTap: widget.onAddPlayer,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: widget.teamColor.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: widget.teamColor, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ADD PLAYER',
                      style: AppTextStyles.headingS(widget.teamColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PLAYER ROW
// ═══════════════════════════════════════════════════════════════

class _PlayerRow extends StatefulWidget {
  const _PlayerRow({
    required this.index,
    required this.player,
    required this.teamColor,
    required this.is5v5,
    required this.isOnCourt,
    required this.onRemove,
    required this.onToggle,
    required this.onChanged,
  });

  final int index;
  final BballPlayer player;
  final Color teamColor;
  final bool is5v5;
  final bool isOnCourt;
  final VoidCallback onRemove;
  final VoidCallback onToggle;
  final void Function(String name, int number) onChanged;

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _numCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.player.name.isEmpty ? '' : widget.player.name);
    _numCtrl = TextEditingController(
        text: widget.player.number == 0
            ? ''
            : '${widget.player.number}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final name = _nameCtrl.text.trim();
    final number = int.tryParse(_numCtrl.text.trim()) ?? 0;
    widget.onChanged(name, number);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: widget.isOnCourt
                ? widget.teamColor.withValues(alpha: 0.25)
                : context.colors.colorBorderSubtle,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Jersey number
            Container(
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                color: widget.teamColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: widget.teamColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _numCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (_) => _notify(),
                textAlign: TextAlign.center,
                style: AppTextStyles.statM(widget.teamColor),
                decoration: InputDecoration(
                  hintText: '#',
                  hintStyle: AppTextStyles.statM(
                      context.colors.colorTextSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                ),
              ),
            ),

            Container(
                width: 0.5,
                height: 24,
                color: context.colors.colorBorderSubtle),

            const SizedBox(width: AppSpacing.md),

            // Name
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                onChanged: (_) => _notify(),
                style: AppTextStyles.headingS(
                    context.colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Player name',
                  hintStyle: AppTextStyles.headingS(
                      context.colors.colorTextSecondary
                          .withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),

            // On-court toggle (5v5 only)
            if (widget.is5v5)
              GestureDetector(
                onTap: widget.onToggle,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: AppSpacing.sm),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: widget.isOnCourt
                          ? widget.teamColor
                              .withValues(alpha: 0.15)
                          : context.colors.colorSurfaceElevated,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: widget.isOnCourt
                            ? widget.teamColor
                                .withValues(alpha: 0.4)
                            : context.colors.colorBorderSubtle,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      widget.isOnCourt ? 'STARTING' : 'BENCH',
                      style: AppTextStyles.labelS(
                        widget.isOnCourt
                            ? widget.teamColor
                            : context.colors.colorTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),

            // Remove
            GestureDetector(
              onTap: widget.onRemove,
              child: Padding(
                padding:
                    const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: context.colors.colorTextTertiary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
