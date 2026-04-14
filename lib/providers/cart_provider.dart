// lib/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  const CartState({this.items = const []});

  int get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  int get productCount => items.where((i) => i.type == CartItemType.product).length;
  int get bookingCount => items.where((i) => i.type == CartItemType.booking).length;
  bool get isEmpty => items.isEmpty;

  List<CartItem> get products => items.where((i) => i.type == CartItemType.product).toList();
  List<CartItem> get bookings => items.where((i) => i.type == CartItemType.booking).toList();
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem newItem) {
    if (newItem.type == CartItemType.booking) {
      // Check for conflicts: same court, date, and time slot
      final hasConflict = state.items.any((item) =>
          item.type == CartItemType.booking &&
          item.courtId == newItem.courtId &&
          item.date == newItem.date &&
          item.timeSlot == newItem.timeSlot);

      if (hasConflict) {
        // In a real app, we'd throw an error or show a notification
        return;
      }
    }

    if (newItem.type == CartItemType.product) {
      final existingIndex = state.items.indexWhere((i) => i.id == newItem.id && i.type == CartItemType.product);
      if (existingIndex != -1) {
        final existingItem = state.items[existingIndex];
        final updatedItems = [...state.items];
        updatedItems[existingIndex] = existingItem.copyWith(quantity: existingItem.quantity + newItem.quantity);
        state = CartState(items: updatedItems);
        return;
      }
    }

    state = CartState(items: [...state.items, newItem]);
  }

  void removeItem(String id, CartItemType type, {String? date, String? timeSlot}) {
    state = CartState(
      items: state.items.where((i) {
        if (i.id != id || i.type != type) return true;
        if (type == CartItemType.booking) {
          return i.date != date || i.timeSlot != timeSlot;
        }
        return false;
      }).toList(),
    );
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id, CartItemType.product);
      return;
    }
    state = CartState(
      items: state.items.map((i) {
        if (i.id == id && i.type == CartItemType.product) {
          return i.copyWith(quantity: quantity);
        }
        return i;
      }).toList(),
    );
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
