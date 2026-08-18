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
    StrokeStyle style = StrokeStyle.solid,
    bool allowImperfectLine = false,
    bool loose = false,
  }) {
    loose = loose || allowImperfectLine;
    if (points.length < 4) return null;
    final raw = [for (final p in points) p.offset];
    final pts = _resample(raw, loose ? 64 : 48);
    var length = 0.0;
    for (var i = 1; i < pts.length; i++) {
      length += (pts[i] - pts[i - 1]).distance;
    }
    if (length < (loose ? 16 : 24)) return null;

    final closed = _isClosed(pts, length, loose: loose);

    final circle = _asCircle(pts, length, closed: closed, loose: loose);
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
        style: style.name,
      );
    }

    final rect = _asRect(pts, length, closed: closed, loose: loose);
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
        style: style.name,
      );
    }

    final ellipse = _asEllipse(pts, length, closed: closed, loose: loose);
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
        style: style.name,
      );
    }

    final line = _asLine(pts, length, loose: loose);
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
        style: style.name,
      );
    }
    return null;
  }

  static bool _isClosed(
    List<Offset> pts,
    double length, {
    required bool loose,
  }) {
    final gap = (pts.first - pts.last).distance;
    if (gap < math.max(loose ? 48.0 : 28.0, length * (loose ? 0.32 : 0.16))) {
      return true;
    }
    final window = math.max(4, pts.length ~/ (loose ? 4 : 6));
    for (var i = pts.length - window; i < pts.length; i++) {
      if ((pts[i] - pts.first).distance <
          math.max(loose ? 36.0 : 22.0, length * (loose ? 0.22 : 0.12))) {
        return true;
      }
    }
    return false;
  }

  static (Offset, Offset) _lineEnds(List<Offset> pts, {required bool loose}) {
    if (!loose || pts.length < 8) return (pts.first, pts.last);
    final i0 = (pts.length * 0.08).floor().clamp(0, pts.length - 2);
    final i1 = (pts.length * 0.92).ceil().clamp(i0 + 1, pts.length - 1);
    return (pts[i0], pts[i1]);
  }

  static (Offset, Offset)? _asLine(
    List<Offset> pts,
    double length, {
    required bool loose,
  }) {
    var ends = _lineEnds(pts, loose: loose);
    var a = ends.$1;
    var b = ends.$2;
    var span = (b - a).distance;
    if (span < (loose ? 18 : 28)) return null;
    final straight = span / length;
    if (straight < (loose ? 0.58 : 0.88)) return null;
    var maxDev = 0.0;
    for (final p in pts) {
      maxDev = math.max(maxDev, _distToSegment(p, a, b));
    }
    final limit = math.max(loose ? 22.0 : 7.0, span * (loose ? 0.18 : 0.055));
    if (maxDev > limit) return null;

    final dx = (b.dx - a.dx).abs();
    final dy = (b.dy - a.dy).abs();
    final snap = loose ? 0.22 : 0.12;
    if (dy < dx * snap) {
      final y = (a.dy + b.dy) / 2;
      a = Offset(a.dx, y);
      b = Offset(b.dx, y);
    } else if (dx < dy * snap) {
      final x = (a.dx + b.dx) / 2;
      a = Offset(x, a.dy);
      b = Offset(x, b.dy);
    }
    return (a, b);
  }

  static ({Offset center, double radius})? _asCircle(
    List<Offset> pts,
    double length, {
    required bool closed,
    required bool loose,
  }) {
    if (!closed && length < (loose ? 48 : 80)) return null;
    final box = _bounds(pts);
    final aspect =
        (box.width - box.height).abs() / math.max(box.width, box.height);
    if (aspect > (loose ? 0.36 : 0.18)) return null;
    var cx = 0.0, cy = 0.0;
    for (final p in pts) {
      cx += p.dx;
      cy += p.dy;
    }
    var center = Offset(cx / pts.length, cy / pts.length);
    var meanR = 0.0;
    for (final p in pts) {
      meanR += (p - center).distance;
    }
    meanR /= pts.length;
    if (meanR < (loose ? 10 : 14)) return null;
    center = box.center;
    meanR = math.min(box.width, box.height) / 2;

    var varR = 0.0;
    for (final p in pts) {
      final d = (p - center).distance - meanR;
      varR += d * d;
    }
    varR = math.sqrt(varR / pts.length);
    if (varR > meanR * (loose ? 0.38 : 0.20)) return null;

    final expected = 2 * math.pi * meanR;
    final circErr = (length - expected).abs() / expected;
    if (!closed && circErr > (loose ? 0.48 : 0.28)) return null;
    if (closed && circErr > (loose ? 0.58 : 0.38)) return null;
    return (center: center, radius: meanR);
  }

  static Rect? _asRect(
    List<Offset> pts,
    double length, {
    required bool closed,
    required bool loose,
  }) {
    if (!closed && !loose) return null;
    final box = _bounds(pts);
    if (box.width < (loose ? 16 : 22) || box.height < (loose ? 16 : 22)) {
      return null;
    }
    final skinny =
        math.min(box.width, box.height) / math.max(box.width, box.height);
    if (skinny < (loose ? 0.28 : 0.18)) return null;

    final corners = _sharpCorners(pts, loose: loose);
    if (corners.length >= (loose ? 2 : 3) && corners.length <= 8) {
      var right = 0;
      for (var i = 0; i < corners.length; i++) {
        final prev = corners[(i - 1 + corners.length) % corners.length];
        final curr = corners[i];
        final next = corners[(i + 1) % corners.length];
        final a = prev - curr;
        final b = next - curr;
        final den = a.distance * b.distance;
        if (den < 1e-4) continue;
        final cos = ((a.dx * b.dx + a.dy * b.dy) / den).clamp(-1.0, 1.0);
        final deg = math.acos(cos) * 180 / math.pi;
        if (deg > (loose ? 48.0 : 65.0) && deg < (loose ? 140.0 : 115.0)) {
          right++;
        }
      }
      if (right >= (loose ? 2 : 3)) return box;
    }

    var edgeErr = 0.0;
    for (final p in pts) {
      final dx = math.min((p.dx - box.left).abs(), (p.dx - box.right).abs());
      final dy = math.min((p.dy - box.top).abs(), (p.dy - box.bottom).abs());
      edgeErr += math.min(dx, dy);
    }
    edgeErr /= pts.length;
    final limit = math.max(
      loose ? 16.0 : 10.0,
      math.min(box.width, box.height) * (loose ? 0.22 : 0.12),
    );
    if (edgeErr > limit) return null;
    if (!closed && loose && edgeErr > limit * 0.85) return null;
    return box;
  }

  static Rect? _asEllipse(
    List<Offset> pts,
    double length, {
    required bool closed,
    required bool loose,
  }) {
    if (!closed && !loose) return null;
    final box = _bounds(pts);
    if (box.width < (loose ? 18 : 26) || box.height < (loose ? 18 : 26)) {
      return null;
    }
    final skinny =
        math.min(box.width, box.height) / math.max(box.width, box.height);
    if (skinny < (loose ? 0.28 : 0.18)) return null;
    final rx = box.width / 2;
    final ry = box.height / 2;
    if ((rx - ry).abs() / math.max(rx, ry) < (loose ? 0.06 : 0.10)) {
      return null;
    }
    final c = box.center;
    var err = 0.0;
    for (final p in pts) {
      final nx = (p.dx - c.dx) / rx;
      final ny = (p.dy - c.dy) / ry;
      err += (nx * nx + ny * ny - 1).abs();
    }
    err /= pts.length;
    if (err > (loose ? 0.58 : 0.32)) return null;
    return box;
  }

  static List<Offset> _sharpCorners(List<Offset> pts, {bool loose = false}) {
    if (pts.length < 8) return const [];
    final corners = <Offset>[];
    const window = 3;
    for (var i = window; i < pts.length - window; i++) {
      final a = pts[i] - pts[i - window];
      final b = pts[i + window] - pts[i];
      final den = a.distance * b.distance;
      if (den < 4) continue;
      final cos = ((a.dx * b.dx + a.dy * b.dy) / den).clamp(-1.0, 1.0);
      final deg = math.acos(cos) * 180 / math.pi;
      if (deg < (loose ? 32 : 48)) continue;
      if (corners.isNotEmpty && (corners.last - pts[i]).distance < 16) {
        corners[corners.length - 1] = pts[i];
      } else {
        corners.add(pts[i]);
      }
    }
    return corners;
  }

  static Rect _bounds(List<Offset> pts) {
    var minX = pts.first.dx, maxX = pts.first.dx;
    var minY = pts.first.dy, maxY = pts.first.dy;
    for (final p in pts) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static List<Offset> _resample(List<Offset> pts, int count) {
    if (pts.length <= 2) return pts;
    var length = 0.0;
    for (var i = 1; i < pts.length; i++) {
      length += (pts[i] - pts[i - 1]).distance;
    }
    if (length < 1) return pts;
    final step = length / (count - 1);
    final out = <Offset>[pts.first];
    var passed = 0.0;
    var target = step;
    for (var i = 1; i < pts.length && out.length < count - 1; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final seg = (b - a).distance;
      if (seg < 1e-6) continue;
      while (passed + seg >= target && out.length < count - 1) {
        final t = ((target - passed) / seg).clamp(0.0, 1.0);
        out.add(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t));
        target += step;
      }
      passed += seg;
    }
    out.add(pts.last);
    return out;
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
