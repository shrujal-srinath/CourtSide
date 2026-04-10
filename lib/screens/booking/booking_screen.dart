// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/fake_data.dart';

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

  Court? get _court => FakeData.courtByVenueAndSport(widget.venueId, widget.sport);

  List<Slot> get _slots => FakeData.slotsC1;

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;
    final court = _court;
    final canBook = _selectedSlot != null;

    if (court == null) return const Scaffold();

    final morningSlots = _slots.where((s) => _parseHour(s.startTime) < 16).toList();
    final eveningSlots = _slots.where((s) => _parseHour(s.startTime) >= 16).toList();

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        centerTitle: false,
        title: Text('SELECT SLOT',
            style: AppTextStyles.labelM(colors.colorTextPrimary).copyWith(letterSpacing: 1)),
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
                          separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
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

              const SliverPadding(padding: EdgeInsets.only(top: 32)),

              // ── TIME GROUPS ──
              if (morningSlots.isNotEmpty) _buildSlotGroup('Morning', morningSlots, colors, court.pricePerSlot),
              if (eveningSlots.isNotEmpty) _buildSlotGroup('Evening', eveningSlots, colors, court.pricePerSlot),

              SliverToBoxAdapter(child: SizedBox(height: botPad + 280)), // large bottom padding for sticky summary
            ],
          ),

          // ── STICKY FOOTER ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildStickyFooter(colors, canBook, court),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGroup(String groupName, List<Slot> slots, AppColorScheme colors, int price) {
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
                    if (isAvailable) setState(() => _selectedSlot = slot);
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
    if (!canBook) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.of(context).padding.bottom + AppSpacing.lg),
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
                    Text('Date: ${_selectedDate.day} ${_months[_selectedDate.month - 1]}',
                        style: AppTextStyles.labelM(colors.colorTextPrimary)),
                    const SizedBox(height: 4),
                    Text('Time: ${_selectedSlot!.startTime}',
                        style: AppTextStyles.labelM(colors.colorTextPrimary)),
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
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.colorAccentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Book Now · ₹${court.pricePerSlot}',
                style: AppTextStyles.labelM(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
