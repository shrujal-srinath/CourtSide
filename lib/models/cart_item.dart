// lib/models/cart_item.dart

import 'package:flutter/foundation.dart';

enum CartItemType { product, booking }

@immutable
class CartAddon {
  final String id;
  final String name;
  final int price;

  const CartAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartAddon &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class CartItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final CartItemType type;

  // Product fields
  final int quantity;

  // Booking fields
  final String? date;
  final String? timeSlot;
  final String? venueName;
  final String? courtName;
  final String? sport;
  final String? venueId;
  final String? courtId;
  final List<CartAddon> addons;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.type,
    this.quantity = 1,
    this.date,
    this.timeSlot,
    this.venueName,
    this.courtName,
    this.sport,
    this.venueId,
    this.courtId,
    this.addons = const [],
  });

  CartItem copyWith({
    int? quantity,
    List<CartAddon>? addons,
  }) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      type: type,
      quantity: quantity ?? this.quantity,
      date: date,
      timeSlot: timeSlot,
      venueName: venueName,
      courtName: courtName,
      sport: sport,
      venueId: venueId,
      courtId: courtId,
      addons: addons ?? this.addons,
    );
  }

  int get addonsTotal => addons.fold(0, (sum, a) => sum + a.price);
  int get total => (price + addonsTotal) * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          timeSlot == other.timeSlot &&
          date == other.date;

  @override
  int get hashCode => id.hashCode ^ type.hashCode ^ (timeSlot?.hashCode ?? 0) ^ (date?.hashCode ?? 0);
}
