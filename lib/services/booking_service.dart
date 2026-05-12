// lib/services/booking_service.dart
//
// Single source of truth for all booking operations:
//   - Slot availability reads
//   - Atomic booking creation via book_slot RPC (post-Razorpay)
//   - My bookings list
//   - Booking cancellation
//   - Upcoming booking lookup (for home Next Game card)
//
// The book_slot RPC is SECURITY DEFINER and runs in a SERIALIZABLE
// transaction — it atomically locks the slot, writes the booking,
// and flips slot.status = 'booked'. A P0001 error means the slot
// was taken by a concurrent user between payment and this call.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/court.dart';
import '../models/booking_record.dart';
import '../core/time_utils.dart';

// ── Result types ─────────────────────────────────────────────────

sealed class BookingResult {}

final class BookingSuccess extends BookingResult {
  BookingSuccess({required this.bookingId});
  final String bookingId;
}

final class BookingFailure extends BookingResult {
  BookingFailure({required this.message, this.isSlotTaken = false});
  final String message;
  final bool isSlotTaken;
}

// ── Service ──────────────────────────────────────────────────────

class BookingService {
  BookingService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ── Slots ────────────────────────────────────────────────────

  /// Returns all slots for a court on a specific date, ordered by start time.
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

  // ── Bookings write ───────────────────────────────────────────

  /// Atomically reserves the slot and records the booking.
  /// Must be called AFTER Razorpay confirms payment — never before.
  Future<BookingResult> createBooking({
    required String slotId,
    required String courtId,
    required String venueId,
    required String venueName,
    required String sport,
    required int amountPaid,
    required String paymentId,
    required String userId,
    String timeSlot = '',
    bool phoneScoringEnabled = false,
    String? hardwareOptionId,
    bool isPublicGame = false,
    int playerLimit = 10,
  }) async {
    try {
      final result = await _client.rpc('book_slot', params: {
        'p_slot_id':            slotId,
        'p_court_id':           courtId,
        'p_user_id':            userId,
        'p_venue_id':           venueId,
        'p_venue_name':         venueName,
        'p_sport':              sport,
        'p_amount':             amountPaid,
        'p_payment_id':         paymentId,
        'p_time_slot':          timeSlot,
        'p_phone_scoring':      phoneScoringEnabled,
        'p_hardware_option_id': hardwareOptionId,
        'p_is_public_game':     isPublicGame,
        'p_player_limit':       playerLimit,
      });
      return BookingSuccess(bookingId: result as String);
    } on PostgrestException catch (e) {
      final isSlotTaken = e.code == 'P0001';
      return BookingFailure(
        message: isSlotTaken
            ? 'This slot was just booked by someone else. Please choose another time.'
            : 'Booking failed: ${e.message}',
        isSlotTaken: isSlotTaken,
      );
    } catch (_) {
      return BookingFailure(message: 'Booking failed. Please contact support.');
    }
  }

  // ── Bookings read ────────────────────────────────────────────

  /// Returns all bookings for the current user, newest first.
  Future<List<BookingRecord>> getMyBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('bookings')
        .select('id, venue_name, sport, amount_paid, cs_status, created_at, time_slot')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows.map(_rowToBookingRecord).toList();
  }

  /// Returns the single nearest upcoming booking for the current user,
  /// or null if there are none. Used by the home Next Game card.
  Future<BookingRecord?> getNextUpcomingBooking() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('bookings')
        .select('id, venue_name, sport, amount_paid, cs_status, created_at, time_slot')
        .eq('user_id', userId)
        .eq('cs_status', 'upcoming')
        .order('created_at', ascending: true)
        .limit(1);

    if (rows.isEmpty) return null;
    return _rowToBookingRecord(rows.first);
  }

  /// Returns all upcoming bookings for the current user.
  Future<List<BookingRecord>> getUpcomingBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from('bookings')
        .select('id, venue_name, sport, amount_paid, cs_status, created_at, time_slot')
        .eq('user_id', userId)
        .eq('cs_status', 'upcoming')
        .order('created_at', ascending: true);

    return rows.map(_rowToBookingRecord).toList();
  }

  /// Returns a single booking by ID.
  Future<BookingRecord?> getBookingById(String bookingId) async {
    final row = await _client
        .from('bookings')
        .select('id, venue_name, sport, amount_paid, cs_status, created_at, time_slot')
        .eq('id', bookingId)
        .maybeSingle();

    return row == null ? null : _rowToBookingRecord(row);
  }

  // ── Cancellation ─────────────────────────────────────────────

  /// Cancels a booking and releases the slot back to 'available'.
  /// Only works on bookings the current user owns that are still 'upcoming'.
  Future<void> cancelBooking(String bookingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.rpc('cancel_booking', params: {
      'p_booking_id': bookingId,
      'p_user_id': userId,
    });
  }

  // ── Converters ───────────────────────────────────────────────

  Slot _rowToSlot(Map<String, dynamic> row) {
    final statusStr = row['status'] as String? ?? 'available';
    final status = switch (statusStr) {
      'booked'  => SlotStatus.booked,
      'blocked' => SlotStatus.blocked,
      _         => SlotStatus.available,
    };
    return Slot(
      id:        row['id'] as String,
      courtId:   (row['venue_court_id'] as String?) ?? '',
      startTime: TimeUtils.formatPgTime(row['start_time'] as String),
      endTime:   TimeUtils.formatPgTime(row['end_time'] as String),
      status:    status,
    );
  }

  BookingRecord _rowToBookingRecord(Map<String, dynamic> row) {
    final statusStr = row['cs_status'] as String? ?? 'upcoming';
    final status = switch (statusStr) {
      'completed' => BookingStatus.completed,
      'cancelled' => BookingStatus.cancelled,
      _           => BookingStatus.upcoming,
    };

    final createdAt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] as String)
        : null;
    final dateLabel = createdAt != null
        ? TimeUtils.formatBookingDate(createdAt)
        : '';

    return BookingRecord(
      id:        row['id'] as String,
      venueName: (row['venue_name'] as String?) ?? '',
      sport:     (row['sport'] as String?) ?? '',
      date:      dateLabel,
      timeSlot:  (row['time_slot'] as String?) ?? '',
      amount:    (row['amount_paid'] as int?) ?? 0,
      status:    status,
    );
  }
}
