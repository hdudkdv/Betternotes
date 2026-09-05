import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/editor/domain/ink_engine.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('InkEngine records strokes and undo', () {
    final engine = InkEngine()
      ..setTool(InkTool.pen)
      ..setColor(0xFF000000)
      ..setWidth(3);

    engine.beginStroke(const Offset(10, 10));
    engine.appendStroke(const Offset(20, 20));
    engine.endStroke();

    expect(engine.strokes, hasLength(1));
    expect(engine.canUndo, isTrue);

    engine.undo();
    expect(engine.strokes, isEmpty);
    expect(engine.canRedo, isTrue);

    engine.redo();
    expect(engine.strokes, hasLength(1));
  });

  test('a huge jump starts a new stroke instead of a stray line', () {
    final engine = InkEngine()
      ..setTool(InkTool.pen)
      ..setColor(0xFF000000)
      ..setWidth(3);

    engine.beginStroke(const Offset(10, 10), t: 1000);
    engine.appendStroke(const Offset(18, 14), t: 1008);
    engine.appendStroke(const Offset(400, 500), t: 1016);
    engine.endStroke();

    expect(engine.strokes, hasLength(2));
    expect(engine.strokes.first.points.last.x, closeTo(18, 0.01));
    expect(engine.strokes.last.points.first.x, closeTo(400, 0.01));
  });

  test('a short pause then a nearby landing starts a new stroke', () {
    final engine = InkEngine()
      ..setTool(InkTool.pen)
      ..setColor(0xFF000000)
      ..setWidth(3);

    engine.beginStroke(const Offset(20, 20), t: 1000);
    engine.appendStroke(const Offset(28, 22), t: 1008);
    engine.appendStroke(const Offset(36, 24), t: 1016);
    // Lift, then land on the next letter ~20px away after 70ms.
    engine.appendStroke(const Offset(56, 26), t: 1086);
    engine.endStroke();

    expect(engine.strokes, hasLength(2));
    expect(engine.strokes.first.points.last.x, closeTo(36, 0.01));
    expect(engine.strokes.last.points.first.x, closeTo(56, 0.01));
  });

  test('fast continuous writing does not split mid-stroke', () {
    final engine = InkEngine()
      ..setTool(InkTool.pen)
      ..setColor(0xFF000000)
      ..setWidth(3);

    engine.beginStroke(const Offset(10, 10), t: 1000);
    engine.appendStroke(const Offset(22, 14), t: 1008);
    engine.appendStroke(const Offset(36, 20), t: 1016);
    engine.appendStroke(const Offset(52, 28), t: 1024);
    engine.endStroke();

    expect(engine.strokes, hasLength(1));
    expect(engine.strokes.single.points, hasLength(4));
  });

  test('stroke hit testing works', () {
    final stroke = InkStroke(
      id: '1',
      tool: InkTool.pen,
      colorValue: 0xFF000000,
      width: 4,
      points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 50, y: 0)],
    );
    expect(stroke.hitsPoint(const Offset(25, 1), tolerance: 4), isTrue);
    expect(stroke.hitsPoint(const Offset(25, 40), tolerance: 4), isFalse);
  });

  test('diagonal stroke does not hit from inside its bounding box', () {
    final stroke = InkStroke(
      id: 'diag',
      tool: InkTool.pen,
      colorValue: 0xFF000000,
      width: 3,
      points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 200, y: 200)],
    );
    expect(stroke.hitsPoint(const Offset(100, 100), tolerance: 6), isTrue);
    expect(stroke.hitsPoint(const Offset(180, 20), tolerance: 6), isFalse);
    expect(stroke.hitsPoint(const Offset(20, 180), tolerance: 6), isFalse);
  });

  test('precise eraser uses a much smaller tip than stroke mode', () {
    final engine = InkEngine()
      ..setTool(InkTool.eraser)
      ..setWidth(16)
      ..setEraserMode(EraserMode.stroke);
    expect(engine.eraseRadius, 8);
    engine.setEraserMode(EraserMode.precise);
    expect(engine.eraseRadius, lessThan(4));
  });

  test('eraser skips strokes that are not in eraseTargets', () {
    final engine = InkEngine(
      initial: [
        InkStroke(
          id: 'pen',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 4,
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 40, y: 0)],
        ),
        InkStroke(
          id: 'pencil',
          tool: InkTool.pencil,
          colorValue: 0xFF000000,
          width: 4,
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 40, y: 0)],
        ),
      ],
    )
      ..setTool(InkTool.eraser)
      ..setWidth(20)
      ..setEraserMode(EraserMode.stroke)
      ..setEraseTargets({ContentKind.pen});

    engine.beginStroke(const Offset(20, 0));
    engine.endStroke();

    expect(engine.strokes.map((s) => s.id), ['pencil']);
  });

  test('lasso only selects strokes allowed by lassoTargets', () {
    final engine = InkEngine(
      initial: [
        InkStroke(
          id: 'pen',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 3,
          points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 12, y: 12)],
        ),
        InkStroke(
          id: 'marker',
          tool: InkTool.marker,
          colorValue: 0xFF000000,
          width: 8,
          points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 12, y: 12)],
        ),
      ],
    )
      ..setTool(InkTool.lasso)
      ..setLassoTargets({ContentKind.marker});

    engine.beginStroke(const Offset(0, 0));
    engine.appendStroke(const Offset(40, 0));
    engine.appendStroke(const Offset(40, 40));
    engine.appendStroke(const Offset(0, 40));
    engine.endStroke();

    expect(engine.selectedIds, {'marker'});
  });

  test('strokeAt returns the topmost stroke under a point', () {
    final engine = InkEngine(
      initial: [
        InkStroke(
          id: 'back',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 4,
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 40, y: 0)],
        ),
        InkStroke(
          id: 'front',
          tool: InkTool.pen,
          colorValue: 0xFFFF0000,
          width: 4,
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 40, y: 0)],
        ),
      ],
    );

    expect(engine.strokeAt(const Offset(20, 0))?.id, 'front');
    expect(engine.strokeAt(const Offset(20, 40)), isNull);
  });

  test('selectIds and recolorSelected update the chosen strokes', () {
    final engine = InkEngine(
      initial: [
        InkStroke(
          id: 'a',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 3,
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 10, y: 0)],
        ),
        InkStroke(
          id: 'b',
          tool: InkTool.pen,
          colorValue: 0xFF000000,
          width: 3,
          points: const [StrokePoint(x: 0, y: 20), StrokePoint(x: 10, y: 20)],
        ),
      ],
    );

    engine.selectIds({'a'});
    expect(engine.selectedIds, {'a'});

    engine.recolorSelected(0xFF00AA00);
    expect(
      engine.strokes.firstWhere((s) => s.id == 'a').colorValue,
      0xFF00AA00,
    );
    expect(
      engine.strokes.firstWhere((s) => s.id == 'b').colorValue,
      0xFF000000,
    );

    engine.undo();
    expect(
      engine.strokes.firstWhere((s) => s.id == 'a').colorValue,
      0xFF000000,
    );
  });
}
