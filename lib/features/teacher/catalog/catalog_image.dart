import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/local_file_image.dart';

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
    final child = LocalFileImage(
      path,
      fit: BoxFit.contain,
      errorBuilder: _broken,
    );
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
