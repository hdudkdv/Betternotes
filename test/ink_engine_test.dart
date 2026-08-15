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
}
