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

    if (stroke.isFountain || stroke.isPencil) {
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

    final path = Path()..moveTo(stroke.points.first.x, stroke.points.first.y);
    for (var i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final mid = Offset((prev.x + curr.x) / 2, (prev.y + curr.y) / 2);
      path.quadraticBezierTo(prev.x, prev.y, mid.dx, mid.dy);
    }
    path.lineTo(stroke.points.last.x, stroke.points.last.y);
    canvas.drawPath(path, paint);
  }

  /// Pencil: pressure → opacity. Fountain: pressure → stroke width.
  void _paintPressureStroke(Canvas canvas, InkStroke stroke) {
    final points = stroke.points;
    if (points.length == 1) {
      final p = points.first.pressure.clamp(0.05, 1.0);
      final width = stroke.isFountain
          ? stroke.width * _fountainWidthFactor(p)
          : stroke.width;
      final alpha = stroke.isPencil ? _pencilAlpha(p) : 1.0;
      canvas.drawCircle(
        points.first.offset,
        width / 2,
        Paint()
          ..color = stroke.color.withValues(alpha: alpha)
          ..style = PaintingStyle.fill,
      );
      return;
    }

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final pa = a.pressure.clamp(0.05, 1.0);
      final pb = b.pressure.clamp(0.05, 1.0);
      final pressure = (pa + pb) / 2;

      late final double width;
      late final double alpha;
      if (stroke.isFountain) {
        width = stroke.width * _fountainWidthFactor(pressure);
        alpha = 1.0;
      } else {
        width = stroke.width;
        alpha = _pencilAlpha(pressure);
      }

      final paint = Paint()
        ..color = stroke.color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width;
      canvas.drawLine(a.offset, b.offset, paint);
    }
  }

  static double _fountainWidthFactor(double pressure) {
    // Light touch ≈ 35% of base width, firm press ≈ 145%.
    return 0.35 + pressure * 1.10;
  }

  static double _pencilAlpha(double pressure) {
    // Soft graphite look: faint when light, denser when pressed.
    return (0.12 + pressure * 0.82).clamp(0.08, 0.95);
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
