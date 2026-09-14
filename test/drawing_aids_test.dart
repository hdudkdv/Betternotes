import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/editor/domain/drawing_aids.dart';

void main() {
  test('ruler defaults to the lower third when no viewport center is given', () {
    const page = Size(400, 800);
    final aid = RulerAid.defaults(page);
    expect(aid.center.dx, 200);
    expect(aid.center.dy, 600);
  });

  test('ruler spawn uses the visible viewport center', () {
    const page = Size(400, 800);
    final aids = DrawingAidsController();
    aids.toggleRuler(page, visibleCenter: const Offset(180, 520));
    expect(aids.ruler, isNotNull);
    expect(aids.ruler!.center, const Offset(180, 520));
  });
}
