// lib/screens/scoring/basketball/basketball_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import 'models/basketball_models.dart';

class BasketballSetupScreen extends ConsumerStatefulWidget {
  const BasketballSetupScreen({super.key, required this.mode});
  final BballMode mode;

  @override
  ConsumerState<BasketballSetupScreen> createState() =>
      _BasketballSetupScreenState();
}

class _BasketballSetupScreenState
    extends ConsumerState<BasketballSetupScreen> {
  BballFormat _format = BballFormat.fiveVsFive;
  BballClockFormat _clockFormat = BballClockFormat.quarters;
  int _periodMinutes = 10;
  bool _customTime = false;
  bool _hasShotClock = true;
  bool _extraStats = false;
  int _shotClockDuration = 24;
  int _timeoutsPerTeam = 2;
  bool _autoResetShotClock = false;

  final _teamACtrl = TextEditingController(text: 'Team A');
  final _teamBCtrl = TextEditingController(text: 'Team B');
  final _customCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _teamACtrl.dispose();
    _teamBCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  void _applyFormatDefaults(BballFormat format) {
    setState(() {
      _format = format;
      if (format == BballFormat.threeVsThree) {
        // FIBA 3x3: single 10-min period, 12s shot clock, 7-foul bonus, 1 timeout
        _clockFormat = BballClockFormat.fullGame;
        _periodMinutes = 10;
        _hasShotClock = true;
        _shotClockDuration = 12;
        _timeoutsPerTeam = 1;
        _autoResetShotClock = true;
      } else {
        _clockFormat = BballClockFormat.quarters;
        _periodMinutes = 10;
        _hasShotClock = true;
        _shotClockDuration = 24;
        _timeoutsPerTeam = 2;
        _autoResetShotClock = false;
      }
      _customTime = false;
      _customCtrl.text = '$_periodMinutes';
    });
  }

  void _onStart() {
    int minutes = _periodMinutes;
    if (_customTime) {
      minutes = int.tryParse(_customCtrl.text.trim()) ?? 10;
      minutes = minutes.clamp(1, 60);
    }

    final config = BballGameConfig(
      mode: widget.mode,
      format: _format,
      clockFormat: _clockFormat,
      periodMinutes: minutes,
      hasShotClock: _hasShotClock,
      extraStats: _extraStats,
      timeoutsPerTeam: _timeoutsPerTeam,
      shotClockDuration: _shotClockDuration,
      autoResetShotClock: _autoResetShotClock,
      teamA: BballTeamConfig(
        name: _teamACtrl.text.trim().isEmpty
            ? 'Team A'
            : _teamACtrl.text.trim(),
        color: AppColors.teamBlue,
      ),
      teamB: BballTeamConfig(
        name: _teamBCtrl.text.trim().isEmpty
            ? 'Team B'
            : _teamBCtrl.text.trim(),
        color: AppColors.teamRed,
      ),
    );

    if (widget.mode == BballMode.quick) {
      context.push(AppRoutes.bballScorer, extra: config);
    } else {
      context.push(AppRoutes.bballPlayers, extra: config);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isDetailed = widget.mode == BballMode.detailed;
    final is3v3 = _format == BballFormat.threeVsThree;

    return Scaffold(
      backgroundColor: AppColors.black,
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
                      color: AppColors.surface,
                      border:
                          Border.all(color: AppColors.border, width: 0.5),
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
                      isDetailed ? 'DETAILED STATS' : 'QUICK GAME',
                      style: AppTextStyles.overline(
                        isDetailed
                            ? AppColors.info
                            : AppColors.basketball,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'GAME SETUP',
                      style: AppTextStyles.headingL(
                          AppColors.textPrimaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FORMAT
                  _SectionLabel('FORMAT'),
                  _SegmentedPicker(
                    options: const ['3 vs 3', '5 vs 5'],
                    selected: _format == BballFormat.threeVsThree ? 0 : 1,
                    onChanged: (i) => _applyFormatDefaults(
                      i == 0
                          ? BballFormat.threeVsThree
                          : BballFormat.fiveVsFive,
                    ),
                  ),

                  // Format defaults hint
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      is3v3
                          ? 'FIBA 3x3: Full game (10 min) · First to 21 wins · 12s shot clock · 7-foul bonus · 1 timeout · +1 inside arc / +2 outside'
                          : 'FIBA 5v5: 4 quarters · 24s shot clock · 5-foul bonus per quarter · 2 timeouts',
                      style: AppTextStyles.bodyS(
                          AppColors.textSecondaryDark),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // TEAM NAMES
                  _SectionLabel('TEAM NAMES'),
                  Row(
                    children: [
                      Expanded(
                        child: _TeamNameField(
                          controller: _teamACtrl,
                          accentColor: AppColors.teamBlue,
                          hint: 'Team A',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _TeamNameField(
                          controller: _teamBCtrl,
                          accentColor: AppColors.teamRed,
                          hint: 'Team B',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // PERIODS
                  _SectionLabel(is3v3 ? 'GAME FORMAT' : 'PERIODS'),
                  if (is3v3)
                    _SegmentedPicker(
                      options: const ['Full Game', '2 Halves'],
                      selected: _clockFormat == BballClockFormat.fullGame ? 0 : 1,
                      onChanged: (i) => setState(() {
                        _clockFormat = i == 0
                            ? BballClockFormat.fullGame
                            : BballClockFormat.halves;
                      }),
                    )
                  else
                    _SegmentedPicker(
                      options: const ['4 Quarters', '2 Halves'],
                      selected:
                          _clockFormat == BballClockFormat.quarters ? 0 : 1,
                      onChanged: (i) => setState(() {
                        _clockFormat = i == 0
                            ? BballClockFormat.quarters
                            : BballClockFormat.halves;
                      }),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // TIME PER PERIOD
                  _SectionLabel('TIME PER PERIOD'),
                  _TimePicker(
                    selected: _customTime ? -1 : _periodMinutes,
                    onSelected: (m) => setState(() {
                      if (m == -1) {
                        _customTime = true;
                      } else {
                        _customTime = false;
                        _periodMinutes = m;
                      }
                    }),
                  ),
                  if (_customTime)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppSpacing.md),
                      child: _CustomTimeField(controller: _customCtrl),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // SHOT CLOCK
                  _SectionLabel('SHOT CLOCK'),
                  _ToggleRow(
                    label:
                        '$_shotClockDuration-second shot clock',
                    value: _hasShotClock,
                    onChanged: (v) => setState(() => _hasShotClock = v),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // SHOT CLOCK AUTO-RESET
                  _SectionLabel('SHOT CLOCK RESET'),
                  _ToggleRow(
                    label: 'Auto-reset shot clock on score',
                    value: _autoResetShotClock,
                    onChanged: (v) => setState(() => _autoResetShotClock = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Resets shot clock automatically when a basket is scored. FIBA 3x3 default: on.',
                      style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // EXTRA STATS (detailed mode only or optional)
                  _SectionLabel('EXTRA STATS'),
                  _ToggleRow(
                    label: 'Track REB / AST / STL / BLK / TO',
                    value: _extraStats,
                    onChanged: (v) => setState(() => _extraStats = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Adds extra stat buttons to the scorer. Best for detailed tracking.',
                      style: AppTextStyles.bodyS(
                          AppColors.textSecondaryDark),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),

          // CTA
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
                bottomPad + AppSpacing.lg),
            child: GestureDetector(
              onTap: _onStart,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    isDetailed ? 'NEXT: ADD PLAYERS' : 'START GAME',
                    style: AppTextStyles.headingM(AppColors.white),
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
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.overline(AppColors.textSecondaryDark),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEGMENTED PICKER
// ═══════════════════════════════════════════════════════════════

class _SegmentedPicker extends StatelessWidget {
  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final active = i == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: AppDuration.fast,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: active ? AppColors.red : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.headingS(
                      active
                          ? AppColors.white
                          : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TEAM NAME FIELD
// ═══════════════════════════════════════════════════════════════

class _TeamNameField extends StatelessWidget {
  const _TeamNameField({
    required this.controller,
    required this.accentColor,
    required this.hint,
  });

  final TextEditingController controller;
  final Color accentColor;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style:
                  AppTextStyles.headingS(AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppTextStyles.headingS(AppColors.textSecondaryDark),
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

// ═══════════════════════════════════════════════════════════════
//  TIME PICKER
// ═══════════════════════════════════════════════════════════════

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.selected, required this.onSelected});
  final int selected; // -1 = custom
  final ValueChanged<int> onSelected;

  static const _options = [8, 10, 12];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._options.map((m) {
          final active = selected == m;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(m),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  height: 44,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.red.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: active
                          ? AppColors.red.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: active ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${m}m',
                      style: AppTextStyles.headingS(
                        active
                            ? AppColors.white
                            : AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        Expanded(
          child: GestureDetector(
            onTap: () => onSelected(-1),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              height: 44,
              decoration: BoxDecoration(
                color: selected == -1
                    ? AppColors.red.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected == -1
                      ? AppColors.red.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: selected == -1 ? 1.5 : 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  'Custom',
                  style: AppTextStyles.headingS(
                    selected == -1
                        ? AppColors.white
                        : AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CUSTOM TIME FIELD
// ═══════════════════════════════════════════════════════════════

class _CustomTimeField extends StatelessWidget {
  const _CustomTimeField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.red.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.headingS(AppColors.textPrimaryDark),
              decoration: const InputDecoration(
                hintText: '10',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Text(
            'minutes',
            style:
                AppTextStyles.bodyS(AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TOGGLE ROW
// ═══════════════════════════════════════════════════════════════

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: value
                ? AppColors.red.withValues(alpha: 0.35)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.headingS(AppColors.textPrimaryDark),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedContainer(
              duration: AppDuration.fast,
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.red
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: value
                      ? AppColors.red
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: AnimatedAlign(
                duration: AppDuration.fast,
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
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
