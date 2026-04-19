import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fake_data.dart';

class ReviewsState {
  const ReviewsState({required this.added});
  final Map<String, List<ProductReview>> added;

  List<ProductReview> forProduct(String productId) => added[productId] ?? const [];
}

class ReviewsNotifier extends StateNotifier<ReviewsState> {
  ReviewsNotifier() : super(const ReviewsState(added: {}));

  void addReview(String productId, ProductReview review) {
    final existing = state.added[productId] ?? [];
    state = ReviewsState(added: {
      ...state.added,
      productId: [review, ...existing],
    });
  }
}

final reviewsProvider = StateNotifierProvider<ReviewsNotifier, ReviewsState>(
  (_) => ReviewsNotifier(),
);
