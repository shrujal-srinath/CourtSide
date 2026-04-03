import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════
//  COURTSIDE SPLASH SCREEN — Production Implementation
//
//  ARCHITECTURE: Single AnimationController → single progress value →
//  all visual states derived via pure functions. No Interval soup.
//  Every phase is causally connected to the next.
//
//  SEQUENCE (4.6s total):
//  ┌─────────────────────────────────────────────────────────────┐
//  │  0.00─0.04  Black void (builds anticipation)               │
//  │  0.04─0.26  Pin drops with gravity + damped bounce          │
//  │  0.20─0.40  Impact ripples (3 staggered, start PRE-impact)  │
//  │  0.30─0.62  Zoom: red circle expands, court scales up       │
//  │  0.62─0.68  Court breathes at full screen                   │
//  │  0.68─0.80  Court collapses to center line                  │
//  │  0.77─0.90  COURT/SIDE text slides in                       │
//  │  0.90─1.00  Final logo holds                                │
//  └─────────────────────────────────────────────────────────────┘
//
//  KEY DESIGN DECISIONS:
//  • ONE court drawing function used at every scale (pin → fullscreen)
//  • Zoom is a real expansion of the red circle, not a canvas hack
//  • Halfway line SURVIVES the collapse — it IS the divider
//  • Phase overlaps create continuous energy transfer
//  • Pin has subtle tilt during fall → corrects on impact
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
    // Brief delay to ensure first frame renders
    await Future.delayed(const Duration(milliseconds: 80));
    await _ctrl.forward();
    // Hold final logo briefly
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Replace Placeholder() with your HomeScreen route as needed.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Placeholder(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
        builder: (_, __) => CustomPaint(
          size: size,
          painter: _SplashPainter(
            t: _ctrl.value,
            screen: size,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CUSTOM CURVES
// ═══════════════════════════════════════════════════════════════════════

/// Gravity drop with a single damped bounce.
/// Models real physics: quadratic free-fall → elastic impact → settle.
class _GravityBounceCurve extends Curve {
  const _GravityBounceCurve();

  @override
  double transformInternal(double t) {
    // Phase 1: Free-fall (0 → 0.58) — quadratic acceleration
    if (t < 0.58) {
      final p = t / 0.58;
      return p * p; // value goes 0 → 1.0 at impact
    }

    // Phase 2: Damped oscillation around 1.0 (0.58 → 1.0)
    final p = (t - 0.58) / 0.42; // 0→1 within bounce phase
    final decay = math.exp(-5.0 * p);
    final oscillation = math.cos(p * math.pi * 2.8);
    return 1.0 + decay * oscillation * -0.14;
    // Peaks: ~1.14 overshoot, then ~0.95, then ~1.02, settles at 1.0
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  PHASE TIMING CONSTANTS
// ═══════════════════════════════════════════════════════════════════════

// All values are fractions of total duration (0.0 → 1.0)
class _T {
  // Pin drop (gravity + bounce)
  static const double dropStart = 0.04;
  static const double dropEnd = 0.26;

  // Impact ripples (start slightly BEFORE impact for anticipation)
  static const double rippleStart = 0.20;
  static const double rippleEnd = 0.42;

  // Zoom: red circle expands, court scales, pin body fades
  static const double zoomStart = 0.30;
  static const double zoomEnd = 0.62;

  // Court breathe (subtle pulse at full screen)
  static const double breatheStart = 0.62;
  static const double breatheEnd = 0.68;

  // Collapse: scaleY → 0, halfway line survives
  static const double collapseStart = 0.68;
  static const double collapseEnd = 0.80;

  // Text reveal (overlaps collapse end)
  static const double textStart = 0.77;
  static const double textEnd = 0.90;

  // Final hold: 0.90 → 1.00
}

// ═══════════════════════════════════════════════════════════════════════
//  PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _SplashPainter extends CustomPainter {
  final double t; // master progress 0→1
  final Size screen;

  // ── Palette ──
  static const _red = Color(0xFFCC0000);
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  // ── Pin geometry (at scale 1.0) ──
  static const double _headR = 60.0;
  static const double _innerR = _headR * 0.82; // 49.2
  static const double _pinW = _headR * 2.17; // ~130
  static const double _pinH = _headR * 3.13; // ~188
  static const double _headCY =
      -_pinH / 2 + _headR + 2; // head center Y relative to pin center

  // ── Court proportions (consistent at ALL scales) ──
  static const double _courtAspect = 1.52; // height / width

  const _SplashPainter({required this.t, required this.screen});

  // ── Phase progress helper ──
  // Returns 0→1 for t within [start, end], clamped
  double _p(double start, double end) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return (t - start) / (end - start);
  }

  // Same but with easing curve applied
  double _e(double start, double end, Curve curve) {
    return curve.transform(_p(start, end));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── PHASE COMPUTATIONS ──
    // All visual states derived from t — no external animation objects

    // Pin drop: 0 = offscreen, 1 = landed (with bounce overshoot)
    final dropRaw = _p(_T.dropStart, _T.dropEnd);
    final dropVal = const _GravityBounceCurve().transform(dropRaw);

    // Zoom: 0 = pin visible, 1 = full screen court
    final zoomT = _e(_T.zoomStart, _T.zoomEnd, Curves.easeInOutCubic);

    // Breathe: subtle scale pulse
    final breatheT = _p(_T.breatheStart, _T.breatheEnd);
    final breatheScale = 1.0 + 0.015 * math.sin(breatheT * math.pi);

    // Collapse: 1 = full court, 0 = crushed to line
    final collapseT =
        _e(_T.collapseStart, _T.collapseEnd, Curves.easeInOutCubic);
    final collapseScaleY = 1.0 - collapseT;

    // Text reveal
    final courtWordT = _e(_T.textStart, _T.textEnd, Curves.easeOutCubic);
    final sideWordT = _e(_T.textStart + 0.02, _T.textEnd, Curves.easeOutCubic);

    // ── Pin landing position ──
    // Position pin so its inner red circle center lands exactly at screen
    // center. This way the zoom expand is perfectly centered — no drift.
    // _headCY is negative (head is above pin center), so subtracting it
    // pushes pin center DOWN, placing the head circle AT cy.
    final pinTargetY = cy - _headCY; // ≈ cy + 32

    // ── DRAW ORDER (back to front) ──
    _drawBackground(canvas, size, zoomT, cx, cy, pinTargetY);
    _drawFullCourt(canvas, size, cx, cy, zoomT, breatheScale, collapseScaleY);
    _drawDividerLine(canvas, size, cx, cy, collapseT, courtWordT);
    _drawText(canvas, size, cx, cy, courtWordT, sideWordT);
    _drawRipples(canvas, cx, cy, pinTargetY);
    _drawZoomTransition(canvas, size, cx, cy, pinTargetY, zoomT);
    _drawPin(canvas, size, cx, cy, pinTargetY, dropVal, zoomT);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  1. BACKGROUND
  // ═══════════════════════════════════════════════════════════════════
  void _drawBackground(Canvas canvas, Size size, double zoomT, double cx,
      double cy, double pinTargetY) {
    // Always black base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _black,
    );

    // Red fills in as zoom progresses
    // The red comes from the expanding circle in _drawZoomTransition
    // But once zoom is past ~0.7, we draw a full red background
    // to avoid any edge artifacts
    if (zoomT > 0.6) {
      final redAlpha = ((zoomT - 0.6) / 0.3).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = _red.withValues(alpha: redAlpha),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  2. ZOOM TRANSITION — Red circle expands from pin to fill screen
  // ═══════════════════════════════════════════════════════════════════
  void _drawZoomTransition(Canvas canvas, Size size, double cx, double cy,
      double pinTargetY, double zoomT) {
    if (zoomT <= 0.0 || zoomT >= 1.0) return;

    // Inner circle is positioned at screen center (cx, cy).
    // Zoom just expands it in place — no center drift needed.
    final center = Offset(cx, cy);

    // Start radius = pin's inner circle radius
    // End radius = enough to cover screen corners
    final cornerDist =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final startR = _innerR;
    final endR = cornerDist * 1.1;
    final radius = startR + (endR - startR) * zoomT;

    // Draw expanding red circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _red
        ..isAntiAlias = true,
    );

    // Draw court lines inside the expanding circle
    // Court width scales proportionally
    final startCourtW = _innerR * 0.88;
    final endCourtW = size.width * 0.84;
    final courtW = startCourtW + (endCourtW - startCourtW) * zoomT;

    // Clip to the circle so lines don't leak during early zoom
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    // Court line thickness scales with zoom
    final strokeBase = 4.5 + (courtW / endCourtW) * -2.0;
    final strokeW = strokeBase.clamp(2.0, 5.5);

    _drawCourtLines(
      canvas,
      center: center,
      courtWidth: courtW,
      alpha: 1.0,
      strokeWidth: strokeW,
      scaleY: 1.0,
    );
    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  3. FULL SCREEN COURT (after zoom completes)
  // ═══════════════════════════════════════════════════════════════════
  void _drawFullCourt(Canvas canvas, Size size, double cx, double cy,
      double zoomT, double breatheScale, double collapseScaleY) {
    // Only draw after zoom is nearly complete
    if (zoomT < 0.92) return;

    // Fade in as zoom finishes (smooth handoff from zoom transition)
    final fadeIn = ((zoomT - 0.92) / 0.08).clamp(0.0, 1.0);

    // After collapse is done, only the divider line remains
    if (collapseScaleY <= 0.001) return;

    final courtW = size.width * 0.84 * breatheScale;

    canvas.save();
    // Collapse: scaleY around center line
    canvas.translate(cx, cy);
    canvas.scale(breatheScale, collapseScaleY * breatheScale);
    canvas.translate(-cx, -cy);

    // Fade court lines during collapse
    final collapseAlpha = collapseScaleY < 0.5 ? collapseScaleY / 0.5 : 1.0;

    _drawCourtLines(
      canvas,
      center: Offset(cx, cy),
      courtWidth: courtW,
      alpha: fadeIn * collapseAlpha,
      strokeWidth: 2.4,
      scaleY: 1.0, // already handled by canvas transform
    );
    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  4. DIVIDER LINE — The halfway line that survives the collapse
  // ═══════════════════════════════════════════════════════════════════
  void _drawDividerLine(Canvas canvas, Size size, double cx, double cy,
      double collapseT, double textT) {
    // The divider is the halfway line. It becomes visible as collapse
    // progresses and the other court lines fade.
    if (collapseT < 0.3) return;

    // Width: starts as court halfway line width, may pulse slightly
    final lineW = size.width * 0.54;

    // Alpha: builds up as collapse progresses, fully visible for text
    final alpha = ((collapseT - 0.3) / 0.4).clamp(0.0, 1.0);

    canvas.drawLine(
      Offset(cx - lineW / 2, cy),
      Offset(cx + lineW / 2, cy),
      Paint()
        ..color = _white.withValues(alpha: alpha)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  5. TYPOGRAPHY — COURT slides down, SIDE slides up
  // ═══════════════════════════════════════════════════════════════════
  void _drawText(
      Canvas canvas, Size size, double cx, double cy, double courtT, double sideT) {
    if (courtT <= 0 && sideT <= 0) return;

    final fs = size.width * 0.125;
    const gap = 14.0;
    const slideDistance = 30.0;

    // COURT — white, slides DOWN from above the line
    if (courtT > 0) {
      final yShift = -slideDistance * (1.0 - courtT);
      _drawWord(
        canvas: canvas,
        text: 'COURT',
        color: _white.withValues(alpha: courtT.clamp(0.0, 1.0)),
        cx: cx,
        topY: cy - gap - fs + yShift,
        fontSize: fs,
      );
    }

    // SIDE — very dark (near-black for readability on red)
    if (sideT > 0) {
      final yShift = slideDistance * (1.0 - sideT);
      _drawWord(
        canvas: canvas,
        text: 'SIDE',
        color:
            const Color(0xFF1A0000).withValues(alpha: sideT.clamp(0.0, 1.0)),
        cx: cx,
        topY: cy + gap + yShift,
        fontSize: fs,
      );
    }
  }

  void _drawWord({
    required Canvas canvas,
    required String text,
    required Color color,
    required double cx,
    required double topY,
    required double fontSize,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.18,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, topY));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  6. RIPPLE RINGS — Three elliptical rings from impact point
  // ═══════════════════════════════════════════════════════════════════
  void _drawRipples(Canvas canvas, double cx, double cy, double pinTargetY) {
    // Ripples only visible before zoom takes over
    final zoomT = _e(_T.zoomStart, _T.zoomEnd, Curves.easeInOutCubic);
    if (zoomT > 0.5) return;
    final zoomFade = (1.0 - zoomT * 2.0).clamp(0.0, 1.0);

    // Ripple origin: pin tip when landed
    final tipY = pinTargetY + _pinH / 2;

    // Three staggered ripples
    final r1 = _e(_T.rippleStart, _T.rippleEnd, Curves.easeOutCubic);
    final r2 = _e(
        _T.rippleStart + 0.03, _T.rippleEnd + 0.02, Curves.easeOutCubic);
    final r3 = _e(
        _T.rippleStart + 0.06, _T.rippleEnd + 0.04, Curves.easeOutCubic);

    _drawRing(canvas, cx, tipY, r1, 0.80 * zoomFade);
    _drawRing(canvas, cx, tipY, r2, 0.55 * zoomFade);
    _drawRing(canvas, cx, tipY, r3, 0.35 * zoomFade);
  }

  void _drawRing(
      Canvas canvas, double cx, double tipY, double progress, double maxAlpha) {
    if (progress <= 0) return;
    final r = progress * 80.0;
    final alpha = (maxAlpha * (1.0 - progress)).clamp(0.0, 1.0);
    final stroke = 2.5 * (1.0 - progress * 0.6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, tipY),
        width: r * 2.6, // wide ellipse — ground perspective
        height: r * 0.7,
      ),
      Paint()
        ..color = _red.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.clamp(0.5, 3.0)
        ..isAntiAlias = true,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  7. THE PIN — Drop, bounce, squash, then fade during zoom
  // ═══════════════════════════════════════════════════════════════════
  void _drawPin(Canvas canvas, Size size, double cx, double cy, double pinTargetY,
      double dropVal, double zoomT) {
    // Pin is invisible before drop starts and after zoom takes over
    if (t < _T.dropStart) return;
    if (zoomT > 0.45) return;

    // Fade pin out during early zoom
    final pinAlpha =
        zoomT > 0.1 ? (1.0 - ((zoomT - 0.1) / 0.35)).clamp(0.0, 1.0) : 1.0;
    if (pinAlpha <= 0) return;

    // Pin Y position: offscreen → target
    final offY = -(size.height * 0.6 + _pinH);
    final currentY = offY + (pinTargetY - offY) * dropVal.clamp(0.0, 2.0);

    // Squash/stretch from bounce oscillation
    // When dropVal > 1.0: pin overshot downward → squash
    // When dropVal < 1.0 (bouncing back): stretch
    final overshoot = dropVal - 1.0;
    final squashX = 1.0 + overshoot * 0.6; // wider when squashed
    final squashY = 1.0 - overshoot * 0.5; // shorter when squashed

    // Subtle tilt during fall, corrects on landing
    final dropRaw = _p(_T.dropStart, _T.dropEnd);
    final tilt = dropRaw < 0.5
        ? math.sin(dropRaw * math.pi * 2) * 0.04 // ~2.3° oscillation
        : 0.0; // snaps to 0 on landing

    canvas.save();
    canvas.translate(cx, currentY);
    canvas.rotate(tilt);
    // Squash pivot: base of pin stays planted, head compresses down
    canvas.scale(squashX, squashY);

    _drawPinShape(canvas, pinAlpha);
    canvas.restore();
  }

  // ── PIN SHAPE: teardrop + red circle + court ──
  void _drawPinShape(Canvas canvas, double alpha) {
    final hw = _pinW / 2;
    final tipY = _pinH / 2;

    // ── Shadow ──
    final shadowPath = _teardropPath(0, _headCY, _headR, tipY);
    canvas.drawShadow(
      shadowPath,
      _black.withValues(alpha: 0.35 * alpha),
      16.0,
      true,
    );

    // ── Glossy white teardrop ──
    final bodyPath = _teardropPath(0, _headCY, _headR, tipY);
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 0.9,
      colors: const [
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFFE8E8E8),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(-hw, _headCY - _headR, _pinW, tipY - _headCY + _headR),
        )
        ..isAntiAlias = true,
    );

    // Apply alpha fade if needed
    if (alpha < 1.0) {
      canvas.drawPath(
        bodyPath,
        Paint()
          ..color = _black.withValues(alpha: 1.0 - alpha)
          ..isAntiAlias = true,
      );
    }

    // ── Red inner circle ──
    canvas.drawCircle(
      Offset(0, _headCY),
      _innerR,
      Paint()
        ..color = _red.withValues(alpha: alpha)
        ..isAntiAlias = true,
    );

    // ── Court inside red circle (clipped) ──
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(
          Rect.fromCircle(center: Offset(0, _headCY), radius: _innerR * 0.95),
        ),
    );
    _drawCourtLines(
      canvas,
      center: Offset(0, _headCY),
      courtWidth: _innerR * 0.88,
      alpha: alpha,
      strokeWidth: 4.8,
      scaleY: 1.0,
    );
    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SHARED: COURT LINES
  //  One function, used at pin scale AND full-screen scale.
  //  Court orientation: portrait (long axis vertical).
  // ═══════════════════════════════════════════════════════════════════
  void _drawCourtLines(
    Canvas canvas, {
    required Offset center,
    required double courtWidth,
    required double alpha,
    required double strokeWidth,
    required double scaleY,
  }) {
    if (alpha <= 0) return;

    final cW = courtWidth;
    final cH = cW * _courtAspect;
    final cx = center.dx;
    final cy = center.dy;
    final L = cx - cW / 2;
    final T = cy - cH / 2;
    final R = cx + cW / 2;
    final B = cy + cH / 2;

    final p = Paint()
      ..color = _white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Outer boundary
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(L, T, R, B),
        Radius.circular(cW * 0.04),
      ),
      p,
    );

    // Halfway line
    canvas.drawLine(
      Offset(L, cy),
      Offset(R, cy),
      p,
    );

    // Centre circle
    canvas.drawCircle(
      Offset(cx, cy),
      cW * 0.19,
      p..strokeWidth = strokeWidth * 0.85,
    );
    p.strokeWidth = strokeWidth; // reset

    // Centre spot
    canvas.drawCircle(
      Offset(cx, cy),
      strokeWidth * 0.7,
      Paint()
        ..color = _white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // ── Goal boxes (penalty areas) ──
    final gbW = cW * 0.56;
    final gbH = cH * 0.165;

    // Top penalty area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - gbW / 2, T, gbW, gbH),
        Radius.circular(cW * 0.015),
      ),
      p..strokeWidth = strokeWidth * 0.9,
    );

    // Bottom penalty area
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - gbW / 2, B - gbH, gbW, gbH),
        Radius.circular(cW * 0.015),
      ),
      p..strokeWidth = strokeWidth * 0.9,
    );

    // ── 6-yard boxes ──
    final sbW = cW * 0.32;
    final sbH = cH * 0.075;

    canvas.drawRect(
      Rect.fromLTWH(cx - sbW / 2, T, sbW, sbH),
      p..strokeWidth = strokeWidth * 0.75,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - sbW / 2, B - sbH, sbW, sbH),
      p..strokeWidth = strokeWidth * 0.75,
    );

    // ── Penalty spots ──
    final dot = Paint()
      ..color = _white.withValues(alpha: alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(cx, T + cH * 0.21), strokeWidth * 0.55, dot);
    canvas.drawCircle(Offset(cx, T + cH * 0.79), strokeWidth * 0.55, dot);

    // ── Penalty arcs ──
    // Only draw when court is large enough to see them
    if (courtWidth > 60) {
      final arcR = cW * 0.21;
      final arcStroke = p..strokeWidth = strokeWidth * 0.75;

      // Top arc (below penalty spot)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, T + cH * 0.21), radius: arcR),
        0.4,
        2.3,
        false,
        arcStroke,
      );

      // Bottom arc (above penalty spot)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, T + cH * 0.79), radius: arcR),
        3.5,
        2.3,
        false,
        arcStroke,
      );
    }

    // ── Corner arcs ──
    if (courtWidth > 80) {
      final cr = cW * 0.035;
      final cornerP = p..strokeWidth = strokeWidth * 0.65;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(L, T), radius: cr),
        0,
        math.pi / 2,
        false,
        cornerP,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(R, T), radius: cr),
        math.pi / 2,
        math.pi / 2,
        false,
        cornerP,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(L, B), radius: cr),
        -math.pi / 2,
        math.pi / 2,
        false,
        cornerP,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(R, B), radius: cr),
        math.pi,
        math.pi / 2,
        false,
        cornerP,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TEARDROP PATH — Perfect top arc + bezier taper to tip
  // ═══════════════════════════════════════════════════════════════════
  Path _teardropPath(double cx, double headCY, double headR, double tipY) {
    final path = Path();

    // Top semicircle (left → right, 180° clockwise)
    path.addArc(
      Rect.fromCircle(center: Offset(cx, headCY), radius: headR),
      -math.pi,
      math.pi,
    );

    // Right curve down to tip
    path.cubicTo(
      cx + headR,
      headCY + headR * 0.55,
      cx + headR * 0.15,
      tipY - headR * 0.15,
      cx,
      tipY,
    );

    // Left curve back up
    path.cubicTo(
      cx - headR * 0.15,
      tipY - headR * 0.15,
      cx - headR,
      headCY + headR * 0.55,
      cx - headR,
      headCY,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _SplashPainter old) => old.t != t;
}
