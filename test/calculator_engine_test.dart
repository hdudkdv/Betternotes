import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/tools/calculator/calculator_engine.dart';
import 'package:betternotes/features/tools/calculator/expression_diff.dart';
import 'package:betternotes/features/tools/calculator/function_plotter.dart';
import 'package:betternotes/features/tools/calculator/plot_series.dart';

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

  test('plus-minus expressions return both results', () {
    final result = engine.evaluate('5±2');
    expect(result.ok, isTrue);
    expect(result.display, '7 ; 3');
  });

  test('closes missing parentheses for sqrt(1-x^2', () {
    expect(CalculatorEngine.balanceParens('sqrt(1-x^2'), 'sqrt(1-x^2)');
    final plotted = engine.evaluate('sqrt(1-x^2)', x: 0);
    expect(plotted.ok, isTrue);
    expect(plotted.value, closeTo(1, 1e-6));
    expect(engine.evaluate('sqrt(1-x^2)', x: 2).ok, isFalse);
  });

  test('quadratic equations report both roots as plus-minus', () {
    final result = engine.solve('x^2=9');
    expect(result.ok, isTrue);
    expect(result.display, '±3');
  });

  test('percent and factorial', () {
    expect(engine.evaluate('50%').value, 0.5);
    expect(engine.evaluate('5!').value, 120);
  });

  test('combinatorics and extra functions', () {
    expect(engine.evaluate('2,5+0,5').value, 3);
    expect(engine.evaluate('ncr(5,2)').value, 10);
    expect(engine.evaluate('npr(5,2)').value, 20);
    expect(engine.evaluate('cbrt(8)').value, 2);
    expect(engine.evaluate('min(3,1,4)').value, 1);
    expect(engine.evaluate('mod(10,4)').value, 2);
  });

  test('degrees mode for trig', () {
    engine.degrees = true;
    expect(engine.evaluate('sin(90)').value, closeTo(1, 1e-9));
    expect(engine.evaluate('cos(180)').value, closeTo(-1, 1e-9));
    engine.degrees = false;
    expect(engine.evaluate('sin(0)').value, 0);
  });

  test('normalizes f(x) and splits several functions', () {
    expect(FunctionPlotPrep.normalizeExpression('f(x)=sin(x)'), 'sin(x)');
    expect(FunctionPlotPrep.normalizeExpression('g(x) = x^2'), 'x^2');
    expect(FunctionPlotPrep.splitExpressions('sin(x); x^2'), ['sin(x)', 'x^2']);
  });

  test('statistics helpers', () {
    expect(engine.evaluate('mean(2,4,6)').value, 4);
    expect(engine.evaluate('median(1,5,3)').value, 3);
    expect(engine.evaluate('count(1,2,3,4)').value, 4);
  });

  test('differentiates basic functions', () {
    expect(ExpressionDiff.differentiate('x^2'), '(2*x)');
    expect(engine.evaluate(ExpressionDiff.differentiate('x^2')!, x: 3).value, 6);
  });

  test('plots the upper semicircle sqrt(1-x^2)', () async {
    final bytes = await FunctionPlotter.renderPng('sqrt(1-x^2)');
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(800));
  });
}
