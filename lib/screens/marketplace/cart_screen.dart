import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/booking_draft_provider.dart';
import '../../models/cart_item.dart';
import '../../widgets/common/cs_button.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);
    final draft = ref.watch(bookingDraftProvider);
    final hasBookingDraft = draft.isValid;

    if (cart.isEmpty && !hasBookingDraft) {
      return Scaffold(
        backgroundColor: colors.colorBackgroundPrimary,
        appBar: AppBar(
          title: Text('MY CART', style: AppTextStyles.headingS(colors.colorTextPrimary)),
          backgroundColor: colors.colorBackgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: colors.colorBorderMedium),
              const SizedBox(height: 16),
              Text('Your cart is empty', style: AppTextStyles.headingS(colors.colorTextTertiary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text('MY CART', style: AppTextStyles.headingS(colors.colorTextPrimary)),
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (hasBookingDraft) ...[
                  _buildSectionHeader(context, 'BOOKING IN PROGRESS'),
                  _BookingDraftTile(draft: draft),
                  const SizedBox(height: 24),
                ],
                if (cart.bookingCount > 0) ...[
                  _buildSectionHeader(context, 'SAVED BOOKINGS'),
                  ...cart.bookings.map((item) => _CartItemTile(item: item)),
                  const SizedBox(height: 24),
                ],
                if (cart.productCount > 0) ...[
                  _buildDeliveryInfo(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'SPORTS EQUIPMENT & NUTRITION'),
                  ...cart.products.map((item) => _CartItemTile(item: item)),
                  const SizedBox(height: 24),
                  _buildAddMoreItems(context),
                  const SizedBox(height: 32),
                ],
                if (cart.productCount == 0 && cart.bookingCount > 0) ...[
                  _buildAddMoreItems(context),
                  const SizedBox(height: 32),
                ],
                _buildBillDetails(context, cart, draft),
              ],
            ),
          ),
          _buildCheckoutCTA(context, cart),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: AppTextStyles.overline(context.colors.colorTextTertiary)),
    );
  }

  Widget _buildAddMoreItems(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go(AppRoutes.marketplace),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: context.colors.colorAccentPrimary),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text('ADD MORE ITEMS', style: AppTextStyles.labelS(context.colors.colorAccentPrimary)),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.colorBackgroundPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: context.colors.colorAccentPrimary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELIVERING TO YOU IN', style: AppTextStyles.overline(context.colors.colorTextTertiary)),
              Text('25 - 35 MINS', style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildBillDetails(BuildContext context, CartState cart, BookingDraft draft) {
    final colors = context.colors;
    final hasProducts = cart.productCount > 0;
    final itemTotal = cart.totalAmount + draft.totalAmount;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BILL DETAILS', style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: 16),
          _BillRow(label: 'Item Total', value: '₹$itemTotal'),
          if (hasProducts) ...[
            _BillRow(label: 'Delivery Fee', value: '₹25'),
            _BillRow(label: 'Platform Fee', value: '₹5'),
          ],
          const Divider(height: 24),
          _BillRow(
            label: 'GRAND TOTAL', 
            value: '₹${itemTotal + (hasProducts ? 30 : 0)}', 
            isTotal: true
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutCTA(BuildContext context, CartState cart) {
    String ctaLabel = 'PROCEED TO CHECKOUT';
    if (cart.productCount == 0 && cart.bookingCount > 0) {
      ctaLabel = 'CONFIRM BOOKING';
    } else if (cart.productCount > 0 && cart.bookingCount == 0) {
      ctaLabel = 'CHECKOUT';
    } else {
      ctaLabel = 'CONTINUE TO CHECKOUT';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        border: Border(top: BorderSide(color: context.colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: CsButton.primary(
        label: ctaLabel,
        onTap: () => context.push(AppRoutes.checkout),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isBooking = item.type == CartItemType.booking;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.colorBackgroundPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isBooking 
                ? Icon(Icons.event_available_rounded, color: colors.colorAccentPrimary, size: 24)
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(_getCategoryIcon(item.imageUrl), color: colors.colorTextSecondary, size: 24),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                if (isBooking) ...[
                  Text('${item.date} · ${item.timeSlot}', 
                    style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                  Text(item.sport?.toUpperCase() ?? '', 
                    style: AppTextStyles.overline(colors.colorAccentPrimary).copyWith(fontSize: 9)),
                  if (item.addons.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...item.addons.map((a) => Text('+ ${a.name} (₹${a.price})', 
                      style: AppTextStyles.bodyS(colors.colorAccentPrimary).copyWith(fontSize: 10))),
                  ],
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _QuantitySelector(
                        quantity: item.quantity,
                        onDecrement: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                        onIncrement: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${item.total}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  if (isBooking) {
                    ref.read(cartProvider.notifier).removeItem(item.id, item.type, date: item.date, timeSlot: item.timeSlot);
                  } else {
                    ref.read(cartProvider.notifier).removeItem(item.id, item.type);
                  }
                },
                child: Text('Remove', style: AppTextStyles.labelS(colors.colorError)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('football')) return Icons.sports_soccer_rounded;
    if (category.toLowerCase().contains('basketball')) return Icons.sports_basketball_rounded;
    if (category.toLowerCase().contains('badminton')) return Icons.sports_tennis_rounded;
    if (category.toLowerCase().contains('nutrition')) return Icons.bolt_rounded;
    return Icons.shopping_bag_outlined;
  }
}

class _BookingDraftTile extends ConsumerWidget {
  final BookingDraft draft;
  const _BookingDraftTile({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.colorSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorAccentPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: colors.colorAccentPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded, color: colors.colorAccentPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.venue?.name ?? '', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                Text('${draft.court?.name} · ${draft.slot?.startTime}', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${draft.totalAmount}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => ref.read(bookingDraftProvider.notifier).clear(),
                child: Text('Cancel', style: AppTextStyles.labelS(colors.colorError)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.colorBackgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.colorBorderMedium, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: onDecrement),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$quantity', style: AppTextStyles.headingS(colors.colorTextPrimary)),
          ),
          _Btn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: context.colors.colorAccentPrimary),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _BillRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? AppTextStyles.headingS(context.colors.colorTextPrimary) : AppTextStyles.bodyM(context.colors.colorTextSecondary)),
          Text(value, style: isTotal ? AppTextStyles.headingS(context.colors.colorTextPrimary) : AppTextStyles.bodyM(context.colors.colorTextPrimary)),
        ],
      ),
    );
  }
}
