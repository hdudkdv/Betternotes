import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/domain/pointer_routing.dart';
import 'package:betternotes/features/editor/presentation/widgets/ink_painter.dart';
import 'package:betternotes/features/editor/presentation/widgets/page_background_painter.dart';
import 'package:betternotes/features/editor/presentation/widgets/shape_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('page painters do not claim hits', () {
    expect(ShapePainter(shapes: const []).hitTest(Offset.zero), isFalse);
    expect(InkPainter(strokes: const []).hitTest(Offset.zero), isFalse);
    expect(
      PageBackgroundPainter(template: PageTemplate.lined).hitTest(Offset.zero),
      isFalse,
    );
  });

  testWidgets('shape overlay lets pointers through to the ink listener', (
    tester,
  ) async {
    var downs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => downs++,
                    child: const ColoredBox(color: Color(0xFFFFFFFF)),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ShapePainter(shapes: const []),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 300));
    expect(downs, 1);
  });

  testWidgets('shape CustomPaint without IgnorePointer still misses hits', (
    tester,
  ) async {
    var downs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => downs++,
                    child: const ColoredBox(color: Color(0xFFFFFFFF)),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: ShapePainter(shapes: const []),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 300));
    expect(downs, 1);
  });

  test('left mouse draws like a stylus, right mouse browses like a finger', () {
    const left = PointerDownEvent(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    const right = PointerDownEvent(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    const stylus = PointerDownEvent(kind: PointerDeviceKind.stylus);
    const finger = PointerDownEvent(kind: PointerDeviceKind.touch);

    expect(PointerRouting.drawsLikeStylus(left), isTrue);
    expect(PointerRouting.browsesLikeFinger(left), isFalse);
    expect(PointerRouting.drawsLikeStylus(right), isFalse);
    expect(PointerRouting.browsesLikeFinger(right), isTrue);
    expect(PointerRouting.drawsLikeStylus(stylus), isTrue);
    expect(PointerRouting.browsesLikeFinger(stylus), isFalse);
    expect(PointerRouting.drawsLikeStylus(finger), isFalse);
    expect(PointerRouting.browsesLikeFinger(finger), isTrue);
  });
}
