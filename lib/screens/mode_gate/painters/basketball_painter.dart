// lib/screens/mode_gate/painters/basketball_painter.dart
//
// Tokyo 2020 Olympic-style basketball pictogram.
// Player airborne in jump-shot pose — arm extended up, both feet off ground.
// All coordinates normalized to a 100×120 viewBox.

import 'package:flutter/material.dart';

class BasketballPainter extends CustomPainter {
  const BasketballPainter();

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

    final ball = Paint()
      ..color = const Color(0xFFE8112D)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ── Head ──────────────────────────────────────────────────────
    canvas.drawCircle(const Offset(53, 12), 9.5, body);

    // ── Torso — slight backward lean (shooting form) ─────────────
    _line(canvas, body, const Offset(53, 22), const Offset(50, 46));

    // ── Right arm — shooting, raised up-right ─────────────────────
    _path(canvas, body, [
      const Offset(56, 28),
      const Offset(67, 17),
      const Offset(75, 9),
    ]);

    // ── Ball — red circle at right hand ──────────────────────────
    canvas.drawCircle(const Offset(81, 5), 8.5, ball);

    // ── Left arm — guide hand, slightly raised and outward ────────
    _path(canvas, body, [
      const Offset(49, 28),
      const Offset(38, 32),
      const Offset(33, 25),
    ]);

    // ── Right leg — trailing, bent at knee ────────────────────────
    _path(canvas, body, [
      const Offset(51, 46),
      const Offset(62, 61),
      const Offset(54, 75),
    ]);

    // ── Left leg — leading, knee lifted forward ───────────────────
    _path(canvas, body, [
      const Offset(49, 46),
      const Offset(40, 60),
      const Offset(37, 74),
    ]);

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
