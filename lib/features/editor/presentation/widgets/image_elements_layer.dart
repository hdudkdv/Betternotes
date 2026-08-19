import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../../../shared/widgets/local_file_image.dart';
import '../editor_chrome.dart';
import 'overlay_hit_stack.dart';

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
    final layer = OverlayHitStack(
      children: [
        for (final image in images)
          Positioned(
            left: image.x,
            top: image.y,
            child: GestureDetector(
              onTap: editable ? () => onSelect(image.id) : null,
              onSecondaryTap: editable ? () => onSelect(image.id) : null,
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
                  if (editable && selectedId == image.id) ...[
                    _ResizeHandle(
                      alignment: Alignment.topLeft,
                      image: image,
                      onChanged: onChanged,
                    ),
                    _ResizeHandle(
                      alignment: Alignment.topRight,
                      image: image,
                      onChanged: onChanged,
                    ),
                    _ResizeHandle(
                      alignment: Alignment.bottomLeft,
                      image: image,
                      onChanged: onChanged,
                    ),
                    _ResizeHandle(
                      alignment: Alignment.bottomRight,
                      image: image,
                      onChanged: onChanged,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
    if (!editable) return IgnorePointer(child: layer);
    return layer;
  }

  Widget _buildImage(String path) {
    return LocalFileImage(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Color(0xFFE0E0E0));
      },
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.alignment,
    required this.image,
    required this.onChanged,
  });

  final Alignment alignment;
  final ImageElement image;
  final ValueChanged<ImageElement> onChanged;

  @override
  Widget build(BuildContext context) {
    final left = alignment.x < 0;
    final top = alignment.y < 0;
    return Positioned(
      left: left ? -8 : null,
      right: left ? null : -8,
      top: top ? -8 : null,
      bottom: top ? null : -8,
      child: GestureDetector(
        onPanUpdate: (d) {
          final sx = left ? -1.0 : 1.0;
          final aspect = image.width <= 0 ? 1.0 : image.width / image.height;
          var nextW = (image.width + d.delta.dx * sx).clamp(48.0, 2400.0);
          var nextH = nextW / aspect;
          if (nextH < 48) {
            nextH = 48;
            nextW = nextH * aspect;
          }
          var nextX = image.x;
          var nextY = image.y;
          if (left) nextX += image.width - nextW;
          if (top) nextY += image.height - nextH;
          onChanged(
            image.copyWith(x: nextX, y: nextY, width: nextW, height: nextH),
          );
        },
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: EditorChrome.toolbarSelected,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }
}
