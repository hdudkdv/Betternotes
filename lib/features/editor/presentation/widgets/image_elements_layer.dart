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
    this.onCrop,
  });

  final List<ImageElement> images;
  final String? selectedId;
  final bool editable;
  final ValueChanged<String?> onSelect;
  final ValueChanged<ImageElement> onChanged;
  final ValueChanged<String>? onDelete;
  final ValueChanged<ImageElement>? onCrop;

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
              onLongPress: editable && onCrop != null
                  ? () {
                      onSelect(image.id);
                      onCrop!(image);
                    }
                  : null,
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
                    child: LocalFileImage(
                      image.localPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(color: Color(0xFFE0E0E0));
                      },
                    ),
                  ),
                  if (editable && selectedId == image.id)
                    for (final corner in const [
                      Alignment.topLeft,
                      Alignment.topRight,
                      Alignment.bottomLeft,
                      Alignment.bottomRight,
                    ])
                      _ResizeHandle(
                        image: image,
                        corner: corner,
                        onChanged: onChanged,
                      ),
                  if (editable && selectedId == image.id)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -38,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onCrop != null) ...[
                              _ImageAction(
                                icon: Icons.crop_rounded,
                                color: EditorChrome.toolbarSelected,
                                onTap: () => onCrop!(image),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onDelete != null)
                              _ImageAction(
                                icon: Icons.close_rounded,
                                color: const Color(0xE6C62828),
                                onTap: () => onDelete!(image.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
    if (!editable) return IgnorePointer(child: layer);
    return layer;
  }
}

class _ImageAction extends StatelessWidget {
  const _ImageAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.image,
    required this.corner,
    required this.onChanged,
  });

  final ImageElement image;
  final Alignment corner;
  final ValueChanged<ImageElement> onChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: corner.x < 0 ? -10 : null,
      right: corner.x > 0 ? -10 : null,
      top: corner.y < 0 ? -10 : null,
      bottom: corner.y > 0 ? -10 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          final aspect = image.width <= 0 ? 1.0 : image.width / image.height;
          final widthDelta = d.delta.dx * corner.x;
          final heightDelta = d.delta.dy * corner.y;
          late double nextW;
          late double nextH;
          if (widthDelta.abs() >= heightDelta.abs()) {
            nextW = (image.width + widthDelta).clamp(48.0, 2400.0);
            nextH = nextW / aspect;
          } else {
            nextH = (image.height + heightDelta).clamp(48.0, 2400.0);
            nextW = nextH * aspect;
          }
          if (nextH < 48) {
            nextH = 48;
            nextW = nextH * aspect;
          } else if (nextH > 2400) {
            nextH = 2400;
            nextW = nextH * aspect;
          }
          if (nextW < 48) {
            nextW = 48;
            nextH = nextW / aspect;
          } else if (nextW > 2400) {
            nextW = 2400;
            nextH = nextW / aspect;
          }
          onChanged(
            image.copyWith(
              x: corner.x < 0 ? image.x + image.width - nextW : image.x,
              y: corner.y < 0 ? image.y + image.height - nextH : image.y,
              width: nextW,
              height: nextH,
            ),
          );
        },
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: EditorChrome.toolbarSelected, width: 2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }
}
