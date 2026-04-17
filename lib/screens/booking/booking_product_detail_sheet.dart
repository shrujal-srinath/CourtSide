// lib/screens/booking/booking_product_detail_sheet.dart
//
// Product detail bottom sheet for booking flow shop.
// Shows product visual, description, price, quantity selector, and CTA buttons.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';

class BookingProductDetailSheet extends ConsumerStatefulWidget {
  const BookingProductDetailSheet({required this.item, super.key});
  final ShopItem item;

  @override
  ConsumerState<BookingProductDetailSheet> createState() =>
      _BookingProductDetailSheetState();
}

class _BookingProductDetailSheetState
    extends ConsumerState<BookingProductDetailSheet>
    with SingleTickerProviderStateMixin {
  late int _quantity;
  late AnimationController _submitController;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
    _submitController = AnimationController(
      duration: AppDuration.fast,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _submitController.dispose();
    super.dispose();
  }

  void _onAddToCart() {
    final notifier = ref.read(bookingFlowProvider.notifier);

    // Add item to cart (quantity times)
    for (int i = 0; i < _quantity; i++) {
      notifier.addItem(widget.item);
    }

    // Show success toast
    _showSuccessToast();

    // Close sheet after delay
    Future.delayed(AppDuration.normal, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showSuccessToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart! 🎉'),
        backgroundColor: context.colors.colorSuccess,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;

    // Determine gradient color based on category
    final gradientColor = _getGradientColor(widget.item.category);

    return Container(
      color: colors.colorBackgroundPrimary,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          botPad + AppSpacing.xl,
        ),
        children: [
          // ── Product visual ───────────────────────────────────────
          Center(
            child: Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColor,
                    gradientColor.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(
                child: Text(
                  widget.item.icon,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Product title ────────────────────────────────────────
          Text(
            widget.item.name,
            style: AppTextStyles.headingL(colors.colorTextPrimary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Benefit tagline ──────────────────────────────────────
          Text(
            _getBenefitTagline(widget.item.name),
            style: AppTextStyles.bodyS(colors.colorTextSecondary)
                .copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Description ──────────────────────────────────────────
          Text(
            widget.item.description,
            style: AppTextStyles.bodyM(colors.colorTextSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Price ────────────────────────────────────────────────
          Text(
            '₹${widget.item.price}',
            style: AppTextStyles.displayS(colors.colorAccentPrimary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Quantity selector ────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: colors.colorBorderSubtle,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _quantity > 1
                          ? colors.colorAccentPrimary
                          : colors.colorBorderSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '−',
                        style: AppTextStyles.headingL(
                          _quantity > 1
                              ? colors.colorTextOnAccent
                              : colors.colorTextTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  '$_quantity',
                  style: AppTextStyles.headingM(colors.colorTextPrimary),
                ),
                const SizedBox(width: AppSpacing.lg),
                GestureDetector(
                  onTap: () => setState(() => _quantity++),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '+',
                        style: AppTextStyles.headingL(colors.colorTextOnAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── ADD TO CART button ───────────────────────────────────
          GestureDetector(
            onTap: _onAddToCart,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadow.accentGlow,
              ),
              child: Center(
                child: Text(
                  '+ ADD TO CART',
                  style: AppTextStyles.headingL(colors.colorTextOnAccent),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Divider ──────────────────────────────────────────────
          Divider(
            color: colors.colorBorderSubtle,
            thickness: 0.5,
            height: AppSpacing.lg,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Action bar ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: colors.colorBorderSubtle,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text(
                        '← Return to Shopping',
                        style: AppTextStyles.bodyM(colors.colorTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop('view-cart'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.colorSurfaceElevated,
                      border: Border.all(
                        color: colors.colorBorderSubtle,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text(
                        'View Cart →',
                        style: AppTextStyles.bodyM(colors.colorTextPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGradientColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return const Color(0xFF00C9A7); // cyan/teal
      case 'gear':
        return const Color(0xFFFF6B35); // orange
      case 'apparel':
        return const Color(0xFF8B5CF6); // purple
      case 'recovery':
        return const Color(0xFF22C55E); // green
      default:
        return context.colors.colorAccentPrimary;
    }
  }

  String _getBenefitTagline(String productName) {
    final lowercased = productName.toLowerCase();
    if (lowercased.contains('water')) return 'Stay hydrated, stay sharp';
    if (lowercased.contains('energy')) return 'Instant power boost';
    if (lowercased.contains('electrolyte')) return 'Science-backed hydration';
    if (lowercased.contains('protein')) return 'Muscle-building blend';
    if (lowercased.contains('basketball')) return 'Tournament-grade rubber';
    if (lowercased.contains('cricket')) return 'Professional SG leather';
    if (lowercased.contains('bib')) return 'Reversible neon mesh';
    if (lowercased.contains('shin')) return 'Impact protection';
    if (lowercased.contains('grip sock')) return 'Anti-slip weave';
    if (lowercased.contains('compression')) return 'Muscle support';
    if (lowercased.contains('cap')) return 'Sweat-wicking design';
    if (lowercased.contains('arm sleeve')) return 'UV protection';
    if (lowercased.contains('foam')) return 'Deep tissue massage';
    if (lowercased.contains('ice')) return 'Reusable cold therapy';
    if (lowercased.contains('massage')) return 'Trigger point release';
    if (lowercased.contains('band')) return 'Full-body training';
    return 'Essential gear for champions';
  }
}
