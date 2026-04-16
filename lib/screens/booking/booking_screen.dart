// lib/screens/booking/booking_screen.dart
//
// Slot + Court selection screen — step 0 of the booking flow.
// On confirm: initialises bookingFlowProvider and pushes to the 4-step wizard.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';

// ── Booking Screen ──────────────────────────────────────────────

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    super.key,
    required this.venueId,
    required this.sport,
    this.venue,
  });

  final String venueId;
  final String sport;
  final Venue? venue;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;
  Court? _selectedCourt;

  List<Court> get _courts =>
      FakeData.courtsByVenueAndSport(widget.venueId, widget.sport);

  List<Slot> get _slots =>
      _selectedCourt != null
          ? FakeData.slotsByCourtId(_selectedCourt!.id)
          : FakeData.slotsC1;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  int _parseHour(String timeStr) {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int h = int.parse(timeParts[0]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return h;
  }

  String get _sportLabel {
    switch (widget.sport) {
      case 'basketball': return 'Basketball';
      case 'cricket':    return 'Cricket';
      case 'badminton':  return 'Badminton';
      case 'football':   return 'Football';
      default:           return widget.sport;
    }
  }

  Color _sportColor(AppColorScheme colors) {
    switch (widget.sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      case 'football':   return colors.colorSportFootball;
      default:           return colors.colorAccentPrimary;
    }
  }

  void _onSlotTap(Slot slot, Court court) {
    final courts = _courts;
    if (courts.length > 1 && _selectedCourt == null) {
      setState(() => _selectedSlot = slot);
      _showCourtPicker(slot, courts);
    } else {
      setState(() {
        _selectedSlot = slot;
        _selectedCourt = _selectedCourt ?? court;
      });
    }
  }

  void _showCourtPicker(Slot slot, List<Court> courts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CourtPickerSheet(
        slot: slot,
        courts: courts,
        sport: widget.sport,
        selectedCourt: _selectedCourt,
        onConfirm: (court) {
          Navigator.pop(context);
          setState(() => _selectedCourt = court);
        },
      ),
    );
  }

  void _onConfirmSlot() {
    final court  = _selectedCourt ?? _courts.first;
    final venue  = widget.venue;
    if (venue == null || _selectedSlot == null) return;

    ref.read(bookingFlowProvider.notifier).init(
      venueId: widget.venueId,
      sport:   widget.sport,
      venue:   venue,
      court:   court,
      slot:    _selectedSlot!,
      date:    _selectedDate,
    );
    context.push(AppRoutes.bookInvite(widget.venueId));
  }

  @override
  Widget build(BuildContext context) {
    final colors  = context.colors;
    final botPad  = MediaQuery.of(context).padding.bottom;
    final courts  = _courts;
    final canBook = _selectedSlot != null &&
        (courts.length <= 1 || _selectedCourt != null);

    if (courts.isEmpty) return const Scaffold();

    // Auto-select if single court
    if (courts.length == 1 && _selectedCourt == null) {
      _selectedCourt = courts.first;
    }

    final displayCourt = _selectedCourt ?? courts.first;
    final slots        = _slots;
    final morningSlots = slots.where((s) => _parseHour(s.startTime) < 16).toList();
    final eveningSlots = slots.where((s) => _parseHour(s.startTime) >= 16).toList();

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'SELECT SLOT',
              style: AppTextStyles.labelM(colors.colorTextPrimary)
                  .copyWith(letterSpacing: 1),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _sportColor(colors).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                _sportLabel.toUpperCase(),
                style: AppTextStyles.labelS(_sportColor(colors)),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.colorTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── Visual court selector (multiple courts) ─────────
              if (courts.length > 1)
                SliverToBoxAdapter(
                  child: _VisualCourtSelector(
                    courts: courts,
                    selected: _selectedCourt,
                    sport: widget.sport,
                    colors: colors,
                    onSelect: (court) => setState(() {
                      _selectedCourt = court;
                      _selectedSlot  = null;
                    }),
                  ),
                ),

              // ── Date strip ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Text(
                          '${_months[_selectedDate.month - 1].toUpperCase()} ${_selectedDate.year}',
                          style: AppTextStyles.overline(colors.colorTextTertiary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          itemCount: 14,
                          separatorBuilder: (context0, i0) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final date =
                                DateTime.now().add(Duration(days: i));
                            final isSelected =
                                date.day == _selectedDate.day;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _selectedSlot = null;
                              }),
                              child: AnimatedContainer(
                                duration: AppDuration.normal,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors.colorAccentPrimary
                                      : colors.colorSurfacePrimary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.colorAccentPrimary
                                        : colors.colorBorderSubtle,
                                    width: 0.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: colors.colorAccentPrimary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _weekdays[(date.weekday - 1) % 7]
                                          .toUpperCase(),
                                      style: AppTextStyles.overline(
                                        isSelected
                                            ? Colors.white70
                                            : colors.colorTextTertiary,
                                      ).copyWith(fontSize: 9),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${date.day}',
                                      style: AppTextStyles.headingS(
                                        isSelected
                                            ? Colors.white
                                            : colors.colorTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: 28)),

              if (morningSlots.isNotEmpty)
                _buildSlotGroup('Morning', morningSlots, colors,
                    displayCourt.pricePerSlot, displayCourt),
              if (eveningSlots.isNotEmpty)
                _buildSlotGroup('Evening', eveningSlots, colors,
                    displayCourt.pricePerSlot, displayCourt),

              SliverToBoxAdapter(
                  child: SizedBox(height: botPad + 300)),
            ],
          ),

          // ── Sticky footer ────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStickyFooter(colors, canBook, displayCourt),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSlotGroup(
      String groupName, List<Slot> slots, AppColorScheme colors,
      int price, Court court) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(groupName.toUpperCase(),
                style: AppTextStyles.overline(colors.colorTextTertiary)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: slots.map((slot) {
                final isSelected  = _selectedSlot?.id == slot.id;
                final isBooked    = slot.status == SlotStatus.booked ||
                    slot.status == SlotStatus.blocked;
                final isAvailable = slot.status == SlotStatus.available;

                return GestureDetector(
                  onTap: () {
                    if (isAvailable) _onSlotTap(slot, court);
                  },
                  child: AnimatedContainer(
                    duration: AppDuration.normal,
                    width: (MediaQuery.of(context).size.width -
                            (AppSpacing.lg * 2) - 12) / 2,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.colorAccentPrimary.withValues(alpha: 0.1)
                          : (isBooked
                              ? colors.colorBackgroundPrimary
                              : colors.colorSurfacePrimary),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? colors.colorAccentPrimary
                            : (isBooked
                                ? Colors.transparent
                                : colors.colorBorderSubtle),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.startTime,
                          style: AppTextStyles.headingS(
                            isSelected
                                ? colors.colorAccentPrimary
                                : (isBooked
                                    ? colors.colorTextTertiary
                                    : colors.colorTextPrimary),
                          ).copyWith(
                            decoration: isBooked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBooked ? 'Booked' : '₹$price',
                          style: AppTextStyles.bodyS(
                            isSelected
                                ? colors.colorAccentPrimary
                                    .withValues(alpha: 0.7)
                                : (isBooked
                                    ? colors.colorTextTertiary
                                    : colors.colorTextSecondary),
                          ).copyWith(
                            decoration: isBooked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyFooter(
      AppColorScheme colors, bool canBook, Court court) {
    final slot         = _selectedSlot;
    final needsCourtPick =
        _courts.length > 1 && _selectedCourt == null;

    // Nudge to pick a court
    if (slot != null && needsCourtPick) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(
              top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        ),
        child: GestureDetector(
          onTap: () => _showCourtPicker(slot, _courts),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: colors.colorBorderMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_basketball_rounded,
                    size: 18, color: colors.colorTextSecondary),
                const SizedBox(width: 8),
                Text('Choose a court to continue',
                    style:
                        AppTextStyles.headingS(colors.colorTextSecondary)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: colors.colorTextTertiary),
              ],
            ),
          ),
        ),
      );
    }

    if (!canBook || slot == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Booking summary pill
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.colorBackgroundPrimary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedDate.day} ${_months[_selectedDate.month - 1]} · ${slot.startTime}',
                      style: AppTextStyles.labelM(colors.colorTextPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _selectedCourt?.name ?? court.name,
                      style:
                          AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
                Text('₹${court.pricePerSlot}',
                    style:
                        AppTextStyles.headingM(colors.colorTextPrimary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Confirm CTA
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _onConfirmSlot,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.colorAccentPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirm Slot',
                    style: AppTextStyles.labelM(Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Colors.white),
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
//  VISUAL COURT SELECTOR
// ═══════════════════════════════════════════════════════════════

class _VisualCourtSelector extends StatelessWidget {
  const _VisualCourtSelector({
    required this.courts,
    required this.selected,
    required this.sport,
    required this.colors,
    required this.onSelect,
  });

  final List<Court> courts;
  final Court? selected;
  final String sport;
  final AppColorScheme colors;
  final ValueChanged<Court> onSelect;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SELECT COURT',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const Spacer(),
              Text(
                '${courts.length} courts',
                style: AppTextStyles.bodyS(colors.colorTextTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cards: side-by-side for ≤3 courts, scroll for more
          courts.length <= 2
              ? Row(
                  children: courts.asMap().entries.map((entry) {
                    final i     = entry.key;
                    final court = entry.value;
                    final cardW = (screenW -
                            AppSpacing.lg * 2 -
                            (courts.length - 1) * AppSpacing.sm) /
                        courts.length;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < courts.length - 1
                              ? AppSpacing.sm
                              : 0),
                      child: _CourtCard(
                        court: court,
                        sport: sport,
                        isSelected: selected?.id == court.id,
                        colors: colors,
                        width: cardW,
                        onTap: () => onSelect(court),
                      ),
                    );
                  }).toList(),
                )
              : SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: courts.length,
                    separatorBuilder: (context0, i0) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context0, i) => _CourtCard(
                      court: courts[i],
                      sport: sport,
                      isSelected: selected?.id == courts[i].id,
                      colors: colors,
                      width: 160,
                      onTap: () => onSelect(courts[i]),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Individual court card with custom-painted diagram ────────────

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.sport,
    required this.isSelected,
    required this.colors,
    required this.width,
    required this.onTap,
  });

  final Court court;
  final String sport;
  final bool isSelected;
  final AppColorScheme colors;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        width: width,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.colorAccentPrimary.withValues(alpha: 0.06)
              : colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? colors.colorAccentPrimary
                : colors.colorBorderSubtle,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected ? AppShadow.cardElevated : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card - 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Court diagram
              SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: _CourtDiagramPainter(
                    sport:      sport,
                    isSelected: isSelected,
                    sportColor: _sportColor(colors),
                    lineColor:  colors.colorTextPrimary,
                  ),
                ),
              ),

              // Hairline
              Container(
                height: 0.5,
                color: isSelected
                    ? colors.colorAccentPrimary.withValues(alpha: 0.3)
                    : colors.colorBorderSubtle,
              ),

              // Court details
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            court.name,
                            style: AppTextStyles.headingS(
                              isSelected
                                  ? colors.colorAccentPrimary
                                  : colors.colorTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (court.hasTheBox)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.colorAccentPrimary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text('BOX',
                                style: AppTextStyles.overline(
                                    colors.colorTextOnAccent)
                                    .copyWith(fontSize: 7.5)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${court.surface} · ${court.isIndoor ? "Indoor" : "Outdoor"}',
                      style: AppTextStyles.bodyS(colors.colorTextTertiary),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${court.pricePerSlot}/slot',
                          style:
                              AppTextStyles.labelM(colors.colorAccentPrimary),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.colorSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${court.slotsAvailableToday}',
                              style: AppTextStyles.bodyS(colors.colorSuccess),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _sportColor(AppColorScheme colors) {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      case 'football':   return colors.colorSportFootball;
      default:           return colors.colorAccentPrimary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  COURT DIAGRAM CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════════

class _CourtDiagramPainter extends CustomPainter {
  const _CourtDiagramPainter({
    required this.sport,
    required this.isSelected,
    required this.sportColor,
    required this.lineColor,
  });

  final String sport;
  final bool isSelected;
  final Color sportColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (sport) {
      case 'basketball':
        _paintBasketball(canvas, size);
      case 'cricket':
        _paintCricket(canvas, size);
      default:
        _paintGeneric(canvas, size);
    }
  }

  void _paintBasketball(Canvas canvas, Size size) {
    final w   = size.width;
    final h   = size.height;
    const pad = 6.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = sportColor.withValues(alpha: isSelected ? 0.14 : 0.07),
    );

    final lp = Paint()
      ..color  = lineColor.withValues(alpha: isSelected ? 0.55 : 0.30)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.1 : 0.8
      ..strokeCap   = StrokeCap.round;

    // Court outline
    canvas.drawRect(
        Rect.fromLTRB(pad, pad, w - pad, h - pad), lp);

    // Center line (vertical for landscape court)
    canvas.drawLine(Offset(w / 2, pad), Offset(w / 2, h - pad), lp);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, lp);

    // Key boxes (left and right ends)
    final keyW = w * 0.18;
    final keyH = h * 0.55;
    final keyY = (h - keyH) / 2;
    // Left key
    canvas.drawRect(Rect.fromLTRB(pad, keyY, pad + keyW, keyY + keyH), lp);
    // Right key
    canvas.drawRect(
        Rect.fromLTRB(w - pad - keyW, keyY, w - pad, keyY + keyH), lp);

    // Free throw circles (dashed arcs at end of keys)
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(pad + keyW, h / 2), radius: h * 0.165),
      math.pi / 2, math.pi, false, lp,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(w - pad - keyW, h / 2), radius: h * 0.165),
      math.pi * 1.5, math.pi, false, lp,
    );

    // Three-point arcs
    final tpRadius = h * 0.46;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(pad + 3, h / 2), radius: tpRadius),
      -math.pi * 0.45, math.pi * 0.9, false, lp,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - pad - 3, h / 2), radius: tpRadius),
      math.pi * 0.55, math.pi * 0.9, false, lp,
    );

    // Basket circles
    final basketPaint = Paint()
      ..color = sportColor.withValues(alpha: isSelected ? 0.7 : 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pad + 5, h / 2), 3.5, basketPaint);
    canvas.drawCircle(Offset(w - pad - 5, h / 2), 3.5, basketPaint);
  }

  void _paintCricket(Canvas canvas, Size size) {
    final w   = size.width;
    final h   = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = sportColor.withValues(alpha: isSelected ? 0.14 : 0.07),
    );

    final lp = Paint()
      ..color  = lineColor.withValues(alpha: isSelected ? 0.55 : 0.28)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.1 : 0.8;

    // Outer boundary oval
    canvas.drawOval(
        Rect.fromLTRB(6, 6, w - 6, h - 6), lp);

    // Inner 30-yard circle
    canvas.drawOval(
        Rect.fromLTRB(w * 0.18, h * 0.14, w * 0.82, h * 0.86),
        Paint()
          ..color = lineColor.withValues(alpha: isSelected ? 0.22 : 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);

    // Pitch rectangle (centered, narrow)
    final pitchW = w * 0.07;
    final pitchH = h * 0.48;
    final pitchX = (w - pitchW) / 2;
    final pitchY = (h - pitchH) / 2;

    canvas.drawRect(
        Rect.fromLTWH(pitchX, pitchY, pitchW, pitchH),
        Paint()
          ..color = sportColor.withValues(alpha: isSelected ? 0.30 : 0.15)
          ..style = PaintingStyle.fill);
    canvas.drawRect(
        Rect.fromLTWH(pitchX, pitchY, pitchW, pitchH),
        lp..strokeWidth = 0.7);

    // Crease lines
    const creaseInset = 0.12;
    final creaseY1 = pitchY + pitchH * creaseInset;
    final creaseY2 = pitchY + pitchH * (1 - creaseInset);
    final creaseX1 = pitchX - 5;
    final creaseX2 = pitchX + pitchW + 5;

    canvas.drawLine(Offset(creaseX1, creaseY1), Offset(creaseX2, creaseY1),
        lp..strokeWidth = isSelected ? 1.2 : 0.9);
    canvas.drawLine(Offset(creaseX1, creaseY2), Offset(creaseX2, creaseY2),
        lp..strokeWidth = isSelected ? 1.2 : 0.9);

    // Stumps
    final stumpPaint = Paint()
      ..color  = sportColor.withValues(alpha: isSelected ? 0.65 : 0.4)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap   = StrokeCap.round;

    for (int k = 0; k < 3; k++) {
      final x = pitchX + pitchW * (k + 1) / 4;
      canvas.drawLine(
          Offset(x, pitchY + 3), Offset(x, creaseY1), stumpPaint);
      canvas.drawLine(
          Offset(x, creaseY2), Offset(x, pitchY + pitchH - 3), stumpPaint);
    }
  }

  void _paintGeneric(Canvas canvas, Size size) {
    final w   = size.width;
    final h   = size.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = sportColor.withValues(alpha: isSelected ? 0.12 : 0.06),
    );

    final lp = Paint()
      ..color  = lineColor.withValues(alpha: isSelected ? 0.5 : 0.28)
      ..style  = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.0 : 0.7;

    canvas.drawRect(Rect.fromLTRB(6, 6, w - 6, h - 6), lp);
    canvas.drawLine(Offset(w / 2, 6), Offset(w / 2, h - 6), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, lp);
  }

  @override
  bool shouldRepaint(_CourtDiagramPainter old) =>
      old.isSelected != isSelected || old.sport != sport;
}

// ═══════════════════════════════════════════════════════════════
//  COURT PICKER BOTTOM SHEET (slot-first selection)
// ═══════════════════════════════════════════════════════════════

class _CourtPickerSheet extends StatefulWidget {
  const _CourtPickerSheet({
    required this.slot,
    required this.courts,
    required this.sport,
    required this.selectedCourt,
    required this.onConfirm,
  });

  final Slot slot;
  final List<Court> courts;
  final String sport;
  final Court? selectedCourt;
  final ValueChanged<Court> onConfirm;

  @override
  State<_CourtPickerSheet> createState() => _CourtPickerSheetState();
}

class _CourtPickerSheetState extends State<_CourtPickerSheet> {
  late Court? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCourt ?? widget.courts.first;
  }

  Color _sportColor(AppColorScheme colors) {
    switch (widget.sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      case 'football':   return colors.colorSportFootball;
      default:           return colors.colorAccentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text('PICK A COURT',
                    style:
                        AppTextStyles.overline(colors.colorTextTertiary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        colors.colorAccentPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(widget.slot.startTime,
                      style: AppTextStyles.labelM(
                          colors.colorAccentPrimary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Court cards in sheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: widget.courts.asMap().entries.map((entry) {
                final i     = entry.key;
                final court = entry.value;
                final isSelected = _selected?.id == court.id;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: i < widget.courts.length - 1
                            ? AppSpacing.sm
                            : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = court),
                      child: AnimatedContainer(
                        duration: AppDuration.fast,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.colorAccentPrimary
                                  .withValues(alpha: 0.08)
                              : colors.colorSurfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: isSelected
                                ? colors.colorAccentPrimary
                                : colors.colorBorderSubtle,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card - 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mini diagram
                              SizedBox(
                                height: 70,
                                child: CustomPaint(
                                  painter: _CourtDiagramPainter(
                                    sport:      widget.sport,
                                    isSelected: isSelected,
                                    sportColor: _sportColor(colors),
                                    lineColor:
                                        colors.colorTextPrimary,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      court.name,
                                      style: AppTextStyles.headingS(
                                        isSelected
                                            ? colors.colorAccentPrimary
                                            : colors.colorTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${court.slotsAvailableToday} slots · ₹${court.pricePerSlot}',
                                      style: AppTextStyles.bodyS(
                                          colors.colorTextTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg,
                botPad + AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selected != null
                    ? () => widget.onConfirm(_selected!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.colorAccentPrimary,
                  disabledBackgroundColor: colors.colorSurfaceElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill)),
                  elevation: 0,
                ),
                child: Text('Confirm Court',
                    style:
                        AppTextStyles.headingS(colors.colorTextOnAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
