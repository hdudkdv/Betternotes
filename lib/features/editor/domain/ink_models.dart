import 'dart:ui';

import 'package:equatable/equatable.dart';

enum InkTool {
  none,
  pen,
  pencil,
  fountain,
  marker,
  eraser,
  lasso,
  text,
  shape,

  /// Kept for older sessions; prefer [DrawingGuide.ruler].
  ruler,

  /// Kept for older sessions; prefer [DrawingGuide.compass].
  compass,
  image,
}

/// Straight / circular drawing aids that work together with a pen tool.
enum DrawingGuide { none, ruler, compass }

/// Stroke pattern for pens / markers (pencil stays textured).
enum StrokeStyle { solid, dashed, dotted, dashDot }

extension StrokeStyleX on StrokeStyle {
  static StrokeStyle fromName(String? name) {
    for (final value in StrokeStyle.values) {
      if (value.name == name) return value;
    }
    return StrokeStyle.solid;
  }

  /// Dash / gap lengths in page units, or null for a continuous stroke.
  List<double>? dashPattern(double width) {
    final w = width.clamp(0.8, 40.0);
    switch (this) {
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
}

extension InkToolX on InkTool {
  /// Freehand ink tools that go through begin/append/end stroke.
  bool get isFreehand =>
      this == InkTool.pen ||
      this == InkTool.pencil ||
      this == InkTool.fountain ||
      this == InkTool.marker;

  bool get usesPressureWidth => this == InkTool.fountain;

  bool get usesPressureOpacity => this == InkTool.pencil;

  bool get isGeometryGuide =>
      this == InkTool.ruler || this == InkTool.compass || this == InkTool.shape;
}

enum InteractionMode { edit, read }

/// GoodNotes-style eraser behaviour.
enum EraserMode {
  /// Delete the entire stroke.
  stroke,

  /// Delete a contiguous segment around the contact point.
  section,

  /// Delete only ink under the eraser tip (splits strokes).
  precise,
}

/// Page content the eraser or lasso may affect.
enum ContentKind { pen, pencil, marker, shapes, text, images }

/// Ink kinds the tools currently touch (matches previous behaviour).
const kDefaultContentTargets = {
  ContentKind.pen,
  ContentKind.pencil,
  ContentKind.marker,
};

bool matchesContentFilter(InkStroke stroke, Set<ContentKind> kinds) {
  switch (stroke.tool) {
    case InkTool.pen:
    case InkTool.fountain:
      return kinds.contains(ContentKind.pen);
    case InkTool.pencil:
      return kinds.contains(ContentKind.pencil);
    case InkTool.marker:
      return kinds.contains(ContentKind.marker);
    default:
      return false;
  }
}

bool pointInPolygon(Offset point, List<Offset> polygon) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];
    final intersect =
        ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx <
            (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy + 0.00001) +
                pi.dx);
    if (intersect) inside = !inside;
  }
  return inside;
}

bool rectIntersectsPolygon(Rect rect, List<Offset> polygon) {
  if (polygon.length < 3 || rect.isEmpty) return false;
  const samples = 5;
  final points = <Offset>[
    rect.center,
    rect.topLeft,
    rect.topRight,
    rect.bottomLeft,
    rect.bottomRight,
  ];
  for (var i = 0; i < samples; i++) {
    if (pointInPolygon(points[i], polygon)) return true;
  }
  for (final p in polygon) {
    if (rect.contains(p)) return true;
  }
  return false;
}

enum PageTemplate { blank, lined, grid }

class StrokePoint extends Equatable {
  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.t = 0,
  });

  final double x;
  final double y;
  final double pressure;
  final int t;

  Offset get offset => Offset(x, y);

  StrokePoint copyWith({double? x, double? y, double? pressure, int? t}) {
    return StrokePoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      t: t ?? this.t,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure, 't': t};

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['p'] as num?)?.toDouble() ?? 0.5,
      t: (json['t'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [x, y, pressure, t];
}

class InkStroke extends Equatable {
  const InkStroke({
    required this.id,
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.points,
    this.style = StrokeStyle.solid,
  });

  final String id;
  final InkTool tool;
  final int colorValue;
  final double width;
  final List<StrokePoint> points;
  final StrokeStyle style;

  Color get color => Color(colorValue);

  bool get isMarker => tool == InkTool.marker;
  bool get isPencil => tool == InkTool.pencil;
  bool get isFountain => tool == InkTool.fountain;

  /// Max visual width used for culling / hit padding.
  double get paintWidth {
    if (isFountain) return width * 1.45;
    return width;
  }

  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    var minX = points.first.x;
    var maxX = points.first.x;
    var minY = points.first.y;
    var maxY = points.first.y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final pad = paintWidth;
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  /// True only when [point] is within [tolerance] of the polyline itself.
  /// The bounding box is a cull, never a hit — a diagonal stroke must not
  /// erase when the tip is merely inside the rectangle around the line.
  bool hitsPoint(
    Offset point, {
    double tolerance = 0,
    bool includeStrokeWidth = true,
  }) {
    final raw = tolerance + (includeStrokeWidth ? paintWidth / 2 : 0);
    final hitR = raw < 0.75 ? 0.75 : raw;
    if (!boundingBox.inflate(hitR).contains(point)) return false;
    if (points.length == 1) {
      return (points.first.offset - point).distance <= hitR;
    }
    for (var i = 0; i < points.length - 1; i++) {
      if (_distanceToSegment(point, points[i].offset, points[i + 1].offset) <=
          hitR) {
        return true;
      }
    }
    return false;
  }

  bool intersectsPolygon(List<Offset> polygon) {
    if (polygon.length < 3) return false;
    for (final p in points) {
      if (pointInPolygon(p.offset, polygon)) return true;
    }
    return false;
  }

  InkStroke translated(Offset delta) {
    return InkStroke(
      id: id,
      tool: tool,
      colorValue: colorValue,
      width: width,
      style: style,
      points: [
        for (final p in points)
          StrokePoint(
            x: p.x + delta.dx,
            y: p.y + delta.dy,
            pressure: p.pressure,
            t: p.t,
          ),
      ],
    );
  }

  InkStroke copyWith({
    List<StrokePoint>? points,
    String? id,
    StrokeStyle? style,
  }) {
    return InkStroke(
      id: id ?? this.id,
      tool: tool,
      colorValue: colorValue,
      width: width,
      style: style ?? this.style,
      points: points ?? this.points,
    );
  }

  /// Removes ink under the tip and returns leftover stroke segments.
  List<InkStroke> erasePrecise(
    Offset center,
    double radius, {
    required String Function() newId,
  }) {
    if (points.isEmpty) return const [];
    final keep = List<bool>.filled(points.length, true);
    final hitR = radius < 0.6 ? 0.6 : radius;
    var anyRemoved = false;
    for (var i = 0; i < points.length; i++) {
      if ((points[i].offset - center).distance <= hitR) {
        keep[i] = false;
        anyRemoved = true;
      }
    }
    for (var i = 0; i < points.length - 1; i++) {
      if (_distanceToSegment(center, points[i].offset, points[i + 1].offset) <=
          hitR) {
        keep[i] = false;
        keep[i + 1] = false;
        anyRemoved = true;
      }
    }
    if (!anyRemoved) return [this];

    final result = <InkStroke>[];
    var buffer = <StrokePoint>[];
    void flush() {
      if (buffer.length >= 2) {
        result.add(copyWith(id: newId(), points: List.of(buffer)));
      } else if (buffer.length == 1 && points.length == 1) {
        result.add(copyWith(id: newId(), points: List.of(buffer)));
      }
      buffer = [];
    }

    for (var i = 0; i < points.length; i++) {
      if (keep[i]) {
        buffer.add(points[i]);
      } else {
        flush();
      }
    }
    flush();
    return result;
  }

  /// Removes a contiguous section around the nearest hit.
  List<InkStroke> eraseSection(
    Offset center, {
    required double radius,
    required String Function() newId,
  }) {
    if (points.isEmpty) return const [];
    final hitR = radius + width / 2;
    var bestI = -1;
    var bestD = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = (points[i].offset - center).distance;
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    for (var i = 0; i < points.length - 1; i++) {
      final d = _distanceToSegment(
        center,
        points[i].offset,
        points[i + 1].offset,
      );
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestD > hitR) return [this];

    bool inBand(int i) {
      if ((points[i].offset - center).distance <= hitR) return true;
      if (i > 0 &&
          _distanceToSegment(center, points[i - 1].offset, points[i].offset) <=
              hitR) {
        return true;
      }
      if (i < points.length - 1 &&
          _distanceToSegment(center, points[i].offset, points[i + 1].offset) <=
              hitR) {
        return true;
      }
      return false;
    }

    var start = bestI;
    var end = bestI;
    while (start > 0 && inBand(start - 1)) {
      start--;
    }
    while (end < points.length - 1 && inBand(end + 1)) {
      end++;
    }
    final result = <InkStroke>[];
    if (start >= 2) {
      result.add(copyWith(id: newId(), points: points.sublist(0, start)));
    }
    if (end + 1 <= points.length - 2) {
      result.add(copyWith(id: newId(), points: points.sublist(end + 1)));
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tool': tool.name,
    'color': colorValue,
    'width': width,
    'style': style.name,
    'points': points.map((p) => p.toJson()).toList(),
  };

  factory InkStroke.fromJson(Map<String, dynamic> json) {
    return InkStroke(
      id: json['id'] as String,
      tool: InkTool.values.firstWhere(
        (t) => t.name == json['tool'],
        orElse: () => InkTool.pen,
      ),
      colorValue: json['color'] as int,
      width: (json['width'] as num).toDouble(),
      style: StrokeStyle.values.firstWhere(
        (s) => s.name == (json['style'] as String? ?? ''),
        orElse: () => StrokeStyle.solid,
      ),
      points: [
        for (final p in (json['points'] as List))
          StrokePoint.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
    );
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  @override
  List<Object?> get props => [id, tool, colorValue, width, style, points];
}
