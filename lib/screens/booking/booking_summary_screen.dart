import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/fake_data.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/booking_draft_provider.dart';
import '../../widgets/common/cs_button.dart';

class BookingSummaryScreen extends ConsumerWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final draft = ref.watch(bookingDraftProvider);
    final cart = ref.watch(cartProvider);

    if (!draft.isValid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Summary')),
        body: const Center(child: Text('No active booking draft found.')),
      );
    }

    final total = draft.totalAmount + cart.totalAmount;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text('BOOKING SUMMARY', style: AppTextStyles.headingS(colors.colorTextPrimary)),
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBookingDetails(context, draft),
                const SizedBox(height: 32),
                _buildAddons(context, ref, draft),
                const SizedBox(height: 32),
                _buildSuggestedProducts(context, ref),
                const SizedBox(height: 32),
                _buildPriceBreakdown(context, draft, cart),
                const SizedBox(height: 40),
              ],
            ),
          ),
          _buildBottomPanel(context, ref, draft, cart, total),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(BuildContext context, BookingDraft draft) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR SLOT', style: AppTextStyles.overline(colors.colorTextTertiary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.colorSurfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.colorBorderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(draft.venue?.name ?? '', style: AppTextStyles.headingM(colors.colorTextPrimary)),
              const SizedBox(height: 4),
              Text(draft.court?.name ?? '', style: AppTextStyles.bodyM(colors.colorTextSecondary)),
              const Divider(height: 24),
              Row(
                children: [
                  _InfoPill(icon: Icons.calendar_today_rounded, label: 'Today'),
                  const SizedBox(width: 12),
                  _InfoPill(icon: Icons.access_time_rounded, label: draft.slot?.startTime ?? ''),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddons(BuildContext context, WidgetRef ref, BookingDraft draft) {
    final colors = context.colors;
    final availableAddons = [
      const CartAddon(id: 'addon_software', name: 'Scoring Software', price: 10),
      const CartAddon(id: 'addon_device', name: 'Scoring Device (Rental)', price: 50),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADD-ONS', style: AppTextStyles.overline(colors.colorTextTertiary)),
        const SizedBox(height: 12),
        ...availableAddons.map((addon) {
          final isSelected = draft.addons.any((a) => a.id == addon.id);
          return GestureDetector(
            onTap: () => ref.read(bookingDraftProvider.notifier).toggleAddon(addon),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? colors.colorAccentPrimary.withValues(alpha: 0.05) : colors.colorSurfacePrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    color: isSelected ? colors.colorAccentPrimary : colors.colorTextTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(addon.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                        Text('₹${addon.price}', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSuggestedProducts(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final products = FakeData.productsByCategory('Accessories').take(3).toList();
    final cart = ref.watch(cartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GET READY FOR YOUR MATCH', style: AppTextStyles.overline(colors.colorTextTertiary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (c, i) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = products[index];
              final cartItem = cart.products.where((i) => i.id == p.id).firstOrNull;
              final qty = cartItem?.quantity ?? 0;

              return Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.colorSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.colorBorderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: p.image.startsWith('http') 
                          ? Image.network(p.image, fit: BoxFit.contain)
                          : Icon(Icons.shopping_bag_outlined, color: colors.colorBorderMedium),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(p.name, style: AppTextStyles.bodyS(colors.colorTextPrimary), maxLines: 1),
                    Text('₹${p.price}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                    const SizedBox(height: 8),
                    qty == 0 
                      ? GestureDetector(
                          onTap: () => ref.read(cartProvider.notifier).addItem(CartItem(
                            id: p.id, name: p.name, price: p.price, imageUrl: p.image, type: CartItemType.product
                          )),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.colorAccentPrimary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(child: Text('ADD', style: AppTextStyles.labelS(colors.colorAccentPrimary))),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                               onTap: () => ref.read(cartProvider.notifier).updateQuantity(p.id, qty - 1),
                               child: Icon(Icons.remove_circle_outline, color: colors.colorAccentPrimary, size: 20)),
                            Text('$qty', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                            GestureDetector(
                               onTap: () => ref.read(cartProvider.notifier).addItem(CartItem(
                                  id: p.id, name: p.name, price: p.price, imageUrl: p.image, type: CartItemType.product
                               )),
                               child: Icon(Icons.add_circle_outline, color: colors.colorAccentPrimary, size: 20)),
                          ],
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

  Widget _buildPriceBreakdown(BuildContext context, BookingDraft draft, CartState cart) {
    final colors = context.colors;
    final bookingTotal = draft.totalAmount;
    final productsTotal = cart.totalAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.colorBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRICE BREAKdown', style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: 16),
          _PriceRow(label: 'Booking Base', value: draft.basePrice),
          if (draft.addons.isNotEmpty)
            _PriceRow(label: 'Add-ons', value: draft.addonsTotal),
          if (productsTotal > 0)
            _PriceRow(label: 'Products', value: productsTotal),
          const Divider(height: 32),
          _PriceRow(label: 'TOTAL', value: bookingTotal + productsTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, WidgetRef ref, BookingDraft draft, CartState cart, int total) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        boxShadow: AppShadow.navBar,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Amount', style: AppTextStyles.bodyS(context.colors.colorTextSecondary)),
                Text('₹$total', style: AppTextStyles.headingM(context.colors.colorTextPrimary)),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: CsButton.primary(
              label: 'Proceed to Payment',
              onTap: () {
                // Combine draft and cart into a final checkout state? 
                // For now, checkout screen will read both providers.
                context.push(AppRoutes.checkout);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.colorBackgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.colorBorderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.colorAccentPrimary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelS(colors.colorTextPrimary)),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.isTotal = false});
  final String label;
  final int value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? AppTextStyles.headingS(colors.colorTextPrimary) : AppTextStyles.bodyM(colors.colorTextSecondary)),
          Text('₹$value', style: isTotal ? AppTextStyles.headingM(colors.colorAccentPrimary) : AppTextStyles.bodyM(colors.colorTextPrimary)),
        ],
      ),
    );
  }
}
