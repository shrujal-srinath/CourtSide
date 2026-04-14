// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/constants.dart';
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
      // Multiple courts, none selected yet — show picker sheet
      setState(() => _selectedSlot = slot);
      _showCourtPicker(slot, courts);
    } else {
      // Single court, or court already selected at the top — select directly
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
        selectedCourt: _selectedCourt,
        onConfirm: (court) {
          Navigator.pop(context);
          setState(() => _selectedCourt = court);
        },
      ),
    );
  }

  void _proceed() {
    final slot = _selectedSlot;
    final courts = _courts;
    final court = _selectedCourt ?? (courts.isNotEmpty ? courts.first : null);
    if (slot == null || court == null) return;

    ref.read(bookingFlowProvider.notifier).init(
      venueId: widget.venueId,
      sport: widget.sport,
      venue: widget.venue ?? Venue(
        id: widget.venueId, name: '', address: '', area: '',
        lat: 0, lng: 0, sports: [widget.sport], rating: 0,
        reviewCount: 0, closingTime: '', photoUrl: '',
        amenities: [], isIndoor: false,
      ),
      court: court,
      slot: slot,
      date: _selectedDate,
    );
    context.push(AppRoutes.bookInvite(widget.venueId));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;
    final courts = _courts;
    final canBook = _selectedSlot != null &&
        (courts.length <= 1 || _selectedCourt != null);

    if (courts.isEmpty) return const Scaffold();

    // Auto-select if single court
    if (courts.length == 1 && _selectedCourt == null) {
      _selectedCourt = courts.first;
    }

    final displayCourt = _selectedCourt ?? courts.first;
    final slots = _slots;
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
            Text('SELECT SLOT',
                style: AppTextStyles.labelM(colors.colorTextPrimary).copyWith(letterSpacing: 1)),
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Court picker (when multiple courts) ──
              if (courts.length > 1)
                SliverToBoxAdapter(
                  child: _CourtSelectorRow(
                    courts: courts,
                    selected: _selectedCourt,
                    colors: colors,
                    onSelect: (court) => setState(() {
                      _selectedCourt = court;
                      _selectedSlot = null;
                    }),
                  ),
                ),

              // ── Date strip ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: 14,
                          separatorBuilder: (context0, i0) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final date = DateTime.now().add(Duration(days: i));
                            final isSelected = date.day == _selectedDate.day;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _selectedSlot = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52,
                                decoration: BoxDecoration(
                                  color: isSelected ? colors.colorAccentPrimary : colors.colorSurfacePrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: colors.colorAccentPrimary.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _weekdays[(date.weekday - 1) % 7].toUpperCase(),
                                      style: AppTextStyles.overline(isSelected ? Colors.white70 : colors.colorTextTertiary).copyWith(fontSize: 9),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${date.day}',
                                      style: AppTextStyles.headingS(isSelected ? Colors.white : colors.colorTextPrimary),
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
                _buildSlotGroup('Morning', morningSlots, colors, displayCourt.pricePerSlot, displayCourt),
              if (eveningSlots.isNotEmpty)
                _buildSlotGroup('Evening', eveningSlots, colors, displayCourt.pricePerSlot, displayCourt),

              SliverToBoxAdapter(child: SizedBox(height: botPad + 280)),
            ],
          ),

          // ── STICKY FOOTER ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStickyFooter(colors, canBook, displayCourt),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSlotGroup(
      String groupName, List<Slot> slots, AppColorScheme colors, int price, Court court) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
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
                final isSelected = _selectedSlot?.id == slot.id;
                final isBooked = slot.status == SlotStatus.booked || slot.status == SlotStatus.blocked;
                final isAvailable = slot.status == SlotStatus.available;

                return GestureDetector(
                  onTap: () {
                    if (isAvailable) _onSlotTap(slot, court);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (MediaQuery.of(context).size.width - (AppSpacing.lg * 2) - 12) / 2,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.colorAccentPrimary.withValues(alpha: 0.1)
                          : (isBooked ? colors.colorBackgroundPrimary : colors.colorSurfacePrimary),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colors.colorAccentPrimary
                            : (isBooked ? Colors.transparent : colors.colorBorderSubtle),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.startTime,
                          style: AppTextStyles.headingS(
                            isSelected ? colors.colorAccentPrimary : (isBooked ? colors.colorTextTertiary : colors.colorTextPrimary),
                          ).copyWith(decoration: isBooked ? TextDecoration.lineThrough : null),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹$price',
                          style: AppTextStyles.bodyS(
                            isSelected ? colors.colorAccentPrimary.withValues(alpha: 0.7) : (isBooked ? colors.colorTextTertiary : colors.colorTextSecondary),
                          ).copyWith(decoration: isBooked ? TextDecoration.lineThrough : null),
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

  Widget _buildStickyFooter(AppColorScheme colors, bool canBook, Court court) {
    final slot = _selectedSlot;
    final needsCourtPick = _courts.length > 1 && _selectedCourt == null;

    // Show a "pick a court" nudge if slot selected but no court chosen
    if (slot != null && needsCourtPick) {
      return Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(context).padding.bottom + AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
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
                Icon(Icons.sports_basketball_rounded, size: 18, color: colors.colorTextSecondary),
                const SizedBox(width: 8),
                Text('Choose a court to continue',
                    style: AppTextStyles.headingS(colors.colorTextSecondary)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colors.colorTextTertiary),
              ],
            ),
          ),
        ),
      );
    }

    if (!canBook || slot == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          MediaQuery.of(context).padding.bottom + AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SUMMARY
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.colorBackgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_selectedDate.day} ${_months[_selectedDate.month - 1]} · ${slot.startTime}',
                        style: AppTextStyles.labelM(colors.colorTextPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      _selectedCourt != null ? _selectedCourt!.name : court.name,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                    const SizedBox(height: 2),
                    Text('₹${court.pricePerSlot}',
                        style: AppTextStyles.headingM(colors.colorTextPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // CTA
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.colorAccentPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill)),
                elevation: 0,
              ),
              child: Text(
                'Next · ₹${court.pricePerSlot}',
                style: AppTextStyles.headingS(colors.colorTextOnAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Court Selector Row (inline tabs, multiple courts) ───────────

class _CourtSelectorRow extends StatelessWidget {
  const _CourtSelectorRow({
    required this.courts,
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  final List<Court> courts;
  final Court? selected;
  final AppColorScheme colors;
  final ValueChanged<Court> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELECT COURT', style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: courts.map((court) {
              final isSelected = selected?.id == court.id;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: courts.last.id == court.id ? 0 : AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => onSelect(court),
                    child: AnimatedContainer(
                      duration: AppDuration.fast,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.colorAccentPrimary.withValues(alpha: 0.08)
                            : colors.colorSurfacePrimary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                          width: isSelected ? 1.0 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            court.name,
                            style: AppTextStyles.headingS(isSelected
                                ? colors.colorAccentPrimary
                                : colors.colorTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            court.surface + (court.hasTheBox ? ' · THE BOX' : ''),
                            style: AppTextStyles.bodyS(colors.colorTextTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Court Picker Bottom Sheet ────────────────────────────────────

class _CourtPickerSheet extends StatefulWidget {
  const _CourtPickerSheet({
    required this.slot,
    required this.courts,
    required this.selectedCourt,
    required this.onConfirm,
  });

  final Slot slot;
  final List<Court> courts;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text('CHOOSE COURT', style: AppTextStyles.overline(colors.colorTextTertiary)),
                const Spacer(),
                Text(
                  '· ${widget.slot.startTime}',
                  style: AppTextStyles.labelM(colors.colorAccentPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...widget.courts.map((court) {
            final isSelected = _selected?.id == court.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = court),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppDuration.fast,
                margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.colorAccentPrimary.withValues(alpha: 0.06)
                      : colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                    width: isSelected ? 1.0 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(court.name,
                                  style: AppTextStyles.headingS(colors.colorTextPrimary)),
                              if (court.hasTheBox) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.colorAccentPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text('THE BOX',
                                      style: AppTextStyles.labelS(colors.colorAccentPrimary)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'} · ${court.slotsAvailableToday} slots left',
                            style: AppTextStyles.bodyS(colors.colorTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${court.pricePerSlot}',
                            style: AppTextStyles.headingS(colors.colorTextPrimary)),
                        Text('/ slot', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AnimatedContainer(
                      duration: AppDuration.fast,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? colors.colorAccentPrimary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? colors.colorAccentPrimary : colors.colorBorderMedium,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, botPad + AppSpacing.lg),
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
                    style: AppTextStyles.headingS(colors.colorTextOnAccent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
