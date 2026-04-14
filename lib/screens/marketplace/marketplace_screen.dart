import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import '../../models/fake_data.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _activeCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);
    final products = FakeData.productsByCategory(_activeCategory);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            _buildCategoryTabs(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_activeCategory == 'All') ...[
                    _buildSectionHeader(context, 'SPORTS EQUIPMENT'),
                    _buildProductGrid(context, FakeData.productsByCategory('Football')),
                    _buildProductGrid(context, FakeData.productsByCategory('Basketball')),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'SPORTSWEAR & GEAR'),
                    _buildProductGrid(context, FakeData.productsByCategory('Clothing')),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'NUTRITION & DRINKS'),
                    _buildProductGrid(context, FakeData.productsByCategory('Nutrition')),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'ACCESSORIES'),
                    _buildProductGrid(context, FakeData.productsByCategory('Accessories')),
                  ] else ...[
                    _buildSectionHeader(context, _activeCategory),
                    _buildProductGrid(context, products),
                  ],
                  const SizedBox(height: 100), // Spacing for sticky button
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: cart.isEmpty ? null : _buildStickyCartButton(context, cart),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.colorBackgroundPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.colorBorderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colors.colorTextTertiary, size: 20),
            const SizedBox(width: 12),
            Text('Search for equipment, drinks...', 
              style: AppTextStyles.bodyM(colors.colorTextTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    final categories = ['All', 'Cricket', 'Football', 'Badminton', 'Gym', 'Nutrition', 'Clothing', 'Accessories'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (c, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _activeCategory;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.colorAccentPrimary : context.colors.colorBackgroundPrimary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : context.colors.colorBorderSubtle,
                ),
              ),
              child: Text(
                cat,
                style: AppTextStyles.bodyS(isSelected ? Colors.white : context.colors.colorTextSecondary).copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
          Text('SEE ALL', style: AppTextStyles.overline(context.colors.colorAccentPrimary)),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return _ProductCard(
          product: p,
          onTap: () => context.push(AppRoutes.productDetail(p.id)),
        );
      },
    );
  }

  Widget _buildStickyCartButton(BuildContext context, CartState cart) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90), // Above the custom bottom nav
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.colorAccentPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadow.fab,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cart.items.length} ITEMS', style: AppTextStyles.overline(Colors.white.withValues(alpha: 0.8))),
                Text('₹${cart.totalAmount}', style: AppTextStyles.headingS(Colors.white)),
              ],
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.cart),
              child: Row(
                children: [
                  Text('VIEW CART', style: AppTextStyles.headingS(Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.colorBorderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.colorBackgroundPrimary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: product.image.startsWith('http') 
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, _, _) => Icon(_getCategoryIcon(product.category), size: 48, color: colors.colorBorderMedium),
                          )
                        : Icon(
                            _getCategoryIcon(product.category),
                            size: 48,
                            color: colors.colorBorderMedium,
                          ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Text(product.rating.toString(), 
                            style: AppTextStyles.bodyS(Colors.black).copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.bodyM(colors.colorTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹${product.price}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      const SizedBox(width: 4),
                      Text('₹${product.originalPrice}', 
                        style: AppTextStyles.bodyS(colors.colorTextTertiary).copyWith(decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
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
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.colorAccentPrimary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('ADD', style: AppTextStyles.headingS(colors.colorAccentPrimary).copyWith(fontSize: 12)),
                      ),
                    ),
                  ),
                ],
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
      case 'Clothing': return Icons.checkroom_rounded;
      case 'Accessories': return Icons.extension_rounded;
      default: return Icons.shopping_bag_outlined;
    }
  }
}
