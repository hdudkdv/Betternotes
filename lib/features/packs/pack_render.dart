import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

abstract final class PackRender {
  static Future<Uint8List?> card({
    required String title,
    required String body,
    Color background = const Color(0xFF111111),
    Color foreground = const Color(0xFF39FF14),
    int width = 720,
    int height = 420,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        const Radius.circular(16),
      ),
      Paint()..color = background,
    );
    void text(String value, Offset at, {double size = 16, FontWeight? w}) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: size, fontWeight: w ?? FontWeight.w500),
      )..pushStyle(ui.TextStyle(color: foreground))
        ..addText(value);
      final p = builder.build()
        ..layout(ui.ParagraphConstraints(width: width - 48.0));
      canvas.drawParagraph(p, at);
    }

    text(title, const Offset(24, 20), size: 20, w: FontWeight.w800);
    text(body, const Offset(24, 56), size: 15);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes?.buffer.asUint8List();
  }
}
