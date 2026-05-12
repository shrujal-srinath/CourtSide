// lib/providers/hardware_provider.dart
//
// Fetches hardware rental options from Supabase.
// Used by BookingHardwareScreen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hardware_option.dart';

final hardwareOptionsProvider =
    FutureProvider<List<HardwareOption>>((ref) async {
  final rows = await Supabase.instance.client
      .from('hardware_rentals')
      .select()
      .eq('is_available', true)
      .order('sort_order');

  return rows.map(_rowToOption).toList();
});

HardwareOption _rowToOption(Map<String, dynamic> row) => HardwareOption(
      id:            row['id'] as String,
      name:          row['name'] as String,
      pricePerGame:  (row['price_per_game'] as int?) ?? 0,
      description:   (row['description'] as String?) ?? '',
      icon:          (row['icon'] as String?) ?? '📦',
      isPopular:     false,
      originalPrice: row['original_price'] as int?,
      isBundle:      (row['is_bundle'] as bool?) ?? false,
    );
