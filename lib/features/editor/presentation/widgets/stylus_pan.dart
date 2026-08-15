import 'package:flutter/material.dart';

/// Drag handle that accepts finger **and** Apple Pencil / stylus.
///
/// [GestureDetector] often loses stylus pans to the ink canvas; a raw
/// [Listener] owns the pointer for the whole gesture.
class StylusPan extends StatelessWidget {
  const StylusPan({
    super.key,
    required this.onPanUpdate,
    this.onPanStart,
    this.onPanEnd,
    this.child,
    this.behavior = HitTestBehavior.opaque,
  });

  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback? onPanStart;
  final VoidCallback? onPanEnd;
  final Widget? child;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behavior,
      onPointerDown: (_) => onPanStart?.call(),
      onPointerMove: (event) {
        if (event.down && event.delta != Offset.zero) {
          onPanUpdate(event.delta);
        }
      },
      onPointerUp: (_) => onPanEnd?.call(),
      onPointerCancel: (_) => onPanEnd?.call(),
      child: child ?? const SizedBox.expand(),
    );
  }
}
