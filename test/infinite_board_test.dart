import 'package:betternotes/features/editor/presentation/widgets/ink_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infinite board starts at the viewport, not a preset size', () {
    final size = growInfiniteBoard(
      current: Size.zero,
      viewport: const Size(400, 800),
      contentBounds: const [],
    );
    expect(size, const Size(400, 800));
  });

  test('writing past the edge grows the page', () {
    final grown = growInfiniteBoard(
      current: const Size(400, 800),
      viewport: const Size(400, 800),
      contentBounds: const [Rect.fromLTWH(350, 790, 20, 20)],
      livePoint: const Offset(420, 860),
      padding: 160,
    );
    expect(grown.width, greaterThan(400));
    expect(grown.height, greaterThan(800));
    expect(grown.width, 420 + 160);
    expect(grown.height, 860 + 160);
  });

  test('the board never shrinks after ink is erased from the far edge', () {
    final grown = growInfiniteBoard(
      current: const Size(900, 1200),
      viewport: const Size(400, 800),
      contentBounds: const [],
    );
    expect(grown, const Size(900, 1200));
  });
}
