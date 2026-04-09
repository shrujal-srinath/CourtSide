// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../models/fake_data.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.courtId});
  final String courtId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;

  Court? get _court =>
      FakeData.courts.where((c) => c.id == widget.courtId).firstOrNull;

  Venue? get _venue => _court != null
      ? FakeData.venues.where((v) => v.id == _court!.venueId).firstOrNull
      : null;

  List<Slot> get _slots => FakeData.slotsC1;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final court = _court;
    final venue = _venue;
    final canBook = _selectedSlot != null;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // ── Fixed header ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: c.gradBrand,
              border: Border(
                bottom: BorderSide(color: c.border, width: 0.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(18, topPad + 8, 18, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: c.text, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        court?.name ?? 'Book a Court',
                        style: AppTextStyles.headingM(c.text),
                      ),
                      if (venue != null)
                        Text(
                          venue.name,
                          style: AppTextStyles.bodyS(c.textSec),
                        ),
                    ],
                  ),
                ),
                if (court != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: Text(
                      '₹${court.pricePerSlot}/slot',
                      style: AppTextStyles.labelS(AppColors.red),
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE SECTION
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'PICK A DATE',
                      style: AppTextStyles.overline(c.textSec),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: 14,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final today = DateTime.now();
                        final date = today.add(Duration(days: i));
                        final isToday = i == 0;
                        final isSelected =
                            date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDate = date),
                          child: AnimatedContainer(
                            duration: AppDuration.fast,
                            width: 58,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.red
                                  : c.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.red
                                    : c.border,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  isToday
                                      ? 'TODAY'
                                      : _weekdays[
                                          (date.weekday - 1) % 7],
                                  style: AppTextStyles.overline(
                                    isSelected
                                        ? AppColors.white
                                            .withValues(alpha: 0.8)
                                        : isToday
                                            ? AppColors.red
                                            : c.textSec,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.white
                                        : c.text,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _shortMonths[date.month - 1],
                                  style: AppTextStyles.overline(
                                    isSelected
                                        ? AppColors.white
                                            .withValues(alpha: 0.7)
                                        : c.textTer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SLOTS SECTION
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text(
                          'AVAILABLE SLOTS',
                          style: AppTextStyles.overline(c.textSec),
                        ),
                        const Spacer(),
                        _LegendDot(color: c.surface, label: 'Open'),
                        const SizedBox(width: 10),
                        _LegendDot(
                            color: AppColors.red, label: 'Selected'),
                        const SizedBox(width: 10),
                        _LegendDot(
                            color: c.surfaceHigh, label: 'Booked'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final isSelected = _selectedSlot?.id == slot.id;
                        final isBooked =
                            slot.status == SlotStatus.booked ||
                                slot.status == SlotStatus.blocked;
                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () => setState(
                                  () => _selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: AppDuration.fast,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.red
                                  : isBooked
                                      ? c.surfaceHigh
                                      : c.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.red
                                    : c.border,
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${slot.startTime} – ${slot.endTime}',
                                style: AppTextStyles.bodyS(
                                  isSelected
                                      ? AppColors.white
                                      : isBooked
                                          ? c.textTer
                                          : c.text,
                                ).copyWith(
                                  decoration: isBooked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // SUMMARY CARD — animates in when slot selected
                  AnimatedSwitcher(
                    duration: AppDuration.normal,
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _selectedSlot != null
                        ? Padding(
                            key: const ValueKey('summary'),
                            padding: const EdgeInsets.fromLTRB(
                                18, 24, 18, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: c.gradBrand,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                    color: c.border, width: 0.5),
                              ),
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    icon:
                                        Icons.calendar_today_rounded,
                                    label: 'Date',
                                    value:
                                        '${_selectedDate.day} ${_months[_selectedDate.month - 1]}, ${_selectedDate.year}',
                                  ),
                                  _SummaryRow(
                                    icon: Icons.access_time_rounded,
                                    label: 'Time',
                                    value:
                                        '${_selectedSlot!.startTime} – ${_selectedSlot!.endTime}',
                                  ),
                                  if (court != null)
                                    _SummaryRow(
                                      icon: Icons.currency_rupee_rounded,
                                      label: 'Amount',
                                      value: '₹${court.pricePerSlot}',
                                      isLast: true,
                                      highlight: true,
                                    ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  // Amenities
                  if (venue != null && venue.amenities.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AMENITIES',
                              style:
                                  AppTextStyles.overline(c.textSec)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: venue.amenities.map((a) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.pill),
                                  border: Border.all(
                                      color: c.border, width: 0.5),
                                ),
                                child: Text(a,
                                    style:
                                        AppTextStyles.labelS(c.textSec)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // Cancellation notice
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(18, 20, 18, 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border:
                            Border.all(color: c.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: c.textTer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Free cancellation up to 2 hours before booking.',
                              style: AppTextStyles.bodyS(c.textSec),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: botPad + 90),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Floating CTA ──────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(18, 12, 18, botPad + 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border, width: 0.5)),
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canBook
                ? () {
                    // Booking confirmation — will wire to Supabase later
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canBook ? AppColors.red : c.surfaceHigh,
              disabledBackgroundColor: c.surfaceHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
            child: Text(
              canBook
                  ? 'Book & Pay ₹${court?.pricePerSlot ?? "—"}'
                  : 'Select a time slot',
              style: AppTextStyles.headingS(
                  canBook ? AppColors.white : c.textTer),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: context.col.border, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.overline(context.col.textSec)),
      ],
    );
  }
}

// ── Summary Row ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlight ? AppColors.red : c.textSec),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodyM(c.textSec)),
          const Spacer(),
          Text(
            value,
            style: highlight
                ? AppTextStyles.statM(AppColors.red)
                : AppTextStyles.headingS(c.text),
          ),
        ],
      ),
    );
  }
}
