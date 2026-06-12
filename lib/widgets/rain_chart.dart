import 'package:flutter/material.dart';

import '../models.dart';

/// Grouped bar chart of monthly precipitation for two cities.
class RainChart extends StatelessWidget {
  const RainChart({
    super.key,
    required this.a,
    required this.b,
    required this.colorA,
    required this.colorB,
  });

  final City a;
  final City b;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainPainter(
        rainA: a.precipMm,
        rainB: b.precipMm,
        colorA: colorA,
        colorB: colorB,
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.rainA,
    required this.rainB,
    required this.colorA,
    required this.colorB,
    required this.labelColor,
    required this.gridColor,
  });

  final List<double> rainA;
  final List<double> rainB;
  final Color colorA;
  final Color colorB;
  final Color labelColor;
  final Color gridColor;

  static const _left = 44.0;
  static const _right = 10.0;
  static const _top = 10.0;
  static const _bottom = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    var maxV = 10.0;
    for (final v in [...rainA, ...rainB]) {
      if (v > maxV) maxV = v;
    }
    final step = _niceStep(maxV / 4);
    final yMax = (maxV / step).ceil() * step;

    final plotW = size.width - _left - _right;
    final plotH = size.height - _top - _bottom;
    double y(double v) => _top + plotH * (1 - v / yMax);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var v = 0.0; v <= yMax; v += step) {
      canvas.drawLine(Offset(_left, y(v)), Offset(_left + plotW, y(v)), gridPaint);
      _text(canvas, '${v.toInt()}', Offset(_left - 6, y(v)),
          alignRight: true, vCenter: true);
    }
    final slot = plotW / 12;
    final barW = slot * 0.3;
    for (var m = 0; m < 12; m++) {
      final center = _left + slot * (m + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(center - barW - 1, y(rainA[m]), center - 1, y(0)),
          const Radius.circular(2),
        ),
        Paint()..color = colorA,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(center + 1, y(rainB[m]), center + barW + 1, y(0)),
          const Radius.circular(2),
        ),
        Paint()..color = colorB,
      );
      _text(canvas, monthLetters[m], Offset(center, _top + plotH + 4),
          hCenter: true);
    }
  }

  double _niceStep(double raw) {
    const candidates = [10.0, 25.0, 50.0, 100.0, 150.0, 200.0, 300.0];
    for (final c in candidates) {
      if (raw <= c) return c;
    }
    return 500;
  }

  void _text(
    Canvas canvas,
    String s,
    Offset anchor, {
    bool alignRight = false,
    bool hCenter = false,
    bool vCenter = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 11, color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = anchor.dx;
    var dy = anchor.dy;
    if (alignRight) dx -= tp.width;
    if (hCenter) dx -= tp.width / 2;
    if (vCenter) dy -= tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_RainPainter old) =>
      old.rainA != rainA ||
      old.rainB != rainB ||
      old.colorA != colorA ||
      old.colorB != colorB ||
      old.labelColor != labelColor ||
      old.gridColor != gridColor;
}
