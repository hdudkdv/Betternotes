import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../editor_chrome.dart';

class ImageElementsLayer extends StatelessWidget {
  const ImageElementsLayer({
    super.key,
    required this.images,
    required this.selectedId,
    required this.editable,
    required this.onSelect,
    required this.onChanged,
    this.onDelete,
  });

  final List<ImageElement> images;
  final String? selectedId;
  final bool editable;
  final ValueChanged<String?> onSelect;
  final ValueChanged<ImageElement> onChanged;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final image in images)
          Positioned(
            left: image.x,
            top: image.y,
            child: GestureDetector(
              onTap: editable ? () => onSelect(image.id) : null,
              onPanUpdate: editable && selectedId == image.id
                  ? (d) => onChanged(
                      image.copyWith(
                        x: image.x + d.delta.dx,
                        y: image.y + d.delta.dy,
                      ),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: image.width,
                    height: image.height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedId == image.id
                            ? EditorChrome.toolbarSelected
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _buildImage(image.localPath),
                  ),
                  if (editable &&
                      selectedId == image.id &&
                      onDelete != null)
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Material(
                        color: const Color(0xE6C62828),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onDelete!(image.id),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String path) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(color: Color(0xFFE0E0E0));
        },
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Color(0xFFE0E0E0));
      },
    );
  }
}
