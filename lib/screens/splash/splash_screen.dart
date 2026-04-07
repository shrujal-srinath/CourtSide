import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════
//  COURTSIDE SPLASH SCREEN — Cinematic single-motion rewrite
//
//  The secret to "video not PPT": every phase STARTS before the previous
//  phase ENDS. Momentum carries across boundaries.
//
//  SEQUENCE (all times overlap intentionally):
//  0.00–0.05  Black hold
//  0.05–0.30  Pin drops with gravity (GravityDrop curve)
//  0.24–0.38  Squash on impact (TweenSequence, overlaps drop tail)
//  0.26–0.56  3 ripple rings expand from tip (staggered, overlaps squash)
//  0.32–0.72  Red circle ZOOMS from pin inner → fills screen (canvas clip)
//  0.32–0.52  Pin body fades out as zoom begins
//  0.58–0.72  Court lines "breathe in" at full size (overlaps zoom end)
//  0.68–0.88  Court collapses to center line (scaleY crush)
//  0.80–0.90  Divider line grows outward (the surviving center line)
//  0.82–0.97  "COURT" slides down into position (white)
//  0.85–0.99  "SIDE"  slides up  into position (black on red)
// ═══════════════════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _squash;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );

    // Squash is a TweenSequence — the only one that needs pre-baking
    _squash = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.76)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.76, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 1.00)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 12,
      ),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.24, 0.40),
    ));

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    await _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        builder: (_, unused) => CustomPaint(
          size: size,
          painter: _SplashPainter(
            t: _ctrl.value,
            squashY: _squash.value,
            screen: size,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CURVES
// ─────────────────────────────────────────────────────────────────────────────

/// Quadratic acceleration then exponential-decay oscillation — real gravity feel
class _GravityDrop extends Curve {
  const _GravityDrop();
  @override
  double transformInternal(double t) {
    if (t < 0.62) {
      final p = t / 0.62;
      return p * p; // accelerating fall
    }
    final p = (t - 0.62) / 0.38;
    final decay = math.exp(-6.0 * p);
    return 1.0 + decay * math.cos(p * math.pi * 3.0) * -0.10;
  }
}

/// Exponential zoom — slow start, screaming finish
class _ExpoZoom extends Curve {
  const _ExpoZoom();
  @override
  double transformInternal(double t) {
    if (t == 0.0) return 0.0;
    return math.pow(2.0, 10.0 * (t - 1.0)).toDouble();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SplashPainter extends CustomPainter {
  const _SplashPainter({
    required this.t,
    required this.squashY,
    required this.screen,
  });

  final double t;
  final double squashY;
  final Size screen;

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const _red   = Color(0xFFE8112D);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  // ── Pin dimensions (at 1× scale) ──────────────────────────────────────────
  static const double _headR   = 52.0;  // head circle radius
  static const double _innerR  = _headR * 0.82; // red inner circle
  static const double _tipDY   = _headR * 2.55; // tip below head centre

  // ── Curves ────────────────────────────────────────────────────────────────
  static const _gravityDrop = _GravityDrop();
  static const _expoZoom    = _ExpoZoom();

  // ── Phase helper ──────────────────────────────────────────────────────────
  double _p(double start, double end, {Curve curve = Curves.linear}) {
    if (t <= start) return 0.0;
    if (t >= end)   return 1.0;
    return curve.transform((t - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // ── Values ────────────────────────────────────────────────────────────
    final dropP     = _p(0.05, 0.30, curve: _gravityDrop);
    final zoomP     = _p(0.32, 0.72, curve: _expoZoom);
    final pinFadeP  = _p(0.32, 0.52, curve: Curves.easeIn);   // pin fades OUT
    final collapseP = _p(0.68, 0.88, curve: Curves.easeInQuart);
    final dividerP  = _p(0.80, 0.90, curve: Curves.easeOut);
    final courtWordP= _p(0.82, 0.97, curve: Curves.easeOutCubic);
    final sideWordP = _p(0.85, 0.99, curve: Curves.easeOutCubic);

    // Pin centre when landed (slightly above screen centre for visual balance)
    final pinLandY  = cy - 30.0;
    final pinCY     = -size.height * 0.60 + (pinLandY + size.height * 0.60) * dropP;
    final pinCenter = Offset(cx, pinCY);

    // Ripple tip (bottom of pin)
    final tipY      = pinCY + _headR + _tipDY;

    // ── 1. Background ──────────────────────────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()..color = _black);

    // ── 2. Expanding red circle zoom (cinematic core) ──────────────────────
    // The clip circle grows from the inner circle radius → screen diagonal.
    // Everything drawn inside the clip = "inside the logo".
    if (zoomP > 0.0) {
      final maxR    = math.sqrt(cx * cx + cy * cy) * 1.1;
      final startR  = _innerR;
      // Use cubic easing for the radius itself (different from zoomP curve)
      final circleR = startR + (maxR - startR) * zoomP;

      // Save + clip to expanding circle
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: pinCenter, radius: circleR)),
      );

      // Red fill inside clip
      canvas.drawRect(Offset.zero & size, Paint()..color = _red);

      // Court lines scale up continuously as the circle expands
      // At zoomP=0 they are pin-size; at zoomP=1 they fill the screen.
      final courtScale = (circleR / _innerR) * 0.96;
      final courtAlpha    = math.min(1.0, zoomP * 2.5) * (1.0 - collapseP * 0.85);

      if (courtAlpha > 0.0) {
        canvas.save();
        canvas.translate(pinCenter.dx, pinCenter.dy);
        canvas.scale(1.0, (1.0 - collapseP).clamp(0.001, 1.0) * courtScale);
        canvas.scale(1.0 / courtScale); // undo outer scale for uniform lines
        _paintCourtLines(
          canvas,
          centre: Offset.zero,
          unitSize: _innerR * 2.0 * courtScale,
          alpha: courtAlpha,
          strokeBase: 1.8 + courtScale * 1.2,
        );
        canvas.restore();
      }

      canvas.restore();
      // end clip region
    }

    // ── 3. Ripple rings (from pin tip on impact) ───────────────────────────
    final rippleGlobal = _p(0.26, 0.56);
    if (rippleGlobal > 0 && dropP > 0.85 && zoomP < 0.6) {
      for (int i = 0; i < 3; i++) {
        final rp = (rippleGlobal - i * 0.14).clamp(0.0, 1.0);
        if (rp <= 0) continue;
        final rr    = 14.0 + rp * 90.0;
        final alpha = (1.0 - rp) * 0.45 * (1.0 - zoomP * 1.6).clamp(0.0, 1.0);
        if (alpha <= 0) continue;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, tipY),
            width:  rr * 2.6,
            height: rr * 0.7,
          ),
          Paint()
            ..color = _red.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * (1.0 - rp * 0.5)
            ..isAntiAlias = true,
        );
      }
    }

    // ── 4. Pin (drawn on top; fades as zoom begins) ────────────────────────
    final pinOpacity = ((1.0 - pinFadeP) * (dropP > 0 ? 1.0 : 0.0)).clamp(0.0, 1.0);
    if (pinOpacity > 0.01 && dropP > 0) {
      canvas.save();
      canvas.translate(pinCenter.dx, pinCenter.dy);
      canvas.scale(1.0, squashY); // squash on Y axis
      _drawPin(canvas, pinOpacity);
      canvas.restore();
    }

    // ── 5. Divider line (survives the collapse) ────────────────────────────
    if (dividerP > 0) {
      final lw = size.width * 0.60 * dividerP;
      canvas.drawLine(
        Offset(cx - lw / 2, pinCenter.dy),
        Offset(cx + lw / 2, pinCenter.dy),
        Paint()
          ..color = _white.withValues(alpha: dividerP.clamp(0.0, 1.0))
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }

    // ── 6. Typography ──────────────────────────────────────────────────────
    if (courtWordP > 0 || sideWordP > 0) {
      final fs   = size.width * 0.148;
      const slide = 32.0;
      final lineY = pinCenter.dy;

      if (courtWordP > 0) {
        _drawWord(
          canvas: canvas,
          text:    'COURT',
          color:   _white.withValues(alpha: courtWordP),
          cx:      cx,
          bottomY: lineY - 10.0 - slide * (1.0 - courtWordP),
          fontSize: fs,
        );
      }

      if (sideWordP > 0) {
        _drawWord(
          canvas: canvas,
          text:   'SIDE',
          color:  _black.withValues(alpha: sideWordP),
          cx:     cx,
          topY:   lineY + 10.0 + slide * (1.0 - sideWordP),
          fontSize: fs,
        );
      }
    }
  }

  // ── Draw a word centred on cx, anchored by top or bottom ────────────────
  void _drawWord({
    required Canvas canvas,
    required String text,
    required Color  color,
    required double cx,
    required double fontSize,
    double? topY,
    double? bottomY,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text:  text,
        style: GoogleFonts.spaceGrotesk(
          color:         color,
          fontSize:      fontSize,
          fontWeight:    FontWeight.w900,
          letterSpacing: fontSize * 0.14,
          height:        1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double y = topY ?? (bottomY! - tp.height);
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  // ── Pin: glossy white teardrop + red inner circle + court ────────────────
  void _drawPin(Canvas canvas, double alpha) {
    final hw     = _headR;
    final headCY = 0.0;
    final tipY   = headCY + _headR + _tipDY;

    // Shadow
    final tearPath = _teardropPath(headCY, hw, tipY);
    canvas.drawShadow(
      tearPath,
      _black.withValues(alpha: 0.45 * alpha),
      16.0,
      true,
    );

    // Glossy white body
    final glossPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.26, -0.40),
        radius: 0.88,
        colors: const [
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFDDDDDD),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(
        Rect.fromLTWH(-hw, headCY - hw, hw * 2, tipY - headCY + hw),
      )
      ..isAntiAlias = true;
    canvas.drawPath(tearPath, glossPaint);

    // Dim overlay for opacity
    if (alpha < 1.0) {
      canvas.drawPath(
        tearPath,
        Paint()..color = _black.withValues(alpha: 1.0 - alpha),
      );
    }

    // Inner red circle
    canvas.drawCircle(
      Offset(0, headCY),
      _innerR,
      Paint()..color = _red.withValues(alpha: alpha)..isAntiAlias = true,
    );

    // Court inside pin
    _paintCourtLines(
      canvas,
      centre: Offset(0, headCY),
      unitSize: _innerR * 2.0,
      alpha: alpha,
      strokeBase: 4.5,
    );
  }

  // ── Mathematically clean teardrop path ────────────────────────────────────
  Path _teardropPath(double headCY, double hw, double tipY) {
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: Offset(0, headCY), radius: hw),
      -math.pi, math.pi,
    );
    path.cubicTo(
       hw,        headCY + hw * 0.55,
       hw * 0.18, tipY   - hw * 0.14,
       0,         tipY,
    );
    path.cubicTo(
      -hw * 0.18, tipY   - hw * 0.14,
      -hw,        headCY + hw * 0.55,
      -hw,        headCY,
    );
    path.close();
    return path;
  }

  // ── Court lines — ONE function used for both pin and full-screen ──────────
  // unitSize: the diameter of the inner circle (reference dimension)
  // strokeBase: min stroke width (scaled internally for large sizes)
  void _paintCourtLines(
    Canvas canvas, {
    required Offset centre,
    required double unitSize,
    required double alpha,
    required double strokeBase,
  }) {
    if (alpha <= 0) return;

    final u   = unitSize;
    final cW  = u * 0.52;
    final cH  = u * 0.72;
    final L   = centre.dx - cW / 2;
    final T   = centre.dy - cH / 2;
    final R   = centre.dx + cW / 2;
    final B   = centre.dy + cH / 2;
    final sw  = strokeBase;

    final p = Paint()
      ..color      = _white.withValues(alpha: alpha)
      ..style      = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap  = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Outer boundary
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(L, T, R, B),
        Radius.circular(u * 0.035),
      ),
      p..strokeWidth = sw,
    );

    // Centre line
    canvas.drawLine(Offset(L, centre.dy), Offset(R, centre.dy), p..strokeWidth = sw * 0.85);

    // Centre circle
    canvas.drawCircle(centre, cW * 0.20, p..strokeWidth = sw * 0.80);

    // Centre dot
    canvas.drawCircle(
      centre, sw * 0.90,
      Paint()..color = _white.withValues(alpha: alpha)..style = PaintingStyle.fill,
    );

    // Goal boxes
    final gbW = cW * 0.54;
    final gbH = cH * 0.17;

    // Top goal box
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - gbW / 2, T)
        ..lineTo(centre.dx - gbW / 2, T + gbH)
        ..lineTo(centre.dx + gbW / 2, T + gbH)
        ..lineTo(centre.dx + gbW / 2, T),
      p..strokeWidth = sw * 0.80,
    );

    // Bottom goal box
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - gbW / 2, B)
        ..lineTo(centre.dx - gbW / 2, B - gbH)
        ..lineTo(centre.dx + gbW / 2, B - gbH)
        ..lineTo(centre.dx + gbW / 2, B),
      p..strokeWidth = sw * 0.80,
    );

    // Penalty spots
    final dotPaint = Paint()..color = _white.withValues(alpha: alpha)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centre.dx, T + cH * 0.21), sw * 0.80, dotPaint);
    canvas.drawCircle(Offset(centre.dx, T + cH * 0.79), sw * 0.80, dotPaint);

    // Penalty arcs
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centre.dx, T + cH * 0.21), radius: cW * 0.21),
      0.44, 2.26, false, p..strokeWidth = sw * 0.75,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centre.dx, T + cH * 0.79), radius: cW * 0.21),
      3.58, 2.26, false, p..strokeWidth = sw * 0.75,
    );

    // Corner arcs
    final cr = u * 0.030;
    canvas.drawArc(Rect.fromCircle(center: Offset(L, T), radius: cr),
        0.0,          math.pi / 2, false, p..strokeWidth = sw * 0.65);
    canvas.drawArc(Rect.fromCircle(center: Offset(R, T), radius: cr),
        math.pi / 2,  math.pi / 2, false, p..strokeWidth = sw * 0.65);
    canvas.drawArc(Rect.fromCircle(center: Offset(L, B), radius: cr),
        -math.pi / 2, math.pi / 2, false, p..strokeWidth = sw * 0.65);
    canvas.drawArc(Rect.fromCircle(center: Offset(R, B), radius: cr),
        math.pi,      math.pi / 2, false, p..strokeWidth = sw * 0.65);
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t || old.squashY != squashY;
}
