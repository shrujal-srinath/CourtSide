import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════
//  THE BOX SPLASH SCREEN
//  Only change from original: _run() now uses GoRouter instead of
//  Navigator.pushReplacement(Placeholder()). Everything else untouched.
// ═══════════════════════════════════════════════════════════════════════

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
      duration: const Duration(milliseconds: 4600),
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
    // GoRouter redirect handles where to send: login if not authed, home if authed
    context.go('/login');
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
        builder: (context, _) => CustomPaint(
          size: size,
          painter: _SplashPainter(t: _ctrl.value, screen: size),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CUSTOM CURVES
// ═══════════════════════════════════════════════════════════════════════

class _GravityBounceCurve extends Curve {
  const _GravityBounceCurve();
  @override
  double transformInternal(double t) {
    if (t < 0.58) {
      final p = t / 0.58;
      return p * p;
    }
    final p = (t - 0.58) / 0.42;
    final decay = math.exp(-5.0 * p);
    final oscillation = math.cos(p * math.pi * 2.8);
    return 1.0 + decay * oscillation * -0.14;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  PHASE TIMING CONSTANTS
// ═══════════════════════════════════════════════════════════════════════

class _T {
  static const double dropStart    = 0.04;
  static const double dropEnd      = 0.26;
  static const double rippleStart  = 0.20;
  static const double rippleEnd    = 0.42;
  static const double zoomStart    = 0.30;
  static const double zoomEnd      = 0.62;
  static const double breatheStart = 0.62;
  static const double breatheEnd   = 0.68;
  static const double collapseStart= 0.68;
  static const double collapseEnd  = 0.80;
  static const double textStart    = 0.77;
  static const double textEnd      = 0.90;
}

// ═══════════════════════════════════════════════════════════════════════
//  PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _SplashPainter extends CustomPainter {
  const _SplashPainter({required this.t, required this.screen});
  final double t;
  final Size screen;

  static const _bounce = _GravityBounceCurve();

  double _phase(double t, double start, double end, {Curve curve = Curves.linear}) {
    if (t <= start) return 0;
    if (t >= end)   return 1;
    return curve.transform((t - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // ── Background ──────────────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);

    // ── Pin drop ────────────────────────────────────────────
    final dropP   = _phase(t, _T.dropStart, _T.dropEnd, curve: _bounce);
    final pinY    = -60 + (cy + 40) * dropP;
    final pinTilt = (1 - dropP) * 0.18;

    final rippleP = _phase(t, _T.rippleStart, _T.rippleEnd);
    final zoomP   = _phase(t, _T.zoomStart,  _T.zoomEnd,  curve: Curves.easeInOut);

    // ── Red circle zoom ──────────────────────────────────────
    final maxR = math.sqrt(cx * cx + cy * cy) * 1.05;
    final circR = 18.0 + (maxR - 18) * zoomP;
    final circOpacity = zoomP < 0.98 ? 1.0 : 1 - ((zoomP - 0.98) / 0.02);

    if (zoomP > 0.01) {
      canvas.drawCircle(
        Offset(cx, cy + 40),
        circR,
        Paint()..color = const Color(0xFFE8112D).withValues(alpha: circOpacity),
      );
    }

    // ── Court lines (inside red circle) ─────────────────────
    if (zoomP > 0.05) {
      final breatheP   = _phase(t, _T.breatheStart, _T.breatheEnd, curve: Curves.easeInOut);
      final collapseP  = _phase(t, _T.collapseStart, _T.collapseEnd, curve: Curves.easeInOut);
      final courtScale = 0.7 + breatheP * 0.06 - collapseP * 0.70;
      final courtOpacity = math.max(0.0, 1.0 - collapseP * 0.6);

      canvas.save();
      canvas.translate(cx, cy + 40);
      canvas.scale(courtScale);
      _drawCourt(canvas, size, courtOpacity);
      canvas.restore();
    }

    // ── Impact ripples ───────────────────────────────────────
    if (rippleP > 0 && rippleP < 1) {
      for (int i = 0; i < 3; i++) {
        final rp = math.max(0.0, rippleP - i * 0.12);
        if (rp <= 0) continue;
        final rr = 20.0 + rp * 80;
        final ro = (1 - rp) * 0.35;
        canvas.drawCircle(
          Offset(cx, cy + 40),
          rr,
          Paint()
            ..color  = Colors.white.withValues(alpha: ro)
            ..style  = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // ── Pin ──────────────────────────────────────────────────
    final pinBodyOpacity = 1.0 - zoomP;
    if (pinBodyOpacity > 0.01 && dropP > 0) {
      canvas.save();
      canvas.translate(cx, pinY);
      canvas.rotate(pinTilt);
      _drawPin(canvas, pinBodyOpacity);
      canvas.restore();
    }

    // ── Logo text ────────────────────────────────────────────
    final textP = _phase(t, _T.textStart, _T.textEnd, curve: Curves.easeOut);
    if (textP > 0) {
      final collapseP = _phase(t, _T.collapseStart, _T.collapseEnd, curve: Curves.easeInOut);
      final lineY     = cy + 40 - (size.height * 0.35 * 0.70 * collapseP);

      // THE BOX
      final tp1 = TextPainter(
        text: TextSpan(
          text: 'THE BOX',
          style: TextStyle(
            color: Colors.white.withValues(alpha: textP),
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp1.paint(canvas, Offset(cx - tp1.width / 2, lineY - 28));

      // tagline
      final tp2 = TextPainter(
        text: TextSpan(
          text: 'YOUR STATS. YOUR STORY.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: textP * 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            letterSpacing: 4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp2.paint(canvas, Offset(cx - tp2.width / 2, lineY + 12));
    }
  }

  void _drawPin(Canvas canvas, double opacity) {
    final redPaint   = Paint()..color = const Color(0xFFE8112D).withValues(alpha: opacity);
    final whitePaint = Paint()..color = Colors.white.withValues(alpha: opacity);

    // Head
    canvas.drawCircle(Offset.zero, 18, redPaint);
    canvas.drawCircle(Offset.zero, 7, whitePaint);

    // Body
    final path = Path()
      ..moveTo(-7, 0)
      ..lineTo(0, 45)
      ..lineTo(7, 0)
      ..close();
    canvas.drawPath(path, redPaint);
  }

  void _drawCourt(Canvas canvas, Size size, double opacity) {
    final w  = size.width  * 0.70;
    final h  = size.height * 0.35;
    final lp = Paint()
      ..color       = Colors.white.withValues(alpha: opacity * 0.9)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer rect
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), lp);
    // Centre line
    canvas.drawLine(Offset(0, -h / 2), Offset(0, h / 2), lp);
    // Centre circle
    canvas.drawCircle(Offset.zero, h * 0.22, lp);
    // Centre dot
    canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.white.withValues(alpha: opacity));
    // Three-point arcs
    final arcR = h * 0.42;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(-w * 0.28, 0), width: arcR * 2, height: arcR * 2),
      -math.pi / 2, math.pi, false, lp,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.28, 0), width: arcR * 2, height: arcR * 2),
      math.pi / 2, math.pi, false, lp,
    );
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t;
}