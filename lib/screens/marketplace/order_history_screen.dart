import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/orders_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.colorBackgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.colorTextPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('MY ORDERS', style: AppTextStyles.headingS(colors.colorTextPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${orders.length} orders', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
          ),
        ],
      ),
      body: orders.isEmpty
          ? _buildEmpty(context, colors)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: orders[i]),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: colors.colorBorderMedium),
          const SizedBox(height: 16),
          Text('No orders yet', style: AppTextStyles.headingS(colors.colorTextTertiary)),
          const SizedBox(height: 8),
          Text('Your order history will appear here', style: AppTextStyles.bodyM(colors.colorTextTertiary)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go(AppRoutes.marketplace),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: colors.colorAccentPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('START SHOPPING', style: AppTextStyles.headingS(Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final ShopOrder order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final order = widget.order;
    final statusColor = _statusColor(order.status, colors);

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.id}', style: AppTextStyles.headingS(colors.colorTextPrimary)),
                    _StatusBadge(status: order.status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: colors.colorTextTertiary, size: 14),
                    const SizedBox(width: 6),
                    Text('Placed on ${order.placedDate}', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                    if (order.deliveryDate != null) ...[
                      Text(' · ', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                      Text(
                        order.status == OrderStatus.delivered
                            ? 'Delivered ${order.deliveryDate}'
                            : 'Expected ${order.deliveryDate}',
                        style: AppTextStyles.bodyS(
                          order.status == OrderStatus.delivered ? colors.colorSuccess : colors.colorInfo,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // First item + summary
                _ItemPreview(item: order.items.first, colors: colors),
                if (order.items.length > 1 && !_expanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('+${order.items.length - 1} more item${order.items.length - 1 == 1 ? '' : 's'}',
                        style: AppTextStyles.bodyS(colors.colorTextTertiary)),
                  ),
                if (_expanded)
                  ...order.items.skip(1).map((item) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _ItemPreview(item: item, colors: colors),
                      )),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ORDER TOTAL', style: AppTextStyles.overline(colors.colorTextTertiary)),
                        Text('₹${order.total}', style: AppTextStyles.headingM(colors.colorTextPrimary)),
                      ],
                    ),
                    Row(
                      children: [
                        if (order.items.length > 1)
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Text(
                              _expanded ? 'SHOW LESS' : 'SEE ALL ITEMS',
                              style: AppTextStyles.overline(colors.colorAccentPrimary),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.status == OrderStatus.delivered || order.status == OrderStatus.shipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
              ),
              child: Row(
                children: [
                  if (order.trackingId != null) ...[
                    Icon(Icons.local_shipping_outlined, color: colors.colorTextTertiary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Tracking: ${order.trackingId}',
                          style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                    ),
                  ],
                  if (order.status == OrderStatus.delivered)
                    GestureDetector(
                      onTap: () {},
                      child: Text('REORDER', style: AppTextStyles.overline(colors.colorAccentPrimary)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status, dynamic colors) {
    switch (status) {
      case OrderStatus.delivered: return colors.colorSuccess;
      case OrderStatus.cancelled: return colors.colorError;
      case OrderStatus.outForDelivery: return colors.colorWarning;
      default: return colors.colorInfo;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final order = ShopOrder(id: '', items: const [], status: status, placedDate: '', address: '', total: 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(order.statusLabel, style: AppTextStyles.labelM(color).copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _ItemPreview extends StatelessWidget {
  final OrderLineItem item;
  final dynamic colors;
  const _ItemPreview({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _catColor(item.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_catIcon(item.category), color: _catColor(item.category), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: AppTextStyles.bodyM(colors.colorTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Qty: ${item.quantity}  ·  ₹${item.total}', style: AppTextStyles.bodyS(colors.colorTextTertiary)),
            ],
          ),
        ),
      ],
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
