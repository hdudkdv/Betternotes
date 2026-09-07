import 'dart:ui';

import '../../../data/models/content_models.dart';

Offset scaleOffset(Offset point, Offset origin, double scale) {
  return Offset(
    origin.dx + (point.dx - origin.dx) * scale,
    origin.dy + (point.dy - origin.dy) * scale,
  );
}

ShapeElement scaleShape(ShapeElement shape, Offset origin, double scale) {
  final a = scaleOffset(Offset(shape.x1, shape.y1), origin, scale);
  final b = scaleOffset(Offset(shape.x2, shape.y2), origin, scale);
  return shape.copyWith(
    x1: a.dx,
    y1: a.dy,
    x2: b.dx,
    y2: b.dy,
    strokeWidth: (shape.strokeWidth * scale).clamp(0.4, 80.0),
  );
}

ImageElement scaleImage(ImageElement image, Offset origin, double scale) {
  final originPoint = scaleOffset(Offset(image.x, image.y), origin, scale);
  return image.copyWith(
    x: originPoint.dx,
    y: originPoint.dy,
    width: (image.width * scale).clamp(16.0, 4000.0),
    height: (image.height * scale).clamp(16.0, 4000.0),
  );
}

StickerElement scaleSticker(
  StickerElement sticker,
  Offset origin,
  double scale,
) {
  final originPoint = scaleOffset(Offset(sticker.x, sticker.y), origin, scale);
  return sticker.copyWith(
    x: originPoint.dx,
    y: originPoint.dy,
    width: (sticker.width * scale).clamp(16.0, 4000.0),
    height: (sticker.height * scale).clamp(16.0, 4000.0),
  );
}

TextBlock scaleTextBlock(TextBlock block, Offset origin, double scale) {
  final spans = [
    for (final span in block.spans)
      span.copyWith(fontSize: (span.fontSize * scale).clamp(6.0, 200.0)),
  ];
  if (block.layoutMode == TextLayoutMode.lineBound) {
    return block.copyWith(
      y: origin.dy + (block.y - origin.dy) * scale,
      spans: spans,
    );
  }
  final originPoint = scaleOffset(Offset(block.x, block.y), origin, scale);
  return block.copyWith(
    x: originPoint.dx,
    y: originPoint.dy,
    width: (block.width * scale).clamp(24.0, 4000.0),
    height: (block.height * scale).clamp(18.0, 4000.0),
    spans: spans,
  );
}

/// Uniform scale from the bottom-right corner of [bounds].
double lassoScaleFromHandleDelta(Rect bounds, Offset delta) {
  final start = Offset(bounds.width, bounds.height);
  final length = start.distance;
  if (length < 1) return 1;
  final next = Offset(
    (bounds.width + delta.dx).clamp(8.0, 8000.0),
    (bounds.height + delta.dy).clamp(8.0, 8000.0),
  );
  return (next.distance / length).clamp(0.15, 8.0);
}
