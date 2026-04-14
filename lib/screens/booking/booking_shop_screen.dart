// lib/screens/booking/booking_shop_screen.dart
//
// Step 2 of the booking wizard — buy items for the game.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';
import 'booking_step_widgets.dart';

class BookingShopScreen extends ConsumerWidget {
  const BookingShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow     = ref.watch(bookingFlowProvider);
    final notifier = ref.read(bookingFlowProvider.notifier);
    final colors   = context.colors;
    final botPad   = MediaQuery.of(context).padding.bottom;

    // Group items by category
    final equipment   = shopItems.where((i) => i.category == 'equipment').toList();
    final apparel     = shopItems.where((i) => i.category == 'apparel').toList();
    final accessories = shopItems.where((i) => i.category == 'accessories').toList();

    final cartCount = flow.cartItems.fold(0, (s, i) => s + i.quantity);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingStepHeader(
            step: 2,
            title: 'Add to your game',
            subtitle: 'Equipment and accessories',
            onBack: () => context.pop(),
            colors: colors,
          ),
          BookingStepProgressBar(currentStep: 2, colors: colors),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg,
                  botPad + AppSpacing.xxl + 70),
              children: [
                if (equipment.isNotEmpty) ...[
                  _CategoryHeader(label: 'EQUIPMENT', colors: colors),
                  ...equipment.map((item) => _ShopItemRow(
                        item: item,
                        quantity: notifier.quantityOf(item.id),
                        colors: colors,
                        onAdd: () => notifier.addItem(item),
                        onRemove: () => notifier.removeItem(item),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (apparel.isNotEmpty) ...[
                  _CategoryHeader(label: 'APPAREL', colors: colors),
                  ...apparel.map((item) => _ShopItemRow(
                        item: item,
                        quantity: notifier.quantityOf(item.id),
                        colors: colors,
                        onAdd: () => notifier.addItem(item),
                        onRemove: () => notifier.removeItem(item),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (accessories.isNotEmpty) ...[
                  _CategoryHeader(label: 'ACCESSORIES', colors: colors),
                  ...accessories.map((item) => _ShopItemRow(
                        item: item,
                        quantity: notifier.quantityOf(item.id),
                        colors: colors,
                        onAdd: () => notifier.addItem(item),
                        onRemove: () => notifier.removeItem(item),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookingStepFooter(
        label: cartCount == 0
            ? 'Skip — no items'
            : 'Next — Gear rental ($cartCount item${cartCount == 1 ? '' : 's'})',
        isSkip: cartCount == 0,
        colors: colors,
        botPad: botPad,
        onTap: () => context.push(AppRoutes.bookHardware(flow.venueId)),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.colors});
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(label, style: AppTextStyles.overline(colors.colorTextTertiary)),
    );
  }
}

class _ShopItemRow extends StatelessWidget {
  const _ShopItemRow({
    required this.item,
    required this.quantity,
    required this.colors,
    required this.onAdd,
    required this.onRemove,
  });

  final ShopItem item;
  final int quantity;
  final AppColorScheme colors;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inCart = quantity > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: inCart ? colors.colorAccentSubtle : colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: inCart
              ? colors.colorAccentPrimary.withValues(alpha: 0.3)
              : colors.colorBorderSubtle,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(item.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTextStyles.headingS(colors.colorTextPrimary)),
                const SizedBox(height: 2),
                Text(item.description,
                    style: AppTextStyles.bodyS(colors.colorTextTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₹${item.price}',
                    style: AppTextStyles.labelM(colors.colorAccentPrimary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Stepper
          _QuantityStepper(
            quantity: quantity,
            colors: colors,
            onAdd: onAdd,
            onRemove: onRemove,
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.colors,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final AppColorScheme colors;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.colorAccentPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add, color: colors.colorTextOnAccent, size: 18),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.colorSurfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: Icon(Icons.remove,
                color: colors.colorTextPrimary, size: 16),
          ),
        ),
        SizedBox(
          width: 28,
          child: Center(
            child: Text('$quantity',
                style: AppTextStyles.headingS(colors.colorTextPrimary)),
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.colorAccentPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: colors.colorTextOnAccent, size: 16),
          ),
        ),
      ],
    );
  }
}
