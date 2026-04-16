// lib/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';
import '../services/courtside_booking_service.dart';

// ── Service singleton ──────────────────────────────────────────

final _bookingServiceProvider =
    Provider<CourtsideBookingService>((_) => CourtsideBookingService());

// ── Slots for a court on a date ────────────────────────────────

class SlotsParams {
  const SlotsParams(this.courtId, this.date);
  final String courtId;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is SlotsParams &&
      courtId == other.courtId &&
      date.year == other.date.year &&
      date.month == other.date.month &&
      date.day == other.date.day;

  @override
  int get hashCode => Object.hash(courtId, date.year, date.month, date.day);
}

final slotsProvider = FutureProvider.family<List<Slot>, SlotsParams>(
  (ref, params) => ref
      .read(_bookingServiceProvider)
      .getSlotsByCourtAndDate(params.courtId, params.date),
);

// ── My bookings ────────────────────────────────────────────────

final myBookingsProvider = FutureProvider<List<BookingRecord>>(
  (ref) => ref.read(_bookingServiceProvider).getMyBookings(),
);
