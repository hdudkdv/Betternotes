import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'calculator_engine.dart';
import 'expression_diff.dart';
import 'plot_series.dart';

class _Sampled {
  const _Sampled(this.label, this.color, this.dashed, this.ys);

  final String label;
  final Color color;
  final bool dashed;
  final List<double?> ys;
}

abstract final class FunctionPlotter {
  static String normalizeExpression(String raw) =>
      FunctionPlotPrep.normalizeExpression(raw);

  static Future<Uint8List?> renderPng(
    Object input, {
    double? xMin,
    double? xMax,
    int width = 780,
    int height = 520,
    bool degrees = false,
  }) async {
    final series = _coerce(input);
    if (series.isEmpty) return null;

    final minX = xMin ?? (degrees ? -360.0 : -8.0);
    final maxX = xMax ?? (degrees ? 360.0 : 8.0);
    final engine = CalculatorEngine()..degrees = degrees;
    const samples = 720;
    final xs = [
      for (var i = 0; i <= samples; i++)
        minX + (maxX - minX) * (i / samples),
    ];

    final sampled = <_Sampled>[];
    final finite = <double>[];
    for (var i = 0; i < series.length; i++) {
      final item = series[i];
      final expr = FunctionPlotPrep.normalizeExpression(item.expression);
      if (expr.isEmpty) continue;
      final color = item.color ?? kPlotColors[i % kPlotColors.length];
      final ys = _sample(engine, expr, xs, finite);
      if (ys.whereType<double>().length >= 8) {
        sampled.add(
          _Sampled(item.displayLabel, color, false, ys),
        );
      }
      if (item.plotDerivative) {
        final symbolic = ExpressionDiff.differentiate(expr);
        final dLabel = symbolic == null
            ? "${item.displayLabel.replaceAll('(x)', '')}'(x)"
            : "${item.displayLabel.replaceAll('(x)', '')}'(x)=$symbolic";
        final dYs = symbolic != null
            ? _sample(engine, symbolic, xs, finite)
            : _sampleNumericDerivative(engine, expr, xs, finite);
        if (dYs.whereType<double>().length >= 8) {
          sampled.add(_Sampled(dLabel, color.withValues(alpha: 0.75), true, dYs));
        }
      }
    }
    if (sampled.isEmpty || finite.length < 8) return null;

    finite.sort();
    final lo = finite[(finite.length * 0.04).floor()];
    final hi = finite[((finite.length - 1) * 0.96).round()];
    var yMin = lo;
    var yMax = hi;
    if ((yMax - yMin).abs() < 1e-6) {
      yMin -= 1;
      yMax += 1;
    }
    final padY = (yMax - yMin) * 0.14;
    yMin -= padY;
    yMax += padY;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFCF7),
    );

    const padL = 48.0;
    const padR = 20.0;
    const padT = 28.0;
    final legendH = 22.0 * sampled.length + 8;
    final plot = Rect.fromLTWH(
      padL,
      padT,
      width - padL - padR,
      height - padT - legendH - 16,
    );

    Offset map(double x, double y) {
      final nx = (x - minX) / (maxX - minX);
      final ny = (yMax - y) / (yMax - yMin);
      return Offset(plot.left + nx * plot.width, plot.top + ny * plot.height);
    }

    final grid = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    final xStep = _niceStep(maxX - minX);
    var xTick = (minX / xStep).ceil() * xStep;
    while (xTick <= maxX + 1e-9) {
      canvas.drawLine(map(xTick, yMin), map(xTick, yMax), grid);
      xTick += xStep;
    }
    final yStep = _niceStep(yMax - yMin);
    var yTick = (yMin / yStep).ceil() * yStep;
    while (yTick <= yMax + 1e-9) {
      canvas.drawLine(map(minX, yTick), map(maxX, yTick), grid);
      yTick += yStep;
    }

    final axis = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1.4;
    if (yMin <= 0 && yMax >= 0) {
      canvas.drawLine(map(minX, 0), map(maxX, 0), axis);
    }
    if (minX <= 0 && maxX >= 0) {
      canvas.drawLine(map(0, yMin), map(0, yMax), axis);
    }

    final jump = (yMax - yMin) * 0.45;
    for (final curve in sampled) {
      _drawCurve(canvas, xs, curve, map, yMin, yMax, jump);
    }

    var ly = plot.bottom + 10;
    for (final curve in sampled) {
      canvas.drawLine(
        Offset(plot.left, ly + 8),
        Offset(plot.left + 22, ly + 8),
        Paint()
          ..color = curve.color
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      _drawLabel(canvas, curve.label, Offset(plot.left + 28, ly), curve.color);
      ly += 22;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes?.buffer.asUint8List();
  }

  static List<PlotSeries> _coerce(Object input) {
    if (input is List<PlotSeries>) return input;
    if (input is PlotSeries) return [input];
    if (input is String) {
      return [
        for (final part in FunctionPlotPrep.splitExpressions(input))
          PlotSeries(expression: part),
      ];
    }
    return const [];
  }

  static List<double?> _sample(
    CalculatorEngine engine,
    String expr,
    List<double> xs,
    List<double> finite,
  ) {
    final ys = <double?>[];
    for (final x in xs) {
      final r = engine.evaluate(expr, x: x);
      if (!r.ok || !r.value.isFinite) {
        ys.add(null);
        continue;
      }
      ys.add(r.value);
      finite.add(r.value);
    }
    return ys;
  }

  static List<double?> _sampleNumericDerivative(
    CalculatorEngine engine,
    String expr,
    List<double> xs,
    List<double> finite,
  ) {
    final ys = <double?>[];
    for (final x in xs) {
      final d = ExpressionDiff.numeric(engine, expr, x);
      if (!d.isFinite) {
        ys.add(null);
        continue;
      }
      ys.add(d);
      finite.add(d);
    }
    return ys;
  }

  static void _drawCurve(
    Canvas canvas,
    List<double> xs,
    _Sampled curve,
    Offset Function(double x, double y) map,
    double yMin,
    double yMax,
    double jump,
  ) {
    final path = Path();
    var started = false;
    double? lastY;
    for (var i = 0; i < xs.length; i++) {
      final y = curve.ys[i];
      if (y == null || y < yMin - jump || y > yMax + jump) {
        started = false;
        lastY = null;
        continue;
      }
      if (lastY != null && (y - lastY).abs() > jump) {
        started = false;
      }
      final p = map(xs[i], y);
      if (!started) {
        path.moveTo(p.dx, p.dy);
        started = true;
      } else {
        path.lineTo(p.dx, p.dy);
      }
      lastY = y;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = curve.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = curve.dashed ? 1.8 : 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  static double _niceStep(double range) {
    if (range <= 0) return 1;
    final raw = range / 6;
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final n = raw / exp;
    final nice = n < 1.5 ? 1.0 : n < 3.5 ? 2.0 : n < 7.5 ? 5.0 : 10.0;
    return nice * exp;
  }

  static void _drawLabel(Canvas canvas, String text, Offset at, Color color) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 13, fontWeight: FontWeight.w600),
    )..pushStyle(ui.TextStyle(color: color))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 640));
    canvas.drawParagraph(paragraph, at);
  }
}
