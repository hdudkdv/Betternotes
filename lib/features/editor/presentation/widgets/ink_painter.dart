import 'dart:math' as math;
import 'dart:ui' as ui;

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
    this.cacheSettled = false,
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

  /// Live editor canvas only — thumbnails must leave this off.
  final bool cacheSettled;

  /// Cached picture of committed strokes for the live editor.
  static ui.Picture? _settledPicture;
  static List<InkStroke>? _settledFor;
  static Rect? _settledCull;
  static Set<String> _settledSelected = const {};

  @override
  void paint(Canvas canvas, Size size) {
    final cull = visibleWorldRect?.inflate(48);

    if (cacheSettled) {
      final settledChanged =
          !identical(_settledFor, strokes) ||
          _settledCull != cull ||
          !_setEquals(_settledSelected, selectedIds);

      if (settledChanged) {
        final recorder = ui.PictureRecorder();
        final settledCanvas = Canvas(recorder);
        for (final stroke in strokes) {
          if (cull != null && !stroke.boundingBox.overlaps(cull)) continue;
          _paintStroke(
            settledCanvas,
            stroke,
            selected: selectedIds.contains(stroke.id),
            live: false,
          );
        }
        _settledPicture?.dispose();
        _settledPicture = recorder.endRecording();
        _settledFor = strokes;
        _settledCull = cull;
        _settledSelected = Set<String>.of(selectedIds);
      }

      final picture = _settledPicture;
      if (picture != null) {
        canvas.drawPicture(picture);
      }
    } else {
      for (final stroke in strokes) {
        if (cull != null && !stroke.boundingBox.overlaps(cull)) continue;
        _paintStroke(
          canvas,
          stroke,
          selected: selectedIds.contains(stroke.id),
          live: false,
        );
      }
    }

    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke!, live: true);
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

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _paintStroke(
    Canvas canvas,
    InkStroke stroke, {
    bool selected = false,
    required bool live,
  }) {
    if (stroke.points.isEmpty) return;

    if (stroke.isPencil) {
      _paintPencilStroke(canvas, stroke, live: live);
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
      final pressure = ((a.pressure + b.pressure) / 2).clamp(0.05, 1.0);
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

  /// Graphite look without per-point stamp storms (those killed frame rate).
  ///
  /// Soft underlay + core ribbon + a few sparse grains. Committed strokes are
  /// cached as a [ui.Picture] so only the live stroke is redrawn each frame.
  void _paintPencilStroke(
    Canvas canvas,
    InkStroke stroke, {
    required bool live,
  }) {
    final points = stroke.points;
    if (points.isEmpty) return;

    if (points.length == 1) {
      final p = points.first.pressure.clamp(0.05, 1.0);
      canvas.drawCircle(
        points.first.offset,
        stroke.width * (0.35 + p * 0.2),
        Paint()
          ..color = stroke.color.withValues(alpha: 0.2 + p * 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.35),
      );
      return;
    }

    final path = _smoothPath(points);
    var pressureSum = 0.0;
    for (final p in points) {
      pressureSum += p.pressure;
    }
    final avgP = (pressureSum / points.length).clamp(0.05, 1.0);

    // Soft graphite cloud under the stroke (one blur pass).
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.color.withValues(alpha: 0.12 + avgP * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 1.25
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.45),
    );

    // Pressure-varying core — segment lines, no blur.
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final pressure = ((a.pressure + b.pressure) / 2).clamp(0.05, 1.0);
      canvas.drawLine(
        a.offset,
        b.offset,
        Paint()
          ..color = stroke.color.withValues(alpha: 0.22 + pressure * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke.width * (0.55 + pressure * 0.35),
      );
    }

    // Sparse grain — much cheaper than per-sample stamp clouds.
    // Live strokes use an even larger step so drawing stays smooth.
    final step = live
        ? math.max(3.2, stroke.width * 1.1)
        : math.max(2.2, stroke.width * 0.75);
    var distance = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = b.offset - a.offset;
      final len = segment.distance;
      if (len < 0.001) continue;
      final dir = segment / len;
      final normal = Offset(-dir.dy, dir.dx);
      var d = distance % step;
      if (d > 0) d = step - d;
      while (d < len) {
        final t = d / len;
        final pos = Offset(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
        final pressure =
            (a.pressure + (b.pressure - a.pressure) * t).clamp(0.05, 1.0);
        final seed =
            stroke.id.hashCode ^ ((distance + d) * 97).round() ^ (i * 31);
        final rng = math.Random(seed);
        final across = (rng.nextDouble() - 0.5) * stroke.width * 0.55;
        final grain = pos + normal * across;
        canvas.drawCircle(
          grain,
          stroke.width * (0.08 + rng.nextDouble() * 0.1),
          Paint()
            ..color = stroke.color.withValues(
              alpha: (0.18 + pressure * 0.4) * (0.5 + rng.nextDouble() * 0.5),
            ),
        );
        d += step;
      }
      distance += len;
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
