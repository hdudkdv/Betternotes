import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  /// Bumps when the settled Picture upgrades from preview → rich grain.
  static final ValueNotifier<int> settledCacheTick = ValueNotifier(0);

  /// Cached picture of committed strokes for the live editor.
  static ui.Picture? _settledPicture;
  static List<InkStroke>? _settledFor;
  static Rect? _settledCull;
  static Set<String> _settledSelected = const {};
  static int _richUpgradeToken = 0;

  static ui.Picture _recordSettled(
    List<InkStroke> strokes,
    Rect? cull,
    Set<String> selectedIds, {
    required bool rich,
  }) {
    final recorder = ui.PictureRecorder();
    final settledCanvas = Canvas(recorder);
    final painter = InkPainter(strokes: strokes, selectedIds: selectedIds);
    for (final stroke in strokes) {
      if (cull != null && !stroke.boundingBox.overlaps(cull)) continue;
      painter._paintStroke(
        settledCanvas,
        stroke,
        selected: selectedIds.contains(stroke.id),
        live: !rich,
      );
    }
    return recorder.endRecording();
  }

  void _cacheSettledPreviewThenUpgrade(Rect? cull) {
    _settledPicture?.dispose();
    _settledPicture = _recordSettled(
      strokes,
      cull,
      selectedIds,
      rich: false,
    );
    _settledFor = strokes;
    _settledCull = cull;
    _settledSelected = Set<String>.of(selectedIds);

    final hasPencil = strokes.any((s) => s.isPencil);
    if (!hasPencil) {
      // Non-pencil strokes look identical in preview/rich paths.
      return;
    }

    final token = ++_richUpgradeToken;
    final strokesRef = strokes;
    final cullRef = cull;
    final selectedRef = Set<String>.of(selectedIds);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (token != _richUpgradeToken) return;
      if (!identical(_settledFor, strokesRef)) return;
      final rich = _recordSettled(
        strokesRef,
        cullRef,
        selectedRef,
        rich: true,
      );
      _settledPicture?.dispose();
      _settledPicture = rich;
      settledCacheTick.value++;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cull = visibleWorldRect?.inflate(48);

    if (cacheSettled) {
      final settledChanged =
          !identical(_settledFor, strokes) ||
          _settledCull != cull ||
          !_setEquals(_settledSelected, selectedIds);

      if (settledChanged) {
        // Cheap preview first so page flips stay smooth; rich graphite
        // upgrades on the next frame.
        _cacheSettledPreviewThenUpgrade(cull);
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

  /// Graphite pencil: rich grain on committed strokes (Picture-cached),
  /// lighter preview while the stroke is still live.
  void _paintPencilStroke(
    Canvas canvas,
    InkStroke stroke, {
    required bool live,
  }) {
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
        rich: !live,
      );
      return;
    }

    final path = _smoothPath(points);
    var pressureSum = 0.0;
    for (final p in points) {
      pressureSum += p.pressure;
    }
    final avgP = (pressureSum / points.length).clamp(0.05, 1.0);

    // One soft underlay (single blur — not per grain).
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.color.withValues(alpha: 0.11 + avgP * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 1.3
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke.width * 0.5),
    );

    // Side graphite ribbons (settled only) — cheap extra texture.
    if (!live) {
      _paintPencilJitterRibbon(canvas, points, stroke, side: -1.0);
      _paintPencilJitterRibbon(canvas, points, stroke, side: 1.0);
    }

    // Pressure-varying core ribbon.
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final pressure = ((a.pressure + b.pressure) / 2).clamp(0.05, 1.0);
      corePaint
        ..color = stroke.color.withValues(alpha: 0.2 + pressure * 0.48)
        ..strokeWidth = stroke.width * (0.5 + pressure * 0.4);
      canvas.drawLine(a.offset, b.offset, corePaint);
    }

    // Grain stamps. Settled strokes are cached → can be dense & detailed.
    // Live strokes stay sparse so the pen feels smooth.
    final step = live
        ? math.max(2.8, stroke.width * 0.95)
        : math.max(0.7, stroke.width * 0.32);
    final grainPaint = Paint();
    var distance = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = b.offset - a.offset;
      final len = segment.distance;
      if (len < 0.001) continue;
      final dir = segment / len;
      final normal = Offset(-dir.dy, dir.dx);
      var d = 0.0;
      while (d < len) {
        final t = d / len;
        final pos = Offset(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
        final pressure =
            (a.pressure + (b.pressure - a.pressure) * t).clamp(0.05, 1.0);
        final seed = stroke.id.hashCode ^
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
          rich: !live,
          reuse: grainPaint,
        );
        d += step;
      }
      distance += len;
    }
  }

  void _paintPencilJitterRibbon(
    Canvas canvas,
    List<StrokePoint> points,
    InkStroke stroke, {
    required double side,
  }) {
    final path = Path();
    var started = false;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1].offset;
      final b = points[i].offset;
      final seg = b - a;
      final len = seg.distance;
      if (len < 0.001) continue;
      final normal = Offset(-seg.dy / len, seg.dx / len) * side;
      final seed = stroke.id.hashCode ^ (i * 17) ^ side.hashCode;
      final rng = math.Random(seed);
      final offset = stroke.width * (0.18 + rng.nextDouble() * 0.22);
      final p = b + normal * offset;
      if (!started) {
        path.moveTo((a + normal * offset).dx, (a + normal * offset).dy);
        started = true;
      }
      path.lineTo(p.dx, p.dy);
    }
    if (!started) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width * 0.45,
    );
  }

  void _paintPencilStamp(
    Canvas canvas,
    Offset center,
    double width,
    double pressure,
    Color color, {
    Offset normal = Offset.zero,
    required int seed,
    required bool rich,
    Paint? reuse,
  }) {
    final rng = math.Random(seed);
    final density = rich ? (5 + (pressure * 8).round()) : (2 + (pressure * 3).round());
    final baseAlpha = (0.16 + pressure * 0.55).clamp(0.1, 0.78);
    final spread = width * (0.45 + (1 - pressure) * 0.35);
    final paint = reuse ?? Paint();

    // Soft core without MaskFilter — blur-per-stamp was the FPS killer.
    paint.color = color.withValues(alpha: baseAlpha * (rich ? 0.5 : 0.4));
    canvas.drawCircle(center, width * (0.26 + pressure * 0.16), paint);

    final n = normal == Offset.zero
        ? Offset(rng.nextDouble() - 0.5, rng.nextDouble() - 0.5)
        : normal;
    final nLen = n.distance;
    final nUnit = nLen < 1e-6 ? const Offset(0, 1) : n / nLen;
    final tangent = Offset(-nUnit.dy, nUnit.dx);

    for (var i = 0; i < density; i++) {
      final along = (rng.nextDouble() - 0.5) * width * (rich ? 0.4 : 0.3);
      final across = (rng.nextDouble() - 0.5) * spread;
      final p = center + tangent * along + nUnit * across;
      final r = width * (rich ? (0.05 + rng.nextDouble() * 0.15) : (0.07 + rng.nextDouble() * 0.1));
      final a = baseAlpha * (0.35 + rng.nextDouble() * 0.65);
      paint.color = color.withValues(alpha: a.clamp(0.05, 0.85));
      canvas.drawCircle(p, r, paint);
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
