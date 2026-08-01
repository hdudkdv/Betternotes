import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../shared/utils/page_units.dart';

/// Interactive ruler / compass overlays that persist across page changes when
/// fixed, and live in page coordinates so zoom/pan keeps them on the paper.
class DrawingAidsController extends ChangeNotifier {
  RulerAid? ruler;
  CompassAid? compass;

  bool get hasRuler => ruler != null;
  bool get hasCompass => compass != null;

  void toggleRuler(Size pageSize) {
    if (ruler != null) {
      ruler = null;
    } else {
      compass = null;
      ruler = RulerAid.defaults(pageSize);
    }
    notifyListeners();
  }

  void toggleCompass(Size pageSize) {
    if (compass != null) {
      compass = null;
    } else {
      ruler = null;
      compass = CompassAid.defaults(pageSize);
    }
    notifyListeners();
  }

  void clearUnfixed() {
    var changed = false;
    if (ruler != null && !ruler!.fixed) {
      ruler = null;
      changed = true;
    }
    if (compass != null && !compass!.fixed) {
      compass = null;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void updateRuler(RulerAid value) {
    ruler = value;
    notifyListeners();
  }

  void updateCompass(CompassAid value) {
    compass = value;
    notifyListeners();
  }

  void setRulerFixed(bool fixed) {
    final r = ruler;
    if (r == null) return;
    ruler = r.copyWith(fixed: fixed);
    notifyListeners();
  }

  void setCompassFixed(bool fixed) {
    final c = compass;
    if (c == null) return;
    compass = c.copyWith(fixed: fixed);
    notifyListeners();
  }

  /// Snap a freehand sample onto the active aid, if any.
  Offset constrainPoint(Offset point) {
    final r = ruler;
    if (r != null) return r.project(point);
    final c = compass;
    if (c != null &&
        c.center != null &&
        (c.phase == CompassPhase.ready || c.phase == CompassPhase.adjusting)) {
      return c.project(point);
    }
    return point;
  }

  /// Non-null only while an aid should constrain ink.
  Offset Function(Offset)? get activeConstraint {
    if (ruler != null) return constrainPoint;
    final c = compass;
    if (c != null &&
        c.center != null &&
        (c.phase == CompassPhase.ready || c.phase == CompassPhase.adjusting)) {
      return constrainPoint;
    }
    return null;
  }
}

class RulerAid {
  const RulerAid({
    required this.pageSize,
    required this.center,
    required this.angle,
    this.fixed = false,
  });

  factory RulerAid.defaults(Size pageSize) {
    return RulerAid(
      pageSize: pageSize,
      center: Offset(pageSize.width * 0.5, pageSize.height * 0.42),
      angle: 0,
    );
  }

  /// Page the ruler spans edge-to-edge.
  final Size pageSize;

  /// Anchor on the infinite line (usually near the page center).
  final Offset center;

  /// Radians; 0 = horizontal along +X.
  final double angle;
  final bool fixed;

  Offset get direction => Offset(math.cos(angle), math.sin(angle));

  Offset get normal => Offset(-direction.dy, direction.dx);

  /// Endpoints clipped to the page rectangle (always edge → edge).
  (Offset, Offset) get span {
    final far = direction * (pageSize.width + pageSize.height + 4);
    return clipLineToRect(
      center - far,
      center + far,
      Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );
  }

  Offset get start => span.$1;
  Offset get end => span.$2;

  double get lengthPt => (end - start).distance;

  /// Edge the ink snaps to (bottom edge of the ruler body).
  static const double edgeOffset = 14;

  Offset get edgeStart => start - normal * edgeOffset;
  Offset get edgeEnd => end - normal * edgeOffset;

  /// Angle in degrees, normalized to (-90, 90] relative to the page X axis.
  double get inclinationDeg {
    var deg = angle * 180 / math.pi;
    while (deg > 90) {
      deg -= 180;
    }
    while (deg <= -90) {
      deg += 180;
    }
    return deg;
  }

  Offset project(Offset point) {
    final a = edgeStart;
    final ab = edgeEnd - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 < 1e-6) return a;
    var t = ((point.dx - a.dx) * ab.dx + (point.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    // Only magnetize when the tip is near the ruler edge.
    if ((proj - point).distance > 40) return point;
    return proj;
  }

  RulerAid copyWith({
    Size? pageSize,
    Offset? center,
    double? angle,
    bool? fixed,
  }) {
    return RulerAid(
      pageSize: pageSize ?? this.pageSize,
      center: center ?? this.center,
      angle: angle ?? this.angle,
      fixed: fixed ?? this.fixed,
    );
  }
}

/// Clip an infinite line segment to a rectangle; returns the two edge hits.
(Offset, Offset) clipLineToRect(Offset a, Offset b, Rect rect) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  var t0 = 0.0;
  var t1 = 1.0;

  bool clip(double p, double q) {
    if (p == 0) return q >= 0;
    final r = q / p;
    if (p < 0) {
      if (r > t1) return false;
      if (r > t0) t0 = r;
    } else {
      if (r < t0) return false;
      if (r < t1) t1 = r;
    }
    return true;
  }

  // Liang–Barsky against rect expanded slightly so we always hit edges.
  final r = rect.inflate(0.5);
  if (!clip(-dx, a.dx - r.left) ||
      !clip(dx, r.right - a.dx) ||
      !clip(-dy, a.dy - r.top) ||
      !clip(dy, r.bottom - a.dy)) {
    // Degenerate fallback: horizontal through center.
    return (Offset(r.left, a.dy.clamp(r.top, r.bottom)), Offset(r.right, a.dy.clamp(r.top, r.bottom)));
  }
  return (
    Offset(a.dx + t0 * dx, a.dy + t0 * dy),
    Offset(a.dx + t1 * dx, a.dy + t1 * dy),
  );
}

enum CompassPhase {
  /// Tap the page to set the pivot.
  placingCenter,

  /// Radius wheel / arm adjustment.
  adjusting,

  /// Ready — freehand ink snaps onto the circle.
  ready,
}

class CompassAid {
  const CompassAid({
    this.center,
    required this.radiusMm,
    this.armAngle = 0,
    this.phase = CompassPhase.placingCenter,
    this.fixed = false,
  });

  factory CompassAid.defaults(Size pageSize) {
    return CompassAid(
      center: null,
      radiusMm: 30,
      armAngle: -math.pi / 4,
      phase: CompassPhase.placingCenter,
    );
  }

  final Offset? center;
  final double radiusMm;
  final double armAngle;
  final CompassPhase phase;
  final bool fixed;

  double get radiusPt => PageUnits.mmToPt(radiusMm);

  Offset? get armTip {
    final c = center;
    if (c == null) return null;
    return c + Offset(math.cos(armAngle), math.sin(armAngle)) * radiusPt;
  }

  Offset project(Offset point) {
    final c = center;
    if (c == null) return point;
    final delta = point - c;
    final d = delta.distance;
    if (d < 0.5) {
      return c + Offset(math.cos(armAngle), math.sin(armAngle)) * radiusPt;
    }
    final onCircle = c + delta * (radiusPt / d);
    // Only magnetize near the circumference so free drawing elsewhere works.
    if ((onCircle - point).distance > 36) return point;
    return onCircle;
  }

  CompassAid copyWith({
    Offset? center,
    double? radiusMm,
    double? armAngle,
    CompassPhase? phase,
    bool? fixed,
    bool clearCenter = false,
  }) {
    return CompassAid(
      center: clearCenter ? null : (center ?? this.center),
      radiusMm: radiusMm ?? this.radiusMm,
      armAngle: armAngle ?? this.armAngle,
      phase: phase ?? this.phase,
      fixed: fixed ?? this.fixed,
    );
  }
}
