// lib/screens/booking/booking_screen.dart
//
// Slot + Court selection — step 0 of the booking flow.
// Flow: pick date → pick time slot → select court → confirm.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';

// ─────────────────────────────────────────────────────────────────
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
  Slot?    _selectedSlot;
  Court?   _selectedCourt;
  int      _durationMin = 60;  // 60 or 90

  // All courts for this venue+sport
  List<Court> get _courts =>
      FakeData.courtsByVenueAndSport(widget.venueId, widget.sport);

  // Slots from the first available court (all courts share same slot pattern)
  List<Slot> get _allSlots {
    final courts = _courts;
    if (courts.isEmpty) return [];
    return FakeData.slotsByCourtId(courts.first.id);
  }

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _months   = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int _parseHour(String timeStr) {
    final parts = timeStr.split(' ');
    int h = int.parse(parts[0].split(':')[0]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return h;
  }

  String get _sportLabel {
    const map = {
      'basketball': 'Basketball',
      'cricket':    'Cricket',
      'badminton':  'Badminton',
      'football':   'Football',
    };
    return map[widget.sport] ?? widget.sport;
  }

  Color _sportColor(AppColorScheme c) {
    switch (widget.sport) {
      case 'basketball': return c.colorSportBasketball;
      case 'cricket':    return c.colorSportCricket;
      case 'badminton':  return c.colorSportBadminton;
      case 'football':   return c.colorSportFootball;
      default:           return c.colorAccentPrimary;
    }
  }

  void _onConfirmSlot() {
    final court = _selectedCourt;
    final slot  = _selectedSlot;
    final venue = widget.venue;
    if (venue == null || slot == null || court == null) return;

    ref.read(bookingFlowProvider.notifier).init(
      venueId: widget.venueId,
      sport:   widget.sport,
      venue:   venue,
      court:   court,
      slot:    slot,
      date:    _selectedDate,
    );
    context.push(AppRoutes.bookInvite(widget.venueId));
  }

  @override
  Widget build(BuildContext context) {
    final colors  = context.colors;
    final botPad  = MediaQuery.of(context).padding.bottom;
    final courts  = _courts;
    final slots   = _allSlots;
    final canBook = _selectedSlot != null && _selectedCourt != null;

    if (courts.isEmpty) {
      return Scaffold(
        backgroundColor: colors.colorBackgroundPrimary,
        body: Center(
          child: Text('No courts available',
              style: AppTextStyles.bodyM(colors.colorTextSecondary)),
        ),
      );
    }

    // Morning = before 4 PM, Evening = 4 PM+
    final morningSlots = slots.where((s) => _parseHour(s.startTime) < 16).toList();
    final eveningSlots = slots.where((s) => _parseHour(s.startTime) >= 16).toList();

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── App bar ──────────────────────────────────────────
              _buildAppBar(colors),

              // ── Date strip ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _DateStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() {
                    _selectedDate = d;
                    _selectedSlot = null;
                  }),
                  months:   _months,
                  weekdays: _weekdays,
                  colors:   colors,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.xl)),

              // ── Duration toggle + section header ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Text('SELECT TIME',
                          style: AppTextStyles.overline(colors.colorTextTertiary)),
                      const Spacer(),
                      _DurationToggle(
                        selected:   _durationMin,
                        onSelected: (v) => setState(() {
                          _durationMin  = v;
                          _selectedSlot = null;
                        }),
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.md)),

              // ── Time slot grid ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (morningSlots.isNotEmpty) ...[
                        _SlotGroupLabel('MORNING', colors),
                        const SizedBox(height: AppSpacing.sm),
                        _SlotGrid(
                          slots:       morningSlots,
                          selectedId:  _selectedSlot?.id,
                          price:       courts.first.pricePerSlot,
                          colors:      colors,
                          onSelect:    (s) => setState(() {
                            _selectedSlot  = s;
                            _selectedCourt = null;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      if (eveningSlots.isNotEmpty) ...[
                        _SlotGroupLabel('EVENING', colors),
                        const SizedBox(height: AppSpacing.sm),
                        _SlotGrid(
                          slots:       eveningSlots,
                          selectedId:  _selectedSlot?.id,
                          price:       courts.first.pricePerSlot,
                          colors:      colors,
                          onSelect:    (s) => setState(() {
                            _selectedSlot  = s;
                            _selectedCourt = null;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Court section (appears after slot selected) ───────
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: AppDuration.slow,
                  curve:    Curves.easeOutCubic,
                  child: _selectedSlot == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xxxl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: Row(
                                children: [
                                  Text('AVAILABLE COURTS',
                                      style: AppTextStyles.overline(
                                          colors.colorTextTertiary)),
                                  const Spacer(),
                                  Text('${courts.length} court${courts.length > 1 ? 's' : ''}',
                                      style: AppTextStyles.bodyS(
                                          colors.colorTextTertiary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...courts.asMap().entries.map((e) => Padding(
                              padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  e.key < courts.length - 1
                                      ? AppSpacing.md
                                      : 0),
                              child: _CourtCard(
                                court:      e.value,
                                sport:      widget.sport,
                                isSelected: _selectedCourt?.id == e.value.id,
                                colors:     colors,
                                onTap: () => setState(
                                    () => _selectedCourt = e.value),
                              ),
                            )),
                          ],
                        ),
                ),
              ),

              SliverToBoxAdapter(
                  child: SizedBox(height: botPad + (canBook ? 140 : 60))),
            ],
          ),

          // ── Sticky footer ─────────────────────────────────────
          if (canBook)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _StickyFooter(
                selectedDate:  _selectedDate,
                selectedSlot:  _selectedSlot!,
                selectedCourt: _selectedCourt!,
                months:        _months,
                colors:        colors,
                onConfirm:     _onConfirmSlot,
                botPad:        botPad,
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(AppColorScheme colors) {
    final venueName = widget.venue?.name ?? 'Book a Court';
    return SliverAppBar(
      backgroundColor:  colors.colorBackgroundPrimary,
      surfaceTintColor: colors.colorBackgroundPrimary,
      elevation:        0,
      pinned:           true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.colorTextPrimary, size: 18),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            venueName,
            style: GoogleFonts.spaceGrotesk(
              fontSize:      16,
              fontWeight:    FontWeight.w700,
              letterSpacing: -0.3,
              color:         colors.colorTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:  _sportColor(colors),
                  shape:  BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _sportLabel,
                style: GoogleFonts.inter(
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                  color:      colors.colorTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
            height: 0.5, color: colors.colorBorderSubtle),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DATE STRIP
// ─────────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selectedDate,
    required this.onDateSelected,
    required this.months,
    required this.weekdays,
    required this.colors,
  });

  final DateTime                selectedDate;
  final ValueChanged<DateTime>  onDateSelected;
  final List<String>            months;
  final List<String>            weekdays;
  final AppColorScheme          colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
          child: Text(
            '${months[selectedDate.month - 1].toUpperCase()} ${selectedDate.year}',
            style: AppTextStyles.overline(colors.colorTextTertiary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 14,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) {
              final date       = DateTime.now().add(Duration(days: i));
              final isSelected = date.day == selectedDate.day &&
                                 date.month == selectedDate.month;
              final isToday    = i == 0;

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: AnimatedContainer(
                  duration: AppDuration.normal,
                  width: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.colorAccentPrimary
                        : colors.colorSurfacePrimary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                                  .withValues(alpha: 0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday
                            ? 'TODAY'
                            : weekdays[(date.weekday - 1) % 7],
                        style: GoogleFonts.inter(
                          fontSize:      8,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isSelected
                              ? colors.colorTextOnAccent.withValues(alpha: 0.8)
                              : colors.colorTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize:   20,
                          fontWeight: FontWeight.w700,
                          height:     1.0,
                          color: isSelected
                              ? colors.colorTextOnAccent
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  DURATION TOGGLE
// ─────────────────────────────────────────────────────────────────

class _DurationToggle extends StatelessWidget {
  const _DurationToggle({
    required this.selected,
    required this.onSelected,
    required this.colors,
  });

  final int                  selected;
  final ValueChanged<int>    onSelected;
  final AppColorScheme       colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color:        colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [60, 90].map((mins) {
          final isActive = selected == mins;
          return GestureDetector(
            onTap: () => onSelected(mins),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 30,
              decoration: BoxDecoration(
                color:        isActive
                    ? colors.colorAccentPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: Text(
                  '${mins}m',
                  style: GoogleFonts.inter(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? colors.colorTextOnAccent
                        : colors.colorTextSecondary,
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

// ─────────────────────────────────────────────────────────────────
//  SLOT GROUP LABEL
// ─────────────────────────────────────────────────────────────────

class _SlotGroupLabel extends StatelessWidget {
  const _SlotGroupLabel(this.label, this.colors);
  final String         label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.overline(colors.colorTextTertiary));
  }
}

// ─────────────────────────────────────────────────────────────────
//  SLOT GRID — 3-col chip layout
// ─────────────────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedId,
    required this.price,
    required this.colors,
    required this.onSelect,
  });

  final List<Slot>            slots;
  final String?               selectedId;
  final int                   price;
  final AppColorScheme        colors;
  final ValueChanged<Slot>    onSelect;

  @override
  Widget build(BuildContext context) {
    final screenW   = MediaQuery.of(context).size.width;
    final chipW     = (screenW - AppSpacing.lg * 2 - AppSpacing.sm * 2) / 3;

    return Wrap(
      spacing:    AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: slots.map((slot) {
        final isSelected  = selectedId == slot.id;
        final isBooked    = slot.status == SlotStatus.booked ||
                            slot.status == SlotStatus.blocked;
        final isAvailable = slot.status == SlotStatus.available;

        return GestureDetector(
          onTap: isAvailable ? () => onSelect(slot) : null,
          child: AnimatedContainer(
            duration: AppDuration.normal,
            width:  chipW,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.colorAccentPrimary.withValues(alpha: 0.12)
                  : isBooked
                      ? colors.colorSurfacePrimary.withValues(alpha: 0.5)
                      : colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected
                    ? colors.colorAccentPrimary
                    : colors.colorBorderSubtle,
                width: isSelected ? 1.5 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.colorAccentPrimary
                            .withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.startTime,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colors.colorAccentPrimary
                        : isBooked
                            ? colors.colorTextTertiary
                            : colors.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                isBooked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 9,
                              color: colors.colorTextTertiary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(
                            'Booked',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: colors.colorTextTertiary
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '₹$price',
                        style: GoogleFonts.inter(
                          fontSize:   11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? colors.colorAccentPrimary
                                  .withValues(alpha: 0.8)
                              : colors.colorTextSecondary,
                        ),
                      ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  COURT CARD — full-width, horizontal, Playo-inspired
// ─────────────────────────────────────────────────────────────────

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.sport,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final Court          court;
  final String         sport;
  final bool           isSelected;
  final AppColorScheme colors;
  final VoidCallback   onTap;

  Color _sportColor() {
    switch (sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      case 'football':   return colors.colorSportFootball;
      default:           return colors.colorAccentPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.normal,
        height: 88,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.colorAccentPrimary.withValues(alpha: 0.07)
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
          child: Row(
            children: [
              // Court diagram accent strip
              SizedBox(
                width: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _CourtDiagramPainter(
                        sport:      sport,
                        isSelected: isSelected,
                        sportColor: _sportColor(),
                        lineColor:  colors.colorTextPrimary,
                      ),
                    ),
                    // Fade to card bg on the right edge
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end:   Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              isSelected
                                  ? colors.colorAccentPrimary
                                      .withValues(alpha: 0.07)
                                  : colors.colorSurfacePrimary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Court details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md,
                      AppSpacing.lg,  AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              court.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize:   15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: isSelected
                                    ? colors.colorAccentPrimary
                                    : colors.colorTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (court.hasTheBox) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _BoxBadge(colors: colors),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Surface + indoor badge
                      Row(
                        children: [
                          _InfoPill(
                            label: court.surface,
                            colors: colors,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _InfoPill(
                            label: court.isIndoor ? 'Indoor' : 'Outdoor',
                            colors: colors,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Price + availability
                      Row(
                        children: [
                          Text(
                            '₹${court.pricePerSlot}/slot',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? colors.colorAccentPrimary
                                  : colors.colorTextPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width:  7,
                            height: 7,
                            decoration: BoxDecoration(
                              color:  colors.colorSuccess,
                              shape:  BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.colorSuccess
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${court.slotsAvailableToday} left',
                            style: GoogleFonts.inter(
                              fontSize:   11,
                              fontWeight: FontWeight.w500,
                              color:      colors.colorSuccess,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Selection indicator
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: AnimatedContainer(
                  duration: AppDuration.normal,
                  width:  22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colors.colorAccentPrimary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colors.colorAccentPrimary
                          : colors.colorBorderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                            size: 13, color: colors.colorTextOnAccent)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxBadge extends StatelessWidget {
  const _BoxBadge({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        colors.colorAccentPrimary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('BOX',
          style: GoogleFonts.spaceGrotesk(
            fontSize:      8,
            fontWeight:    FontWeight.w800,
            letterSpacing: 0.5,
            color:         colors.colorTextOnAccent,
          )),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.colors});
  final String         label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color:        colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize:   10,
          fontWeight: FontWeight.w500,
          color:      colors.colorTextSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  STICKY FOOTER
// ─────────────────────────────────────────────────────────────────

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.selectedDate,
    required this.selectedSlot,
    required this.selectedCourt,
    required this.months,
    required this.colors,
    required this.onConfirm,
    required this.botPad,
  });

  final DateTime       selectedDate;
  final Slot           selectedSlot;
  final Court          selectedCourt;
  final List<String>   months;
  final AppColorScheme colors;
  final VoidCallback   onConfirm;
  final double         botPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg,
          AppSpacing.lg, botPad + AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color:        colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: colors.colorTextTertiary),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selectedDate.day} ${months[selectedDate.month - 1]} · ${selectedSlot.startTime}–${selectedSlot.endTime}',
                      style: AppTextStyles.labelM(colors.colorTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedCourt.name,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹${selectedCourt.pricePerSlot}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize:   18,
                    fontWeight: FontWeight.w800,
                    color:      colors.colorTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // CTA button
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              width:  double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color:        colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow:    AppShadow.accentGlow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirm Slot',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      color:      colors.colorTextOnAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: colors.colorTextOnAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COURT DIAGRAM PAINTER (preserved from original)
// ═══════════════════════════════════════════════════════════════════

class _CourtDiagramPainter extends CustomPainter {
  const _CourtDiagramPainter({
    required this.sport,
    required this.isSelected,
    required this.sportColor,
    required this.lineColor,
  });

  final String sport;
  final bool   isSelected;
  final Color  sportColor;
  final Color  lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (sport) {
      case 'basketball': _paintBasketball(canvas, size);
      case 'cricket':    _paintCricket(canvas, size);
      default:           _paintGeneric(canvas, size);
    }
  }

  void _paintBasketball(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    const pad = 6.0;

    canvas.drawRect(Offset.zero & size,
        Paint()..color = sportColor.withValues(
            alpha: isSelected ? 0.18 : 0.10));

    final lp = Paint()
      ..color       = lineColor.withValues(alpha: isSelected ? 0.50 : 0.25)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.1 : 0.8
      ..strokeCap   = StrokeCap.round;

    canvas.drawRect(Rect.fromLTRB(pad, pad, w - pad, h - pad), lp);
    canvas.drawLine(Offset(w / 2, pad), Offset(w / 2, h - pad), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, lp);

    final keyW = w * 0.22; final keyH = h * 0.55;
    final keyY = (h - keyH) / 2;
    canvas.drawRect(Rect.fromLTRB(pad, keyY, pad + keyW, keyY + keyH), lp);
    canvas.drawRect(
        Rect.fromLTRB(w - pad - keyW, keyY, w - pad, keyY + keyH), lp);

    canvas.drawArc(Rect.fromCircle(
        center: Offset(pad + keyW, h / 2), radius: h * 0.165),
        math.pi / 2, math.pi, false, lp);
    canvas.drawArc(Rect.fromCircle(
        center: Offset(w - pad - keyW, h / 2), radius: h * 0.165),
        math.pi * 1.5, math.pi, false, lp);

    final tpR = h * 0.46;
    canvas.drawArc(Rect.fromCircle(
        center: Offset(pad + 3, h / 2), radius: tpR),
        -math.pi * 0.45, math.pi * 0.9, false, lp);
    canvas.drawArc(Rect.fromCircle(
        center: Offset(w - pad - 3, h / 2), radius: tpR),
        math.pi * 0.55, math.pi * 0.9, false, lp);

    final bp = Paint()
      ..color = sportColor.withValues(alpha: isSelected ? 0.70 : 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pad + 5, h / 2), 3.5, bp);
    canvas.drawCircle(Offset(w - pad - 5, h / 2), 3.5, bp);
  }

  void _paintCricket(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;

    canvas.drawRect(Offset.zero & size,
        Paint()..color = sportColor.withValues(
            alpha: isSelected ? 0.18 : 0.10));

    final lp = Paint()
      ..color       = lineColor.withValues(alpha: isSelected ? 0.50 : 0.25)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.1 : 0.8;

    canvas.drawOval(Rect.fromLTRB(6, 6, w - 6, h - 6), lp);
    canvas.drawOval(
        Rect.fromLTRB(w * 0.18, h * 0.14, w * 0.82, h * 0.86),
        Paint()
          ..color       = lineColor.withValues(alpha: isSelected ? 0.22 : 0.12)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 0.6);

    final pW = w * 0.07; final pH = h * 0.48;
    final pX = (w - pW) / 2; final pY = (h - pH) / 2;
    canvas.drawRect(Rect.fromLTWH(pX, pY, pW, pH),
        Paint()
          ..color = sportColor.withValues(alpha: isSelected ? 0.30 : 0.15)
          ..style = PaintingStyle.fill);
    canvas.drawRect(Rect.fromLTWH(pX, pY, pW, pH),
        lp..strokeWidth = 0.7);

    final cY1 = pY + pH * 0.12; final cY2 = pY + pH * 0.88;
    canvas.drawLine(Offset(pX - 5, cY1), Offset(pX + pW + 5, cY1),
        lp..strokeWidth = isSelected ? 1.2 : 0.9);
    canvas.drawLine(Offset(pX - 5, cY2), Offset(pX + pW + 5, cY2),
        lp..strokeWidth = isSelected ? 1.2 : 0.9);

    final sp = Paint()
      ..color       = sportColor.withValues(alpha: isSelected ? 0.65 : 0.4)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap   = StrokeCap.round;
    for (int k = 0; k < 3; k++) {
      final x = pX + pW * (k + 1) / 4;
      canvas.drawLine(Offset(x, pY + 3), Offset(x, cY1), sp);
      canvas.drawLine(Offset(x, cY2), Offset(x, pY + pH - 3), sp);
    }
  }

  void _paintGeneric(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = sportColor.withValues(
            alpha: isSelected ? 0.12 : 0.06));
    final lp = Paint()
      ..color       = lineColor.withValues(alpha: isSelected ? 0.45 : 0.22)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.0 : 0.7;
    canvas.drawRect(Rect.fromLTRB(6, 6, w - 6, h - 6), lp);
    canvas.drawLine(Offset(w / 2, 6), Offset(w / 2, h - 6), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, lp);
  }

  @override
  bool shouldRepaint(_CourtDiagramPainter old) =>
      old.isSelected != isSelected || old.sport != sport;
}
