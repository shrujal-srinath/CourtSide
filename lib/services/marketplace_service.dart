// lib/services/marketplace_service.dart
//
// Read-only product catalogue from Supabase.
// Cart / checkout / orders are NOT wired in Phase 1 — marketplace is browse-only.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class MarketplaceService {
  MarketplaceService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns active products, optionally filtered by category.
  /// Pass category = 'All' or null for all categories.
  Future<List<Product>> listProducts({String? category, String? query}) async {
    var req = _client
        .from('products')
        .select()
        .eq('is_active', true);

    if (category != null && category != 'All') {
      req = req.eq('category', category);
    }

    if (query != null && query.trim().isNotEmpty) {
      final safe = query.trim().replaceAll(',', '');
      req = req.ilike('name', '%$safe%');
    }

    final rows = await req.order('name');
    return rows.map(_rowToProduct).toList();
  }

  /// Returns a single product by ID.
  Future<Product?> getProductById(String id) async {
    final row = await _client
        .from('products')
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    return row == null ? null : _rowToProduct(row);
  }

  /// Returns reviews for a product, ordered by most recent.
  Future<List<ProductReview>> getReviews(String productId) async {
    final rows = await _client
        .from('product_reviews')
        .select('id, user_id, rating, title, comment, verified, helpful_count, '
                'created_at, user_profiles(full_name, username)')
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(20);

    return rows.map(_rowToReview).toList();
  }

  // ── Converters ────────────────────────────────────────────────

  Product _rowToProduct(Map<String, dynamic> row) {
    final specs = (row['specifications'] as Map<String, dynamic>?) ?? {};
    return Product(
      id:            row['id'] as String,
      name:          row['name'] as String,
      price:         (row['price'] as int?) ?? 0,
      originalPrice: (row['original_price'] as int?) ?? (row['price'] as int? ?? 0),
      rating:        (row['rating'] as num?)?.toDouble() ?? 0.0,
      image:         (row['category'] as String? ?? '').toLowerCase(),
      category:      (row['category'] as String?) ?? '',
      description:   (row['description'] as String?) ?? '',
      brand:         (row['brand'] as String?) ?? '',
      reviewCount:   (row['review_count'] as int?) ?? 0,
      inStock:       (row['in_stock'] as bool?) ?? true,
      specifications: specs.map((k, v) => MapEntry(k, v.toString())),
      tags:          List<String>.from((row['tags'] as List?) ?? []),
    );
  }

  ProductReview _rowToReview(Map<String, dynamic> row) {
    final profile = row['user_profiles'] as Map<String, dynamic>?;
    final name = (profile?['full_name'] as String?)?.isNotEmpty == true
        ? profile!['full_name'] as String
        : (profile?['username'] as String?) ?? 'Anonymous';

    final createdAt = row['created_at'] != null
        ? DateTime.tryParse(row['created_at'] as String)
        : null;
    final dateLabel = createdAt != null ? _relativeDate(createdAt) : '';

    return ProductReview(
      id:           row['id'] as String,
      userName:     name,
      rating:       (row['rating'] as num?)?.toDouble() ?? 0.0,
      title:        (row['title'] as String?) ?? '',
      comment:      (row['comment'] as String?) ?? '',
      date:         dateLabel,
      helpfulCount: (row['helpful_count'] as int?) ?? 0,
      verified:     (row['verified'] as bool?) ?? false,
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} weeks ago';
    return '${(diff.inDays / 30).round()} months ago';
  }
}
