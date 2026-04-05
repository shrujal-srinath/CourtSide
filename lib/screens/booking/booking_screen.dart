// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/app_spacing.dart';
import '../../core/app_gradients.dart';
import '../../models/fake_data.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.courtId});
  final String courtId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  Slot? _selectedSlot;

  Court? get _court =>
      FakeData.courts.where((c) => c.id == widget.courtId).firstOrNull;

  Venue? get _venue => _court != null
      ? FakeData.venues.where((v) => v.id == _court!.venueId).firstOrNull
      : null;

  List<Slot> get _slots => FakeData.slotsC1;

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: AppDuration.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: AppDuration.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool get _canProceed {
    if (_currentStep == 1) return _selectedSlot != null;
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final court = _court;
    final venue = _venue;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF080A0F), Color(0xFF0D1829)],
              ),
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            padding: EdgeInsets.fromLTRB(18, topPad + 8, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _currentStep > 0
                          ? _prevStep()
                          : Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: AppColors.border, width: 0.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            court?.name ?? 'Book a Court',
                            style: AppTextStyles.headingM(
                                AppColors.textPrimaryDark),
                          ),
                          if (venue != null)
                            Text(
                              venue.name,
                              style: AppTextStyles.bodyS(
                                  AppColors.textSecondaryDark),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _StepIndicator(currentStep: _currentStep),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DateStep(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                ),
                _SlotStep(
                  slots: _slots,
                  selectedSlot: _selectedSlot,
                  court: court,
                  onSlotSelected: (s) => setState(() => _selectedSlot = s),
                ),
                _SummaryStep(
                  court: court,
                  venue: venue,
                  selectedDate: _selectedDate,
                  selectedSlot: _selectedSlot,
                ),
              ],
            ),
          ),

          // Bottom CTA
          Container(
            padding: EdgeInsets.fromLTRB(
                18, 14, 18, MediaQuery.of(context).padding.bottom + 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _canProceed
                    ? () {
                        if (_currentStep < 2) {
                          _nextStep();
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canProceed ? AppColors.red : AppColors.surfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  _currentStep == 2
                      ? 'Pay ₹${court?.pricePerSlot ?? '—'} & Confirm'
                      : _currentStep == 1
                          ? 'Confirm Slot'
                          : 'Choose a Slot →',
                  style: AppTextStyles.headingS(AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ─────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;
  static const _labels = ['Date', 'Time', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isPast = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppColors.red
                      : isPast
                          ? Colors.transparent
                          : AppColors.surfaceHigh,
                  border: isPast
                      ? Border.all(color: AppColors.red, width: 1.5)
                      : isActive
                          ? null
                          : Border.all(color: AppColors.border, width: 1),
                ),
                child: Center(
                  child: isPast
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.red, size: 14)
                      : Text(
                          '${i + 1}',
                          style: AppTextStyles.labelM(
                            isActive
                                ? AppColors.white
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[i],
                        style: AppTextStyles.overline(
                          isActive || isPast
                              ? AppColors.textPrimaryDark
                              : AppColors.textTertiaryDark,
                        ),
                      ),
                      if (i < 2)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(top: 3),
                          color: isPast
                              ? AppColors.red.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Step 1: Date ───────────────────────────────────────────────

class _DateStep extends StatelessWidget {
  const _DateStep(
      {required this.selectedDate, required this.onDateSelected});
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a Date',
              style: AppTextStyles.displayS(AppColors.textPrimaryDark)),
          const SizedBox(height: 6),
          Text('Choose when you want to play',
              style: AppTextStyles.bodyM(AppColors.textSecondaryDark)),
          const SizedBox(height: 24),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final date = today.add(Duration(days: i));
                final isToday = i == 0;
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;
                return GestureDetector(
                  onTap: () => onDateSelected(date),
                  child: AnimatedContainer(
                    duration: AppDuration.fast,
                    width: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.red : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: isSelected ? AppColors.red : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday
                              ? 'TODAY'
                              : _weekdays[(date.weekday - 1) % 7],
                          style: AppTextStyles.overline(
                            isSelected
                                ? AppColors.white.withValues(alpha: 0.7)
                                : isToday
                                    ? AppColors.red
                                    : AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _months[date.month - 1],
                          style: AppTextStyles.overline(
                            isSelected
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.textTertiaryDark,
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
    );
  }
}

// ── Step 2: Time Slot ──────────────────────────────────────────

class _SlotStep extends StatelessWidget {
  const _SlotStep({
    required this.slots,
    required this.selectedSlot,
    required this.court,
    required this.onSlotSelected,
  });

  final List<Slot> slots;
  final Slot? selectedSlot;
  final Court? court;
  final ValueChanged<Slot> onSlotSelected;


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a Slot',
              style: AppTextStyles.displayS(AppColors.textPrimaryDark)),
          const SizedBox(height: 6),
          Text(
            court != null
                ? '${court!.name} · ₹${court!.pricePerSlot}/slot'
                : 'Select your preferred time',
            style: AppTextStyles.bodyM(AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _LegendDot(color: AppColors.surface, label: 'Available'),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.red, label: 'Selected'),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.surfaceHigh, label: 'Booked'),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemCount: slots.length,
            itemBuilder: (c, i) {
              final slot = slots[i];
              final isSelected = selectedSlot?.id == slot.id;
              final isBooked = slot.status == SlotStatus.booked ||
                  slot.status == SlotStatus.blocked;
              return GestureDetector(
                onTap: isBooked ? null : () => onSlotSelected(slot),
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.red
                        : isBooked
                            ? AppColors.surfaceHigh
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? AppColors.red : AppColors.border,
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
                                ? AppColors.textTertiaryDark
                                : AppColors.textPrimaryDark,
                      ).copyWith(
                          decoration:
                              isBooked ? TextDecoration.lineThrough : null),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyles.overline(AppColors.textSecondaryDark)),
      ],
    );
  }
}

// ── Step 3: Summary ────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.court,
    required this.venue,
    required this.selectedDate,
    required this.selectedSlot,
  });

  final Court? court;
  final Venue? venue;
  final DateTime selectedDate;
  final Slot? selectedSlot;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${selectedDate.day} ${_months[selectedDate.month - 1]}, ${selectedDate.year}';
    final timeStr = selectedSlot != null
        ? '${selectedSlot!.startTime} – ${selectedSlot!.endTime}'
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirm Booking',
              style: AppTextStyles.displayS(AppColors.textPrimaryDark)),
          const SizedBox(height: 6),
          Text('Review your booking details',
              style: AppTextStyles.bodyM(AppColors.textSecondaryDark)),
          const SizedBox(height: 24),

          // Summary card
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    icon: Icons.sports_basketball_rounded,
                    label: 'Court',
                    value: court?.name ?? '—'),
                _SummaryRow(
                    icon: Icons.location_on_rounded,
                    label: 'Venue',
                    value: venue?.name ?? '—'),
                _SummaryRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: dateStr),
                _SummaryRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: timeStr),
                _SummaryRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Amount',
                    value: court != null ? '₹${court!.pricePerSlot}' : '—',
                    isLast: true,
                    highlight: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (venue != null && venue!.amenities.isNotEmpty) ...[
            Text('AMENITIES',
                style: AppTextStyles.overline(AppColors.textSecondaryDark)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: venue!.amenities.map((a) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border:
                        Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(a,
                      style: AppTextStyles.labelS(
                          AppColors.textSecondaryDark)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'Free cancellation up to 2 hours before your booking. After that, the slot fee is non-refundable.',
              style: AppTextStyles.bodyS(AppColors.textSecondaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlight
                  ? AppColors.red
                  : AppColors.textSecondaryDark),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.bodyM(AppColors.textSecondaryDark)),
          const Spacer(),
          Text(
            value,
            style: highlight
                ? AppTextStyles.statM(AppColors.red)
                : AppTextStyles.headingS(AppColors.textPrimaryDark),
          ),
        ],
      ),
    );
  }
}
