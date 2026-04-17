// lib/screens/booking/booking_hardware_screen.dart
//
// Step 2 of the booking wizard — rent Courtside scoring hardware.
// Multi-select hardware with bundle discount logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fake_data.dart';
import '../../providers/booking_flow_provider.dart';
import 'booking_step_widgets.dart';

class BookingHardwareScreen extends ConsumerStatefulWidget {
  const BookingHardwareScreen({super.key});

  @override
  ConsumerState<BookingHardwareScreen> createState() =>
      _BookingHardwareScreenState();
}

class _BookingHardwareScreenState extends ConsumerState<BookingHardwareScreen> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    final flow = ref.read(bookingFlowProvider);
    _selectedIds = flow.hardware != null ? {flow.hardware!.id} : {};
  }

  void _toggleHardware(String hwId) {
    setState(() {
      if (_selectedIds.contains(hwId)) {
        _selectedIds.remove(hwId);
      } else {
        _selectedIds.add(hwId);
      }
    });
  }

  int _calculateTotal() {
    int total = 0;
    for (final hw in hardwareOptions) {
      if (_selectedIds.contains(hw.id)) {
        total += hw.pricePerGame;
      }
    }
    // Apply bundle discount if both hw1 and hw2 selected
    if (_selectedIds.contains('hw1') && _selectedIds.contains('hw2')) {
      total -= 49; // Bundle discount ₹49
    }
    return total;
  }

  bool _hasBundleDiscount() {
    return _selectedIds.contains('hw1') && _selectedIds.contains('hw2');
  }

  void _confirmSelection() {
    final notifier = ref.read(bookingFlowProvider.notifier);
    if (_selectedIds.isNotEmpty) {
      final selected =
          hardwareOptions.firstWhere((hw) => _selectedIds.contains(hw.id));
      notifier.selectHardware(selected);
    } else {
      notifier.selectHardware(null);
    }
    final flow = ref.read(bookingFlowProvider);
    context.push(AppRoutes.bookShop(flow.venueId));
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(bookingFlowProvider);
    final colors = context.colors;
    final botPad = MediaQuery.of(context).padding.bottom;
    final total = _calculateTotal();
    final hasBundleDiscount = _hasBundleDiscount();

    return Scaffold(
      backgroundColor: colors.colorBackgroundPrimary,
      body: Column(
        children: [
          BookingWizardNav(
            currentStep: 2,
            venueId: flow.venueId,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                  AppSpacing.lg, botPad + AppSpacing.xxl + 70),
              children: [
                // ── THE BOX intro ──────────────────────────────────────
                _TheBoxHeroBanner(colors: colors),
                const SizedBox(height: AppSpacing.lg),

                // ── What you get section ───────────────────────────────
                Text('WHAT YOU GET',
                    style: AppTextStyles.overline(colors.colorTextTertiary)),
                const SizedBox(height: AppSpacing.sm),
                _FeatureBullets(colors: colors),
                const SizedBox(height: AppSpacing.xl),

                // ── Hardware options ────────────────────────────────────
                Text('CHOOSE YOUR SETUP',
                    style: AppTextStyles.overline(colors.colorTextTertiary)),
                const SizedBox(height: AppSpacing.sm),
                ...hardwareOptions.map((hw) => _HardwareTile(
                  option: hw,
                  selected: _selectedIds.contains(hw.id),
                  colors: colors,
                  onTap: () => _toggleHardware(hw.id),
                )),
                const SizedBox(height: AppSpacing.lg),

                // ── Bundle offer ───────────────────────────────────────
                if (hasBundleDiscount)
                  _BundleOfferBanner(colors: colors, saved: 49),
                if (hasBundleDiscount) const SizedBox(height: AppSpacing.lg),

                // ── How it works ───────────────────────────────────────
                _HowItWorksSection(colors: colors),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookingStepFooter(
        label: total == 0
            ? 'Skip — no gear rental'
            : hasBundleDiscount
                ? 'Next — Shop (₹$total/game, Save ₹49)'
                : 'Next — Shop (₹$total/game)',
        isSkip: total == 0,
        colors: colors,
        botPad: botPad,
        onTap: _confirmSelection,
      ),
    );
  }
}

// ── Bundle Offer Banner ──────────────────────────────────────────

class _BundleOfferBanner extends StatelessWidget {
  const _BundleOfferBanner({required this.colors, required this.saved});
  final AppColorScheme colors;
  final int saved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.colorSuccess.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.colorSuccess.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.colorSuccess.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer_rounded,
                size: 20, color: colors.colorSuccess),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bundle Discount Applied',
                    style: AppTextStyles.headingS(colors.colorTextPrimary)),
                Text('Select both items to save ₹$saved',
                    style: AppTextStyles.bodyS(colors.colorTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── THE BOX Hero Banner ───────────────────────────────────────────

class _TheBoxHeroBanner extends StatelessWidget {
  const _TheBoxHeroBanner({required this.colors});
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.colorAccentPrimary.withValues(alpha: 0.12),
            colors.colorAccentPrimary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: colors.colorAccentPrimary.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.colorAccentPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadow.fab,
                ),
                child: const Center(
                  child: Text('📟', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('THE BOX',
                            style: AppTextStyles.headingM(colors.colorTextPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.colorAccentPrimary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('BY COURTSIDE',
                              style: AppTextStyles.labelS(colors.colorTextOnAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Smart hardware. Real stats. Zero effort.',
                      style: AppTextStyles.bodyS(colors.colorTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 0.5,
            color: colors.colorAccentPrimary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'THE BOX is a court-side scoring system with staff-assisted setup. '
            'It\'s not fully automated — but after your game you get a detailed stats breakdown '
            'and a full performance report for every player on the court.',
            style: AppTextStyles.bodyS(colors.colorTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Feature Bullets ───────────────────────────────────────────────

class _FeatureBullets extends StatelessWidget {
  const _FeatureBullets({required this.colors});
  final AppColorScheme colors;

  static const _features = [
    (Icons.wifi_rounded,              'Real-time sync',       'Scores update live on every player\'s phone'),
    (Icons.bar_chart_rounded,         'Auto stat tracking',   'Points, rebounds, assists logged per player'),
    (Icons.videocam_rounded,          'Game film',            '1080p auto-edited highlight clip post-game'),
    (Icons.share_rounded,             'Instant share',        'Share your stat card to Instagram in one tap'),
    (Icons.history_rounded,           'Career history',       'All games stored in your Courtside profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.colorSurfacePrimary,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
      ),
      child: Column(
        children: _features.asMap().entries.map((entry) {
          final (icon, title, sub) = entry.value;
          final isLast = entry.key == _features.length - 1;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.colorAccentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 16, color: colors.colorAccentPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.headingS(colors.colorTextPrimary)),
                        const SizedBox(height: 2),
                        Text(sub, style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(height: 0.5, color: colors.colorBorderSubtle),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── How It Works ──────────────────────────────────────────────────

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.colors});
  final AppColorScheme colors;

  static const _steps = [
    ('1', 'Pick up at the desk', 'Staff hands you the hardware when you arrive at the venue'),
    ('2', 'Staff helps you set up', 'A venue staff member gets THE BOX ready at your court in ~2 minutes'),
    ('3', 'Play your game',      'Hardware tracks everything automatically as you play'),
    ('4', 'Get your player reports', 'Open Courtside after the game — full stats breakdown for every player'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW IT WORKS', style: AppTextStyles.overline(colors.colorTextTertiary)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.colorSurfacePrimary,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.colorBorderSubtle, width: 0.5),
          ),
          child: Column(
            children: _steps.asMap().entries.map((entry) {
              final (num, title, sub) = entry.value;
              final isLast = entry.key == _steps.length - 1;
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colors.colorAccentPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(num,
                              style: AppTextStyles.labelM(colors.colorTextOnAccent)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: AppTextStyles.headingS(colors.colorTextPrimary)),
                            const SizedBox(height: 2),
                            Text(sub,
                                style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 13),
                      child: Container(
                        width: 2,
                        height: 20,
                        color: colors.colorAccentPrimary.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: colors.colorTextTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Hardware is available at THE BOX–equipped venues only. Check the venue page for availability.',
                style: AppTextStyles.bodyS(colors.colorTextTertiary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Hardware Tile ─────────────────────────────────────────────────

class _HardwareTile extends StatelessWidget {
  const _HardwareTile({
    required this.option,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final HardwareOption option;
  final bool selected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? colors.colorAccentSubtle : colors.colorSurfacePrimary,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? colors.colorAccentPrimary : colors.colorBorderSubtle,
            width: selected ? 1.5 : 0.5,
          ),
          boxShadow: selected ? AppShadow.card : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? colors.colorAccentPrimary
                    : colors.colorSurfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(option.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(option.name,
                            style: AppTextStyles.headingS(colors.colorTextPrimary)),
                      ),
                      if (option.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.colorWarning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('POPULAR',
                              style: AppTextStyles.overline(colors.colorWarning)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(option.description,
                      style: AppTextStyles.bodyS(colors.colorTextSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${option.pricePerGame} / game',
                    style: AppTextStyles.labelM(colors.colorAccentPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppDuration.fast,
              child: selected
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('on'),
                      color: colors.colorAccentPrimary, size: 24)
                  : Icon(Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('off'),
                      color: colors.colorTextTertiary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
