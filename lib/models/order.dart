class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  final String name;
  final int quantity;
  final int price;
  final String category;

  int get total => price * quantity;
}

enum OrderStatus {
  placed,
  confirmed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.items,
    required this.status,
    required this.placedDate,
    required this.address,
    required this.total,
    this.deliveryDate,
    this.trackingId,
  });

  final String id;
  final List<OrderLineItem> items;
  final OrderStatus status;
  final String placedDate;
  final String address;
  final int total;
  final String? deliveryDate;
  final String? trackingId;

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:          return 'Order Placed';
      case OrderStatus.confirmed:       return 'Confirmed';
      case OrderStatus.shipped:         return 'Shipped';
      case OrderStatus.outForDelivery:  return 'Out for Delivery';
      case OrderStatus.delivered:       return 'Delivered';
      case OrderStatus.cancelled:       return 'Cancelled';
    }
  }
}
