import 'dart:math' as math;
import 'dart:ui';

/// Snaps a free endpoint onto the nearest [stepDeg] angle from [origin].
Offset snapRulerEndpoint(Offset origin, Offset pointer, {double stepDeg = 15}) {
  final delta = pointer - origin;
  final length = delta.distance;
  if (length < 0.5) return pointer;
  final angle = math.atan2(delta.dy, delta.dx);
  final step = stepDeg * math.pi / 180;
  final snapped = (angle / step).round() * step;
  return origin + Offset(math.cos(snapped), math.sin(snapped)) * length;
}
