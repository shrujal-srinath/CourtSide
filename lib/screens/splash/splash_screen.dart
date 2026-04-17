import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  COURTSIDE SPLASH — Brand-first cinematic (2200ms)
//
//  0.00–0.10  Black hold
//  0.10–0.28  Jordan Red panel floods up from bottom
//  0.28–0.58  "COURT" enters from top (easeOutBack)
//  0.38–0.68  "SIDE"  enters from bottom (easeOutBack)
//  0.68–0.80  Tagline fades in
//  0.80–0.95  Hold
//  0.95–1.00  Canvas fades out
// ═══════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: size,
          painter: _SplashPainter(t: _ctrl.value, screen: size),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TIMING CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const double redFloodStart   = 0.10;
  static const double redFloodEnd     = 0.28;
  static const double courtStart      = 0.28;
  static const double courtEnd        = 0.65;
  static const double sideStart       = 0.38;
  static const double sideEnd         = 0.72;
  static const double taglineStart    = 0.72;
  static const double taglineEnd      = 0.82;
  static const double fadeOutStart    = 0.92;
  static const double fadeOutEnd      = 1.00;
}

// ─────────────────────────────────────────────────────────────────────────────
//  CURVES
// ─────────────────────────────────────────────────────────────────────────────

class _EaseOutBack extends Curve {
  const _EaseOutBack({this.overshoot = 1.70158});
  final double overshoot;
  @override
  double transformInternal(double t) {
    final s = overshoot + 1;
    return 1.0 + s * math.pow(t - 1.0, 3) + overshoot * math.pow(t - 1.0, 2);
  }
}

class _EaseInOutCubic extends Curve {
  const _EaseInOutCubic();
  @override
  double transformInternal(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SplashPainter extends CustomPainter {
  const _SplashPainter({required this.t, required this.screen});

  final double t;
  final Size screen;

  static const _red       = Color(0xFFE8112D);
  static const _offWhite  = Color(0xFFF8F9FA);
  static const _void      = Color(0xFF080A0F);

  static const _easeOutBack    = _EaseOutBack(overshoot: 1.55);
  static const _easeInOutCubic = _EaseInOutCubic();

  double _e(double start, double end, {Curve curve = Curves.linear}) {
    if (t <= start) return 0.0;
    if (t >= end)   return 1.0;
    return curve.transform((t - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    final redFloodP  = _e(_T.redFloodStart,  _T.redFloodEnd,  curve: _easeInOutCubic);
    final courtWordP = _e(_T.courtStart,      _T.courtEnd,     curve: _easeOutBack);
    final sideWordP  = _e(_T.sideStart,       _T.sideEnd,      curve: _easeOutBack);
    final taglineP   = _e(_T.taglineStart,    _T.taglineEnd,   curve: Curves.easeOut);
    final fadeOutP   = _e(_T.fadeOutStart,    _T.fadeOutEnd,   curve: Curves.easeIn);

    // Global fade-out alpha applied to everything
    final globalAlpha = (1.0 - fadeOutP).clamp(0.0, 1.0);

    // ── 1. Black background
    canvas.drawRect(Offset.zero & size, Paint()..color = _void);

    // ── 2. Red panel floods up from bottom
    if (redFloodP > 0) {
      final panelH = size.height * redFloodP;
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - panelH, size.width, panelH),
        Paint()..color = _red.withValues(alpha: globalAlpha),
      );
    }

    // ── 3. "COURT" — Off White, enters from top
    if (courtWordP > 0) {
      final fs         = size.width * 0.18;
      final slideY     = 120.0 * (1.0 - courtWordP);
      final alpha      = (courtWordP.clamp(0.0, 1.0) * globalAlpha).clamp(0.0, 1.0);
      _drawWord(
        canvas:   canvas,
        text:     'COURT',
        color:    _offWhite.withValues(alpha: alpha),
        cx:       cx,
        fontSize: fs,
        // bottomY: just above center — baseline at cy - 4
        bottomY:  cy - 4 - slideY,
      );
    }

    // ── 4. "SIDE" — Void Black, enters from bottom
    if (sideWordP > 0) {
      final fs      = size.width * 0.18;
      final slideY  = 120.0 * (1.0 - sideWordP);
      final alpha   = (sideWordP.clamp(0.0, 1.0) * globalAlpha).clamp(0.0, 1.0);
      _drawWord(
        canvas:   canvas,
        text:     'SIDE',
        color:    _void.withValues(alpha: alpha),
        cx:       cx,
        fontSize: fs,
        // topY: cap-height at cy + 4
        topY:     cy + 4 + slideY,
      );
    }

    // ── 5. Tagline
    if (taglineP > 0) {
      final alpha    = (taglineP * 0.6 * globalAlpha).clamp(0.0, 1.0);
      final fs       = size.width * 0.18;
      // Approximate cap height ≈ 0.72 * fontSize for SpaceGrotesk
      final capH     = fs * 0.72;
      final taglineY = cy + 4 + capH + 12;
      _drawTagline(
        canvas:   canvas,
        cx:       cx,
        y:        taglineY,
        alpha:    alpha,
      );
    }
  }

  void _drawWord({
    required Canvas canvas,
    required String text,
    required Color  color,
    required double cx,
    required double fontSize,
    double? topY,
    double? bottomY,
  }) {
    final style = GoogleFonts.spaceGrotesk(
      fontSize:      fontSize,
      fontWeight:    FontWeight.w800,
      letterSpacing: -fontSize * 0.01,
      height:        1.0,
      color:         color,
    );

    final tp = TextPainter(
      text:          TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final double y = topY ?? (bottomY! - tp.height);
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawTagline({
    required Canvas canvas,
    required double cx,
    required double y,
    required double alpha,
  }) {
    final style = GoogleFonts.inter(
      fontSize:   13,
      fontWeight: FontWeight.w400,
      color:      _offWhite.withValues(alpha: alpha),
      letterSpacing: 0.2,
    );

    final tp = TextPainter(
      text:          TextSpan(text: 'Your court. Your stats.', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t;
}
