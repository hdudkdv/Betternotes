import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/editor/domain/geometry_guides.dart';

void main() {
  test('ruler snap locks to 15 degree steps', () {
    const origin = Offset.zero;
    // ~10° should snap to 15°
    final snapped = snapRulerEndpoint(origin, const Offset(100, 17.6));
    final angle = snapped.direction * 180 / 3.1415926535;
    expect(angle, closeTo(15, 0.5));
    expect(snapped.distance, closeTo(101.5, 2));
  });
}
