// lib/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/court.dart';
import '../models/booking_record.dart';
import '../models/demo_slots.dart';
import '../services/booking_service.dart';
import 'app_mode_provider.dart';
import 'demo_store_provider.dart';

// ── Service singleton ──────────────────────────────────────────

final bookingServiceProvider =
    Provider<BookingService>((_) => BookingService());

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
  (ref, params) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      return DemoSlots.forCourt(params.courtId, params.date);
    }
    return ref
        .read(bookingServiceProvider)
        .getSlotsByCourtAndDate(params.courtId, params.date);
  },
);

// ── My bookings (mode-aware) ───────────────────────────────────

final myBookingsProvider = FutureProvider<List<BookingRecord>>(
  (ref) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      return ref.watch(demoStoreProvider).bookings;
    }
    return ref.read(bookingServiceProvider).getMyBookings();
  },
);

// ── Upcoming bookings (for home Next Game card) ────────────────

final upcomingBookingsProvider = FutureProvider<List<BookingRecord>>(
  (ref) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      return ref
          .watch(demoStoreProvider)
          .bookings
          .where((b) => b.status == BookingStatus.upcoming)
          .toList();
    }
    return ref.read(bookingServiceProvider).getUpcomingBookings();
  },
);

final nextUpcomingBookingProvider = FutureProvider<BookingRecord?>(
  (ref) async {
    if (ref.watch(appModeProvider) == AppMode.demo) {
      final upcoming = ref
          .watch(demoStoreProvider)
          .bookings
          .where((b) => b.status == BookingStatus.upcoming)
          .toList();
      return upcoming.isEmpty ? null : upcoming.first;
    }
    return ref.read(bookingServiceProvider).getNextUpcomingBooking();
  },
);
