// lib/providers/orders_provider.dart
// Phase 1: stubbed — marketplace checkout is disabled.
// Phase 4: wire to orders table via Supabase.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrdersNotifier extends StateNotifier<List<ShopOrder>> {
  OrdersNotifier() : super(const []);

  void addOrder(ShopOrder order) {
    state = [order, ...state];
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<ShopOrder>>(
  (_) => OrdersNotifier(),
);
