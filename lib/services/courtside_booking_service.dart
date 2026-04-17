// lib/services/courtside_booking_service.dart
//
// Slot availability reads + atomic booking via book_slot RPC.
// Never touches payment — Razorpay flows through payment_service.dart.
//
// Schema notes:
//   - slots.venue_court_id (uuid) — FK to courts.id
//   - bookings.cs_status  — 'upcoming' | 'completed' | 'cancelled'
//   - bookings.amount_paid — mirrors Courtside 'amount'

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fake_data.dart';

class CourtsideBookingService {
  CourtsideBookingService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ── Slots ──────────────────────────────────────────────────────

  /// Returns all slots for a court on a specific date.
  Future<List<Slot>> getSlotsByCourtAndDate(
    String courtId,
    DateTime date,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final rows = await _client
        .from('slots')
        .select('id, start_time, end_time, status')
        .eq('venue_court_id', courtId)
        .eq('date', dateStr)
        .order('start_time');

    return rows.map(_rowToSlot).toList();
  }

  // ── Bookings ───────────────────────────────────────────────────

  /// Atomically books a slot via the book_slot RPC.
  /// Returns the new booking ID, or throws if the slot was taken.
  Future<String> bookSlot({
    required String slotId,
    required String courtId,
    required int amount,
    required String venueName,
    required String sport,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final result = await _client.rpc('book_slot', params: {
      'p_slot_id': slotId,
      'p_court_id': courtId,
      'p_user_id': userId,
      'p_amount': amount,
      'p_venue_name': venueName,
      'p_sport': sport,
    });

    return result as String;
  }

  /// Returns all bookings for the current user, ordered by newest first.
  Future<List<BookingRecord>> getMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('bookings')
        .select('id, venue_name, sport, amount_paid, cs_status, created_at, slot_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map(_rowToBookingRecord).toList();
  }

  /// Cancels a booking by setting cs_status to 'cancelled'.
  /// Only cancels bookings that are still 'upcoming' — guards against
  /// accidentally cancelling already-completed or already-cancelled bookings.
  Future<void> cancelBooking(String bookingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('bookings')
        .update({'cs_status': 'cancelled'})
        .eq('id', bookingId)
        .eq('user_id', userId)
        .eq('cs_status', 'upcoming'); // guard: only cancel upcoming bookings
  }

  // ── Converters ─────────────────────────────────────────────────

  Slot _rowToSlot(Map<String, dynamic> row) {
    final statusStr = row['status'] as String? ?? 'available';
    final status = switch (statusStr) {
      'booked' => SlotStatus.booked,
      'blocked' => SlotStatus.blocked,
      _ => SlotStatus.available,
    };
    return Slot(
      id: row['id'] as String,
      courtId: row['venue_court_id']?.toString() ?? '',
      startTime: _formatTime(row['start_time'] as String),
      endTime: _formatTime(row['end_time'] as String),
      status: status,
    );
  }

  BookingRecord _rowToBookingRecord(Map<String, dynamic> row) {
    final statusStr = row['cs_status'] as String? ?? 'upcoming';
    final status = switch (statusStr) {
      'completed' => BookingStatus.completed,
      'cancelled' => BookingStatus.cancelled,
      _ => BookingStatus.upcoming,
    };

    final createdAt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] as String)
        : null;
    final dateLabel = createdAt != null ? _formatDate(createdAt) : '';

    return BookingRecord(
      id: row['id'] as String,
      venueName: (row['venue_name'] as String?) ?? '',
      sport: (row['sport'] as String?) ?? '',
      date: dateLabel,
      timeSlot: '',
      amount: (row['amount_paid'] as int?) ?? 0,
      status: status,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  /// Converts "09:00:00" → "9:00 AM"
  String _formatTime(String pgTime) {
    final parts = pgTime.split(':');
    if (parts.length < 2) return pgTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:$m $period';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 0) return '$diff days ago';
    return '${d.day} ${_months[d.month - 1]}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
