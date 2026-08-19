import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A [Stack] that only participates in hit testing through its children.
///
/// Overlay layers (stickies, images, stickers) must fill the page for layout,
/// but empty regions have to let ink / page-swipe through to the canvas.
class OverlayHitStack extends Stack {
  const OverlayHitStack({
    super.key,
    super.alignment,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _OverlayHitRenderStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }
}

class _OverlayHitRenderStack extends RenderStack {
  _OverlayHitRenderStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    return hitTestChildren(result, position: position);
  }
}
