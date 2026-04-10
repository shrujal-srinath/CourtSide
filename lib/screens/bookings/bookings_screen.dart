// lib/screens/booking/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.courtId});
  final String courtId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  Court? _court;
  Venue? _venue;
  final Set<String> _selectedSlots = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _court = FakeData.courts
        .where((c) => c.id == widget.courtId)
        .firstOrNull;
    if (_court != null) {
      _venue = FakeData.venues
          .where((v) => v.id == _court!.venueId)
          .firstOrNull;
    }
  }

  List<Slot> get _slots => FakeData.slotsC1; // use c1 slots for all courts in fake mode

  int get _totalAmount => _selectedSlots.length * (_court?.pricePerSlot ?? 0);

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month) return 'Today';
    final tomorrow = now.add(const Duration(days: 1));
    if (d.day == tomorrow.day && d.month == tomorrow.month) return 'Tomorrow';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (_court == null || _venue == null) {
      return Scaffold(
        backgroundColor: context.colors.colorBackgroundPrimary,
        body: Center(
          child: Text('Court not found',
            style: TextStyle(color: context.colors.colorTextPrimary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.colorBackgroundPrimary,
      body: Column(
        children: [
          SizedBox(height: topPad),

          // ── Header ───────────────────────────────────────────
          Container(
            color: context.colors.colorBackgroundPrimary,
            padding: const EdgeInsets.fromLTRB(14, 8, 18, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.colorSurfacePrimary,
                      border: Border.all(color: context.colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: context.colors.colorTextPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Book a slot',
                        style: GoogleFonts.inter(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: context.colors.colorTextPrimary,
                        ),
                      ),
                      Text('${_venue!.name} · ${_court!.name}',
                        style: GoogleFonts.inter(
                          fontSize: 12, color: context.colors.colorTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: context.colors.colorBorderSubtle),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date strip ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Text('Select date',
                      style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: context.colors.colorTextSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: 7,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final date = DateTime.now().add(Duration(days: i));
                        final active = date.day == _selectedDate.day &&
                            date.month == _selectedDate.month;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _selectedSlots.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.red
                                  : context.colors.colorSurfacePrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppColors.red
                                    : context.colors.colorBorderSubtle,
                                width: 0.5,
                              ),
                            ),
                            child: Text(_formatDate(date),
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.white
                                    : context.colors.colorTextSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Slot grid ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                    child: Text('Available slots',
                      style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: context.colors.colorTextSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _slots.length,
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final selected = _selectedSlots.contains(slot.id);
                        final available = slot.status == SlotStatus.available;
                        final booked = slot.status == SlotStatus.booked;

                        Color bgColor;
                        Color borderColor;
                        Color textColor;

                        if (selected) {
                          bgColor = AppColors.red;
                          borderColor = AppColors.red;
                          textColor = AppColors.white;
                        } else if (booked) {
                          bgColor = context.colors.colorSurfaceElevated;
                          borderColor = context.colors.colorBorderSubtle;
                          textColor = context.colors.colorTextSecondary;
                        } else if (available) {
                          bgColor = context.colors.colorSurfacePrimary;
                          borderColor = context.colors.colorBorderSubtle;
                          textColor = context.colors.colorTextPrimary;
                        } else {
                          bgColor = context.colors.colorSurfaceElevated;
                          borderColor = context.colors.colorBorderSubtle;
                          textColor = context.colors.colorTextSecondary;
                        }

                        return GestureDetector(
                          onTap: available
                              ? () => setState(() {
                                  if (selected) {
                                    _selectedSlots.remove(slot.id);
                                  } else {
                                    _selectedSlots.add(slot.id);
                                  }
                                })
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: borderColor, width: 0.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(slot.startTime,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                if (booked)
                                  Text('Booked',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      color: context.colors.colorTextSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Slot legend
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Row(
                      children: [
                        _Legend(color: AppColors.red, label: 'Selected'),
                        const SizedBox(width: 16),
                        _Legend(color: context.colors.colorSurfacePrimary,
                          label: 'Available', border: true),
                        const SizedBox(width: 16),
                        _Legend(
                          color: context.colors.colorSurfaceElevated,
                          label: 'Booked'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom confirm bar ────────────────────────────────────
      bottomNavigationBar: _selectedSlots.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(
                18, 14, 18,
                MediaQuery.of(context).padding.bottom + 14),
              decoration: BoxDecoration(
                color: context.colors.colorSurfacePrimary,
                border: Border(
                  top: BorderSide(color: context.colors.colorBorderSubtle, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_selectedSlots.length} slot${_selectedSlots.length > 1 ? 's' : ''}  ·  ${_court!.slotDurationMin * _selectedSlots.length} min',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: context.colors.colorTextSecondary),
                        ),
                        Text('₹$_totalAmount',
                          style: GoogleFonts.inter(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: context.colors.colorTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _confirmBooking(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Confirm booking',
                        style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _confirmBooking(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        court: _court!,
        venue: _venue!,
        slots: _slots.where((s) => _selectedSlots.contains(s.id)).toList(),
        total: _totalAmount,
        onConfirm: () {
          Navigator.pop(context);
          _showSuccess(context);
        },
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: context.colors.colorSurfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                  color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Booking confirmed!',
                style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: context.colors.colorTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text('${_venue!.name}\n${_selectedSlots.length} slot${_selectedSlots.length > 1 ? 's' : ''} · ₹$_totalAmount',
                style: GoogleFonts.inter(
                  fontSize: 14, color: context.colors.colorTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/bookings');
                  },
                  child: const Text('View booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.border = false,
  });
  final Color color;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border
                ? Border.all(color: context.colors.colorBorderSubtle, width: 0.5)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 11, color: context.colors.colorTextSecondary),
        ),
      ],
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.court,
    required this.venue,
    required this.slots,
    required this.total,
    required this.onConfirm,
  });

  final Court court;
  final Venue venue;
  final List<Slot> slots;
  final int total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: context.colors.colorBorderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18, 16, 18,
              MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm booking',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: context.colors.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _Row('Venue', venue.name),
                _Row('Court', court.name),
                _Row('Slots', slots.map((s) => s.startTime).join(', ')),
                _Row('Duration', '${court.slotDurationMin * slots.length} min'),
                const SizedBox(height: 8),
                Container(height: 0.5, color: context.colors.colorBorderSubtle),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: context.colors.colorTextPrimary,
                      ),
                    ),
                    Text('₹$total',
                      style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: context.colors.colorTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text('Pay & confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, color: context.colors.colorTextSecondary),
          ),
          Flexible(
            child: Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: context.colors.colorTextPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}