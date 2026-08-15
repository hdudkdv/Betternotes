import 'dart:math' as math;
import 'dart:ui';

import '../../../data/models/content_models.dart';
import 'ink_models.dart';

/// Turns a freehand stroke into a geometric [ShapeElement] when the path
/// is close enough to a line, rectangle, circle or ellipse.
class ShapeRecognition {
  ShapeRecognition._();

  static ShapeElement? recognize(
    List<StrokePoint> points, {
    required String pageId,
    required int colorValue,
    required double strokeWidth,
  }) {
    if (points.length < 8) return null;
    final pts = [for (final p in points) p.offset];
    var length = 0.0;
    for (var i = 1; i < pts.length; i++) {
      length += (pts[i] - pts[i - 1]).distance;
    }
    if (length < 28) return null;

    final line = _asLine(pts, length);
    if (line != null) {
      return ShapeElement.create(
        pageId: pageId,
        kind: ShapeKind.line,
        x1: line.$1.dx,
        y1: line.$1.dy,
        x2: line.$2.dx,
        y2: line.$2.dy,
        colorValue: colorValue,
        strokeWidth: strokeWidth,
      );
    }

    final circle = _asCircle(pts);
    if (circle != null) {
      return ShapeElement.create(
        pageId: pageId,
        kind: ShapeKind.circle,
        x1: circle.center.dx,
        y1: circle.center.dy,
        x2: circle.center.dx + circle.radius,
        y2: circle.center.dy,
        colorValue: colorValue,
        strokeWidth: strokeWidth,
      );
    }

    final rect = _asRect(pts);
    if (rect != null) {
      return ShapeElement.create(
        pageId: pageId,
        kind: ShapeKind.rect,
        x1: rect.left,
        y1: rect.top,
        x2: rect.right,
        y2: rect.bottom,
        colorValue: colorValue,
        strokeWidth: strokeWidth,
      );
    }

    final ellipse = _asEllipse(pts);
    if (ellipse != null) {
      return ShapeElement.create(
        pageId: pageId,
        kind: ShapeKind.ellipse,
        x1: ellipse.left,
        y1: ellipse.top,
        x2: ellipse.right,
        y2: ellipse.bottom,
        colorValue: colorValue,
        strokeWidth: strokeWidth,
      );
    }
    return null;
  }

  static (Offset, Offset)? _asLine(List<Offset> pts, double length) {
    final a = pts.first;
    final b = pts.last;
    final span = (b - a).distance;
    if (span < 24) return null;
    if (span / length < 0.86) return null;
    var maxDev = 0.0;
    for (final p in pts) {
      maxDev = math.max(maxDev, _distToSegment(p, a, b));
    }
    if (maxDev > math.max(8.0, span * 0.06)) return null;
    return (a, b);
  }

  static ({Offset center, double radius})? _asCircle(List<Offset> pts) {
    final closed = (pts.first - pts.last).distance < 36;
    if (!closed) return null;
    var cx = 0.0, cy = 0.0;
    for (final p in pts) {
      cx += p.dx;
      cy += p.dy;
    }
    final center = Offset(cx / pts.length, cy / pts.length);
    var meanR = 0.0;
    for (final p in pts) {
      meanR += (p - center).distance;
    }
    meanR /= pts.length;
    if (meanR < 16) return null;
    var varR = 0.0;
    for (final p in pts) {
      final d = (p - center).distance - meanR;
      varR += d * d;
    }
    varR = math.sqrt(varR / pts.length);
    if (varR > meanR * 0.12) return null;
    return (center: center, radius: meanR);
  }

  static Rect? _asRect(List<Offset> pts) {
    final closed = (pts.first - pts.last).distance < 40;
    if (!closed) return null;
    var minX = pts.first.dx, maxX = pts.first.dx;
    var minY = pts.first.dy, maxY = pts.first.dy;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final box = Rect.fromLTRB(minX, minY, maxX, maxY);
    if (box.width < 24 || box.height < 24) return null;
    var edgeErr = 0.0;
    for (final p in pts) {
      final dx = math.min((p.dx - box.left).abs(), (p.dx - box.right).abs());
      final dy = math.min((p.dy - box.top).abs(), (p.dy - box.bottom).abs());
      edgeErr += math.min(dx, dy);
    }
    edgeErr /= pts.length;
    if (edgeErr > math.max(7.0, math.min(box.width, box.height) * 0.08)) {
      return null;
    }
    return box;
  }

  static Rect? _asEllipse(List<Offset> pts) {
    final closed = (pts.first - pts.last).distance < 40;
    if (!closed) return null;
    var minX = pts.first.dx, maxX = pts.first.dx;
    var minY = pts.first.dy, maxY = pts.first.dy;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final box = Rect.fromLTRB(minX, minY, maxX, maxY);
    if (box.width < 28 || box.height < 28) return null;
    final rx = box.width / 2;
    final ry = box.height / 2;
    if ((rx - ry).abs() / math.max(rx, ry) < 0.12) return null;
    final c = box.center;
    var err = 0.0;
    for (final p in pts) {
      final nx = (p.dx - c.dx) / rx;
      final ny = (p.dy - c.dy) / ry;
      err += (nx * nx + ny * ny - 1).abs();
    }
    err /= pts.length;
    if (err > 0.22) return null;
    return box;
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-6) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }
}
