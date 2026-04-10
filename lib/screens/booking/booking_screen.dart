// lib/screens/booking/booking_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/cs_button.dart';

// ── Bottom-sheet result types ───────────────────────────────────

sealed class _SheetResult {}

final class _SheetSuccess extends _SheetResult {
  _SheetSuccess({required this.bookingId, required this.qrCode});
  final String bookingId;
  final String qrCode;
}

final class _SheetFailure extends _SheetResult {
  _SheetFailure({required this.message});
  final String message;
}

// ── Booking Screen ──────────────────────────────────────────────

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.courtId});
  final String courtId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
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

  // ── Payment flow ──────────────────────────────────────────────

  Future<void> _openConfirmSheet() async {
    // razorpay_flutter does not compile for web — show a clear message instead.
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment requires the mobile app. Testing on Android emulator.',
          ),
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';
    final userEmail = user?.email ?? '';
    final userName =
        (user?.userMetadata?['full_name'] as String?) ?? 'Player';
    final court = _court;
    final slot = _selectedSlot;

    if (court == null || slot == null) return;

    final formattedDate =
        '${_selectedDate.day} ${_months[_selectedDate.month - 1]}, ${_selectedDate.year}';

    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        court: court,
        venue: _venue,
        slot: slot,
        formattedDate: formattedDate,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
      ),
    );

    if (!mounted) return;

    if (result is _SheetSuccess) {
      _showSuccess(result.qrCode, result.bookingId);
    } else if (result is _SheetFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: context.colors.colorError,
        ),
      );
    }
    // null result = user dismissed sheet by swiping — no action needed
  }

  void _showSuccess(String qrCode, String bookingId) {
    final colors = context.colors;
    final refDisplay = bookingId.length >= 8
        ? bookingId.substring(0, 8).toUpperCase()
        : bookingId.toUpperCase();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: colors.colorSurfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Success mark ────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.colorSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.colorSuccess,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Booking Confirmed!',
                style: AppTextStyles.headingL(colors.colorTextPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Show this QR at the entrance.',
                style: AppTextStyles.bodyM(colors.colorTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // ── QR code ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  // colorTextOnAccent is #FFFFFF — required for QR scanability
                  color: colors.colorTextOnAccent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: QrImageView(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: 160,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // ── Booking reference ────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: colors.colorBorderSubtle,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'REF: $refDisplay',
                  style: AppTextStyles.labelM(colors.colorTextSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CsButton.primary(
                label: 'Done',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  context.go(AppRoutes.bookings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final court = _court;
    final venue = _venue;
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
                  onTap: () => context.pop(),
                  child: Container(
                    width: 38,
                    height: 38,
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
                      color: colors.colorAccentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                          color: colors.colorAccentPrimary.withValues(alpha: 0.3),
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

          // ── Scrollable content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── DATE SECTION ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Text(
                      'PICK A DATE',
                      style: AppTextStyles.overline(colors.colorTextTertiary),
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
                        final isSelected = date.year == _selectedDate.year &&
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isToday
                                      ? 'TODAY'
                                      : _weekdays[(date.weekday - 1) % 7],
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

                  // ── SLOTS SECTION ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        Text(
                          'AVAILABLE SLOTS',
                          style:
                              AppTextStyles.overline(colors.colorTextTertiary),
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
                        final isSelected = _selectedSlot?.id == slot.id;
                        final isBooked = slot.status == SlotStatus.booked ||
                            slot.status == SlotStatus.blocked;
                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () => setState(() => _selectedSlot = slot),
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
                                  decorationColor: colors.colorTextTertiary,
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
                          AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
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
                        borderRadius: BorderRadius.circular(AppRadius.md),
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

      // ── CTA bar ───────────────────────────────────────────────
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
          onTap: canBook ? _openConfirmSheet : null,
          isDisabled: !canBook,
        ),
      ),
    );
  }
}

// ── Confirm Sheet ────────────────────────────────────────────────

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.court,
    required this.venue,
    required this.slot,
    required this.formattedDate,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  final Court court;
  final Venue? venue;
  final Slot slot;
  final String formattedDate;
  final String userId;
  final String userEmail;
  final String userName;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final _isLoading = ValueNotifier<bool>(false);
  late final PaymentService _paymentService;
  late final BookingService _bookingService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _bookingService = BookingService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    _isLoading.value = true;

    final amountInPaise = widget.court.pricePerSlot * 100; // rupees → paise
    final description =
        '${widget.court.name} · ${widget.slot.startTime}–${widget.slot.endTime}';

    final paymentResult = await _paymentService.initiatePayment(
      amountInPaise: amountInPaise,
      description: description,
      userEmail: widget.userEmail,
      userName: widget.userName,
    );

    if (!mounted) return;

    if (paymentResult is PaymentSuccess) {
      final bookingResult = await _bookingService.createBooking(
        slotId: widget.slot.id,
        venueId: widget.court.venueId,
        sport: widget.court.sport,
        amountPaid: widget.court.pricePerSlot,
        paymentId: paymentResult.paymentId,
        userId: widget.userId,
      );

      if (!mounted) return;

      if (bookingResult is BookingSuccess) {
        Navigator.of(context).pop(
          _SheetSuccess(
            bookingId: bookingResult.bookingId,
            qrCode: bookingResult.qrCode,
          ),
        );
      } else if (bookingResult is BookingFailure) {
        Navigator.of(context).pop(
          _SheetFailure(message: bookingResult.message),
        );
      }
    } else if (paymentResult is PaymentFailure) {
      Navigator.of(context).pop(
        _SheetFailure(message: paymentResult.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Sheet handle ──────────────────────────────────
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.xl),

          // ── Title ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Confirm Booking',
                style: AppTextStyles.headingL(colors.colorTextPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Review your booking before payment.',
                style: AppTextStyles.bodyM(colors.colorTextSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Summary ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                    color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Column(
                children: [
                  if (widget.venue != null)
                    _SheetRow(
                      label: 'Venue',
                      value: widget.venue!.name,
                      colors: colors,
                    ),
                  _SheetRow(
                    label: 'Court',
                    value: widget.court.name,
                    colors: colors,
                  ),
                  _SheetRow(
                    label: 'Date',
                    value: widget.formattedDate,
                    colors: colors,
                  ),
                  _SheetRow(
                    label: 'Time',
                    value:
                        '${widget.slot.startTime} – ${widget.slot.endTime}',
                    colors: colors,
                  ),
                  _SheetRow(
                    label: 'Amount',
                    value: '₹${widget.court.pricePerSlot}',
                    colors: colors,
                    isLast: true,
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Pay button ────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, botPad + AppSpacing.xl,
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, isLoading, _) => CsButton.primary(
                label: 'Pay & Confirm  ₹${widget.court.pricePerSlot}',
                onTap: isLoading ? null : _handlePay,
                isLoading: isLoading,
                isDisabled: isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet summary row ────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.label,
    required this.value,
    required this.colors,
    this.isLast = false,
    this.highlight = false,
  });

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

// ── Legend Dot ───────────────────────────────────────────────────

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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                Border.all(color: colors.colorBorderSubtle, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.overline(colors.colorTextSecondary)),
      ],
    );
  }
}

// ── Summary Row (booking screen inline summary) ──────────────────

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
