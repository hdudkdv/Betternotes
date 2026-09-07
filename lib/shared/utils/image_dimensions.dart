import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'file_store.dart';

Future<Uint8List> readLocalImageBytes(String path) async {
  if (path.startsWith('memory:')) {
    return base64Decode(path.substring(7));
  }
  return createFileStore().readBytes(path);
}

/// Decodes pixel size from image bytes (JPEG, PNG, WebP, …).
Future<Size?> readImageSizeFromBytes(Uint8List bytes) async {
  try {
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    codec.dispose();
    if (size.width < 1 || size.height < 1) return null;
    return size;
  } catch (_) {
    return null;
  }
}

/// Scales [image] to sit on [page] without changing its aspect ratio.
Size fitImageOnPage(Size image, Size page, {double maxFraction = 0.72}) {
  if (image.width < 1 || image.height < 1) {
    return Size(page.width * 0.4, page.height * 0.3);
  }
  final maxW = math.max(48.0, page.width * maxFraction);
  final maxH = math.max(48.0, page.height * maxFraction);
  final scale = math.min(maxW / image.width, maxH / image.height);
  return Size(image.width * scale, image.height * scale);
}
