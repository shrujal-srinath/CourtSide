// lib/providers/shop_items_provider.dart
//
// Provides ShopItems for the in-booking shop step.
// Phase 1: reads from the products table filtered to 'Equipment' + 'Hydration'
// categories (the closest equivalent to the old ShopItem seed list).
// Phase 2: add a dedicated 'is_booking_addon' flag to products table.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_item.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';

final _svcProvider = Provider<MarketplaceService>((_) => MarketplaceService());

/// Returns ShopItems for the booking wizard shop step.
/// Bridges Product → ShopItem so BookingShopScreen needs no changes yet.
final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final service = ref.read(_svcProvider);

  // Fetch Equipment + Hydration products as booking add-ons.
  final equipment  = await service.listProducts(category: 'Equipment');
  final hydration  = await service.listProducts(category: 'Hydration');

  return [...equipment, ...hydration]
      .map(_productToShopItem)
      .toList();
});

ShopItem _productToShopItem(Product p) => ShopItem(
      id:          p.id,
      name:        p.name,
      price:       p.price,
      category:    p.category.toLowerCase(),
      icon:        _categoryIcon(p.category),
      description: p.description,
    );

String _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'equipment':  return '🏀';
    case 'hydration':  return '💧';
    case 'nutrition':  return '🥤';
    case 'footwear':   return '👟';
    case 'apparel':    return '👕';
    case 'protection': return '🦺';
    default:           return '📦';
  }
}
