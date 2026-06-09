// lib/models/demo_slots.dart
//
// Deterministic slot generation for DEMO mode. LIVE mode never touches this —
// it reads real slots from Supabase. Generated slots are stable for a given
// (court, date) so the demo looks consistent across rebuilds, and times are
// formatted "6:00 AM" / "7:30 PM" to match the booking screen's parser.

import 'fake_data.dart';

class DemoSlots {
  /// Slots for a court on a date: hourly-ish windows from 06:00 to 22:00,
  /// sized to the court's slot duration. A deterministic subset is marked
  /// booked so availability looks lived-in; past windows (for today) are
  /// returned as blocked so they can't be booked.
  static List<Slot> forCourt(String courtId, DateTime date) {
    final court = _court(courtId);
    final durationMin = court?.slotDurationMin ?? 60;

    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final slots = <Slot>[];
    var minutesFromMidnight = 6 * 60; // 06:00
    const endOfDay = 22 * 60; // 22:00
    var index = 0;

    while (minutesFromMidnight + durationMin <= endOfDay) {
      final startH = minutesFromMidnight ~/ 60;
      final startM = minutesFromMidnight % 60;
      final endMinutes = minutesFromMidnight + durationMin;
      final endH = endMinutes ~/ 60;
      final endM = endMinutes % 60;

      // Deterministic "booked" pattern: every 3rd slot, seeded by court id.
      final seed = courtId.hashCode + date.day;
      final isBooked = (index + seed) % 3 == 0;
      final isPast = isToday && minutesFromMidnight <= now.hour * 60 + now.minute;

      slots.add(Slot(
        id: '${courtId}_${date.toIso8601String().split('T').first}_$index',
        courtId: courtId,
        startTime: _fmt(startH, startM),
        endTime: _fmt(endH, endM),
        status: isPast
            ? SlotStatus.blocked
            : isBooked
                ? SlotStatus.booked
                : SlotStatus.available,
      ));

      minutesFromMidnight += durationMin;
      index++;
    }
    return slots;
  }

  static Court? _court(String courtId) {
    for (final c in FakeData.courts) {
      if (c.id == courtId) return c;
    }
    return null;
  }

  static String _fmt(int hour24, int minute) {
    final period = hour24 >= 12 ? 'PM' : 'AM';
    var h = hour24 % 12;
    if (h == 0) h = 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$h:$mm $period';
  }
}
