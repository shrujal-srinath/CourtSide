import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/fake_data.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final product = FakeData.productById(productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }
    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context, product),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductInfo(context, product),
                    _buildExpandableDetails(context, product),
                    _buildSimilarProducts(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomBar(context, ref, product),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Product product) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: context.colors.colorBackgroundPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: PageView.builder(
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              color: context.colors.colorBackgroundPrimary,
              child: Center(
                child: Icon(
                  _getCategoryIcon(product.category),
                  size: 100,
                  color: context.colors.colorBorderMedium,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, Product product) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.category.toUpperCase(), style: AppTextStyles.overline(colors.colorAccentPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('IN STOCK', style: AppTextStyles.bodyS(Colors.green).copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.name, style: AppTextStyles.headingM(colors.colorTextPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(product.rating.toString(), style: AppTextStyles.headingS(colors.colorTextPrimary)),
              const SizedBox(width: 4),
              Text('(120 reviews)', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${product.price}', style: AppTextStyles.headingL(colors.colorTextPrimary)),
              const SizedBox(width: 12),
              Text('₹${product.originalPrice}', style: AppTextStyles.headingS(colors.colorTextTertiary).copyWith(decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${product.discountPercent}% OFF', style: AppTextStyles.bodyS(colors.colorAccentPrimary).copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Description', style: AppTextStyles.headingS(colors.colorTextPrimary)),
          const SizedBox(height: 8),
          Text(product.description, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildExpandableDetails(BuildContext context, Product product) {
    return Column(
      children: [
        _buildDetailTile(context, 'Product Details', product.description),
        _buildDetailTile(context, 'Specifications', 'Category: ${product.category}\nRating: ${product.rating} stars'),
        _buildDetailTile(context, 'Return Policy', '7 days easy return'),
      ],
    );
  }

  Widget _buildDetailTile(BuildContext context, String title, String content) {
    return ExpansionTile(
      title: Text(title, style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Text(content, style: AppTextStyles.bodyM(context.colors.colorTextSecondary)),
      ],
    );
  }

  Widget _buildSimilarProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Similar Products', style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (c, i) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                decoration: BoxDecoration(
                  color: context.colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.colorBorderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.colorBackgroundPrimary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(child: Icon(Icons.sports_soccer, color: context.colors.colorBorderMedium)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cosco Football', style: AppTextStyles.bodyS(context.colors.colorTextPrimary), maxLines: 1),
                          const SizedBox(height: 4),
                          Text('₹799', style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, Product product) {
    final colors = context.colors;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          border: Border(top: BorderSide(color: colors.colorBorderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRICE', style: AppTextStyles.overline(colors.colorTextTertiary)),
                Text('₹${product.price}', style: AppTextStyles.headingM(colors.colorTextPrimary)),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final item = CartItem(
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    imageUrl: product.image,
                    type: CartItemType.product,
                  );
                  ref.read(cartProvider.notifier).addItem(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${product.name} to cart')),
                  );
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.colorAccentPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('ADD TO CART', style: AppTextStyles.headingS(Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Football': return Icons.sports_soccer_rounded;
      case 'Basketball': return Icons.sports_basketball_rounded;
      case 'Badminton': return Icons.sports_tennis_rounded;
      case 'Nutrition': return Icons.bolt_rounded;
      default: return Icons.shopping_bag_outlined;
    }
  }
}
