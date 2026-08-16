import 'package:flutter/material.dart';

import 'calculator_engine.dart';

const kPlotColors = <Color>[
  Color(0xFF1D4E89),
  Color(0xFFB42318),
  Color(0xFF0F766E),
  Color(0xFFD4A017),
  Color(0xFF7C3AED),
  Color(0xFF0A84FF),
];

class PlotSeries {
  const PlotSeries({
    required this.expression,
    this.label,
    this.color,
    this.plotDerivative = false,
  });

  final String expression;
  final String? label;
  final Color? color;
  final bool plotDerivative;

  String get displayLabel =>
      label ?? FunctionPlotPrep.prettyLabel(expression);
}

abstract final class FunctionPlotPrep {
  static const _fnNames = ['f', 'g', 'h', 'p', 'q', 'y'];

  static List<String> splitExpressions(String raw) {
    return [
      for (final part in raw.split(RegExp(r'[\n;]+')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  static String normalizeExpression(String raw) {
    var s = CalculatorEngine.prepareSource(raw).trim();
    s = s.replaceFirst(
      RegExp(r"^[a-zA-Z]'?\s*\(\s*x\s*\)\s*="),
      '',
    );
    s = s.replaceFirst(RegExp(r'^y\s*='), '');
    s = s.trim();
    if (!s.contains('=')) return s;
    final parts = s.split('=');
    if (parts.length != 2) return s;
    final left = parts[0].trim();
    final right = parts[1].trim();
    final leftHasX = left.toLowerCase().contains('x');
    final rightHasX = right.toLowerCase().contains('x');
    if (leftHasX && !rightHasX) return left;
    if (rightHasX && !leftHasX) return right;
    if (leftHasX && rightHasX) return '($left)-($right)';
    return left;
  }

  static String prettyLabel(String raw) {
    final trimmed = raw.trim();
    if (RegExp(r"^[a-zA-Z]'?\s*\(\s*x\s*\)\s*=").hasMatch(trimmed)) {
      return trimmed.split('=').first.trim();
    }
    if (trimmed.toLowerCase().startsWith('y=')) return 'y';
    return 'f(x)';
  }

  static String nextFnName(int index) {
    if (index < _fnNames.length) return '${_fnNames[index]}(x)';
    return 'f${index + 1}(x)';
  }

  /// Pulls a plottable expression from a Tafelwerk term/value pair.
  static String? fromFormula({required String term, required String value}) {
    final candidates = [value, term];
    for (final raw in candidates) {
      final prepared = CalculatorEngine.prepareSource(raw).trim();
      if (prepared.isEmpty) continue;
      final normalized = normalizeExpression(prepared);
      if (normalized.toLowerCase().contains('x')) return normalized;
      if (RegExp(r"^[a-zA-Z]'?\s*\(\s*x\s*\)").hasMatch(prepared)) {
        return normalizeExpression(prepared);
      }
    }
    return null;
  }

  static bool looksPlottable(String term, String value) {
    return fromFormula(term: term, value: value) != null;
  }
}
