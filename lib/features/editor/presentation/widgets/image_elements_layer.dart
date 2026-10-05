import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../../../shared/widgets/local_file_image.dart';
import '../editor_chrome.dart';
import 'overlay_hit_stack.dart';
import 'stylus_pan.dart';

class ImageElementsLayer extends StatelessWidget {
  const ImageElementsLayer({
    super.key,
    required this.images,
    required this.selectedId,
    required this.editable,
    required this.onSelect,
    required this.onChanged,
    this.onEditStart,
    this.onDelete,
    this.onCrop,
  });

  final List<ImageElement> images;
  final String? selectedId;
  final bool editable;
  final ValueChanged<String?> onSelect;
  final ValueChanged<ImageElement> onChanged;
  final VoidCallback? onEditStart;
  final ValueChanged<String>? onDelete;
  final ValueChanged<ImageElement>? onCrop;

  static const _sidePad = 14.0;
  static const _topPad = 32.0;

  @override
  Widget build(BuildContext context) {
    final layer = OverlayHitStack(
      children: [
        for (final image in images)
          Positioned(
            left: image.x - _sidePad,
            top: image.y - _topPad,
            width: image.width + _sidePad * 2,
            height: image.height + _topPad + _sidePad,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _sidePad,
                  top: _topPad,
                  width: image.width,
                  height: image.height,
                  child: StylusPan(
                    onPanStart: editable
                        ? () {
                            if (selectedId != image.id) onSelect(image.id);
                            onEditStart?.call();
                          }
                        : null,
                    onPanUpdate: editable
                        ? (delta) => onChanged(
                            image.copyWith(
                              x: image.x + delta.dx,
                              y: image.y + delta.dy,
                            ),
                          )
                        : (_) {},
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: editable ? () => onSelect(image.id) : null,
                      onSecondaryTap: editable
                          ? () => onSelect(image.id)
                          : null,
                      onLongPress: editable && onCrop != null
                          ? () {
                              onSelect(image.id);
                              onCrop!(image);
                            }
                          : null,
                      child: Container(
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
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(color: Color(0xFFE0E0E0));
                          },
                        ),
                      ),
                    ),
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
                      padLeft: _sidePad,
                      padTop: _topPad,
                      onEditStart: onEditStart,
                      onChanged: onChanged,
                    ),
                if (editable && selectedId == image.id)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 2,
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
                            const SizedBox(width: 4),
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
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onTap(),
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(icon, color: Colors.white, size: 13),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.image,
    required this.corner,
    required this.padLeft,
    required this.padTop,
    required this.onChanged,
    this.onEditStart,
  });

  final ImageElement image;
  final Alignment corner;
  final double padLeft;
  final double padTop;
  final ValueChanged<ImageElement> onChanged;
  final VoidCallback? onEditStart;

  @override
  Widget build(BuildContext context) {
    const visual = 12.0;
    const hit = 22.0;
    final left = corner.x < 0
        ? padLeft - hit / 2
        : padLeft + image.width - hit / 2;
    final top = corner.y < 0
        ? padTop - hit / 2
        : padTop + image.height - hit / 2;
    return Positioned(
      left: left,
      top: top,
      child: StylusPan(
        onPanStart: onEditStart,
        onPanUpdate: (delta) {
          final aspect = image.width <= 0 ? 1.0 : image.width / image.height;
          final widthDelta = delta.dx * corner.x;
          final heightDelta = delta.dy * corner.y;
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
        child: SizedBox(
          width: hit,
          height: hit,
          child: Center(
            child: Container(
              width: visual,
              height: visual,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: EditorChrome.toolbarSelected,
                  width: 1.25,
                ),
                borderRadius: BorderRadius.circular(2.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 1.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
