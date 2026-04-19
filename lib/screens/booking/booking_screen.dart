// lib/screens/booking/booking_screen.dart
//
// Slot + Court selection — step 0 of the booking flow.
// Flow: pick date → pick court (or All) → pick time slot → confirm.
//   • If a specific court is pre-selected, slot tap → immediate confirm CTA.
//   • If "All courts" is selected, slot tap → _CourtPickerSheet to disambiguate.

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
  Court?   _selectedCourt;     // null = "All courts" active in filter
  int      _durationMin = 60;

  List<Court> get _courts =>
      FakeData.courtsByVenueAndSport(widget.venueId, widget.sport);

  // Slots for the currently focused court (or first court when All selected)
  List<Slot> get _allSlots {
    final courts = _courts;
    if (courts.isEmpty) return [];
    final court = _selectedCourt ?? courts.first;
    return FakeData.slotsByCourtId(court.id);
  }

  // How many courts have a given slot available
  int _availableCourtCount(Slot slot) {
    if (slot.status == SlotStatus.booked ||
        slot.status == SlotStatus.blocked) { return 0; }
    return _courts.length;
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

  // Called when user taps an available slot chip
  void _onSlotTapped(Slot slot) {
    if (_selectedCourt != null) {
      // Court already chosen → immediately confirm
      setState(() => _selectedSlot = slot);
    } else {
      // "All courts" mode → ask user to pick a court first
      setState(() => _selectedSlot = slot);
      _showCourtPicker(slot);
    }
  }

  void _showCourtPicker(Slot slot) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CourtPickerSheet(
        courts:   _courts,
        slot:     slot,
        colors:   colors,
        onSelect: (court) {
          Navigator.pop(context);
          setState(() {
            _selectedCourt = court;
            _selectedSlot  = slot;
          });
        },
      ),
    );
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
                  selectedDate:    _selectedDate,
                  onDateSelected:  (d) => setState(() {
                    _selectedDate  = d;
                    _selectedSlot  = null;
                  }),
                  months:   _months,
                  weekdays: _weekdays,
                  colors:   colors,
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(top: AppSpacing.xl)),

              // ── Court selector ───────────────────────────────────
              SliverToBoxAdapter(
                child: _VisualCourtSelector(
                  courts:   courts,
                  selected: _selectedCourt,
                  colors:   colors,
                  onSelect: (court) => setState(() {
                    _selectedCourt = court;
                    _selectedSlot  = null;
                  }),
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
                          courtCount:  _availableCourtCount,
                          onSelect:    _onSlotTapped,
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
                          courtCount:  _availableCourtCount,
                          onSelect:    _onSlotTapped,
                        ),
                      ],
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
//  VISUAL COURT SELECTOR — horizontal strip of 88×56 squares
// ─────────────────────────────────────────────────────────────────

class _VisualCourtSelector extends StatelessWidget {
  const _VisualCourtSelector({
    required this.courts,
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  final List<Court>          courts;
  final Court?               selected;   // null → "All courts" active
  final AppColorScheme       colors;
  final ValueChanged<Court?> onSelect;

  @override
  Widget build(BuildContext context) {
    final allActive = selected == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text('COURT',
                  style: AppTextStyles.overline(colors.colorTextTertiary)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${courts.length} available',
                style: AppTextStyles.overline(colors.colorSuccess),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              // "All courts" pill
              _CourtSquare(
                label:    'All',
                isActive: allActive,
                colors:   colors,
                onTap:    () => onSelect(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...courts.asMap().entries.map((e) {
                final isActive = selected?.id == e.value.id;
                return Padding(
                  padding: EdgeInsets.only(
                      right: e.key < courts.length - 1 ? AppSpacing.sm : 0),
                  child: _CourtSquare(
                    label:    e.value.name,
                    isActive: isActive,
                    hasBox:   e.value.hasTheBox,
                    colors:   colors,
                    onTap:    () => onSelect(e.value),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourtSquare extends StatefulWidget {
  const _CourtSquare({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
    this.hasBox = false,
  });

  final String         label;
  final bool           isActive;
  final bool           hasBox;
  final AppColorScheme colors;
  final VoidCallback   onTap;

  @override
  State<_CourtSquare> createState() => _CourtSquareState();
}

class _CourtSquareState extends State<_CourtSquare> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale:    _pressed ? 0.96 : 1.0,
        duration: Duration(milliseconds: _pressed ? 80 : 120),
        curve:    _pressed ? Curves.easeIn : Curves.elasticOut,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          width:  88,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.colors.colorAccentPrimary
                : widget.colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.isActive
                  ? widget.colors.colorAccentPrimary
                  : widget.colors.colorBorderSubtle,
              width: 0.5,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.colors.colorAccentPrimary
                          .withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: widget.isActive
                          ? widget.colors.colorTextOnAccent
                          : widget.colors.colorTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.hasBox)
                Positioned(
                  top: 5,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? widget.colors.colorTextOnAccent.withValues(alpha: 0.25)
                          : widget.colors.colorAccentPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'BOX',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize:      7,
                        fontWeight:    FontWeight.w800,
                        letterSpacing: 0.4,
                        color:         widget.isActive
                            ? widget.colors.colorTextOnAccent
                            : widget.colors.colorTextOnAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  COURT PICKER SHEET — shown when slot tapped in "All courts" mode
// ─────────────────────────────────────────────────────────────────

class _CourtPickerSheet extends StatelessWidget {
  const _CourtPickerSheet({
    required this.courts,
    required this.slot,
    required this.colors,
    required this.onSelect,
  });

  final List<Court>          courts;
  final Slot                 slot;
  final AppColorScheme       colors;
  final ValueChanged<Court>  onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        colors.colorSurfaceOverlay,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:        colors.colorBorderSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Text('PICK A COURT',
              style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            slot.startTime,
            style: GoogleFonts.spaceGrotesk(
              fontSize:   22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: colors.colorTextPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Court list
          ...courts.asMap().entries.map((e) {
            final court = e.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: e.key < courts.length - 1 ? AppSpacing.sm : 0),
              child: GestureDetector(
                onTap: () => onSelect(court),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color:        colors.colorSurfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                        color: colors.colorBorderSubtle, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                court.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize:   15,
                                  fontWeight: FontWeight.w700,
                                  color:      colors.colorTextPrimary,
                                ),
                              ),
                              if (court.hasTheBox) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _BoxBadge(colors: colors),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _InfoPill(label: court.surface, colors: colors),
                              const SizedBox(width: AppSpacing.xs),
                              _InfoPill(
                                  label: court.isIndoor ? 'Indoor' : 'Outdoor',
                                  colors: colors),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '₹${court.pricePerSlot}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize:   16,
                          fontWeight: FontWeight.w800,
                          color:      colors.colorTextPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: colors.colorTextTertiary),
                    ],
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
            separatorBuilder: (context, i) => const SizedBox(width: AppSpacing.sm),
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
                        isToday ? 'TODAY' : weekdays[(date.weekday - 1) % 7],
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
                color: isActive
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
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.overline(colors.colorTextTertiary));
}

// ─────────────────────────────────────────────────────────────────
//  SLOT GRID — 3-col chip layout with "N free" indicator
// ─────────────────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.selectedId,
    required this.price,
    required this.colors,
    required this.courtCount,
    required this.onSelect,
  });

  final List<Slot>              slots;
  final String?                 selectedId;
  final int                     price;
  final AppColorScheme          colors;
  final int Function(Slot)      courtCount;
  final ValueChanged<Slot>      onSelect;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final chipW   = (screenW - AppSpacing.lg * 2 - AppSpacing.sm * 2) / 3;

    return Wrap(
      spacing:    AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: slots.map((slot) {
        final isSelected  = selectedId == slot.id;
        final isBooked    = slot.status == SlotStatus.booked ||
                            slot.status == SlotStatus.blocked;
        final isAvailable = slot.status == SlotStatus.available;
        final freeCount   = courtCount(slot);

        return GestureDetector(
          onTap: isAvailable ? () => onSelect(slot) : null,
          child: AnimatedContainer(
            duration: AppDuration.normal,
            width:  chipW,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.colorSurfaceElevated
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
                            .withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // ── Corner selection dot ──────────────────────
                if (isSelected)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        color: colors.colorAccentPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:      colors.colorAccentPrimary.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(
                  slot.startTime,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color: isBooked
                        ? colors.colorTextTertiary
                        : colors.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (isBooked)
                  Row(
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
                          fontSize: 9,
                          color: colors.colorTextTertiary
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    '₹$price',
                    style: GoogleFonts.inter(
                      fontSize:   10,
                      fontWeight: FontWeight.w500,
                      color: colors.colorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$freeCount free',
                    style: GoogleFonts.inter(
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                      color: freeCount >= 2
                          ? colors.colorSuccess
                          : freeCount == 1
                              ? colors.colorWarning
                              : colors.colorTextTertiary,
                    ),
                  ),
                ],
              ],
                ),   // Column
              ],     // Stack.children
            ),       // Stack
          ),
        );
      }).toList(),
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
