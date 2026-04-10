// lib/screens/booking/booking_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Venue? get _venue => widget.venue ??
      FakeData.venues.where((v) => v.id == widget.venueId).firstOrNull;

  List<Court> get _courts =>
      FakeData.courtsByVenueAndSport(widget.venueId, widget.sport);

  List<Slot> get _slots {
    final court = _selectedCourt ?? _courts.firstOrNull;
    if (court == null) return FakeData.slotsC1;
    return FakeData.slotsByCourtId(court.id);
  }

  Color get _sportColor {
    final colors = context.colors;
    switch (widget.sport) {
      case 'basketball': return colors.colorSportBasketball;
      case 'cricket':    return colors.colorSportCricket;
      case 'badminton':  return colors.colorSportBadminton;
      default:           return colors.colorSportFootball;
    }
  }

  String get _sportLabel {
    switch (widget.sport) {
      case 'basketball': return 'Basketball';
      case 'cricket':    return 'Box Cricket';
      case 'badminton':  return 'Badminton';
      default:           return 'Football';
    }
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // ── Slot selection ────────────────────────────────────────────

  void _onSlotTap(Slot slot) {
    final courts = _courts;
    if (courts.length > 1) {
      // Multiple courts: show picker first
      setState(() => _selectedSlot = slot);
      _showCourtPicker(slot);
    } else {
      // Single court: auto-select
      setState(() {
        _selectedSlot = slot;
        _selectedCourt = courts.firstOrNull;
      });
    }
  }

  void _showCourtPicker(Slot slot) {
    final courts = _courts;
    showModalBottomSheet<Court?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CourtPickerSheet(
        courts: courts,
        slot: slot,
        initialCourt: _selectedCourt,
      ),
    ).then((court) {
      if (!mounted || court == null) return;
      setState(() => _selectedCourt = court);
    });
  }

  // ── Payment flow ──────────────────────────────────────────────

  Future<void> _openConfirmSheet() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Payment requires the mobile app. Testing on Android emulator.'),
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? '';
    final userEmail = user?.email ?? '';
    final userName =
        (user?.userMetadata?['full_name'] as String?) ?? 'Player';
    final court = _selectedCourt;
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
        sport: widget.sport,
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.colorSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: colors.colorSuccess, size: 36),
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.colorSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: colors.colorBorderSubtle, width: 0.5),
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
    final venue = _venue;
    final courts = _courts;
    final canBook = _selectedSlot != null && _selectedCourt != null;
    final slotSelected = _selectedSlot != null;
    final awaitingCourt = slotSelected && _selectedCourt == null;
    final sc = _sportColor;
    final firstCourt = courts.firstOrNull;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
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
                        venue?.name ?? 'Book a Court',
                        style:
                            AppTextStyles.headingM(colors.colorTextPrimary),
                      ),
                      if (venue != null)
                        Text(
                          venue.area,
                          style:
                              AppTextStyles.bodyS(colors.colorTextSecondary),
                        ),
                    ],
                  ),
                ),
                // Sport badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 2,
                      vertical: AppSpacing.xs + 1),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: sc.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Text(
                    _sportLabel,
                    style: AppTextStyles.labelS(sc),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── DATE STRIP ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Text(
                      'PICK A DATE',
                      style:
                          AppTextStyles.overline(colors.colorTextTertiary),
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
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _selectedSlot = null;
                            _selectedCourt = null;
                          }),
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

                  const SizedBox(height: AppSpacing.xxl),

                  // ── SLOTS SECTION ──────────────────────────────
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
                        if (firstCourt != null)
                          Text(
                            '${courts.length} court${courts.length > 1 ? 's' : ''} · ₹${firstCourt.pricePerSlot}/slot',
                            style: AppTextStyles.labelS(
                                colors.colorTextSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),

                  // Full-width slot row cards
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Column(
                      children: _slots.asMap().entries.map((entry) {
                        final slot = entry.value;
                        final isSelected = _selectedSlot?.id == slot.id;
                        final isBooked =
                            slot.status == SlotStatus.booked ||
                                slot.status == SlotStatus.blocked;
                        final isAvailable = !isBooked;

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm),
                          child: GestureDetector(
                            onTap: isAvailable
                                ? () => _onSlotTap(slot)
                                : null,
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: AppDuration.fast,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.colorAccentPrimary
                                        .withValues(alpha: 0.08)
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
                              child: Opacity(
                                opacity: isBooked ? 0.45 : 1.0,
                                child: Row(
                                  children: [
                                    // Status dot
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isBooked
                                            ? colors.colorTextTertiary
                                            : isSelected
                                                ? colors.colorAccentPrimary
                                                : colors.colorSuccess,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    // Time + subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${slot.startTime} – ${slot.endTime}',
                                            style: AppTextStyles.headingS(
                                              isBooked
                                                  ? colors.colorTextTertiary
                                                  : isSelected
                                                      ? colors
                                                          .colorAccentPrimary
                                                      : colors
                                                          .colorTextPrimary,
                                            ),
                                          ),
                                          if (firstCourt != null && !isBooked)
                                            Text(
                                              '${firstCourt.slotDurationMin} min · ${courts.length} court${courts.length > 1 ? 's' : ''} available',
                                              style: AppTextStyles.bodyS(
                                                  colors.colorTextSecondary),
                                            ),
                                          if (isBooked)
                                            Text(
                                              'Booked',
                                              style: AppTextStyles.bodyS(
                                                  colors.colorTextTertiary),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Price + chevron
                                    if (isAvailable) ...[
                                      Text(
                                        firstCourt != null
                                            ? '₹${firstCourt.pricePerSlot}'
                                            : '',
                                        style: AppTextStyles.headingS(
                                          isSelected
                                              ? colors.colorAccentPrimary
                                              : colors.colorTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: isSelected
                                            ? colors.colorAccentPrimary
                                            : colors.colorTextTertiary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Court selection indicator ──────────────────
                  if (slotSelected && courts.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, 0),
                      child: AnimatedSwitcher(
                        duration: AppDuration.normal,
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
                        child: _selectedCourt != null
                            ? Container(
                                key: const ValueKey('court-selected'),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: colors.colorSurfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                      color: colors.colorSuccess
                                          .withValues(alpha: 0.3),
                                      width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.sports_outlined,
                                        size: 16,
                                        color: colors.colorSuccess),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      _selectedCourt!.name,
                                      style: AppTextStyles.headingS(
                                          colors.colorTextPrimary),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _showCourtPicker(
                                          _selectedSlot!),
                                      child: Text(
                                        'Change',
                                        style: AppTextStyles.labelS(
                                            colors.colorInfo),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                key: const ValueKey('court-pick'),
                                onTap: () =>
                                    _showCourtPicker(_selectedSlot!),
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: colors.colorAccentPrimary
                                        .withValues(alpha: 0.06),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                        color: colors.colorAccentPrimary
                                            .withValues(alpha: 0.3),
                                        width: 0.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded,
                                          size: 16,
                                          color: colors.colorAccentPrimary),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Choose your court',
                                        style: AppTextStyles.headingS(
                                            colors.colorAccentPrimary),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.chevron_right_rounded,
                                          size: 18,
                                          color: colors.colorAccentPrimary),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                  // ── Booking summary ────────────────────────────
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
                    child: canBook
                        ? Padding(
                            key: const ValueKey('summary'),
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg, AppSpacing.xl,
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
                                    icon: Icons.sports_outlined,
                                    label: 'Court',
                                    value: _selectedCourt!.name,
                                    colors: colors,
                                  ),
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
                                  _SummaryRow(
                                    icon: Icons.currency_rupee_rounded,
                                    label: 'Amount',
                                    value: '₹${_selectedCourt!.pricePerSlot}',
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

                  // ── Amenities ──────────────────────────────────
                  if (_venue != null && _venue!.amenities.isNotEmpty)
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
                            children: _venue!.amenities.map((a) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm + 2,
                                    vertical: AppSpacing.xs + 1),
                                decoration: BoxDecoration(
                                  color: colors.colorSurfaceElevated,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
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

                  // ── Cancellation notice ────────────────────────
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
              top: BorderSide(
                  color: colors.colorBorderSubtle, width: 0.5)),
        ),
        child: awaitingCourt
            ? CsButton.secondary(
                label: 'Choose a Court',
                onTap: _selectedSlot != null
                    ? () => _showCourtPicker(_selectedSlot!)
                    : null,
              )
            : CsButton.primary(
                label: canBook
                    ? 'Book & Pay ₹${_selectedCourt!.pricePerSlot}'
                    : 'Select a time slot',
                onTap: canBook ? _openConfirmSheet : null,
                isDisabled: !canBook,
              ),
      ),
    );
  }
}

// ── Court Picker Sheet ────────────────────────────────────────────

class _CourtPickerSheet extends StatefulWidget {
  const _CourtPickerSheet({
    required this.courts,
    required this.slot,
    this.initialCourt,
  });

  final List<Court> courts;
  final Slot slot;
  final Court? initialCourt;

  @override
  State<_CourtPickerSheet> createState() => _CourtPickerSheetState();
}

class _CourtPickerSheetState extends State<_CourtPickerSheet> {
  Court? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCourt ?? widget.courts.firstOrNull;
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
          // Handle
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your court',
                        style: AppTextStyles.headingL(colors.colorTextPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.slot.startTime} – ${widget.slot.endTime}',
                        style: AppTextStyles.bodyS(colors.colorTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Court cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: widget.courts.map((court) {
                final isSelected = _selected?.id == court.id;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = court),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: AppDuration.fast,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.colorAccentPrimary
                                .withValues(alpha: 0.06)
                            : colors.colorSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? colors.colorAccentPrimary
                              : colors.colorBorderSubtle,
                          width: isSelected ? 1.0 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Radio
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? colors.colorAccentPrimary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? colors.colorAccentPrimary
                                    : colors.colorBorderMedium,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded,
                                    size: 12,
                                    color: colors.colorTextOnAccent)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  court.name,
                                  style: AppTextStyles.headingS(
                                      colors.colorTextPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${court.surface} · ${court.isIndoor ? 'Indoor' : 'Outdoor'}${court.hasTheBox ? ' · THE BOX' : ''}',
                                  style: AppTextStyles.bodyS(
                                      colors.colorTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${court.pricePerSlot}',
                            style: AppTextStyles.headingS(
                                colors.colorTextPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, botPad + AppSpacing.xl),
            child: CsButton.primary(
              label: 'Confirm Court',
              onTap: _selected != null
                  ? () => Navigator.of(context).pop(_selected)
                  : null,
              isDisabled: _selected == null,
            ),
          ),
        ],
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
    required this.sport,
    required this.formattedDate,
    required this.userId,
    required this.userEmail,
    required this.userName,
  });

  final Court court;
  final Venue? venue;
  final Slot slot;
  final String sport;
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

    final amountInPaise = widget.court.pricePerSlot * 100;
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

  Future<void> _launchShop() async {
    final uri = Uri.parse('https://courtside.in/shop');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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

            // Title
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

            // Summary
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

            // ── Equipment add-ons ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEED EQUIPMENT?',
                    style: AppTextStyles.overline(colors.colorTextTertiary),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Row(
                    children: [
                      Expanded(
                        child: _EquipmentCard(
                          icon: Icons.sports_tennis_rounded,
                          name: 'Racket Rental',
                          price: '+₹150/session',
                          onBuyNow: _launchShop,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _EquipmentCard(
                          icon: Icons.directions_run_rounded,
                          name: 'Shoe Rental',
                          price: '+₹100/session',
                          onBuyNow: _launchShop,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Pay button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0,
                  AppSpacing.lg, botPad + AppSpacing.xl),
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
      ),
    );
  }
}

// ── Equipment Card ───────────────────────────────────────────────

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.icon,
    required this.name,
    required this.price,
    required this.onBuyNow,
    required this.colors,
  });

  final IconData icon;
  final String name;
  final String price;
  final VoidCallback onBuyNow;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: colors.colorTextSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(name,
              style: AppTextStyles.labelM(colors.colorTextPrimary)),
          const SizedBox(height: 2),
          Text(price,
              style: AppTextStyles.bodyS(colors.colorTextSecondary)),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: onBuyNow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buy Now',
                  style: AppTextStyles.labelS(colors.colorInfo)
                      .copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: colors.colorInfo),
                ),
                const SizedBox(width: 2),
                Icon(Icons.open_in_new_rounded,
                    size: 10, color: colors.colorInfo),
              ],
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
