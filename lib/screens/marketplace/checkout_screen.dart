import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cart_provider.dart';
import '../../providers/booking_draft_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/orders_provider.dart';
import '../../models/fake_data.dart';
import '../../widgets/common/cs_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'upi';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cart = ref.watch(cartProvider);
    final draft = ref.watch(bookingDraftProvider);
    final addresses = ref.watch(addressProvider);
    final hasProducts = cart.productCount > 0;
    final hasBooking = draft.isValid;

    if (!hasProducts && !hasBooking) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHECKOUT')),
        body: const Center(child: Text('Your checkout is empty.')),
      );
    }

    final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        title: Text('CHECKOUT', style: AppTextStyles.headingS(colors.colorTextPrimary)),
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hasProducts) ...[
            _buildStepHeader(context, '1', 'DELIVERY ADDRESS'),
            const SizedBox(height: 12),
            _buildAddressSection(context, colors, defaultAddr, addresses),
            const SizedBox(height: 28),
          ],
          _buildStepHeader(context, hasProducts ? '2' : '1', 'PAYMENT METHOD'),
          const SizedBox(height: 12),
          _buildPaymentMethods(context, colors),
          const SizedBox(height: 28),
          _buildOrderSummary(context, colors, cart, draft),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _buildPlaceOrderButton(context, ref, cart, draft, defaultAddr),
    );
  }

  Widget _buildStepHeader(BuildContext context, String step, String title) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(color: colors.colorAccentPrimary, shape: BoxShape.circle),
          child: Center(child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.headingS(colors.colorTextPrimary)),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context, dynamic colors, DeliveryAddress? selected, List<DeliveryAddress> addresses) {
    if (selected == null) {
      return GestureDetector(
        onTap: () => _showAddressSheet(context, colors, addresses),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.colorBorderSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: colors.colorAccentPrimary),
              const SizedBox(width: 12),
              Text('Add delivery address', style: AppTextStyles.headingS(colors.colorAccentPrimary)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorAccentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(selected.label, style: AppTextStyles.overline(colors.colorAccentPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Text(selected.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                ],
              ),
              GestureDetector(
                onTap: () => _showAddressSheet(context, colors, addresses),
                child: Text('CHANGE', style: AppTextStyles.overline(colors.colorAccentPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(selected.fullAddress, style: AppTextStyles.bodyM(colors.colorTextSecondary)),
          const SizedBox(height: 4),
          Text(selected.phone, style: AppTextStyles.bodyS(colors.colorTextTertiary)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context, dynamic colors) {
    final methods = [
      ('upi', Icons.qr_code_rounded, 'UPI — GPay / PhonePe / Paytm'),
      ('card', Icons.credit_card_rounded, 'Credit / Debit Card'),
      ('wallet', Icons.account_balance_wallet_rounded, 'Wallet'),
      ('cod', Icons.money_rounded, 'Cash on Delivery'),
    ];

    return Column(
      children: methods.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => setState(() => _selectedPayment = m.$1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.colorSurfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedPayment == m.$1 ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                width: _selectedPayment == m.$1 ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(m.$2, color: _selectedPayment == m.$1 ? colors.colorAccentPrimary : colors.colorTextSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(m.$3, style: AppTextStyles.bodyM(colors.colorTextPrimary))),
                if (_selectedPayment == m.$1)
                  Icon(Icons.check_circle_rounded, color: colors.colorAccentPrimary, size: 20),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildOrderSummary(BuildContext context, dynamic colors, CartState cart, BookingDraft draft) {
    final hasProducts = cart.productCount > 0;
    final hasBooking = draft.isValid;
    final productsTotal = cart.totalAmount;
    final bookingTotal = draft.totalAmount;
    final deliveryFee = hasProducts ? 30 : 0;
    final grandTotal = productsTotal + bookingTotal + deliveryFee;

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
                      Text('Court Booking: ${draft.venue?.name}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
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
                  Expanded(child: Text('${item.name} ×${item.quantity}', style: AppTextStyles.bodyM(colors.colorTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('₹${item.total}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                ],
              ),
            )),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery & Platform Fees', style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                  Text('₹$deliveryFee', style: AppTextStyles.bodyS(colors.colorTextPrimary)),
                ],
              ),
            ),
            const Divider(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              Text('₹$grandTotal', style: AppTextStyles.headingM(colors.colorAccentPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(BuildContext context, WidgetRef ref, CartState cart, BookingDraft draft, DeliveryAddress? addr) {
    final colors = context.colors;
    final hasProducts = cart.productCount > 0;
    final grandTotal = cart.totalAmount + draft.totalAmount + (hasProducts ? 30 : 0);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: CsButton.primary(
        label: 'PAY ₹$grandTotal',
        onTap: () => _handlePlaceOrder(context, ref, cart, draft, addr, grandTotal),
      ),
    );
  }

  void _handlePlaceOrder(BuildContext context, WidgetRef ref, CartState cart, BookingDraft draft, DeliveryAddress? addr, int total) {
    if (draft.isValid) {
      FakeData.bookingHistory.insert(0, BookingRecord(
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
      ));
    }

    if (cart.productCount > 0) {
      ref.read(ordersProvider.notifier).addOrder(ShopOrder(
        id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        items: cart.products.map((i) => OrderLineItem(name: i.name, quantity: i.quantity, price: i.price, category: 'Equipment')).toList(),
        status: OrderStatus.placed,
        placedDate: _todayLabel(),
        address: addr?.fullAddress ?? 'Bengaluru',
        total: total,
        trackingId: 'CS-TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      ));
    }

    ref.read(cartProvider.notifier).clear();
    ref.read(bookingDraftProvider.notifier).clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.colorSurfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: colors.colorSuccess.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: colors.colorSuccess, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Order Confirmed!', style: AppTextStyles.headingM(colors.colorTextPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Your order has been placed successfully. Delivering in 30-45 mins.', style: AppTextStyles.bodyM(colors.colorTextSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () { Navigator.pop(ctx); context.go(AppRoutes.orderHistory); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.colorBorderMedium),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(child: Text('MY ORDERS', style: AppTextStyles.headingS(colors.colorTextSecondary))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { Navigator.pop(ctx); context.go(AppRoutes.marketplace); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: colors.colorAccentPrimary, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('KEEP SHOPPING', style: AppTextStyles.headingS(Colors.white))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showAddressSheet(BuildContext context, dynamic colors, List<DeliveryAddress> addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.colorSurfaceOverlay,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.colorBorderMedium, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('DELIVERY ADDRESS', style: AppTextStyles.headingS(colors.colorTextPrimary)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...addresses.map((addr) => GestureDetector(
                      onTap: () {
                        ref.read(addressProvider.notifier).setDefault(addr.id);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: addr.isDefault ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                            width: addr.isDefault ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: colors.colorAccentPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                addr.label == 'HOME' ? Icons.home_rounded : Icons.work_rounded,
                                color: colors.colorAccentPrimary, size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(addr.label, style: AppTextStyles.overline(colors.colorAccentPrimary).copyWith(fontSize: 8)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(addr.name, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(addr.fullAddress, style: AppTextStyles.bodyS(colors.colorTextSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            if (addr.isDefault)
                              Icon(Icons.check_circle_rounded, color: colors.colorAccentPrimary, size: 20)
                            else
                              Icon(Icons.radio_button_unchecked_rounded, color: colors.colorBorderMedium, size: 20),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAddNewAddressSheet(context, colors);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.colorAccentPrimary.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add_location_alt_rounded, color: colors.colorAccentPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text('Add new address', style: AppTextStyles.headingS(colors.colorAccentPrimary)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, color: colors.colorAccentPrimary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNewAddressSheet(BuildContext context, dynamic colors) {
    final nameCtrl    = TextEditingController();
    final phoneCtrl   = TextEditingController();
    final streetCtrl  = TextEditingController();
    final areaCtrl    = TextEditingController();
    final cityCtrl    = TextEditingController(text: 'Bengaluru');
    final pincodeCtrl = TextEditingController();
    String selectedLabel = 'HOME';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.colorSurfaceOverlay,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.colorBorderMedium, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx2),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text('ADD NEW ADDRESS', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                  ],
                ),
                const SizedBox(height: 20),
                // Label selector
                Row(
                  children: ['HOME', 'WORK', 'OTHER'].map((label) {
                    final isSelected = selectedLabel == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedLabel = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.colorAccentPrimary.withValues(alpha: 0.12) : colors.colorSurfacePrimary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isSelected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                label == 'HOME' ? Icons.home_rounded : label == 'WORK' ? Icons.work_rounded : Icons.location_on_rounded,
                                color: isSelected ? colors.colorAccentPrimary : colors.colorTextTertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(label, style: AppTextStyles.labelM(isSelected ? colors.colorAccentPrimary : colors.colorTextSecondary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _AddressField(ctrl: nameCtrl,    label: 'Full Name',      icon: Icons.person_outline_rounded,       colors: colors),
                const SizedBox(height: 12),
                _AddressField(ctrl: phoneCtrl,   label: 'Phone Number',   icon: Icons.phone_outlined,               colors: colors, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _AddressField(ctrl: streetCtrl,  label: 'Street / Flat',  icon: Icons.home_outlined,                colors: colors),
                const SizedBox(height: 12),
                _AddressField(ctrl: areaCtrl,    label: 'Area / Locality', icon: Icons.location_city_outlined,      colors: colors),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _AddressField(ctrl: cityCtrl,    label: 'City',    icon: Icons.apartment_outlined, colors: colors)),
                    const SizedBox(width: 12),
                    Expanded(child: _AddressField(ctrl: pincodeCtrl, label: 'Pincode', icon: Icons.pin_drop_outlined,  colors: colors, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      if (nameCtrl.text.trim().isEmpty || streetCtrl.text.trim().isEmpty) return;
                      final newAddr = DeliveryAddress(
                        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                        label: selectedLabel,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty ? '' : phoneCtrl.text.trim(),
                        street: streetCtrl.text.trim(),
                        area: areaCtrl.text.trim(),
                        city: cityCtrl.text.trim().isEmpty ? 'Bengaluru' : cityCtrl.text.trim(),
                        pincode: pincodeCtrl.text.trim(),
                        isDefault: false,
                      );
                      ref.read(addressProvider.notifier).addAddress(newAddr);
                      ref.read(addressProvider.notifier).setDefault(newAddr.id);
                      Navigator.pop(ctx2);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.colorAccentPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('SAVE ADDRESS', style: AppTextStyles.headingS(Colors.white))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final dynamic colors;
  final TextInputType keyboardType;

  const _AddressField({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.colors,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: colors.colorTextTertiary, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              style: AppTextStyles.bodyM(colors.colorTextPrimary),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: AppTextStyles.bodyM(colors.colorTextTertiary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
