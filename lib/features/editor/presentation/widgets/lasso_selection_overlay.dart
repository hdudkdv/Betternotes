import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../editor_chrome.dart';
import 'overlay_hit_stack.dart';

/// Bounding box + one resize handle for a lasso / object group.
class LassoSelectionOverlay extends StatelessWidget {
  const LassoSelectionOverlay({
    super.key,
    required this.bounds,
    required this.onScaleStart,
    required this.onScaleDelta,
    required this.onScaleEnd,
    this.onDragActive,
  });

  final Rect bounds;
  final VoidCallback onScaleStart;
  final ValueChanged<Offset> onScaleDelta;
  final VoidCallback onScaleEnd;
  final ValueChanged<bool>? onDragActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OverlayHitStack(
      children: [
        Positioned(
          left: bounds.left - 3,
          top: bounds.top - 3,
          width: bounds.width + 6,
          height: bounds.height + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: EditorChrome.toolbarSelected,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    onDragActive?.call(true);
                    onScaleStart();
                  },
                  onPanUpdate: (d) => onScaleDelta(d.delta),
                  onPanEnd: (_) {
                    onScaleEnd();
                    onDragActive?.call(false);
                  },
                  onPanCancel: () {
                    onScaleEnd();
                    onDragActive?.call(false);
                  },
                  child: Tooltip(
                    message: l10n.scaleSelection,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: EditorChrome.toolbarSelected,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
