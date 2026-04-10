// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_button.dart';

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
    final colors  = context.colors;
    final topPad  = MediaQuery.of(context).padding.top;
    final botPad  = MediaQuery.of(context).padding.bottom;
    final court   = _court;
    final venue   = _venue;
    final canBook = _selectedSlot != null;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            color: colors.colorBackgroundPrimary,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topPad + AppSpacing.sm,
                AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_rounded,
                        color: colors.colorTextPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        court?.name ?? 'Book a Court',
                        style: AppTextStyles.headingM(colors.colorTextPrimary),
                      ),
                      if (venue != null)
                        Text(
                          venue.name,
                          style: AppTextStyles.bodyS(colors.colorTextSecondary),
                        ),
                    ],
                  ),
                ),
                if (court != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 2,
                        vertical: AppSpacing.xs + 1),
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: colors.colorAccentPrimary
                              .withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: Text(
                      '₹${court.pricePerSlot}/slot',
                      style: AppTextStyles.labelS(colors.colorAccentPrimary),
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── DATE SECTION ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Text(
                      'PICK A DATE',
                      style: AppTextStyles.overline(
                          colors.colorTextTertiary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      itemCount: 14,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
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
                                  ? colors.colorAccentPrimary
                                  : colors.colorSurfacePrimary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? colors.colorAccentPrimary
                                    : isToday
                                        ? colors.colorAccentPrimary
                                            .withValues(alpha: 0.4)
                                        : colors.colorBorderSubtle,
                                width: isSelected ? 1.0 : 0.5,
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
                                        ? colors.colorTextOnAccent
                                            .withValues(alpha: 0.8)
                                        : isToday
                                            ? colors.colorAccentPrimary
                                            : colors.colorTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${date.day}',
                                  style: AppTextStyles.statM(
                                    isSelected
                                        ? colors.colorTextOnAccent
                                        : colors.colorTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _shortMonths[date.month - 1],
                                  style: AppTextStyles.overline(
                                    isSelected
                                        ? colors.colorTextOnAccent
                                            .withValues(alpha: 0.7)
                                        : colors.colorTextTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

                  // ── SLOTS SECTION ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Text(
                          'AVAILABLE SLOTS',
                          style: AppTextStyles.overline(
                              colors.colorTextTertiary),
                        ),
                        const Spacer(),
                        _LegendDot(
                            color: colors.colorSurfaceElevated,
                            label: 'Open',
                            colors: colors),
                        const SizedBox(width: AppSpacing.sm + 2),
                        _LegendDot(
                            color: colors.colorAccentPrimary,
                            label: 'Selected',
                            colors: colors),
                        const SizedBox(width: AppSpacing.sm + 2),
                        _LegendDot(
                            color: colors.colorSurfacePrimary,
                            label: 'Booked',
                            colors: colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.sm + 2,
                        mainAxisSpacing: AppSpacing.sm + 2,
                        childAspectRatio: 2.4,
                      ),
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final isSelected =
                            _selectedSlot?.id == slot.id;
                        final isBooked =
                            slot.status == SlotStatus.booked ||
                                slot.status == SlotStatus.blocked;
                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () =>
                                  setState(() => _selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: AppDuration.fast,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.colorAccentPrimary
                                  : isBooked
                                      ? colors.colorSurfacePrimary
                                      : colors.colorSurfaceElevated,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? colors.colorAccentPrimary
                                    : isBooked
                                        ? colors.colorBorderSubtle
                                        : colors.colorBorderMedium,
                                width: isSelected ? 1.0 : 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${slot.startTime} – ${slot.endTime}',
                                style: AppTextStyles.headingS(
                                  isSelected
                                      ? colors.colorTextOnAccent
                                      : isBooked
                                          ? colors.colorTextTertiary
                                          : colors.colorTextPrimary,
                                ).copyWith(
                                  decoration: isBooked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor:
                                      colors.colorTextTertiary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── BOOKING SUMMARY ────────────────────────────
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
                                AppSpacing.lg, AppSpacing.xxl,
                                AppSpacing.lg, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.colorSurfacePrimary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                    color: colors.colorBorderSubtle,
                                    width: 0.5),
                              ),
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Date',
                                    value:
                                        '${_selectedDate.day} ${_months[_selectedDate.month - 1]}, ${_selectedDate.year}',
                                    colors: colors,
                                  ),
                                  _SummaryRow(
                                    icon: Icons.access_time_rounded,
                                    label: 'Time',
                                    value:
                                        '${_selectedSlot!.startTime} – ${_selectedSlot!.endTime}',
                                    colors: colors,
                                  ),
                                  if (court != null)
                                    _SummaryRow(
                                      icon: Icons.currency_rupee_rounded,
                                      label: 'Amount',
                                      value: '₹${court.pricePerSlot}',
                                      isLast: true,
                                      highlight: true,
                                      colors: colors,
                                    ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  // ── AMENITIES ──────────────────────────────────
                  if (venue != null && venue.amenities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.xxl,
                          AppSpacing.lg, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AMENITIES',
                              style: AppTextStyles.overline(
                                  colors.colorTextTertiary)),
                          const SizedBox(height: AppSpacing.sm + 2),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: venue.amenities.map((a) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm + 2,
                                    vertical: AppSpacing.xs + 1),
                                decoration: BoxDecoration(
                                  color: colors.colorSurfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.pill),
                                  border: Border.all(
                                      color: colors.colorBorderSubtle,
                                      width: 0.5),
                                ),
                                child: Text(a,
                                    style: AppTextStyles.labelS(
                                        colors.colorTextSecondary)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                  // ── CANCELLATION NOTICE ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.xl,
                        AppSpacing.lg, AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.colorSurfacePrimary,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: colors.colorBorderSubtle, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 14,
                              color: colors.colorTextTertiary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Free cancellation up to 2 hours before booking.',
                              style: AppTextStyles.bodyS(
                                  colors.colorTextSecondary),
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

      // ── CTA bar ────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md,
            AppSpacing.lg, botPad + AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(
              top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        ),
        child: CsButton.primary(
          label: canBook
              ? 'Book & Pay ₹${court?.pricePerSlot ?? "—"}'
              : 'Select a time slot',
          onTap: canBook
              ? () {
                  // Will wire to Supabase later
                  Navigator.pop(context);
                }
              : null,
          isDisabled: !canBook,
        ),
      ),
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.colors,
  });
  final Color color;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: colors.colorBorderSubtle, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.overline(colors.colorTextSecondary)),
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
    required this.colors,
    this.isLast = false,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColorScheme colors;
  final bool isLast;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: colors.colorBorderSubtle, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlight
                  ? colors.colorAccentPrimary
                  : colors.colorTextSecondary),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(label,
              style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          const Spacer(),
          Text(
            value,
            style: highlight
                ? AppTextStyles.statM(colors.colorAccentPrimary)
                : AppTextStyles.headingS(colors.colorTextPrimary),
          ),
        ],
      ),
    );
  }
}
