// lib/services/booking_service.dart
//
// Writes confirmed bookings to Supabase AFTER Razorpay has confirmed payment.
// Payment-first, DB-write-second — never the other way around.
//
// Supabase prerequisites:
//   1. RLS on `bookings` table: users can only INSERT where user_id = auth.uid()
//   2. Run the following SQL once in Supabase SQL editor to enable atomic
//      slot-count increment:
//
//      CREATE OR REPLACE FUNCTION increment_slot_booked(p_slot_id text)
//      RETURNS void
//      LANGUAGE sql
//      SECURITY DEFINER
//      AS $$
//        UPDATE slots SET booked = booked + 1 WHERE id = p_slot_id;
//      $$;

import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

// ── Result types ────────────────────────────────────────────────

sealed class BookingResult {}

final class BookingSuccess extends BookingResult {
  BookingSuccess({required this.bookingId, required this.qrCode});
  final String bookingId;
  final String qrCode;
}

final class BookingFailure extends BookingResult {
  BookingFailure({required this.message});
  final String message;
}

// ── Service ─────────────────────────────────────────────────────

class BookingService {
  BookingService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Creates a confirmed booking row then atomically increments the slot count.
  ///
  /// If the bookings INSERT fails, the slot count is NOT touched.
  /// If only the slot increment fails, the booking still stands (non-fatal).
  Future<BookingResult> createBooking({
    required String slotId,
    required String venueId,
    required String sport,
    required int amountPaid,
    required String paymentId,
    required String userId,
  }) async {
    try {
      final qrCode = _generateUuid();

      // Step 1: Insert booking. Throws on any DB error.
      final response = await _client
          .from('bookings')
          .insert({
            'user_id': userId,
            'slot_id': slotId,
            'venue_id': venueId,
            'sport': sport,
            'status': 'confirmed',
            'amount_paid': amountPaid,
            'payment_id': paymentId,
            'qr_code': qrCode,
            'checked_in': false,
          })
          .select('id')
          .single();

      final bookingId = response['id'] as String;

      // Step 2: Atomically increment slot booked count via RPC.
      // Non-fatal if this fails — the booking is confirmed regardless.
      try {
        await _client.rpc(
          'increment_slot_booked',
          params: {'p_slot_id': slotId},
        );
      } catch (_) {
        // Slot count is cosmetic; do not surface this error to the user.
      }

      return BookingSuccess(bookingId: bookingId, qrCode: qrCode);
    } on PostgrestException catch (e) {
      return BookingFailure(message: e.message);
    } catch (_) {
      return BookingFailure(
        message: 'Booking failed. Please contact support.',
      );
    }
  }

  /// Generates a UUID v4 string using dart:math's secure random.
  String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    // Set version 4 bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant bits
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
