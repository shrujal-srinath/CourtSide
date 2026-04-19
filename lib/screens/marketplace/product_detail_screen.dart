import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/reviews_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String  productId;
  final String? fromBookingVenueId;
  const ProductDetailScreen({super.key, required this.productId, this.fromBookingVenueId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentPage = 0;
  bool _descExpanded = false;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = FakeData.productById(widget.productId);
    if (product == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Product not found')));
    }

    final baseReviews = FakeData.reviewsByProductId(widget.productId);
    final addedReviews = ref.watch(reviewsProvider).forProduct(widget.productId);
    final allReviews = [...addedReviews, ...baseReviews];

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context, colors, product),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(context, colors, product),
                    _buildDeliveryInfo(context, colors),
                    _buildDivider(colors),
                    _buildDescription(context, colors, product),
                    _buildDivider(colors),
                    _buildSpecifications(context, colors, product),
                    _buildDivider(colors),
                    _buildReviewsSection(context, colors, product, allReviews),
                    _buildSimilarProducts(context, colors, product),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomBar(context, colors, product),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic colors, Product product) {
    final catColor = _catColor(product.category);
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: colors.colorBackgroundPrimary,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: colors.colorSurfaceOverlay, shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 16),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: colors.colorSurfaceOverlay, shape: BoxShape.circle),
            child: Icon(Icons.share_outlined, color: colors.colorTextPrimary, size: 18),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              color: catColor.withValues(alpha: 0.06),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: 3,
                itemBuilder: (_, i) => _buildImagePage(catColor, product, i),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? colors.colorAccentPrimary : colors.colorBorderMedium,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePage(Color catColor, Product product, int index) {
    final tints = [0.06, 0.1, 0.07];
    final sizes = [80.0, 72.0, 88.0];
    return Container(
      color: catColor.withValues(alpha: tints[index]),
      child: Center(
        child: Icon(_catIcon(product.category), size: sizes[index], color: catColor.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, dynamic colors, Product product) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.brand.toUpperCase(), style: AppTextStyles.overline(colors.colorTextTertiary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.inStock
                      ? colors.colorSuccess.withValues(alpha: 0.1)
                      : colors.colorError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.inStock ? 'IN STOCK' : 'OUT OF STOCK',
                  style: AppTextStyles.bodyS(product.inStock ? colors.colorSuccess : colors.colorError)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.name, style: AppTextStyles.headingL(colors.colorTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StarRow(rating: product.rating),
              const SizedBox(width: 8),
              Text('${product.rating}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              const SizedBox(width: 6),
              Text('(${_formatCount(product.reviewCount)} reviews)', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${product.price}', style: AppTextStyles.displayS(colors.colorTextPrimary)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('₹${product.originalPrice}',
                    style: AppTextStyles.headingS(colors.colorTextTertiary).copyWith(decoration: TextDecoration.lineThrough)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${product.discountPercent}% OFF',
                    style: AppTextStyles.bodyS(colors.colorAccentPrimary).copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('You save ₹${product.originalPrice - product.price}', style: AppTextStyles.bodyS(colors.colorSuccess)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.colorSurfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: colors.colorAccentPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery estimate', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                  Text('30-45 min · Koramangala', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.colorSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('FREE above ₹499', style: AppTextStyles.bodyS(colors.colorSuccess).copyWith(fontWeight: FontWeight.w600, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, dynamic colors, Product product) {
    final text = product.description;
    final isLong = text.length > 120;
    final displayText = isLong && !_descExpanded ? '${text.substring(0, 120)}...' : text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ABOUT THIS PRODUCT', style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: 10),
          Text(displayText, style: AppTextStyles.bodyM(colors.colorTextSecondary).copyWith(height: 1.6)),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Text(_descExpanded ? 'Read less' : 'Read more',
                  style: AppTextStyles.bodyM(colors.colorAccentPrimary).copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecifications(BuildContext context, dynamic colors, Product product) {
    if (product.specifications.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      title: Text('SPECIFICATIONS', style: AppTextStyles.headingS(colors.colorTextPrimary)),
      iconColor: colors.colorTextSecondary,
      collapsedIconColor: colors.colorTextTertiary,
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: product.specifications.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final spec = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: i < product.specifications.length - 1
                      ? Border(bottom: BorderSide(color: colors.colorBorderSubtle, width: 0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(spec.key, style: AppTextStyles.bodyM(colors.colorTextTertiary))),
                    Expanded(flex: 3, child: Text(spec.value, style: AppTextStyles.bodyM(colors.colorTextPrimary))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, dynamic colors, Product product, List<ProductReview> reviews) {
    final breakdown = _ratingBreakdown(product.rating);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RATINGS & REVIEWS', style: AppTextStyles.overline(colors.colorTextTertiary)),
              GestureDetector(
                onTap: () => _showWriteReviewSheet(context, colors),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.colorAccentPrimary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('WRITE REVIEW', style: AppTextStyles.labelM(colors.colorAccentPrimary).copyWith(fontSize: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text('${product.rating}', style: AppTextStyles.scoreXXL(colors.colorTextPrimary).copyWith(fontSize: 56)),
                  _StarRow(rating: product.rating, size: 16),
                  const SizedBox(height: 4),
                  Text('${_formatCount(product.reviewCount)} ratings', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: breakdown.map((b) => _buildRatingBar(colors, b.$1, b.$2)).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...reviews.map((r) => _buildReviewCard(colors, r)),
          if (reviews.length > 4) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('See all ${_formatCount(product.reviewCount)} reviews',
                  style: AppTextStyles.bodyM(colors.colorAccentPrimary).copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRatingBar(dynamic colors, int stars, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$stars', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 11)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: colors.colorSurfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(stars >= 4 ? Colors.amber : (stars == 3 ? Colors.orange : colors.colorError)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('${(pct * 100).round()}%', style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(fontSize: 10), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic colors, ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(review.userName[0], style: AppTextStyles.headingS(colors.colorAccentPrimary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(review.userName, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                        if (review.verified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, color: colors.colorSuccess, size: 13),
                          const SizedBox(width: 3),
                          Text('Verified', style: AppTextStyles.bodyS(colors.colorSuccess).copyWith(fontSize: 10)),
                        ],
                      ],
                    ),
                    Text(review.date, style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                  ],
                ),
              ),
              _StarRow(rating: review.rating, size: 13),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.title, style: AppTextStyles.headingS(colors.colorTextPrimary)),
          const SizedBox(height: 4),
          Text(review.comment, style: AppTextStyles.bodyM(colors.colorTextSecondary).copyWith(height: 1.5)),
          if (review.helpfulCount > 0) ...[
            const SizedBox(height: 10),
            Text('${review.helpfulCount} people found this helpful',
                style: AppTextStyles.bodyS(colors.colorTextTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarProducts(BuildContext context, dynamic colors, Product product) {
    final similar = FakeData.productsByCategory(product.category)
        .where((p) => p.id != product.id)
        .take(6)
        .toList();
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text('MORE IN ${product.category.toUpperCase()}', style: AppTextStyles.overline(colors.colorTextTertiary)),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _SimilarProductCard(product: similar[i]),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, dynamic colors, Product product) {
    final cartItems = ref.watch(cartProvider.select((s) => s.products));
    final item = cartItems.where((i) => i.id == product.id).firstOrNull;
    final qty = item?.quantity ?? 0;
    final fromBooking = widget.fromBookingVenueId;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Return to Booking strip (only when arrived from booking) ──
          if (fromBooking != null)
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.colorSurfaceOverlay,
                  border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 13, color: colors.colorTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Return to Booking',
                      style: AppTextStyles.labelM(colors.colorTextSecondary),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRICE', style: AppTextStyles.overline(colors.colorTextTertiary)),
                Text('₹${product.price}', style: AppTextStyles.headingL(colors.colorTextPrimary)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: qty == 0
                  ? GestureDetector(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(CartItem(
                          id: product.id, name: product.name, price: product.price,
                          imageUrl: product.image, type: CartItemType.product,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Added to cart'),
                          backgroundColor: colors.colorSurfaceElevated,
                          behavior: SnackBarBehavior.floating,
                        ));
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(color: colors.colorAccentPrimary, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text('ADD TO CART', style: AppTextStyles.headingS(Colors.white))),
                      ),
                    )
                  : Row(
                      children: [
                        GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(product.id, qty - 1),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: colors.colorSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.colorBorderMedium),
                            ),
                            child: Icon(Icons.remove, color: colors.colorAccentPrimary),
                          ),
                        ),
                        Expanded(child: Center(child: Text('$qty in cart', style: AppTextStyles.headingS(colors.colorAccentPrimary)))),
                        GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(product.id, qty + 1),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: colors.colorAccentPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.cart),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: colors.colorAccentPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('CART', style: AppTextStyles.headingS(Colors.white)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildDivider(dynamic colors) {
    return Container(height: 6, color: colors.colorBackgroundPrimary);
  }

  void _showWriteReviewSheet(BuildContext context, dynamic colors) {
    double selectedRating = 5.0;
    final titleCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.colorSurfaceOverlay,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.colorBorderMedium, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Write a Review', style: AppTextStyles.headingM(colors.colorTextPrimary)),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setSheet(() => selectedRating = (i + 1).toDouble()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber, size: 38,
                      ),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                style: AppTextStyles.bodyM(colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Review title (e.g. "Great quality!")',
                  hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                  filled: true, fillColor: colors.colorSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: AppTextStyles.bodyM(colors.colorTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                  filled: true, fillColor: colors.colorSurfaceElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (commentCtrl.text.trim().isEmpty) return;
                    ref.read(reviewsProvider.notifier).addReview(
                      widget.productId,
                      ProductReview(
                        id: 'r_u_${DateTime.now().millisecondsSinceEpoch}',
                        userName: 'You',
                        rating: selectedRating,
                        title: titleCtrl.text.trim().isEmpty ? 'My Review' : titleCtrl.text.trim(),
                        comment: commentCtrl.text.trim(),
                        date: 'Just now',
                        helpfulCount: 0,
                        verified: true,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Review submitted — thanks!'),
                      backgroundColor: colors.colorSuccess,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.colorAccentPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('SUBMIT REVIEW', style: AppTextStyles.headingS(Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<(int, double)> _ratingBreakdown(double rating) {
    if (rating >= 4.6) return [(5, 0.68), (4, 0.20), (3, 0.07), (2, 0.03), (1, 0.02)];
    if (rating >= 4.3) return [(5, 0.52), (4, 0.28), (3, 0.12), (2, 0.05), (1, 0.03)];
    return [(5, 0.38), (4, 0.32), (3, 0.18), (2, 0.08), (1, 0.04)];
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _SimilarProductCard extends ConsumerWidget {
  final Product product;
  const _SimilarProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetail(product.id)),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _catColor(product.category).withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(child: Icon(_catIcon(product.category), size: 50, color: _catColor(product.category).withValues(alpha: 0.45))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.bodyS(colors.colorTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹${product.price}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, color: Colors.amber, size: size);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
        }
        return Icon(Icons.star_outline_rounded, color: Colors.amber, size: size);
      }),
    );
  }
}

Color _catColor(String cat) {
  switch (cat) {
    case 'Hydration': return const Color(0xFF0EA5E9);
    case 'Nutrition': return const Color(0xFF22C55E);
    case 'Equipment': return const Color(0xFFFF6B35);
    case 'Footwear': return const Color(0xFF8B5CF6);
    case 'Apparel': return const Color(0xFFF59E0B);
    case 'Protection': return const Color(0xFFEC4899);
    default: return const Color(0xFF6B7280);
  }
}

IconData _catIcon(String cat) {
  switch (cat) {
    case 'Hydration': return Icons.water_drop_rounded;
    case 'Nutrition': return Icons.fitness_center_rounded;
    case 'Equipment': return Icons.sports_basketball_rounded;
    case 'Footwear': return Icons.directions_run_rounded;
    case 'Apparel': return Icons.checkroom_rounded;
    case 'Protection': return Icons.shield_rounded;
    default: return Icons.shopping_bag_rounded;
  }
}
