// lib/screens/mode_gate/painters/football_painter.dart
//
// Tokyo 2020 Olympic-style football pictogram.
// Player mid-kick — kicking leg raised to near-horizontal, body leaning
// forward for momentum, arms spread wide for balance.
// All coordinates normalized to a 100×120 viewBox.

import 'package:flutter/material.dart';

class FootballPainter extends CustomPainter {
  const FootballPainter();

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

    // ── Head — slightly forward ────────────────────────────────────
    canvas.drawCircle(const Offset(48, 11), 9.5, body);

    // ── Torso — leaning forward for momentum ──────────────────────
    _line(canvas, body, const Offset(48, 21), const Offset(44, 46));

    // ── Right arm — extended right for balance ─────────────────────
    _path(canvas, body, [
      const Offset(48, 28),
      const Offset(62, 33),
      const Offset(74, 28),
    ]);

    // ── Left arm — extended left for balance ──────────────────────
    _path(canvas, body, [
      const Offset(43, 28),
      const Offset(30, 33),
      const Offset(20, 28),
    ]);

    // ── Standing leg (left) — planted, slightly bent ───────────────
    _path(canvas, body, [
      const Offset(42, 46),
      const Offset(40, 65),
      const Offset(38, 84),
    ]);
    // Standing foot flat
    _line(canvas, body, const Offset(38, 84), const Offset(30, 84));

    // ── Kicking leg (right) — RAISED HIGH, almost horizontal ──────
    // Thigh goes from hip outward and upward
    _path(canvas, body, [
      const Offset(46, 46),
      const Offset(64, 44), // knee at hip level = fully raised
      const Offset(80, 50), // lower leg angling slightly down at contact
    ]);

    // ── Ball — at foot contact point ──────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(86, 55),
        width: 16,
        height: 16,
      ),
      body,
    );

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
