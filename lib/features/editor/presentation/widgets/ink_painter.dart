import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/ink_models.dart';

class InkPainter extends CustomPainter {
  InkPainter({
    required this.strokes,
    this.activeStroke,
    this.lassoPoints = const [],
    this.selectedIds = const {},
    this.visibleWorldRect,
    this.eraserCursor,
    this.eraserRadius,
    this.paintEpoch = 0,
  });

  final List<InkStroke> strokes;
  final InkStroke? activeStroke;
  final List<Offset> lassoPoints;
  final Set<String> selectedIds;

  /// When set, only strokes intersecting this rect are painted (infinite canvas).
  final Rect? visibleWorldRect;
  final Offset? eraserCursor;
  final double? eraserRadius;

  /// Detects in-place active-stroke mutations (same object identity).
  final int paintEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    final cull = visibleWorldRect?.inflate(48);

    for (final stroke in strokes) {
      if (cull != null && !stroke.boundingBox.overlaps(cull)) continue;
      _paintStroke(canvas, stroke, selected: selectedIds.contains(stroke.id));
    }
    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke!);
    }
    if (lassoPoints.length >= 2) {
      final path = Path()..moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (final p in lassoPoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final paint = Paint()
        ..color = const Color(0xFF2F6FED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0x332F6FED)
          ..style = PaintingStyle.fill,
      );
    }

    final tip = eraserCursor;
    final r = eraserRadius;
    if (tip != null && r != null && r > 0) {
      canvas.drawCircle(
        tip,
        r,
        Paint()
          ..color = const Color(0x66000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        tip,
        r,
        Paint()
          ..color = const Color(0x22000000)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintStroke(Canvas canvas, InkStroke stroke, {bool selected = false}) {
    if (stroke.points.isEmpty) return;

    if (stroke.isPencil) {
      _paintPencilStroke(canvas, stroke);
    } else if (stroke.isFountain) {
      _paintPressureStroke(canvas, stroke);
    } else {
      _paintUniformStroke(canvas, stroke);
    }

    if (selected) {
      final box = stroke.boundingBox.inflate(4);
      canvas.drawRect(
        box,
        Paint()
          ..color = const Color(0xFF2F6FED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  Path _smoothPath(List<StrokePoint> points) {
    final path = Path()..moveTo(points.first.x, points.first.y);
    if (points.length == 1) return path;
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.x + curr.x) / 2, (prev.y + curr.y) / 2);
      path.quadraticBezierTo(prev.x, prev.y, mid.dx, mid.dy);
    }
    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  void _paintUniformStroke(Canvas canvas, InkStroke stroke) {
    final paint = Paint()
      ..color = stroke.isMarker
          ? stroke.color.withValues(alpha: 0.35)
          : stroke.color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width
      ..blendMode = stroke.isMarker ? BlendMode.multiply : BlendMode.srcOver;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        stroke.points.first.offset,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = _smoothPath(stroke.points);
    final pattern = _dashPattern(stroke);
    if (pattern == null) {
      canvas.drawPath(path, paint);
    } else {
      if (stroke.style == StrokeStyle.dashed) {
        paint.strokeCap = StrokeCap.butt;
      }
      _drawDashedPath(canvas, path, paint, pattern);
    }
  }

  List<double>? _dashPattern(InkStroke stroke) {
    final w = stroke.width;
    switch (stroke.style) {
      case StrokeStyle.solid:
        return null;
      case StrokeStyle.dashed:
        return [w * 3.2, w * 2.2];
      case StrokeStyle.dotted:
        return [0.05, w * 2.4];
      case StrokeStyle.dashDot:
        return [w * 3.2, w * 1.5, 0.05, w * 1.5];
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> pattern,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      var index = 0;
      while (distance < metric.length) {
        final seg = pattern[index % pattern.length];
        final next = math.min(distance + seg, metric.length);
        if (draw && next > distance) {
          canvas.drawPath(metric.extractPath(distance, next), paint);
        }
        distance = next;
        draw = !draw;
        index++;
      }
    }
  }

  /// Fountain: pressure → stroke width (smooth segments).
  void _paintPressureStroke(Canvas canvas, InkStroke stroke) {
    final points = stroke.points;
    if (points.length == 1) {
      final p = points.first.pressure.clamp(0.05, 1.0);
      final width = stroke.width * _fountainWidthFactor(p);
      canvas.drawCircle(
        points.first.offset,
        width / 2,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
      return;
    }

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final pressure =
          ((a.pressure + b.pressure) / 2).clamp(0.05, 1.0);
      final width = stroke.width * _fountainWidthFactor(pressure);
      canvas.drawLine(
        a.offset,
        b.offset,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = width,
      );
    }
  }

  /// GoodNotes-like graphite: soft core + seeded grain along the path.
  void _paintPencilStroke(Canvas canvas, InkStroke stroke) {
    final points = stroke.points;
    if (points.isEmpty) return;

    if (points.length == 1) {
      _paintPencilStamp(
        canvas,
        points.first.offset,
        stroke.width,
        points.first.pressure.clamp(0.05, 1.0),
        stroke.color,
        seed: stroke.id.hashCode ^ points.first.t,
      );
      return;
    }

    // Soft continuous under-layer so the stroke reads as one mark.
    final soft = Paint()
      ..color = stroke.color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.width * 1.15
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55);
    canvas.drawPath(_smoothPath(points), soft);

    // Grain stamps along the polyline — denser / darker with pressure.
    var distance = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = b.offset - a.offset;
      final len = segment.distance;
      if (len < 0.001) continue;
      final dir = segment / len;
      final normal = Offset(-dir.dy, dir.dx);
      final step = math.max(0.55, stroke.width * 0.28);
      var d = 0.0;
      while (d < len) {
        final t = d / len;
        final pos = Offset(
          a.x + (b.x - a.x) * t,
          a.y + (b.y - a.y) * t,
        );
        final pressure =
            (a.pressure + (b.pressure - a.pressure) * t).clamp(0.05, 1.0);
        final seed =
            stroke.id.hashCode ^
            ((distance + d) * 1000).round() ^
            (i * 73856093);
        _paintPencilStamp(
          canvas,
          pos,
          stroke.width,
          pressure,
          stroke.color,
          normal: normal,
          seed: seed,
        );
        d += step;
      }
      distance += len;
    }
  }

  void _paintPencilStamp(
    Canvas canvas,
    Offset center,
    double width,
    double pressure,
    Color color, {
    Offset normal = Offset.zero,
    required int seed,
  }) {
    final rng = math.Random(seed);
    final density = (4 + pressure * 10).round();
    final baseAlpha = (0.16 + pressure * 0.55).clamp(0.1, 0.78);
    final spread = width * (0.45 + (1 - pressure) * 0.35);

    // Soft graphite core.
    canvas.drawCircle(
      center,
      width * (0.28 + pressure * 0.18),
      Paint()
        ..color = color.withValues(alpha: baseAlpha * 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.22),
    );

    for (var i = 0; i < density; i++) {
      final along = (rng.nextDouble() - 0.5) * width * 0.35;
      final across = (rng.nextDouble() - 0.5) * spread;
      final n = normal == Offset.zero
          ? Offset(rng.nextDouble() - 0.5, rng.nextDouble() - 0.5)
          : normal;
      final nLen = n.distance;
      final nUnit = nLen < 1e-6 ? const Offset(0, 1) : n / nLen;
      final tangent = Offset(-nUnit.dy, nUnit.dx);
      final p = center + tangent * along + nUnit * across;
      final r = width * (0.06 + rng.nextDouble() * 0.16);
      final a = baseAlpha * (0.35 + rng.nextDouble() * 0.65);
      canvas.drawCircle(
        p,
        r,
        Paint()..color = color.withValues(alpha: a.clamp(0.05, 0.85)),
      );
    }
  }

  static double _fountainWidthFactor(double pressure) {
    // Light touch ≈ 35% of base width, firm press ≈ 145%.
    return 0.35 + pressure * 1.10;
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) {
    return oldDelegate.paintEpoch != paintEpoch ||
        oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.lassoPoints != lassoPoints ||
        oldDelegate.selectedIds != selectedIds ||
        oldDelegate.visibleWorldRect != visibleWorldRect ||
        oldDelegate.eraserCursor != eraserCursor ||
        oldDelegate.eraserRadius != eraserRadius;
  }
}
