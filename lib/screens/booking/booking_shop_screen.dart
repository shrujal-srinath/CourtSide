// lib/screens/booking/booking_shop_screen.dart
//
// Step 3 of the booking wizard — buy items delivered to venue.
// Multi-section horizontal scrollable layout with product detail sheets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';
import 'booking_step_widgets.dart';
import 'booking_product_detail_sheet.dart';

class BookingShopScreen extends ConsumerWidget {
  const BookingShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bookingFlowProvider);
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    // Group items by category
    final equipment = shopItems.where((i) => i.category == 'equipment').toList();
    final apparel = shopItems.where((i) => i.category == 'apparel').toList();
    final accessories = shopItems.where((i) => i.category == 'accessories').toList();

    final cartCount = flow.cartItems.fold(0, (s, i) => s + i.quantity);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingWizardNav(
            currentStep: 3,
            venueId: flow.venueId,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
                  botPad + AppSpacing.xxl + 70),
              children: [
                // ── Delivery promise banner ──────────────────────
                _DeliveryBanner(colors: colors),
                const SizedBox(height: AppSpacing.xl),

                // ── Equipment section (Hydration & Wellness) ───────
                if (equipment.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'HYDRATION & WELLNESS',
                    colors: colors,
                  ),
                  _HorizontalProductGrid(
                    items: equipment,
                    colors: colors,
                    onTap: (item) => _showProductDetail(context, item),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // ── Apparel section (Protective Gear) ──────────────
                if (apparel.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'PROTECTIVE GEAR',
                    colors: colors,
                  ),
                  _HorizontalProductGrid(
                    items: apparel,
                    colors: colors,
                    onTap: (item) => _showProductDetail(context, item),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // ── Accessories section (Performance Apparel) ──────
                if (accessories.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'PERFORMANCE APPAREL',
                    colors: colors,
                  ),
                  _HorizontalProductGrid(
                    items: accessories,
                    colors: colors,
                    onTap: (item) => _showProductDetail(context, item),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookingStepFooter(
        label: cartCount == 0
            ? 'Skip — no items'
            : 'Next — Review ($cartCount item${cartCount == 1 ? '' : 's'} · ₹${flow.shopTotal})',
        isSkip: cartCount == 0,
        colors: colors,
        botPad: botPad,
        onTap: () => context.push(AppRoutes.bookCart(flow.venueId)),
      ),
    );
  }

  void _showProductDetail(BuildContext context, ShopItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return BookingProductDetailSheet(item: item);
          },
        );
      },
    );
  }
}

// ── Section header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.overline(colors.colorTextTertiary),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Explore More →',
            style: AppTextStyles.bodyS(colors.colorAccentPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Horizontal product grid ──────────────────────────────────────

class _HorizontalProductGrid extends StatelessWidget {
  const _HorizontalProductGrid({
    required this.items,
    required this.colors,
    required this.onTap,
  });

  final List<ShopItem> items;
  final AppColorScheme colors;
  final Function(ShopItem) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1 ? 0 : AppSpacing.lg,
            ),
            child: _ProductCard(
              item: item,
              colors: colors,
              onTap: () => onTap(item),
            ),
          );
        },
      ),
    );
  }
}

// ── Product card (for horizontal scroll) ──────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  final ShopItem item;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppDuration.fast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _scaleController.forward();
  }

  void _onTapUp() {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColor = _getCategoryColor(widget.item.category);

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.98).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: widget.colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: widget.colors.colorBorderSubtle,
              width: 0.5,
            ),
            boxShadow: AppShadow.card,
          ),
          child: Column(
            children: [
              // Product visual
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColor,
                      gradientColor.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.card),
                    topRight: Radius.circular(AppRadius.card),
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.item.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              // Product info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: AppTextStyles.headingS(
                          widget.colors.colorTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '₹${widget.item.price}',
                        style: AppTextStyles.labelM(
                          widget.colors.colorAccentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'equipment':
        return const Color(0xFF00C9A7); // cyan/teal for Hydration
      case 'apparel':
        return const Color(0xFFFF6B35); // orange for Protective Gear
      case 'accessories':
        return const Color(0xFF8B5CF6); // purple for Performance Apparel
      default:
        return const Color(0xFF22C55E); // green for Recovery
    }
  }
}

// ── Delivery banner ──────────────────────────────────────────────

// ── Delivery promise banner ───────────────────────────────────────

class _DeliveryBanner extends StatelessWidget {
  const _DeliveryBanner({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.colorSuccess.withValues(alpha: 0.08),
            colors.colorSuccess.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.colorSuccess.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.colorSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.local_shipping_rounded,
                size: 22, color: colors.colorSuccess),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Delivered to your court',
                      style: AppTextStyles.headingS(colors.colorTextPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.colorSuccess,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('FREE',
                          style: AppTextStyles.overline(
                                  colors.colorTextOnAccent)
                              .copyWith(fontSize: 8)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Items will be ready at the venue by the time you arrive.',
                  style: AppTextStyles.bodyS(colors.colorTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
