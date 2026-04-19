import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';

class OrdersNotifier extends StateNotifier<List<ShopOrder>> {
  OrdersNotifier() : super(List.of(FakeData.shopOrderHistory));

  void addOrder(ShopOrder order) {
    state = [order, ...state];
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<ShopOrder>>(
  (_) => OrdersNotifier(),
);
