// lib/providers/confirmed_bookings_provider.dart
//
// Holds bookings confirmed during this session so My Bookings reflects them.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';

class ConfirmedBookingsNotifier extends Notifier<List<BookingRecord>> {
  @override
  List<BookingRecord> build() => [];

  void add(BookingRecord record) {
    state = [record, ...state];
  }
}

final confirmedBookingsProvider =
    NotifierProvider<ConfirmedBookingsNotifier, List<BookingRecord>>(
        ConfirmedBookingsNotifier.new);
