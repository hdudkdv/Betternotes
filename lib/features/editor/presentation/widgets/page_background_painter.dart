import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/ink_models.dart';

class PageBackgroundPainter extends CustomPainter {
  PageBackgroundPainter({
    required this.template,
    this.pdfImage,
    this.paper,
    this.visibleWorldRect,
    this.infinite = false,
  });

  final PageTemplate template;
  final ui.Image? pdfImage;
  final PaperTemplate? paper;
  final Rect? visibleWorldRect;
  final bool infinite;

  @override
  void paint(Canvas canvas, Size size) {
    final pageSize = size;
    final fullRect = Offset.zero & pageSize;

    final bgColor = paper != null
        ? Color(paper!.backgroundColor)
        : const Color(0xFFFFFBF5);
    canvas.drawRect(fullRect, Paint()..color = bgColor);

    if (pdfImage != null) {
      paintImage(
        canvas: canvas,
        rect: fullRect,
        image: pdfImage!,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      );
      return;
    }

    // Finite notebook pages are always rendered in full. Their transformed
    // viewport is not a reliable paint clip during a pan and would otherwise
    // make ruled/grid lines disappear temporarily.
    final clip = infinite
        ? (visibleWorldRect ?? fullRect).intersect(fullRect).inflate(64)
        : fullRect;
    if (clip.isEmpty) return;

    final style = paper?.style ?? template.name;
    final linePaint = Paint()
      ..color = Color(paper?.lineColor ?? 0xFFD7D2C8)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.butt;

    switch (style) {
      case 'blank':
        break;
      case 'custom':
        _paintCustom(canvas, pageSize, clip, linePaint);
        break;
      case 'lined':
        _paintLined(canvas, pageSize, clip, linePaint);
        break;
      case 'grid':
        _paintGrid(canvas, pageSize, clip, linePaint);
        break;
      case 'dotted':
        _paintDotted(canvas, pageSize, clip, linePaint);
        break;
      default:
        break;
    }

    if (!infinite) {
      canvas.drawRect(
        fullRect.deflate(0.5),
        Paint()
          ..color = const Color(0xFFE6E0D4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintCustom(Canvas canvas, Size pageSize, Rect clip, Paint linePaint) {
    final hs = paper?.horizontalLines ?? const <double>[];
    final vs = paper?.verticalLines ?? const <double>[];
    for (final y in hs) {
      if (y < clip.top - 1 || y > clip.bottom + 1) continue;
      // Edge-to-edge.
      canvas.drawLine(Offset(0, y), Offset(pageSize.width, y), linePaint);
    }
    final marginPaint = Paint()
      ..color = const Color(0xFFE8A0A0)
      ..strokeWidth = 1;
    for (final x in vs) {
      if (x < clip.left - 1 || x > clip.right + 1) continue;
      canvas.drawLine(Offset(x, 0), Offset(x, pageSize.height), marginPaint);
    }
  }

  void _paintLined(Canvas canvas, Size pageSize, Rect clip, Paint linePaint) {
    final spacing = paper?.lineSpacing ?? 28.0;
    final marginTop = paper?.marginTop ?? 48.0;
    final marginLeft = paper?.marginLeft ?? 72.0;

    linePaint
      ..isAntiAlias = true
      ..strokeWidth = 1
      ..filterQuality = FilterQuality.none;

    final yStart = infinite
        ? ((clip.top / spacing).floor() * spacing)
        : marginTop;
    final yEnd = infinite ? clip.bottom : pageSize.height;

    for (var y = yStart; y <= yEnd + 0.01; y += spacing) {
      if (!infinite && y < marginTop - 0.01) continue;
      if (y < clip.top - 1 || y > clip.bottom + 1) continue;
      final yy = infinite ? y : y.roundToDouble();
      canvas.drawLine(Offset(0, yy), Offset(pageSize.width, yy), linePaint);
    }

    if (!infinite ||
        clip.overlaps(Rect.fromLTWH(marginLeft - 1, 0, 2, pageSize.height))) {
      final marginPaint = Paint()
        ..color = const Color(0xFFE8A0A0)
        ..strokeWidth = 1
        ..isAntiAlias = true;
      final xx = infinite ? marginLeft : marginLeft.roundToDouble();
      canvas.drawLine(
        Offset(xx, 0),
        Offset(xx, pageSize.height),
        marginPaint,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size pageSize, Rect clip, Paint linePaint) {
    final spacing = paper?.gridSize ?? 24.0;
    linePaint
      ..isAntiAlias = true
      ..strokeWidth = 1
      ..filterQuality = FilterQuality.none;
    // Start at 0 so the grid seals against every edge.
    final xStart = infinite ? ((clip.left / spacing).floor() * spacing) : 0.0;
    final yStart = infinite ? ((clip.top / spacing).floor() * spacing) : 0.0;
    final xEnd = infinite ? clip.right : pageSize.width;
    final yEnd = infinite ? clip.bottom : pageSize.height;

    for (var x = xStart; x <= xEnd + 0.01; x += spacing) {
      if (x < clip.left - 1 || x > clip.right + 1) continue;
      final xx = infinite ? x : x.roundToDouble();
      canvas.drawLine(Offset(xx, 0), Offset(xx, pageSize.height), linePaint);
    }
    for (var y = yStart; y <= yEnd + 0.01; y += spacing) {
      if (y < clip.top - 1 || y > clip.bottom + 1) continue;
      final yy = infinite ? y : y.roundToDouble();
      canvas.drawLine(Offset(0, yy), Offset(pageSize.width, yy), linePaint);
    }
  }

  void _paintDotted(Canvas canvas, Size pageSize, Rect clip, Paint linePaint) {
    final spacing = paper?.gridSize ?? 16.0;
    final dot = Paint()
      ..color = linePaint.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final xStart = infinite ? ((clip.left / spacing).floor() * spacing) : spacing;
    final yStart = infinite ? ((clip.top / spacing).floor() * spacing) : spacing;
    final xEnd = infinite ? clip.right : pageSize.width - 8;
    final yEnd = infinite ? clip.bottom : pageSize.height - 8;
    for (var x = xStart; x <= xEnd + 0.01; x += spacing) {
      for (var y = yStart; y <= yEnd + 0.01; y += spacing) {
        if (x < clip.left - 2 || x > clip.right + 2) continue;
        if (y < clip.top - 2 || y > clip.bottom + 2) continue;
        canvas.drawCircle(Offset(x, y), 1.15, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PageBackgroundPainter oldDelegate) {
    return oldDelegate.template != template ||
        oldDelegate.pdfImage != pdfImage ||
        oldDelegate.paper != paper ||
        oldDelegate.visibleWorldRect != visibleWorldRect ||
        oldDelegate.infinite != infinite;
  }
}
