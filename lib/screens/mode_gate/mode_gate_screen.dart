// lib/screens/mode_gate/mode_gate_screen.dart
//
// Mode gate — choose between Play (book a court) and Explore (browse app).
// White-background screen, two full-height stacked cards, typography-led.
// Olympic-style sport pictograms cycle every 2 seconds.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import 'painters/basketball_painter.dart';
import 'painters/cricket_painter.dart';
import 'painters/football_painter.dart';

// ── Local palette (light-mode screen, intentionally off dark token system) ──
const _kBg        = Color(0xFFFAFAFA);
const _kCardBg    = Color(0xFFFFFFFF);
const _kBorder    = Color(0xFFE5E7EB);
const _kInk       = Color(0xFF0D0D0D);
const _kRed       = Color(0xFFE8112D);
const _kGrey      = Color(0xFF6B7280);
const _kGreyLight = Color(0xFF9CA3AF);
const _kIconBg    = Color(0xFFF3F4F6);

// ─────────────────────────────────────────────────────────────────
class ModeGateScreen extends StatefulWidget {
  const ModeGateScreen({super.key});

  @override
  State<ModeGateScreen> createState() => _ModeGateScreenState();
}

class _ModeGateScreenState extends State<ModeGateScreen>
    with TickerProviderStateMixin {

  // ── Entry animations ─────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double>   _screenFade;
  late final Animation<Offset>   _card1Slide;
  late final Animation<Offset>   _card2Slide;

  // ── Sport cycling ─────────────────────────────────────────────────
  int _sportIndex = 0;
  Timer? _cycleTimer;

  static const _sports = ['BASKETBALL', 'CRICKET', 'FOOTBALL'];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );

    _screenFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _card1Slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _card2Slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.12, 0.92, curve: Curves.easeOutCubic),
    ));

    _entryCtrl.forward();

    _cycleTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _sportIndex = (_sportIndex + 1) % _sports.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _cycleTimer?.cancel();
    super.dispose();
  }

  // ── Press scale state ─────────────────────────────────────────────
  bool _playPressed    = false;
  bool _explorePressed = false;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _screenFade,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md, topPad + AppSpacing.md,
            AppSpacing.md, botPad + AppSpacing.md,
          ),
          child: Column(
            children: [
              // ── PLAY CARD ────────────────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _card1Slide,
                  child: _PressScaleWrapper(
                    pressed: _playPressed,
                    onTapDown: () => setState(() => _playPressed = true),
                    onTapUp: () {
                      setState(() => _playPressed = false);
                      context.go(AppRoutes.playHome);
                    },
                    onTapCancel: () => setState(() => _playPressed = false),
                    child: _GateCard(
                      eyebrow: 'GET ON THE COURT',
                      title: 'Play',
                      titleColor: _kRed,
                      description:
                          'Find courts near you, book a slot and\nstart tracking your game stats.',
                      bottomLeft: _SportPictogram(sport: _sports[_sportIndex]),
                      arrowColor: _kInk,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── EXPLORE CARD ──────────────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _card2Slide,
                  child: _PressScaleWrapper(
                    pressed: _explorePressed,
                    onTapDown: () => setState(() => _explorePressed = true),
                    onTapUp: () {
                      setState(() => _explorePressed = false);
                      context.go(AppRoutes.home);
                    },
                    onTapCancel: () => setState(() => _explorePressed = false),
                    child: _GateCard(
                      eyebrow: 'BROWSE THE APP',
                      title: 'Explore',
                      titleColor: _kInk,
                      description:
                          'Discover stats, shop gear, follow players\nand find new courts.',
                      bottomLeft: const _ExploreIcons(),
                      arrowColor: _kInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  final String   eyebrow;
  final String   title;
  final Color    titleColor;
  final String   description;
  final Widget   bottomLeft;
  final Color    arrowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: _kBorder, width: 1.5),
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
            style: AppTextStyles.overline(_kGreyLight),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Hero title
          Text(
            title,
            style: AppTextStyles.displayXL(titleColor).copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: AppTextStyles.bodyM(_kGrey).copyWith(height: 1.55),
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
      duration: const Duration(milliseconds: 400),
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
              style: AppTextStyles.overline(_kGreyLight).copyWith(
                fontSize: 9,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _painterFor(String sport) {
    switch (sport) {
      case 'CRICKET':    return const CricketPainter();
      case 'FOOTBALL':   return const FootballPainter();
      default:           return const BasketballPainter();
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
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kIconBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: _kGrey),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.overline(_kGreyLight).copyWith(
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MiniIconWithDot extends StatelessWidget {
  const _MiniIconWithDot({required this.icon, required this.label});
  final IconData icon;
  final String   label;

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
                color: _kIconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: _kGrey),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _kRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kCardBg, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.overline(_kGreyLight).copyWith(
            fontSize: 9,
            letterSpacing: 1.0,
          ),
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
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// ── Press scale wrapper ───────────────────────────────────────────

class _PressScaleWrapper extends StatelessWidget {
  const _PressScaleWrapper({
    required this.child,
    required this.pressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  final Widget    child;
  final bool      pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeIn,
        child: child,
      ),
    );
  }
}
