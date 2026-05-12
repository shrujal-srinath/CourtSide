// lib/providers/marketplace_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/marketplace_service.dart';

final _marketplaceServiceProvider =
    Provider<MarketplaceService>((_) => MarketplaceService());

// ── Products list ──────────────────────────────────────────────

class ProductsParams {
  const ProductsParams({this.category, this.query});
  final String? category;
  final String? query;

  @override
  bool operator ==(Object other) =>
      other is ProductsParams &&
      category == other.category &&
      query == other.query;

  @override
  int get hashCode => Object.hash(category, query);
}

final productsProvider =
    FutureProvider.family<List<Product>, ProductsParams>(
  (ref, params) => ref
      .read(_marketplaceServiceProvider)
      .listProducts(category: params.category, query: params.query),
);

// ── Product detail ─────────────────────────────────────────────

final productDetailProvider =
    FutureProvider.family<Product?, String>(
  (ref, id) =>
      ref.read(_marketplaceServiceProvider).getProductById(id),
);

// ── Product reviews ────────────────────────────────────────────

final productReviewsProvider =
    FutureProvider.family<List<ProductReview>, String>(
  (ref, productId) =>
      ref.read(_marketplaceServiceProvider).getReviews(productId),
);
