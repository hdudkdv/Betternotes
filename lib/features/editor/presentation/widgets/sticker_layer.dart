import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/sticker_catalog.dart';
import '../editor_chrome.dart';
import 'overlay_hit_stack.dart';

class StickerLayer extends StatelessWidget {
  const StickerLayer({
    super.key,
    required this.stickers,
    required this.selectedId,
    required this.editable,
    required this.onSelect,
    required this.onChanged,
    this.onDelete,
  });

  final List<StickerElement> stickers;
  final String? selectedId;
  final bool editable;
  final ValueChanged<String?> onSelect;
  final ValueChanged<StickerElement> onChanged;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final layer = OverlayHitStack(
      children: [
        for (final sticker in stickers)
          Positioned(
            left: sticker.x,
            top: sticker.y,
            child: GestureDetector(
              onTap: editable ? () => onSelect(sticker.id) : null,
              onSecondaryTap: editable ? () => onSelect(sticker.id) : null,
              onPanUpdate: editable && selectedId == sticker.id
                  ? (d) => onChanged(
                      sticker.copyWith(
                        x: sticker.x + d.delta.dx,
                        y: sticker.y + d.delta.dy,
                      ),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: sticker.width,
                    height: sticker.height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedId == sticker.id
                            ? EditorChrome.toolbarSelected
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _StickerPainter(sticker.catalogId),
                    ),
                  ),
                  if (editable && selectedId == sticker.id && onDelete != null)
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Material(
                        color: const Color(0xE6C62828),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onDelete!(sticker.id),
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
                  if (editable && selectedId == sticker.id)
                    _ResizeHandle(sticker: sticker, onChanged: onChanged),
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

class _StickerPainter extends CustomPainter {
  const _StickerPainter(this.catalogId);

  final String catalogId;

  @override
  void paint(Canvas canvas, Size size) {
    final def = StickerCatalog.byId(catalogId);
    if (def == null) return;
    StickerCatalog.paint(canvas, def, Offset.zero & size);
  }

  @override
  bool shouldRepaint(covariant _StickerPainter oldDelegate) =>
      oldDelegate.catalogId != catalogId;
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.sticker,
    required this.onChanged,
  });

  final StickerElement sticker;
  final ValueChanged<StickerElement> onChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -8,
      bottom: -8,
      child: GestureDetector(
        onPanUpdate: (d) {
          final next = (sticker.width + d.delta.dx).clamp(36.0, 280.0);
          onChanged(sticker.copyWith(width: next, height: next));
        },
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: EditorChrome.toolbarSelected, width: 2),
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
