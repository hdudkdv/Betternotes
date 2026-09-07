import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/lasso_transform.dart';

void main() {
  test('lassoScaleFromHandleDelta grows uniformly from the corner', () {
    const bounds = Rect.fromLTWH(10, 20, 100, 50);
    expect(lassoScaleFromHandleDelta(bounds, Offset.zero), closeTo(1, 0.001));
    expect(
      lassoScaleFromHandleDelta(bounds, const Offset(100, 50)),
      closeTo(2, 0.02),
    );
    expect(
      lassoScaleFromHandleDelta(bounds, const Offset(-50, -25)),
      lessThan(1),
    );
  });

  test('scaleShape keeps a circle centered relative to the origin', () {
    final circle = ShapeElement.create(
      pageId: 'p',
      kind: ShapeKind.circle,
      x1: 40,
      y1: 40,
      x2: 50,
      y2: 40,
    );
    final scaled = scaleShape(circle, Offset.zero, 2);
    expect(scaled.x1, closeTo(80, 0.01));
    expect(scaled.y1, closeTo(80, 0.01));
    expect(scaled.x2, closeTo(100, 0.01));
  });

  test('scaleTextBlock grows free text and its type size', () {
    const block = TextBlock(
      id: 't',
      pageId: 'p',
      x: 10,
      y: 20,
      width: 80,
      height: 40,
      layoutMode: TextLayoutMode.free,
      spans: [TextSpanStyle(text: 'Hi', fontSize: 16)],
    );
    final scaled = scaleTextBlock(block, Offset.zero, 2);
    expect(scaled.x, 20);
    expect(scaled.y, 40);
    expect(scaled.width, 160);
    expect(scaled.spans.single.fontSize, 32);
  });
}
