import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';

export '../../domain/geometry_guides.dart' show snapRulerEndpoint;

class ShapePainter extends CustomPainter {
  ShapePainter({required this.shapes, this.draft});

  final List<ShapeElement> shapes;
  final ShapeElement? draft;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      _paintShape(canvas, shape);
    }
    if (draft != null) {
      _paintShape(canvas, draft!, preview: true);
      _paintGuides(canvas, draft!);
    }
  }

  void _paintShape(Canvas canvas, ShapeElement shape, {bool preview = false}) {
    final paint = Paint()
      ..color = Color(shape.colorValue).withValues(alpha: preview ? 0.7 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final a = Offset(shape.x1, shape.y1);
    final b = Offset(shape.x2, shape.y2);
    switch (shape.kind) {
      case ShapeKind.line:
        canvas.drawLine(a, b, paint);
      case ShapeKind.arrow:
        canvas.drawLine(a, b, paint);
        _drawArrowHead(canvas, a, b, paint);
      case ShapeKind.rect:
        canvas.drawRect(Rect.fromPoints(a, b), paint);
      case ShapeKind.ellipse:
        canvas.drawOval(Rect.fromPoints(a, b), paint);
      case ShapeKind.circle:
        final radius = (b - a).distance;
        canvas.drawCircle(a, radius, paint);
    }
  }

  void _paintGuides(Canvas canvas, ShapeElement shape) {
    final guide = Paint()
      ..color = const Color(0x662F6FED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final a = Offset(shape.x1, shape.y1);
    final b = Offset(shape.x2, shape.y2);

    if (shape.kind == ShapeKind.line || shape.kind == ShapeKind.arrow) {
      // Extend the ruler ray slightly past the endpoints.
      final dir = b - a;
      final len = dir.distance;
      if (len < 1) return;
      final unit = dir / len;
      final start = a - unit * 24;
      final end = b + unit * 24;
      canvas.drawLine(
        start,
        end,
        guide..strokeWidth = 1,
      );
      // Tick marks every ~40px along the segment.
      final ticks = (len / 40).floor().clamp(0, 40);
      for (var i = 1; i <= ticks; i++) {
        final t = i / (ticks + 1);
        final p = Offset.lerp(a, b, t)!;
        final n = Offset(-unit.dy, unit.dx);
        canvas.drawLine(p - n * 5, p + n * 5, guide);
      }
      return;
    }

    if (shape.kind == ShapeKind.circle) {
      final radius = (b - a).distance;
      canvas.drawLine(a, b, guide);
      canvas.drawCircle(
        a,
        3.5,
        Paint()
          ..color = const Color(0xFF2F6FED)
          ..style = PaintingStyle.fill,
      );
      // Faint full circle guide under the stroke.
      canvas.drawCircle(
        a,
        radius,
        Paint()
          ..color = const Color(0x332F6FED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawArrowHead(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dir = b - a;
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final left = Offset(-unit.dy, unit.dx);
    final tip = b;
    final base = b - unit * 12;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + left.dx * 7, base.dy + left.dy * 7)
      ..lineTo(base.dx - left.dx * 7, base.dy - left.dy * 7)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shapes != shapes || oldDelegate.draft != draft;
  }

  // Decorative overlay only — a full-page CustomPaint would otherwise swallow
  // every pointer (Flutter defaults hitTest to true) and kill ink + page swipe.
  @override
  bool hitTest(Offset position) => false;
}
