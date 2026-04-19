import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';

class AddressNotifier extends StateNotifier<List<DeliveryAddress>> {
  AddressNotifier() : super(List.of(FakeData.addresses));

  void addAddress(DeliveryAddress address) {
    state = [...state, address];
  }

  void setDefault(String id) {
    state = state.map((a) => a.copyWith(isDefault: a.id == id)).toList();
  }

  DeliveryAddress? get defaultAddress =>
      state.where((a) => a.isDefault).firstOrNull ?? state.firstOrNull;
}

final addressProvider = StateNotifierProvider<AddressNotifier, List<DeliveryAddress>>(
  (_) => AddressNotifier(),
);
