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
    required this.center,
    required this.angle,
    required this.lengthPt,
    this.fixed = false,
  });

  factory RulerAid.defaults(Size pageSize) {
    return RulerAid(
      center: Offset(pageSize.width * 0.5, pageSize.height * 0.45),
      angle: 0,
      lengthPt: PageUnits.cmToPt(12),
    );
  }

  /// Midpoint of the ruler in page coordinates.
  final Offset center;

  /// Radians; 0 = horizontal along +X.
  final double angle;

  /// Full length in PDF points.
  final double lengthPt;
  final bool fixed;

  Offset get direction => Offset(math.cos(angle), math.sin(angle));

  Offset get normal => Offset(-direction.dy, direction.dx);

  Offset get start => center - direction * (lengthPt / 2);
  Offset get end => center + direction * (lengthPt / 2);

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
    Offset? center,
    double? angle,
    double? lengthPt,
    bool? fixed,
  }) {
    return RulerAid(
      center: center ?? this.center,
      angle: angle ?? this.angle,
      lengthPt: lengthPt ?? this.lengthPt,
      fixed: fixed ?? this.fixed,
    );
  }
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
