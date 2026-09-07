import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/image_dimensions.dart';
import '../../../../shared/widgets/local_file_image.dart';

/// Returns a normalized crop rect (0–1), or null if cancelled.
Future<Rect?> showImageCropSheet(
  BuildContext context, {
  required String path,
}) {
  return showDialog<Rect>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: _ImageCropEditor(path: path),
    ),
  );
}

class _ImageCropEditor extends StatefulWidget {
  const _ImageCropEditor({required this.path});

  final String path;

  @override
  State<_ImageCropEditor> createState() => _ImageCropEditorState();
}

class _ImageCropEditorState extends State<_ImageCropEditor> {
  Rect _crop = const Rect.fromLTWH(0.08, 0.08, 0.84, 0.84);
  double _aspect = 4 / 3;

  static const _min = 0.08;

  @override
  void initState() {
    super.initState();
    _loadAspect();
  }

  Future<void> _loadAspect() async {
    try {
      final bytes = await readLocalImageBytes(widget.path);
      final size = await readImageSizeFromBytes(bytes);
      if (!mounted || size == null || size.height < 1) return;
      setState(() => _aspect = size.width / size.height);
    } catch (_) {}
  }

  void _moveCorner(Alignment corner, Offset delta, Size box) {
    if (box.width < 1 || box.height < 1) return;
    var left = _crop.left;
    var top = _crop.top;
    var right = _crop.right;
    var bottom = _crop.bottom;
    final dx = delta.dx / box.width;
    final dy = delta.dy / box.height;
    if (corner.x < 0) {
      left = (left + dx).clamp(0.0, right - _min);
    } else {
      right = (right + dx).clamp(left + _min, 1.0);
    }
    if (corner.y < 0) {
      top = (top + dy).clamp(0.0, bottom - _min);
    } else {
      bottom = (bottom + dy).clamp(top + _min, 1.0);
    }
    setState(() => _crop = Rect.fromLTRB(left, top, right, bottom));
  }

  void _moveRect(Offset delta, Size box) {
    if (box.width < 1 || box.height < 1) return;
    var dx = delta.dx / box.width;
    var dy = delta.dy / box.height;
    if (_crop.left + dx < 0) dx = -_crop.left;
    if (_crop.right + dx > 1) dx = 1 - _crop.right;
    if (_crop.top + dy < 0) dy = -_crop.top;
    if (_crop.bottom + dy > 1) dy = 1 - _crop.bottom;
    setState(() => _crop = _crop.shift(Offset(dx, dy)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.cropImage,
            style: AppTheme.headline(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cropImageHint,
            style: AppTheme.body(color: AppTheme.inkMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420, maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AspectRatio(
                  aspectRatio: _aspect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: AppTheme.paperDeep,
                          child: LocalFileImage(widget.path, fit: BoxFit.fill),
                        ),
                        LayoutBuilder(
                          builder: (context, box) {
                            final size = Size(box.maxWidth, box.maxHeight);
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _DimPainter(crop: _crop),
                                  ),
                                ),
                                Positioned(
                                  left: _crop.left * size.width,
                                  top: _crop.top * size.height,
                                  width: _crop.width * size.width,
                                  height: _crop.height * size.height,
                                  child: GestureDetector(
                                    onPanUpdate: (d) =>
                                        _moveRect(d.delta, size),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppTheme.accent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                for (final corner in const [
                                  Alignment.topLeft,
                                  Alignment.topRight,
                                  Alignment.bottomLeft,
                                  Alignment.bottomRight,
                                ])
                                  _CornerHandle(
                                    crop: _crop,
                                    box: size,
                                    alignment: corner,
                                    onDrag: (delta) =>
                                        _moveCorner(corner, delta, size),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, _crop),
                child: Text(l10n.cropApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.crop,
    required this.box,
    required this.alignment,
    required this.onDrag,
  });

  final Rect crop;
  final Size box;
  final Alignment alignment;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    final x = alignment.x < 0 ? crop.left : crop.right;
    final y = alignment.y < 0 ? crop.top : crop.bottom;
    return Positioned(
      left: x * box.width - 14,
      top: y * box.height - 14,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d.delta),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accent, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _DimPainter extends CustomPainter {
  _DimPainter({required this.crop});

  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Rect.fromLTWH(
      crop.left * size.width,
      crop.top * size.height,
      crop.width * size.width,
      crop.height * size.height,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = const Color(0x88000000));
  }

  @override
  bool shouldRepaint(covariant _DimPainter oldDelegate) =>
      oldDelegate.crop != crop;
}
