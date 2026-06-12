import 'package:flutter/material.dart';

import '../models.dart';

/// Line chart of monthly daily highs and lows for two cities.
///
/// Each city is drawn as a shaded band between its average low and average
/// high, so two similar climates literally overlap on screen.
class TempChart extends StatelessWidget {
  const TempChart({
    super.key,
    required this.a,
    required this.b,
    required this.colorA,
    required this.colorB,
    required this.useFahrenheit,
  });

  final City a;
  final City b;
  final Color colorA;
  final Color colorB;
  final bool useFahrenheit;

  @override
  Widget build(BuildContext context) {
    double convert(double c) => useFahrenheit ? celsiusToFahrenheit(c) : c;
    return CustomPaint(
      painter: _TempPainter(
        highA: [for (final v in a.highC) convert(v)],
        lowA: [for (final v in a.lowC) convert(v)],
        highB: [for (final v in b.highC) convert(v)],
        lowB: [for (final v in b.lowC) convert(v)],
        colorA: colorA,
        colorB: colorB,
        unit: useFahrenheit ? '°F' : '°C',
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        gridColor: Theme.of(context).colorScheme.outlineVariant,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TempPainter extends CustomPainter {
  _TempPainter({
    required this.highA,
    required this.lowA,
    required this.highB,
    required this.lowB,
    required this.colorA,
    required this.colorB,
    required this.unit,
    required this.labelColor,
    required this.gridColor,
  });

  final List<double> highA;
  final List<double> lowA;
  final List<double> highB;
  final List<double> lowB;
  final Color colorA;
  final Color colorB;
  final String unit;
  final Color labelColor;
  final Color gridColor;

  static const _left = 40.0;
  static const _right = 10.0;
  static const _top = 10.0;
  static const _bottom = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...highA, ...lowA, ...highB, ...lowB];
    var minV = all.first;
    var maxV = all.first;
    for (final v in all) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final step = (maxV - minV) > 35 ? 10.0 : 5.0;
    final yMin = (minV / step).floor() * step;
    final yMax = (maxV / step).ceil() * step;

    final plotW = size.width - _left - _right;
    final plotH = size.height - _top - _bottom;
    double x(int month) => _left + plotW * month / 11;
    double y(double v) => _top + plotH * (1 - (v - yMin) / (yMax - yMin));

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var v = yMin; v <= yMax; v += step) {
      canvas.drawLine(Offset(_left, y(v)), Offset(_left + plotW, y(v)), gridPaint);
      _text(canvas, '${v.toInt()}$unit', Offset(_left - 6, y(v)),
          alignRight: true, vCenter: true);
    }
    for (var m = 0; m < 12; m++) {
      _text(canvas, monthLetters[m], Offset(x(m), _top + plotH + 4),
          hCenter: true);
    }

    _band(canvas, highA, lowA, colorA, x, y);
    _band(canvas, highB, lowB, colorB, x, y);
  }

  void _band(
    Canvas canvas,
    List<double> high,
    List<double> low,
    Color color,
    double Function(int) x,
    double Function(double) y,
  ) {
    final band = Path()..moveTo(x(0), y(high[0]));
    for (var m = 1; m < 12; m++) {
      band.lineTo(x(m), y(high[m]));
    }
    for (var m = 11; m >= 0; m--) {
      band.lineTo(x(m), y(low[m]));
    }
    band.close();
    canvas.drawPath(band, Paint()..color = color.withValues(alpha: 0.16));

    final highLine = Path()..moveTo(x(0), y(high[0]));
    final lowLine = Path()..moveTo(x(0), y(low[0]));
    for (var m = 1; m < 12; m++) {
      highLine.lineTo(x(m), y(high[m]));
      lowLine.lineTo(x(m), y(low[m]));
    }
    canvas.drawPath(
      highLine,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      lowLine,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
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
  bool shouldRepaint(_TempPainter old) =>
      old.highA != highA ||
      old.highB != highB ||
      old.lowA != lowA ||
      old.lowB != lowB ||
      old.colorA != colorA ||
      old.colorB != colorB ||
      old.unit != unit ||
      old.labelColor != labelColor ||
      old.gridColor != gridColor;
}
