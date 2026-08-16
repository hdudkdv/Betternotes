import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/tools/calculator/calculator_engine.dart';

void main() {
  final engine = CalculatorEngine();

  test('respects operator precedence', () {
    expect(engine.evaluate('2+3*4').value, 14);
    expect(engine.evaluate('(2+3)*4').value, 20);
  });

  test('evaluates functions and constants', () {
    expect(engine.evaluate('sqrt(9)').value, 3);
    expect(engine.evaluate('sin(0)').value, 0);
    expect(engine.evaluate('abs(-4)').ok, isTrue);
  });

  test('plots with x', () {
    expect(engine.evaluate('x*x', x: 3).value, 9);
    expect(engine.evaluate('sin(x)', x: 0).value, 0);
  });

  test('solves a linear equation for x', () {
    final result = engine.solve('2x+3=11');
    expect(result.ok, isTrue);
    expect(result.value, closeTo(4, 1e-6));
  });

  test('percent and factorial', () {
    expect(engine.evaluate('50%').value, 0.5);
    expect(engine.evaluate('5!').value, 120);
  });
}
