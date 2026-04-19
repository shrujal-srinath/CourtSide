// lib/screens/booking/booking_step_widgets.dart
//
// Shared widgets used across all 4 booking wizard steps.
// BookingWizardNav is the airline-style tab header used by all steps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/booking_flow_provider.dart';
import '../../providers/cart_provider.dart';

// ── Step labels & icons ──────────────────────────────────────────
const _stepLabels = ['GAME', 'GEAR', 'SHOP', 'REVIEW'];

// ═══════════════════════════════════════════════════════════════
//  BOOKING WIZARD NAV — airline-style clickable tab header
// ═══════════════════════════════════════════════════════════════

class BookingWizardNav extends ConsumerWidget {
  const BookingWizardNav({
    super.key,
    required this.currentStep,
    required this.onBack,
    required this.venueId,
  });

  /// 1 = GAME, 2 = GEAR, 3 = SHOP, 4 = REVIEW
  final int currentStep;
  final VoidCallback onBack;
  final String venueId;

  void _goToStep(BuildContext context, int step) {
    switch (step) {
      case 1:
        context.go(AppRoutes.bookInvite(venueId));
      case 2:
        context.go(AppRoutes.bookHardware(venueId));
      case 3:
        context.go(AppRoutes.bookShop(venueId));
      case 4:
        context.go(AppRoutes.bookCart(venueId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors   = context.colors;
    final flow     = ref.watch(bookingFlowProvider);
    final topPad   = MediaQuery.of(context).padding.top;
    final shopCart  = ref.watch(cartProvider);
    final cartCount = shopCart.productCount + (flow.hardware != null ? 1 : 0);

    return Container(
      color: colors.colorBackgroundPrimary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad),

          // ── Top row: back + skip + cart ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.colorSurfacePrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: colors.colorBorderSubtle, width: 0.5),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: colors.colorTextPrimary),
                  ),
                ),

                const Spacer(),

                // Skip to payment (hidden on last step)
                if (currentStep < 4) ...[
                  GestureDetector(
                    onTap: () => _goToStep(context, 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip to payment',
                          style: AppTextStyles.bodyS(
                              colors.colorTextTertiary),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: colors.colorTextTertiary),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],

                // Cart icon with badge
                GestureDetector(
                  onTap: () =>
                      _showCartSheet(context, ref, colors, flow),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.colorSurfacePrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cartCount > 0
                                ? colors.colorAccentPrimary
                                    .withValues(alpha: 0.4)
                                : colors.colorBorderSubtle,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: cartCount > 0
                              ? colors.colorAccentPrimary
                              : colors.colorTextTertiary,
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 17,
                            height: 17,
                            decoration: BoxDecoration(
                              color: colors.colorAccentPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.colorBackgroundPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$cartCount',
                                style: AppTextStyles.labelS(
                                        colors.colorTextOnAccent)
                                    .copyWith(fontSize: 8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Tab strip ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final step        = i + 1;
                final isActive    = step == currentStep;
                final isCompleted = step < currentStep;

                return Expanded(
                  child: GestureDetector(
                    onTap: isCompleted ? () => _goToStep(context, step) : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isCompleted) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 9,
                                  color: colors.colorAccentPrimary
                                      .withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                _stepLabels[i],
                                style: AppTextStyles.labelS(
                                  isActive
                                      ? colors.colorAccentPrimary
                                      : isCompleted
                                          ? colors.colorAccentPrimary
                                              .withValues(alpha: 0.55)
                                          : colors.colorTextTertiary,
                                ).copyWith(fontSize: 9.5, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Bottom accent line
                          AnimatedContainer(
                            duration: AppDuration.normal,
                            height: 2,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.colorAccentPrimary
                                  : isCompleted
                                      ? colors.colorAccentPrimary
                                          .withValues(alpha: 0.22)
                                      : colors.colorBorderSubtle,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Hairline divider ──────────────────────────────────
          Container(height: 0.5, color: colors.colorBorderSubtle),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref,
      AppColorScheme colors, BookingFlowState flow) {
    final shopProducts = ref.read(cartProvider).products;
    if (shopProducts.isEmpty && flow.hardware == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cart is empty',
              style: AppTextStyles.bodyM(colors.colorTextPrimary)),
          backgroundColor: colors.colorSurfaceOverlay,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartMiniSheet(flow: flow, colors: colors),
    );
  }
}

// ── Mini cart bottom sheet ────────────────────────────────────────

class _CartMiniSheet extends ConsumerWidget {
  const _CartMiniSheet({required this.flow, required this.colors});

  final BookingFlowState flow;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final items  = ref.watch(cartProvider).products;
    final hw     = flow.hardware;

    return Container(
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.colorBorderMedium,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text('CART SUMMARY',
                    style:
                        AppTextStyles.overline(colors.colorTextTertiary)),
                const Spacer(),
                Text(
                  '₹${items.fold(0, (s, i) => s + i.total) + flow.hwTotal}',
                  style: AppTextStyles.headingS(colors.colorAccentPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              color: colors.colorBorderSubtle),
          const SizedBox(height: AppSpacing.sm),

          // Shop items
          ...items.map((c) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 1),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.colorSurfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        _categoryIcon(c.imageUrl),
                        size: 18,
                        color: colors.colorTextSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: AppTextStyles.headingS(
                                  colors.colorTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('×${c.quantity}',
                              style: AppTextStyles.bodyS(
                                  colors.colorTextTertiary)),
                        ],
                      ),
                    ),
                    Text('₹${c.total}',
                        style:
                            AppTextStyles.labelM(colors.colorTextPrimary)),
                  ],
                ),
              )),

          // Hardware item
          if (hw != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 1),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.colorAccentSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(hw.icon,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.name,
                            style: AppTextStyles.headingS(
                                colors.colorTextPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Gear rental',
                            style: AppTextStyles.bodyS(
                                colors.colorTextTertiary)),
                      ],
                    ),
                  ),
                  Text('₹${hw.pricePerGame}',
                      style:
                          AppTextStyles.labelM(colors.colorTextPrimary)),
                ],
              ),
            ),

          SizedBox(height: botPad + AppSpacing.xl),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'hydration':  return Icons.water_drop_rounded;
      case 'nutrition':  return Icons.fitness_center_rounded;
      case 'equipment':  return Icons.sports_basketball_rounded;
      case 'footwear':   return Icons.directions_run_rounded;
      case 'apparel':    return Icons.checkroom_rounded;
      case 'protection': return Icons.shield_rounded;
      default:           return Icons.shopping_bag_outlined;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOOKING STEP HEADER — kept for any remaining direct uses
// ═══════════════════════════════════════════════════════════════

class BookingStepHeader extends StatelessWidget {
  const BookingStepHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.colors,
  });

  final int step;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: colors.colorBackgroundPrimary,
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topPad + AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.colorSurfacePrimary,
                shape: BoxShape.circle,
                border:
                    Border.all(color: colors.colorBorderSubtle, width: 0.5),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: colors.colorTextPrimary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP $step OF 4',
                    style: AppTextStyles.overline(colors.colorTextTertiary)),
                const SizedBox(height: 2),
                Text(title,
                    style: AppTextStyles.headingL(colors.colorTextPrimary)),
                Text(subtitle,
                    style: AppTextStyles.bodyS(colors.colorTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP PROGRESS BAR — kept for any remaining direct uses
// ═══════════════════════════════════════════════════════════════

class BookingStepProgressBar extends StatelessWidget {
  const BookingStepProgressBar({
    super.key,
    required this.currentStep,
    required this.colors,
  });

  final int currentStep;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: List.generate(4, (i) {
          final active = i < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: active
                    ? colors.colorAccentPrimary
                    : colors.colorBorderSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STEP FOOTER CTA
// ═══════════════════════════════════════════════════════════════

class BookingStepFooter extends StatelessWidget {
  const BookingStepFooter({
    super.key,
    required this.label,
    required this.colors,
    required this.botPad,
    required this.onTap,
    this.isSkip = false,
    this.isLoading = false,
  });

  final String label;
  final AppColorScheme colors;
  final double botPad;
  final VoidCallback onTap;
  final bool isSkip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, botPad + AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        border: Border(
            top: BorderSide(color: colors.colorBorderSubtle, width: 0.5)),
        boxShadow: AppShadow.navBar,
      ),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          height: 54,
          decoration: BoxDecoration(
            color: isSkip
                ? colors.colorSurfaceElevated
                : colors.colorAccentPrimary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: isSkip
                ? Border.all(color: colors.colorBorderSubtle, width: 0.5)
                : null,
            boxShadow: isSkip ? null : AppShadow.fab,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isSkip
                          ? colors.colorTextSecondary
                          : colors.colorTextOnAccent,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSkip)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: colors.colorTextOnAccent,
                          ),
                        ),
                      Text(
                        label,
                        style: AppTextStyles.headingS(
                          isSkip
                              ? colors.colorTextSecondary
                              : colors.colorTextOnAccent,
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
