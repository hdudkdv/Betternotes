import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/file_store.dart';
import 'local_file_image_src.dart';

class LocalFileImage extends StatelessWidget {
  const LocalFileImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('memory:')) {
      try {
        return Image.memory(
          base64Decode(path.substring(7)),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: errorBuilder,
        );
      } catch (_) {
        return _fallback();
      }
    }
    final cached = createFileStore().peekBytes(path);
    if (cached != null) {
      return Image.memory(
        cached,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
    return buildPlatformFileImage(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: const Color(0xFFE0E0E0),
      child: SizedBox(width: width, height: height),
    );
  }
}
