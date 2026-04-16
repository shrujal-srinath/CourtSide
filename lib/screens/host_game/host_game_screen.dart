// lib/screens/host_game/host_game_screen.dart
//
// Host a Game — 4-step creation flow.
// Step 1: Game type (Public pickup / Private match / Tournament)
// Step 2: Sport + court location (any address, not just listed venues)
// Step 3: Date, time, player count
// Step 4: Review + publish

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

// ── Model ─────────────────────────────────────────────────────────

enum _GameType { pickup, privateMatch, tournament }

class _HostGameDraft {
  _GameType? gameType;
  String sport = '';
  String courtName = '';
  String courtAddress = '';
  DateTime? date;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int maxPlayers = 10;
  String? description;
  bool requireApproval = false;
}

// ═══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  final _draft = _HostGameDraft();
  int _step = 0;

  static const _totalSteps = 4;

  void _next() {
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Top bar ─────────────────────────────────────────────
          Container(
            color: colors.colorSurfacePrimary,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topPad + AppSpacing.sm,
                AppSpacing.lg, AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _back,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: colors.colorSurfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colors.colorBorderSubtle, width: 0.5),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: colors.colorTextPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HOST A GAME',
                              style: AppTextStyles.overline(
                                  colors.colorTextTertiary)),
                          Text(
                            _stepTitle(_step),
                            style: AppTextStyles.headingM(
                                colors.colorTextPrimary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_step + 1} / $_totalSteps',
                      style: AppTextStyles.labelS(colors.colorTextTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    backgroundColor: colors.colorBorderSubtle,
                    color: colors.colorAccentPrimary,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),

          // ── Step content ─────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0: return 'Game type';
      case 1: return 'Sport & court';
      case 2: return 'Date & players';
      case 3: return 'Review';
      default: return '';
    }
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0: return _StepGameType(draft: _draft, onNext: _next);
      case 1: return _StepCourtDetails(draft: _draft, onNext: _next);
      case 2: return _StepDateTime(draft: _draft, onNext: _next);
      case 3: return _StepReview(draft: _draft, onPublish: _onPublish);
      default: return const SizedBox.shrink();
    }
  }

  void _onPublish() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PublishSuccessDialog(draft: _draft),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STEP 1 — Game type
// ══════════════════════════════════════════════════════════════

class _StepGameType extends StatefulWidget {
  const _StepGameType({required this.draft, required this.onNext});
  final _HostGameDraft draft;
  final VoidCallback onNext;

  @override
  State<_StepGameType> createState() => _StepGameTypeState();
}

class _StepGameTypeState extends State<_StepGameType> {
  _GameType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.draft.gameType;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),
              _GameTypeCard(
                type: _GameType.pickup,
                title: 'Open Pickup',
                subtitle: 'Anyone can join — great for finding players',
                icon: Icons.groups_rounded,
                iconColor: colors.colorInfo,
                selected: _selected == _GameType.pickup,
                onTap: () => setState(() {
                  _selected = _GameType.pickup;
                  widget.draft.gameType = _GameType.pickup;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              _GameTypeCard(
                type: _GameType.privateMatch,
                title: 'Private Match',
                subtitle: 'Invite-only — you control who joins',
                icon: Icons.lock_rounded,
                iconColor: colors.colorAccentPrimary,
                selected: _selected == _GameType.privateMatch,
                onTap: () => setState(() {
                  _selected = _GameType.privateMatch;
                  widget.draft.gameType = _GameType.privateMatch;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              _GameTypeCard(
                type: _GameType.tournament,
                title: 'Tournament',
                subtitle: 'Structured brackets — best of N format',
                icon: Icons.emoji_events_rounded,
                iconColor: colors.colorWarning,
                selected: _selected == _GameType.tournament,
                onTap: () => setState(() {
                  _selected = _GameType.tournament;
                  widget.draft.gameType = _GameType.tournament;
                }),
              ),
            ],
          ),
        ),
        _NextButton(
          enabled: _selected != null,
          onTap: widget.onNext,
          label: 'Next — Sport & Court',
        ),
      ],
    );
  }
}

class _GameTypeCard extends StatefulWidget {
  const _GameTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });
  final _GameType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GameTypeCard> createState() => _GameTypeCardState();
}

class _GameTypeCardState extends State<_GameTypeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.iconColor.withValues(alpha: 0.07)
                : colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.selected
                  ? widget.iconColor.withValues(alpha: 0.45)
                  : colors.colorBorderSubtle,
              width: widget.selected ? 1 : 0.5,
            ),
            boxShadow: AppShadow.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: AppTextStyles.headingS(colors.colorTextPrimary)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style:
                            AppTextStyles.bodyS(colors.colorTextSecondary)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: AppDuration.fast,
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? widget.iconColor
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.selected
                        ? widget.iconColor
                        : colors.colorBorderMedium,
                    width: 1.5,
                  ),
                ),
                child: widget.selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STEP 2 — Sport & Court details
// ══════════════════════════════════════════════════════════════

class _StepCourtDetails extends StatefulWidget {
  const _StepCourtDetails({required this.draft, required this.onNext});
  final _HostGameDraft draft;
  final VoidCallback onNext;

  @override
  State<_StepCourtDetails> createState() => _StepCourtDetailsState();
}

class _StepCourtDetailsState extends State<_StepCourtDetails> {
  String _sport = '';
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();

  static const _sports = [
    ('basketball', 'Basketball', Icons.sports_basketball_rounded),
    ('cricket', 'Cricket', Icons.sports_cricket_rounded),
    ('football', 'Football', Icons.sports_soccer_rounded),
    ('badminton', 'Badminton', Icons.sports_tennis_rounded),
  ];

  static const _sportColors = {
    'basketball': Color(0xFFFF6B35),
    'cricket': Color(0xFF00C9A7),
    'football': Color(0xFF4CAF50),
    'badminton': Color(0xFFFFC107),
  };

  @override
  void initState() {
    super.initState();
    _sport = widget.draft.sport;
    _nameCtrl.text = widget.draft.courtName;
    _addrCtrl.text = widget.draft.courtAddress;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _sport.isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty &&
      _addrCtrl.text.trim().isNotEmpty;

  void _save() {
    widget.draft.sport = _sport;
    widget.draft.courtName = _nameCtrl.text.trim();
    widget.draft.courtAddress = _addrCtrl.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),

              // Sport picker
              Text('SPORT',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: _sports.map((s) {
                  final id = s.$1;
                  final label = s.$2;
                  final ico = s.$3;
                  final col = _sportColors[id] ?? colors.colorAccentPrimary;
                  final active = _sport == id;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sport = id),
                      child: AnimatedContainer(
                        duration: AppDuration.fast,
                        margin: EdgeInsets.only(
                            right: id != 'badminton' ? AppSpacing.sm : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? col.withValues(alpha: 0.12)
                              : colors.colorSurfacePrimary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: active
                                ? col.withValues(alpha: 0.5)
                                : colors.colorBorderSubtle,
                            width: active ? 1 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(ico,
                                color: active ? col : colors.colorTextTertiary,
                                size: 22),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: AppTextStyles.labelS(active
                                      ? col
                                      : colors.colorTextSecondary)
                                  .copyWith(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Court name
              Text('COURT NAME',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              _Field(
                controller: _nameCtrl,
                hint: 'e.g. My society court, Rajesh\'s rooftop',
                icon: Icons.stadium_outlined,
                onChanged: (_) => setState(() => _save()),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Court address / area
              Text('LOCATION',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              _Field(
                controller: _addrCtrl,
                hint: 'Area or full address',
                icon: Icons.location_on_outlined,
                onChanged: (_) => setState(() => _save()),
              ),

              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: colors.colorTextTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This court doesn\'t need to be listed on Courtside.',
                      style: AppTextStyles.bodyS(colors.colorTextTertiary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _NextButton(
          enabled: _canProceed,
          onTap: () {
            _save();
            widget.onNext();
          },
          label: 'Next — Date & Players',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STEP 3 — Date, time, player count
// ══════════════════════════════════════════════════════════════

class _StepDateTime extends StatefulWidget {
  const _StepDateTime({required this.draft, required this.onNext});
  final _HostGameDraft draft;
  final VoidCallback onNext;

  @override
  State<_StepDateTime> createState() => _StepDateTimeState();
}

class _StepDateTimeState extends State<_StepDateTime> {
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _maxPlayers = 10;
  bool _requireApproval = false;
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.draft.date;
    _startTime = widget.draft.startTime;
    _endTime = widget.draft.endTime;
    _maxPlayers = widget.draft.maxPlayers;
    _requireApproval = widget.draft.requireApproval;
    _descCtrl.text = widget.draft.description ?? '';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => _date != null && _startTime != null && _endTime != null;

  void _save() {
    widget.draft.date = _date;
    widget.draft.startTime = _startTime;
    widget.draft.endTime = _endTime;
    widget.draft.maxPlayers = _maxPlayers;
    widget.draft.requireApproval = _requireApproval;
    widget.draft.description = _descCtrl.text.trim().isEmpty
        ? null
        : _descCtrl.text.trim();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 18, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 20, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) { _startTime = picked; }
        else { _endTime = picked; }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),

              // Date
              Text('DATE',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              _PickerTile(
                icon: Icons.calendar_today_rounded,
                label: _date == null
                    ? 'Pick a date'
                    : '${_date!.day}/${_date!.month}/${_date!.year}',
                filled: _date != null,
                onTap: _pickDate,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Time
              Text('TIME',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_rounded,
                      label: _startTime == null
                          ? 'Start'
                          : _startTime!.format(context),
                      filled: _startTime != null,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_rounded,
                      label: _endTime == null
                          ? 'End'
                          : _endTime!.format(context),
                      filled: _endTime != null,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Max players stepper
              Text('MAX PLAYERS',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: colors.colorBorderSubtle, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_rounded,
                        color: colors.colorTextSecondary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        '$_maxPlayers players',
                        style: AppTextStyles.headingS(colors.colorTextPrimary),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: _maxPlayers > 2
                          ? () => setState(() => _maxPlayers--)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: _maxPlayers < 50
                          ? () => setState(() => _maxPlayers++)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Require approval toggle (only for private / tournament)
              if (widget.draft.gameType != _GameType.pickup) ...[
                _ToggleRow(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Approve join requests',
                  subtitle: 'Players must be approved before they can join',
                  value: _requireApproval,
                  onChanged: (v) => setState(() => _requireApproval = v),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],

              // Optional description
              Text('NOTE (optional)',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: colors.colorBorderSubtle, width: 0.5),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: AppTextStyles.bodyM(colors.colorTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add any rules, skill level, gear needed…',
                    hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        _NextButton(
          enabled: _canProceed,
          onTap: () {
            _save();
            widget.onNext();
          },
          label: 'Review Game',
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STEP 4 — Review & Publish
// ══════════════════════════════════════════════════════════════

class _StepReview extends StatelessWidget {
  const _StepReview({required this.draft, required this.onPublish});
  final _HostGameDraft draft;
  final VoidCallback onPublish;

  String _typeLabel(_GameType? t) {
    switch (t) {
      case _GameType.pickup:        return 'Open Pickup';
      case _GameType.privateMatch:  return 'Private Match';
      case _GameType.tournament:    return 'Tournament';
      default:                      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = draft.date;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '—';
    final timeStr = draft.startTime != null && draft.endTime != null
        ? '${draft.startTime!.format(context)} – ${draft.endTime!.format(context)}'
        : '—';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const SizedBox(height: AppSpacing.md),

              // Summary card
              Container(
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                      color: colors.colorBorderSubtle, width: 0.5),
                  boxShadow: AppShadow.card,
                ),
                child: Column(
                  children: [
                    _ReviewRow(
                        icon: Icons.category_rounded,
                        label: 'Type',
                        value: _typeLabel(draft.gameType)),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.sports_rounded,
                        label: 'Sport',
                        value: draft.sport.isEmpty
                            ? '—'
                            : draft.sport[0].toUpperCase() +
                                draft.sport.substring(1)),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.stadium_outlined,
                        label: 'Court',
                        value: draft.courtName.isEmpty ? '—' : draft.courtName),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        value: draft.courtAddress.isEmpty
                            ? '—'
                            : draft.courtAddress),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: dateStr),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: timeStr),
                    _divider(colors),
                    _ReviewRow(
                        icon: Icons.people_rounded,
                        label: 'Max players',
                        value: '${draft.maxPlayers}'),
                    if (draft.description != null) ...[
                      _divider(colors),
                      _ReviewRow(
                          icon: Icons.notes_rounded,
                          label: 'Note',
                          value: draft.description!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // What happens next
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: colors.colorAccentPrimary.withValues(alpha: 0.18),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WHAT HAPPENS NEXT',
                        style:
                            AppTextStyles.overline(colors.colorTextTertiary)),
                    const SizedBox(height: AppSpacing.sm),
                    _BulletPoint(
                      text: draft.gameType == _GameType.pickup
                          ? 'Your game is listed publicly — anyone nearby can request to join.'
                          : 'Your game is private — share the link to invite people.',
                      colors: colors,
                    ),
                    _BulletPoint(
                      text: 'You\'ll get notified when players join or request approval.',
                      colors: colors,
                    ),
                    _BulletPoint(
                      text: 'You can edit or cancel the game up to 2 hours before it starts.',
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _NextButton(
          enabled: true,
          onTap: onPublish,
          label: draft.gameType == _GameType.pickup
              ? 'Publish Game'
              : 'Create Game',
          isAccent: true,
        ),
      ],
    );
  }

  Widget _divider(AppColorScheme colors) => Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        color: colors.colorBorderSubtle,
      );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.colorTextTertiary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 80,
            child: Text(label,
                style: AppTextStyles.bodyS(colors.colorTextSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.headingS(colors.colorTextPrimary),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text, required this.colors});
  final String text;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5, height: 5,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: colors.colorAccentPrimary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.bodyS(colors.colorTextSecondary))),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PUBLISH SUCCESS DIALOG
// ══════════════════════════════════════════════════════════════

class _PublishSuccessDialog extends StatelessWidget {
  const _PublishSuccessDialog({required this.draft});
  final _HostGameDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPublic = draft.gameType == _GameType.pickup;

    return Dialog(
      backgroundColor: colors.colorSurfaceOverlay,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: colors.colorSuccess.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded,
                  color: colors.colorSuccess, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isPublic ? 'Game Published!' : 'Game Created!',
              style: AppTextStyles.headingL(colors.colorTextPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isPublic
                  ? 'Your pickup game is now live. Players nearby can find and join it.'
                  : 'Share the invite link with your crew to get them in.',
              style: AppTextStyles.bodyM(colors.colorTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(); // close dialog
                  context.pop(); // pop host game screen
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Center(
                    child: Text('Done',
                        style: AppTextStyles.headingS(colors.colorTextOnAccent)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════════

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.colorTextTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodyM(colors.colorTextPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatefulWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_PickerTile> createState() => _PickerTileState();
}

class _PickerTileState extends State<_PickerTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.filled
                ? colors.colorAccentPrimary.withValues(alpha: 0.07)
                : colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.filled
                  ? colors.colorAccentPrimary.withValues(alpha: 0.35)
                  : colors.colorBorderSubtle,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 18,
                  color: widget.filled
                      ? colors.colorAccentPrimary
                      : colors.colorTextTertiary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTextStyles.bodyM(widget.filled
                    ? colors.colorTextPrimary
                    : colors.colorTextTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? colors.colorSurfaceElevated
              : colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? colors.colorTextPrimary : colors.colorTextTertiary),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: colors.colorTextSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.headingS(colors.colorTextPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.bodyS(colors.colorTextSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colors.colorAccentPrimary,
            activeColor: colors.colorTextOnAccent,
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.enabled,
    required this.onTap,
    required this.label,
    this.isAccent = false,
  });
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  final bool isAccent;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = widget.isAccent
        ? colors.colorAccentPrimary
        : widget.enabled
            ? colors.colorAccentPrimary
            : colors.colorSurfaceElevated;
    final fg = widget.enabled
        ? colors.colorTextOnAccent
        : colors.colorTextTertiary;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: AppDuration.fast,
            height: 54,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: widget.enabled ? AppShadow.fab : null,
            ),
            child: Center(
              child: Text(widget.label,
                  style: AppTextStyles.headingS(fg)),
            ),
          ),
        ),
      ),
    );
  }
}
