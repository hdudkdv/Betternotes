import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'calculator_engine.dart';

abstract final class FunctionPlotter {
  static Future<Uint8List?> renderPng(
    String expression, {
    double xMin = -8,
    double xMax = 8,
    int width = 720,
    int height = 480,
  }) async {
    final engine = CalculatorEngine();
    final probe = engine.evaluate(expression, x: 0);
    if (!probe.ok && probe.error != 'Undef') {
      // Still try plotting; some functions are undefined at 0.
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final bg = Paint()..color = const Color(0xFFFFFCF7);
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bg);

    const pad = 36.0;
    final plot = Rect.fromLTWH(pad, pad, width - pad * 2, height - pad * 2);
    final yMin = -6.0;
    final yMax = 6.0;

    Offset map(double x, double y) {
      final nx = (x - xMin) / (xMax - xMin);
      final ny = (yMax - y) / (yMax - yMin);
      return Offset(plot.left + nx * plot.width, plot.top + ny * plot.height);
    }

    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = xMin.ceil(); x <= xMax.floor(); x++) {
      canvas.drawLine(map(x.toDouble(), yMin), map(x.toDouble(), yMax), grid);
    }
    for (var y = yMin.ceil(); y <= yMax.floor(); y++) {
      canvas.drawLine(map(xMin, y.toDouble()), map(xMax, y.toDouble()), grid);
    }
    final axis = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1.4;
    canvas.drawLine(map(xMin, 0), map(xMax, 0), axis);
    canvas.drawLine(map(0, yMin), map(0, yMax), axis);

    final curve = Path();
    var started = false;
    const samples = 360;
    for (var i = 0; i <= samples; i++) {
      final x = xMin + (xMax - xMin) * (i / samples);
      final r = engine.evaluate(expression, x: x);
      if (!r.ok || r.value < yMin - 2 || r.value > yMax + 2) {
        started = false;
        continue;
      }
      final p = map(x, r.value);
      if (!started) {
        curve.moveTo(p.dx, p.dy);
        started = true;
      } else {
        curve.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = const Color(0xFF1D4E89)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes?.buffer.asUint8List();
  }
}
