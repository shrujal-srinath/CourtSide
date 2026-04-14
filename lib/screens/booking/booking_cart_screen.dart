// lib/screens/booking/booking_cart_screen.dart
//
// Step 4 of the booking wizard — review cart and confirm booking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart' show bookingFlowProvider, SkillLevel;
import '../../providers/confirmed_bookings_provider.dart';
import 'booking_step_widgets.dart';

class BookingCartScreen extends ConsumerStatefulWidget {
  const BookingCartScreen({super.key});

  @override
  ConsumerState<BookingCartScreen> createState() => _BookingCartScreenState();
}

class _BookingCartScreenState extends ConsumerState<BookingCartScreen> {
  bool _loading = false;
  late final Razorpay _razorpay;

  static const _razorpayKey = 'rzp_test_Sbka87EhdmeNsc';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  String _skillLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.all:          return 'All Levels';
      case SkillLevel.beginner:     return 'Beginner';
      case SkillLevel.intermediate: return 'Intermediate';
      case SkillLevel.competitive:  return 'Competitive';
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    final flow = ref.read(bookingFlowProvider);
    final date = flow.date;
    final slot = flow.slot;
    final venue = flow.venue;

    // Add to confirmed bookings so My Bookings reflects it
    ref.read(confirmedBookingsProvider.notifier).add(BookingRecord(
      id: response.paymentId ?? 'rzp_${DateTime.now().millisecondsSinceEpoch}',
      venueName: venue?.name ?? 'Venue',
      sport: flow.sport,
      date: date != null ? '${date.day} ${_months[date.month - 1]}' : 'Today',
      timeSlot: slot?.startTime ?? '',
      amount: flow.grandTotal,
      status: BookingStatus.upcoming,
      hasStats: false,
    ));

    ref.read(bookingFlowProvider.notifier).reset();
    context.go(AppRoutes.home);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking confirmed! See you on the court.',
          style: AppTextStyles.bodyM(context.colors.colorTextPrimary),
        ),
        backgroundColor: context.colors.colorSurfaceOverlay,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        duration: const Duration(seconds: 4),
      ),
    );
    setState(() => _loading = false);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment failed: ${response.message ?? 'Please try again.'}',
          style: AppTextStyles.bodyM(context.colors.colorTextPrimary),
        ),
        backgroundColor: context.colors.colorError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _confirmBooking() {
    final flow = ref.read(bookingFlowProvider);
    final venue = flow.venue;
    setState(() => _loading = true);

    final options = <String, dynamic>{
      'key': _razorpayKey,
      'amount': flow.grandTotal * 100, // Razorpay expects paise
      'name': 'Courtside',
      'description': '${venue?.name ?? 'Court'} · ${flow.slot?.startTime ?? ''}',
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {'color': '#E8112D'},
    };
    _razorpay.open(options);
  }

  @override
  Widget build(BuildContext context) {
    final flow   = ref.watch(bookingFlowProvider);
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;
    final date   = flow.date;
    final slot   = flow.slot;
    final court  = flow.court;
    final venue  = flow.venue;

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingStepHeader(
            step: 4,
            title: 'Review & confirm',
            subtitle: 'Your complete order',
            onBack: () => context.pop(),
            colors: colors,
          ),
          BookingStepProgressBar(currentStep: 4, colors: colors),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
                  botPad + AppSpacing.xxl + 80),
              children: [
                // ── Court booking ──────────────────────────────────
                _SectionLabel(label: 'COURT BOOKING', colors: colors),
                _CartSection(colors: colors, child: Column(
                  children: [
                    if (venue != null)
                      _CartRow(
                        icon: Icons.location_on_rounded,
                        label: venue.name,
                        sub: venue.area,
                        colors: colors,
                      ),
                    if (court != null) ...[
                      const _Divider(),
                      _CartRow(
                        icon: Icons.sports_basketball_rounded,
                        label: court.name,
                        sub: '${court.surface} · ${court.isIndoor ? "Indoor" : "Outdoor"}',
                        colors: colors,
                      ),
                    ],
                    if (date != null && slot != null) ...[
                      const _Divider(),
                      _CartRow(
                        icon: Icons.calendar_today_rounded,
                        label: '${date.day} ${_months[date.month - 1]} · ${slot.startTime} – ${slot.endTime}',
                        sub: '${court?.slotDurationMin ?? 45} min session',
                        colors: colors,
                        trailing: '₹${flow.courtTotal}',
                        trailingStyle: AppTextStyles.headingS(colors.colorTextPrimary),
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: AppSpacing.md),

                // ── Game settings ──────────────────────────────────
                _SectionLabel(label: 'GAME SETTINGS', colors: colors),
                _CartSection(colors: colors, child: Column(
                  children: [
                    _CartRow(
                      icon: flow.isPublicGame
                          ? Icons.public_rounded
                          : Icons.lock_rounded,
                      label: flow.isPublicGame ? 'Public Game' : 'Private Game',
                      sub: flow.isPublicGame
                          ? 'Up to ${flow.playerLimit} players · ${_skillLabel(flow.skillLevel)}'
                          : 'Invite-only',
                      colors: colors,
                    ),
                    if (flow.invitedFriendIds.isNotEmpty) ...[
                      const _Divider(),
                      _CartRow(
                        icon: Icons.group_rounded,
                        label: '${flow.invitedFriendIds.length} friend${flow.invitedFriendIds.length == 1 ? '' : 's'} invited',
                        sub: flow.invitedFriendIds.map((id) {
                          final f = fakeFriends.where((f) => f.id == id).firstOrNull;
                          return f?.name.split(' ').first ?? '';
                        }).where((n) => n.isNotEmpty).join(', '),
                        colors: colors,
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: AppSpacing.md),

                // ── Friends detailed list ──────────────────────────
                if (flow.invitedFriendIds.isNotEmpty) ...[
                  _SectionLabel(label: 'PLAYERS', colors: colors),
                  _CartSection(colors: colors, child: Column(
                    children: flow.invitedFriendIds.asMap().entries.map((e) {
                      final idx = e.key;
                      final id  = e.value;
                      final friend = fakeFriends.where((f) => f.id == id).firstOrNull;
                      if (friend == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          if (idx > 0) const _Divider(),
                          _CartRow(
                            label: friend.name,
                            sub: friend.username,
                            colors: colors,
                            avatarText: friend.avatarInitials,
                          ),
                        ],
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Shop items ─────────────────────────────────────
                if (flow.cartItems.isNotEmpty) ...[
                  _SectionLabel(label: 'ITEMS', colors: colors),
                  _CartSection(colors: colors, child: Column(
                    children: flow.cartItems.asMap().entries.map((e) {
                      final idx  = e.key;
                      final item = e.value;
                      return Column(
                        children: [
                          if (idx > 0) const _Divider(),
                          _CartRow(
                            label: '${item.item.name} ×${item.quantity}',
                            sub: item.item.category,
                            colors: colors,
                            iconEmoji: item.item.icon,
                            trailing: '₹${item.subtotal}',
                            trailingStyle: AppTextStyles.bodyM(colors.colorTextSecondary),
                          ),
                        ],
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Hardware ───────────────────────────────────────
                if (flow.hardware != null) ...[
                  _SectionLabel(label: 'HARDWARE RENTAL', colors: colors),
                  _CartSection(colors: colors, child: _CartRow(
                    label: flow.hardware!.name,
                    sub: 'For this game',
                    colors: colors,
                    iconEmoji: flow.hardware!.icon,
                    trailing: '₹${flow.hwTotal}',
                    trailingStyle: AppTextStyles.bodyM(colors.colorTextSecondary),
                  )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Total ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.colorAccentSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: colors.colorAccentPrimary.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total to pay',
                          style: AppTextStyles.headingM(colors.colorTextPrimary)),
                      Text('₹${flow.grandTotal}',
                          style: AppTextStyles.displayS(colors.colorAccentPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookingStepFooter(
        label: _loading ? '' : 'Confirm & Pay · ₹${flow.grandTotal}',
        colors: colors,
        botPad: botPad,
        isLoading: _loading,
        onTap: _confirmBooking,
      ),
    );
  }
}

// ── Cart section container ──────────────────────────────────────

class _CartSection extends StatelessWidget {
  const _CartSection({required this.colors, required this.child});
  final AppColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Divider(
      height: 1,
      thickness: 0.5,
      color: colors.colorBorderSubtle,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colors});
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.xs),
      child: Text(label, style: AppTextStyles.overline(colors.colorTextTertiary)),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.label,
    required this.sub,
    required this.colors,
    this.icon,
    this.iconEmoji,
    this.avatarText,
    this.trailing,
    this.trailingStyle,
  });

  final String label;
  final String sub;
  final AppColorScheme colors;
  final IconData? icon;
  final String? iconEmoji;
  final String? avatarText;
  final String? trailing;
  final TextStyle? trailingStyle;

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (avatarText != null) {
      leading = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.colorSurfaceElevated,
        ),
        child: Center(
          child: Text(avatarText!,
              style: AppTextStyles.labelS(colors.colorTextPrimary)),
        ),
      );
    } else if (iconEmoji != null) {
      leading = Text(iconEmoji!, style: const TextStyle(fontSize: 20));
    } else {
      leading = Icon(icon ?? Icons.circle, color: colors.colorTextTertiary, size: 18);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.headingS(colors.colorTextPrimary)),
                Text(sub,
                    style: AppTextStyles.bodyS(colors.colorTextTertiary)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(trailing!, style: trailingStyle),
          ],
        ],
      ),
    );
  }
}

// Extension for null-safe firstOrNull without collection package
extension _ListX<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
