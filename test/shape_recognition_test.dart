import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/domain/shape_recognition.dart';

List<StrokePoint> _line(Offset a, Offset b, {int n = 20}) {
  return [
    for (var i = 0; i < n; i++)
      StrokePoint(
        x: a.dx + (b.dx - a.dx) * (i / (n - 1)),
        y: a.dy + (b.dy - a.dy) * (i / (n - 1)),
      ),
  ];
}

List<StrokePoint> _circle(Offset c, double r, {int n = 36}) {
  return [
    for (var i = 0; i <= n; i++)
      StrokePoint(
        x: c.dx + r * math.cos(i / n * math.pi * 2),
        y: c.dy + r * math.sin(i / n * math.pi * 2),
      ),
  ];
}

List<StrokePoint> _rect(Rect box, {int n = 10}) {
  final pts = <StrokePoint>[];
  void add(Offset a, Offset b) {
    for (var i = 0; i < n; i++) {
      pts.add(
        StrokePoint(
          x: a.dx + (b.dx - a.dx) * (i / n),
          y: a.dy + (b.dy - a.dy) * (i / n),
        ),
      );
    }
  }

  add(box.topLeft, box.topRight);
  add(box.topRight, box.bottomRight);
  add(box.bottomRight, box.bottomLeft);
  add(box.bottomLeft, box.topLeft);
  pts.add(StrokePoint(x: box.left, y: box.top));
  return pts;
}

void main() {
  test('recognizes a straight line', () {
    final shape = ShapeRecognition.recognize(
      _line(const Offset(20, 40), const Offset(180, 42)),
      pageId: 'p',
      colorValue: 0xFF000000,
      strokeWidth: 2,
    );
    expect(shape?.kind, ShapeKind.line);
  });

  test('recognizes a circle', () {
    final shape = ShapeRecognition.recognize(
      _circle(const Offset(120, 120), 50),
      pageId: 'p',
      colorValue: 0xFF000000,
      strokeWidth: 2,
    );
    expect(shape?.kind, ShapeKind.circle);
  });

  test('recognizes a rectangle', () {
    final shape = ShapeRecognition.recognize(
      _rect(const Rect.fromLTWH(40, 40, 120, 80)),
      pageId: 'p',
      colorValue: 0xFF000000,
      strokeWidth: 2,
    );
    expect(shape?.kind, ShapeKind.rect);
  });

  test('keeps the current stroke style on a recognized line', () {
    final shape = ShapeRecognition.recognize(
      _line(const Offset(20, 40), const Offset(180, 42)),
      pageId: 'p',
      colorValue: 0xFF000000,
      strokeWidth: 2,
      style: StrokeStyle.dashed,
    );
    expect(shape?.kind, ShapeKind.line);
    expect(shape?.style, StrokeStyle.dashed.name);
  });

  test('recognizes a wobbly line when loose', () {
    final pts = <StrokePoint>[];
    for (var i = 0; i < 24; i++) {
      final t = i / 23;
      pts.add(
        StrokePoint(x: 20 + 160 * t, y: 40 + math.sin(t * math.pi * 3) * 10),
      );
    }
    expect(
      ShapeRecognition.recognize(
        pts,
        pageId: 'p',
        colorValue: 0xFF000000,
        strokeWidth: 2,
      )?.kind,
      isNull,
    );
    expect(
      ShapeRecognition.recognize(
        pts,
        pageId: 'p',
        colorValue: 0xFF000000,
        strokeWidth: 2,
        loose: true,
      )?.kind,
      ShapeKind.line,
    );
  });

  test('recognizes an open messy circle when loose', () {
    final pts = <StrokePoint>[];
    for (var i = 0; i < 28; i++) {
      final t = i / 32 * math.pi * 2;
      final wobble = 1 + 0.12 * math.sin(t * 4);
      pts.add(
        StrokePoint(
          x: 120 + 48 * math.cos(t) * wobble,
          y: 120 + 44 * math.sin(t) * wobble,
        ),
      );
    }
    expect(
      ShapeRecognition.recognize(
        pts,
        pageId: 'p',
        colorValue: 0xFF000000,
        strokeWidth: 2,
        loose: true,
      )?.kind,
      anyOf(ShapeKind.circle, ShapeKind.ellipse),
    );
  });
}
