import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/booking_draft_provider.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_button.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);
    final draft = ref.watch(bookingDraftProvider);
    final hasProducts = cart.productCount > 0;
    final hasBooking = draft.isValid;

    if (!hasProducts && !hasBooking) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHECKOUT')),
        body: const Center(child: Text('Your checkout is empty.')),
      );
    }

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text('CHECKOUT', style: AppTextStyles.headingS(colors.colorTextPrimary)),
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasProducts) ...[
            _buildStepHeader(context, '1', 'DELIVERY ADDRESS'),
            const SizedBox(height: 16),
            _buildAddressSelection(context),
            const SizedBox(height: 32),
          ],
          _buildStepHeader(context, hasProducts ? '2' : '1', 'CHOOSE PAYMENT'),
          const SizedBox(height: 16),
          _buildPaymentMethods(context),
          const SizedBox(height: 32),
          _buildOrderSummary(context, cart, draft),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _buildPlaceOrderButton(context, ref, cart, draft),
    );
  }

  Widget _buildStepHeader(BuildContext context, String step, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: context.colors.colorAccentPrimary,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
      ],
    );
  }

  Widget _buildAddressSelection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.colorAccentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HOME', style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
              Text('CHANGE', style: AppTextStyles.overline(context.colors.colorAccentPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('123, Stadium View Apartments, Sports City, Bangalore - 560001', 
            style: AppTextStyles.bodyM(context.colors.colorTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Column(
      children: [
        _PaymentTile(icon: Icons.qr_code_rounded, label: 'UPI (GPay/PhonePe)', isSelected: true),
        const SizedBox(height: 12),
        _PaymentTile(icon: Icons.credit_card_rounded, label: 'Credit / Debit Card'),
        const SizedBox(height: 12),
        _PaymentTile(icon: Icons.wallet_rounded, label: 'Wallet'),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartState cart, BookingDraft draft) {
    final colors = context.colors;
    final hasProducts = cart.productCount > 0;
    final hasBooking = draft.isValid;
    final productsTotal = cart.totalAmount;
    final bookingTotal = draft.totalAmount;
    final deliveryTotal = hasProducts ? 30 : 0;
    final grandTotal = productsTotal + bookingTotal + deliveryTotal;

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
          Text('ORDER SUMMARY', style: AppTextStyles.overline(colors.colorTextTertiary)),
          const SizedBox(height: 16),
          
          if (hasBooking) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking: ${draft.venue?.name}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      Text('${draft.court?.name} · ${draft.slot?.startTime}', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                    ],
                  ),
                ),
                Text('₹${draft.basePrice}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              ],
            ),
            if (draft.addons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...draft.addons.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('+ ${a.name}', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                    Text('₹${a.price}', style: AppTextStyles.bodyS(colors.colorTextPrimary)),
                  ],
                ),
              )),
            ],
            const Divider(height: 24),
          ],

          if (hasProducts) ...[
            ...cart.products.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: AppTextStyles.bodyM(colors.colorTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('₹${item.total}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                ],
              ),
            )),
            if (deliveryTotal > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery & Platform Fees', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                  Text('₹$deliveryTotal', style: AppTextStyles.bodyS(colors.colorTextPrimary)),
                ],
              ),
            ],
            const Divider(height: 24),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GRAND TOTAL', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              Text('₹$grandTotal', style: AppTextStyles.headingM(colors.colorAccentPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, WidgetRef ref, CartState cart, BookingDraft draft) {
    final hasProducts = cart.productCount > 0;
    final grandTotal = cart.totalAmount + draft.totalAmount + (hasProducts ? 30 : 0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        border: Border(top: BorderSide(color: context.colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: CsButton.primary(
        label: 'PAY ₹$grandTotal',
        onTap: () {
          // 1. Process Booking if exists
          if (draft.isValid) {
            final newBooking = BookingRecord(
              id: 'bk_${DateTime.now().millisecondsSinceEpoch}',
              venueName: draft.venue!.name,
              courtName: draft.court!.name,
              sport: draft.court!.sport,
              date: 'Today', 
              timeSlot: draft.slot!.startTime,
              status: BookingStatus.upcoming,
              amount: draft.totalAmount,
              hasStats: false,
              addons: draft.addons.map((a) => a.name).toList(),
            );
            FakeData.bookingHistory.insert(0, newBooking);
          }

          // 2. Clear states
          ref.read(cartProvider.notifier).clear();
          ref.read(bookingDraftProvider.notifier).clear();

          // 3. Show success
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: context.colors.colorSurfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Booking Confirmed!', style: AppTextStyles.headingS(context.colors.colorTextPrimary)),
              content: Text('Your booking and order have been successfully placed.', style: AppTextStyles.bodyM(context.colors.colorTextSecondary)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppRoutes.home);
                  },
                  child: Text('EXPLORE MORE', style: AppTextStyles.labelS(context.colors.colorAccentPrimary)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _PaymentTile({required this.icon, required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? context.colors.colorAccentPrimary : context.colors.colorBorderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? context.colors.colorAccentPrimary : context.colors.colorTextSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyM(context.colors.colorTextPrimary))),
          if (isSelected) Icon(Icons.check_circle_rounded, color: context.colors.colorAccentPrimary),
        ],
      ),
    );
  }
}
