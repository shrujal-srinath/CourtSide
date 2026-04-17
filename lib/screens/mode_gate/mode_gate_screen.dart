// lib/screens/mode_gate/mode_gate_screen.dart
//
// Mode gate — choose between Play (book a court) and Explore (browse app).
// Light-background screen, two full-height stacked cards, typography-led.
// Sport pictogram cycles via Riverpod provider every 2 seconds.
//
// Design tokens:
//   • Colors: LightModeColorTokens (white, greys, red accent)
//   • Shadows: AppShadow.lightCard for card depth
//   • Spacing: AppSpacing tokens (all pixels on 8pt grid)
//   • Typography: AppTextStyles only (no manual overrides)
//   • Animations: Staggered entry via StaggeredCardEntry, press feedback via AnimatedScale

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/tokens/color_tokens.dart';
import '../../providers/sport_cycle_provider.dart';
import 'painters/basketball_painter.dart';
import 'painters/cricket_painter.dart';
import 'painters/football_painter.dart';

// ─────────────────────────────────────────────────────────────────
class ModeGateScreen extends ConsumerWidget {
  const ModeGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final sport  = ref.watch(sportCycleProvider);

    return Scaffold(
      backgroundColor: LightModeColorTokens.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md, topPad + AppSpacing.md,
          AppSpacing.md, botPad + AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App name ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, 0, AppSpacing.lg),
              child: Text(
                'COURTSIDE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize:      26,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: -0.8,
                  color:         LightModeColorTokens.textPrimary,
                ),
              ),
            ),

            // ── PLAY CARD ─────────────────────────────────────────
            Expanded(
              child: _PressScaleWrapper(
                onTap: () => context.go(AppRoutes.playHome),
                child: _GateCard(
                  eyebrow:     'GET ON THE COURT',
                  title:       'Play',
                  titleColor:  LightModeColorTokens.accentPrimary,
                  description: 'Find courts near you, book a slot and\nstart tracking your game stats.',
                  bottomLeft:  sport.when(
                    data:    (s) => _SportPictogram(sport: s),
                    loading: ()  => const SizedBox.shrink(),
                    error:   (_, _) => const SizedBox.shrink(),
                  ),
                  arrowColor: LightModeColorTokens.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── EXPLORE CARD ──────────────────────────────────────
            Expanded(
              child: _PressScaleWrapper(
                onTap: () => context.go(AppRoutes.home),
                child: _GateCard(
                  eyebrow:     'BROWSE THE APP',
                  title:       'Explore',
                  titleColor:  LightModeColorTokens.textPrimary,
                  description: 'Discover stats, shop gear, follow players\nand find new courts.',
                  bottomLeft:  const _ExploreIcons(),
                  arrowColor:  LightModeColorTokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gate card ─────────────────────────────────────────────────────

class _GateCard extends StatelessWidget {
  const _GateCard({
    required this.eyebrow,
    required this.title,
    required this.titleColor,
    required this.description,
    required this.bottomLeft,
    required this.arrowColor,
  });

  final String title;
  final String eyebrow;
  final Color titleColor;
  final String description;
  final Widget bottomLeft;
  final Color arrowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LightModeColorTokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: LightModeColorTokens.border, width: 0.5),
        boxShadow: AppShadow.lightCard,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl, AppSpacing.xxl,
        AppSpacing.xxl, AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Text(
            eyebrow,
            style: AppTextStyles.overline(LightModeColorTokens.textTertiary),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Hero title — use token directly, no copyWith overrides
          Text(
            title,
            style: AppTextStyles.displayL(titleColor),
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: AppTextStyles.bodyM(LightModeColorTokens.textSecondary)
                .copyWith(height: 1.55),
          ),

          const Spacer(),

          // Bottom row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              bottomLeft,
              const Spacer(),
              _ArrowButton(color: arrowColor),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sport pictogram with animated switcher ────────────────────────

class _SportPictogram extends StatelessWidget {
  const _SportPictogram({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDuration.slow,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.18, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(sport),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 76,
              height: 90,
              child: CustomPaint(
                painter: _painterFor(sport),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              sport,
              style: AppTextStyles.overline(LightModeColorTokens.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _painterFor(String sport) {
    switch (sport) {
      case 'CRICKET':
        return const CricketPainter();
      case 'FOOTBALL':
        return const FootballPainter();
      default:
        return const BasketballPainter();
    }
  }
}

// ── Explore icons row ─────────────────────────────────────────────

class _ExploreIcons extends StatelessWidget {
  const _ExploreIcons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniIcon(icon: Icons.bar_chart_rounded, label: 'Stats'),
        const SizedBox(width: AppSpacing.md),
        _MiniIcon(icon: Icons.shopping_bag_rounded, label: 'Shop'),
        const SizedBox(width: AppSpacing.md),
        _MiniIconWithDot(icon: Icons.person_rounded, label: 'Players'),
      ],
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: LightModeColorTokens.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: LightModeColorTokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.overline(LightModeColorTokens.textTertiary),
        ),
      ],
    );
  }
}

class _MiniIconWithDot extends StatelessWidget {
  const _MiniIconWithDot({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: LightModeColorTokens.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: LightModeColorTokens.textSecondary),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: LightModeColorTokens.accentPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: LightModeColorTokens.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.overline(LightModeColorTokens.textTertiary),
        ),
      ],
    );
  }
}

// ── Arrow button ──────────────────────────────────────────────────

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: LightModeColorTokens.textOnAccent,
        size: 22,
      ),
    );
  }
}

// ── Press scale wrapper ───────────────────────────────────────────

class _PressScaleWrapper extends StatefulWidget {
  const _PressScaleWrapper({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScaleWrapper> createState() => _PressScaleWrapperState();
}

class _PressScaleWrapperState extends State<_PressScaleWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: AppDuration.fast,
        curve: Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
