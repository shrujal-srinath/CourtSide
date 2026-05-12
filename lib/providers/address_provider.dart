// lib/providers/address_provider.dart
// Phase 1: stubbed — marketplace checkout is disabled.
// Phase 4: wire to delivery_addresses table via Supabase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';

class AddressNotifier extends StateNotifier<List<DeliveryAddress>> {
  AddressNotifier() : super(const []);

  void addAddress(DeliveryAddress address) {
    state = [...state, address];
  }

  void setDefault(String id) {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
  }

  DeliveryAddress? get defaultAddress =>
      state.where((a) => a.isDefault).firstOrNull ?? state.firstOrNull;
}

final addressProvider =
    StateNotifierProvider<AddressNotifier, List<DeliveryAddress>>(
  (_) => AddressNotifier(),
);
