import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════
//  COURTSIDE SPLASH — Court Traces → Collapses → Logo
//
//  SEQUENCE (times normalised 0→1, total = 3 600 ms):
//  0.00–0.08  Black hold
//  0.08–0.36  Outer court rectangle draws in (path trace)
//  0.28–0.46  Center line traces L → R
//  0.36–0.54  Center circle draws (arc trace)
//  0.42–0.60  Goal boxes draw in (top then bottom)
//  0.58–0.62  Hold — full court glows (glow pulse)
//  0.60–0.78  Court crushes to center line (scaleY easeInQuart)
//  0.66–0.78  Red panel floods up from center as court collapses
//  0.76–0.86  Divider line grows outward from center
//  0.82–0.95  "COURT" slides up (easeOutBack)
//  0.85–0.98  "SIDE"  slides down (easeOutBack)
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
      duration: const Duration(milliseconds: 3600),
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
        builder: (_, _) => CustomPaint(
          size: size,
          painter: _SplashPainter(t: _ctrl.value, screen: size),
        ),
      ),
    );
  }
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

class _EaseInQuart extends Curve {
  const _EaseInQuart();
  @override
  double transformInternal(double t) => t * t * t * t;
}

class _EaseOutCubic extends Curve {
  const _EaseOutCubic();
  @override
  double transformInternal(double t) => 1.0 - math.pow(1.0 - t, 3).toDouble();
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SplashPainter extends CustomPainter {
  const _SplashPainter({required this.t, required this.screen});

  final double t;
  final Size screen;

  static const _red   = Color(0xFFE8112D);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF080A0F);

  static const _easeOutBack  = _EaseOutBack(overshoot: 1.55);
  static const _easeInQuart  = _EaseInQuart();
  static const _easeOutCubic = _EaseOutCubic();

  /// Normalised progress for a phase [start, end] with optional curve.
  double _p(double start, double end, {Curve curve = Curves.linear}) {
    if (t <= start) return 0.0;
    if (t >= end)   return 1.0;
    return curve.transform((t - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;

    // ── Court geometry ─────────────────────────────────────────────────────
    // Court fits ~56 % wide × 74 % tall, centred on screen.
    final cW  = size.width  * 0.56;
    final cH  = size.height * 0.62;
    final cL  = cx - cW / 2;
    final cR  = cx + cW / 2;
    final cT  = cy - cH / 2;
    final cB  = cy + cH / 2;
    final strokeW = size.width * 0.0048.clamp(1.6, 3.2);

    // ── Phase values ───────────────────────────────────────────────────────
    final outerP    = _p(0.08, 0.36, curve: _easeOutCubic);
    final lineP     = _p(0.28, 0.46, curve: _easeOutCubic);
    final circleP   = _p(0.36, 0.54, curve: _easeOutCubic);
    final boxTopP   = _p(0.42, 0.57, curve: _easeOutCubic);
    final boxBotP   = _p(0.46, 0.61, curve: _easeOutCubic);

    final glowP     = _p(0.58, 0.64, curve: Curves.easeOut);

    final collapseP = _p(0.60, 0.78, curve: _easeInQuart);
    final redFloodP = _p(0.66, 0.79, curve: _easeOutCubic);

    final dividerP  = _p(0.76, 0.87, curve: _easeOutCubic);
    final courtWordP= _p(0.82, 0.95, curve: _easeOutBack);
    final sideWordP = _p(0.85, 0.98, curve: _easeOutBack);

    // ── 1. Background — always black ──────────────────────────────────────
    canvas.drawRect(Offset.zero & size, Paint()..color = _black);

    // ── 2. Red panel floods from center line downward ─────────────────────
    if (redFloodP > 0) {
      final panelH = (size.height / 2) * redFloodP;
      canvas.drawRect(
        Rect.fromLTWH(0, cy, size.width, panelH),
        Paint()..color = _red,
      );
      // Matching thin strip above (keeps composition centred)
      canvas.drawRect(
        Rect.fromLTWH(0, cy - panelH * 0.12, size.width, panelH * 0.12),
        Paint()..color = _red.withValues(alpha: redFloodP * 0.15),
      );
    }

    // ── 3. Court lines (drawn with canvas.save/restore for collapse) ───────
    if (outerP > 0) {
      // Collapse crushes scaleY toward cy
      final scaleY = (1.0 - collapseP).clamp(0.0, 1.0);
      // Glow: line alpha brightens slightly on the hold beat, then fades with collapse
      final lineAlpha = ((1.0 - collapseP * 1.15).clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(1.0, scaleY < 0.001 ? 0.001 : scaleY);
      canvas.translate(-cx, -cy);

      _paintCourt(
        canvas: canvas,
        cL: cL, cT: cT, cR: cR, cB: cB,
        cx: cx, cy: cy,
        cW: cW, cH: cH,
        strokeW: strokeW,
        outerP: outerP,
        lineP: lineP,
        circleP: circleP,
        boxTopP: boxTopP,
        boxBotP: boxBotP,
        glowP: glowP,
        lineAlpha: lineAlpha,
      );

      canvas.restore();
    }

    // ── 4. Divider line ────────────────────────────────────────────────────
    if (dividerP > 0) {
      final hw = (size.width * 0.44) * dividerP;
      canvas.drawLine(
        Offset(cx - hw, cy),
        Offset(cx + hw, cy),
        Paint()
          ..color = _white.withValues(alpha: dividerP.clamp(0.0, 1.0))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }

    // ── 5. Typography ──────────────────────────────────────────────────────
    if (courtWordP > 0 || sideWordP > 0) {
      final fs    = size.width * 0.148;
      const gap   = 14.0;

      if (courtWordP > 0) {
        final slideOffset = 36.0 * (1.0 - courtWordP);
        _drawWord(
          canvas: canvas,
          text:     'COURT',
          color:    _white.withValues(alpha: courtWordP.clamp(0.0, 1.0)),
          cx:       cx,
          bottomY:  cy - gap - slideOffset,
          fontSize: fs,
        );
      }

      if (sideWordP > 0) {
        final slideOffset = 36.0 * (1.0 - sideWordP);
        _drawWord(
          canvas: canvas,
          text:    'SIDE',
          color:   _black.withValues(alpha: sideWordP.clamp(0.0, 1.0)),
          cx:      cx,
          topY:    cy + gap + slideOffset,
          fontSize: fs,
        );
      }
    }
  }

  // ── Court: all lines, path-traced with progress values ───────────────────
  void _paintCourt({
    required Canvas canvas,
    required double cL, required double cT,
    required double cR, required double cB,
    required double cx, required double cy,
    required double cW, required double cH,
    required double strokeW,
    required double outerP,
    required double lineP,
    required double circleP,
    required double boxTopP,
    required double boxBotP,
    required double glowP,
    required double lineAlpha,
  }) {
    if (lineAlpha <= 0) return;

    final Paint mkPaint = Paint()
      ..color = _white.withValues(alpha: lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Optional glow on top
    final glowBlur = glowP * 8.0;
    final Paint mkGlow = Paint()
      ..color = _white.withValues(alpha: glowP * 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW + glowBlur * 1.2
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur.clamp(0.1, 12))
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Outer rectangle — draw as a traced path
    if (outerP > 0) {
      final outerPath = Path()
        ..moveTo(cx, cT)               // Start at top center, go clockwise
        ..lineTo(cR, cT)
        ..lineTo(cR, cB)
        ..lineTo(cL, cB)
        ..lineTo(cL, cT)
        ..lineTo(cx, cT);

      final traced = _tracePath(outerPath, outerP);
      if (glowP > 0) canvas.drawPath(traced, mkGlow);
      canvas.drawPath(traced, mkPaint);
    }

    // Center line — traces left to right
    if (lineP > 0) {
      final lx = cL + (cR - cL) * lineP;
      final linePath = Path()
        ..moveTo(cL, cy)
        ..lineTo(lx, cy);
      if (glowP > 0) canvas.drawPath(linePath, mkGlow);
      canvas.drawPath(linePath, mkPaint);
    }

    // Center circle — traces as arc
    if (circleP > 0) {
      final circleR = cW * 0.195;
      final arcAngle = math.pi * 2 * circleP;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: circleR),
        -math.pi / 2,
        arcAngle,
        false,
        mkPaint,
      );
      if (glowP > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: circleR),
          -math.pi / 2,
          arcAngle,
          false,
          mkGlow,
        );
      }
      // Center dot (appears when circle is mostly done)
      if (circleP > 0.7) {
        final dotAlpha = ((circleP - 0.7) / 0.3).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(cx, cy),
          strokeW * 1.1,
          Paint()
            ..color = _white.withValues(alpha: lineAlpha * dotAlpha)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Goal boxes — top and bottom (U-shape opening inward)
    final gbW = cW * 0.52;
    final gbH = cH * 0.155;

    if (boxTopP > 0) {
      final topBoxPath = Path()
        ..moveTo(cx - gbW / 2, cT)
        ..lineTo(cx - gbW / 2, cT + gbH)
        ..lineTo(cx + gbW / 2, cT + gbH)
        ..lineTo(cx + gbW / 2, cT);
      final traced = _tracePath(topBoxPath, boxTopP);
      canvas.drawPath(traced, mkPaint);
    }

    if (boxBotP > 0) {
      final botBoxPath = Path()
        ..moveTo(cx - gbW / 2, cB)
        ..lineTo(cx - gbW / 2, cB - gbH)
        ..lineTo(cx + gbW / 2, cB - gbH)
        ..lineTo(cx + gbW / 2, cB);
      final traced = _tracePath(botBoxPath, boxBotP);
      canvas.drawPath(traced, mkPaint);
    }

    // Penalty spots
    if (boxTopP > 0.85 || boxBotP > 0.85) {
      final dotPaint = Paint()
        ..color = _white.withValues(alpha: lineAlpha)
        ..style = PaintingStyle.fill;
      if (boxTopP > 0.85) {
        final spotAlpha = ((boxTopP - 0.85) / 0.15).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(cx, cT + cH * 0.20),
          strokeW * 0.9,
          dotPaint..color = _white.withValues(alpha: lineAlpha * spotAlpha),
        );
      }
      if (boxBotP > 0.85) {
        final spotAlpha = ((boxBotP - 0.85) / 0.15).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(cx, cT + cH * 0.80),
          strokeW * 0.9,
          dotPaint..color = _white.withValues(alpha: lineAlpha * spotAlpha),
        );
      }
    }
  }

  /// Extract a portion [0..progress] of a Path using PathMetrics.
  Path _tracePath(Path source, double progress) {
    if (progress <= 0) return Path();
    if (progress >= 1) return source;
    final Path result = Path();
    for (final metric in source.computeMetrics()) {
      final len = metric.length * progress;
      if (len > 0) {
        result.addPath(metric.extractPath(0, len), Offset.zero);
      }
    }
    return result;
  }

  // ── Draw a word anchored by bottomY or topY, centred on cx ───────────────
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
        text: text,
        style: GoogleFonts.barlow(
          color:         color,
          fontSize:      fontSize,
          fontWeight:    FontWeight.w800,
          letterSpacing: fontSize * 0.10,
          height:        1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double y = topY ?? (bottomY! - tp.height);
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t;
}
