class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    this.description = '',
    this.sport,
  });

  final String id;
  final String name;
  final int price;
  final String category; // 'equipment' | 'apparel' | 'accessories'
  final String icon;
  final String description;
  final String? sport; // null = any sport
}
