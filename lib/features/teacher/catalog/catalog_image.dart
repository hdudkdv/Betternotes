import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.path,
    this.height = 180,
  });

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path.startsWith('memory:')) {
      child = Image.memory(
        base64Decode(path.substring(7)),
        fit: BoxFit.contain,
        errorBuilder: _broken,
      );
    } else if (kIsWeb) {
      child = Image.network(path, fit: BoxFit.contain, errorBuilder: _broken);
    } else {
      child = Image.file(File(path), fit: BoxFit.contain, errorBuilder: _broken);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: AppTheme.paperDeep,
        child: SizedBox(width: double.infinity, height: height, child: child),
      ),
    );
  }

  Widget _broken(BuildContext context, Object error, StackTrace? stack) {
    return ColoredBox(
      color: AppTheme.paperDeep,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
