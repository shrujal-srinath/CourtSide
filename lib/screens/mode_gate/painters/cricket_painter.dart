// lib/screens/mode_gate/painters/cricket_painter.dart
//
// Tokyo 2020 Olympic-style cricket pictogram.
// Batsman in full overhead backlift — bat raised well above head,
// body coiled side-on, weight loading onto back foot.
// All coordinates normalized to a 100×120 viewBox.

import 'package:flutter/material.dart';

class CricketPainter extends CustomPainter {
  const CricketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 120);

    final body = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..strokeWidth = 6.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bat = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..strokeWidth = 7.0 // slightly thicker — bat blade
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // ── Head — slightly side-on ───────────────────────────────────
    canvas.drawCircle(const Offset(50, 12), 9.5, body);

    // ── Torso — angled slightly forward, body coiling ─────────────
    _line(canvas, body, const Offset(50, 22), const Offset(47, 47));

    // ── Right arm (top hand) — raised up toward bat handle ────────
    _path(canvas, body, [
      const Offset(54, 28),
      const Offset(65, 18),
      const Offset(70, 10),
    ]);

    // ── Left arm (bottom hand) — follows through above shoulder ───
    _path(canvas, body, [
      const Offset(46, 30),
      const Offset(56, 22),
      const Offset(62, 14),
    ]);

    // ── Bat — raised high, almost vertical, extending above head ──
    // Handle from grip point upward, blade extending far above
    _path(canvas, bat, [
      const Offset(64, 14),
      const Offset(70, 3),
      const Offset(74, -6), // extends above canvas = bat tip off-screen
    ]);

    // ── Front leg — planted forward, weight going forward ─────────
    _path(canvas, body, [
      const Offset(47, 47),
      const Offset(40, 66),
      const Offset(35, 82),
    ]);

    // ── Back leg — weight loading, heel slightly raised ────────────
    _path(canvas, body, [
      const Offset(47, 47),
      const Offset(54, 64),
      const Offset(60, 79),
    ]);
    // Back foot turned out (heel up)
    _line(canvas, body, const Offset(60, 79), const Offset(68, 76));

    canvas.restore();
  }

  void _line(Canvas canvas, Paint paint, Offset a, Offset b) {
    canvas.drawLine(a, b, paint);
  }

  void _path(Canvas canvas, Paint paint, List<Offset> pts) {
    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
