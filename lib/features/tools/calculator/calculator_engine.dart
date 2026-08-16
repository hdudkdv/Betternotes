import 'dart:math' as math;

class CalcResult {
  const CalcResult({required this.ok, required this.value, this.error});

  final bool ok;
  final double value;
  final String? error;

  String get display {
    if (!ok) return error ?? 'Error';
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.round().toString();
    }
    var text = value.toStringAsFixed(8);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}

/// Compact expression evaluator: + − × ÷ ^, functions, constants, optional x.
class CalculatorEngine {
  CalcResult evaluate(String source, {double? x}) {
    try {
      final tokens = _tokenize(source);
      if (tokens.isEmpty) {
        return const CalcResult(ok: false, value: 0, error: '');
      }
      final parser = _Parser(tokens, x: x);
      final value = parser.parseExpression();
      if (parser._i < tokens.length) {
        return const CalcResult(ok: false, value: 0, error: 'Syntax');
      }
      if (value.isNaN || value.isInfinite) {
        return const CalcResult(ok: false, value: 0, error: 'Undef');
      }
      return CalcResult(ok: true, value: value);
    } catch (e) {
      return CalcResult(ok: false, value: 0, error: '$e');
    }
  }

  List<String> _tokenize(String raw) {
    final src = raw
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .toLowerCase();
    final out = <String>[];
    var i = 0;
    while (i < src.length) {
      final ch = src[i];
      if ('+-*/^()=!%'.contains(ch)) {
        out.add(ch);
        i++;
      } else if (ch == '.' || _isDigit(ch)) {
        final start = i;
        i++;
        while (i < src.length && (_isDigit(src[i]) || src[i] == '.')) {
          i++;
        }
        out.add(src.substring(start, i));
      } else if (_isLetter(ch)) {
        final start = i;
        i++;
        while (i < src.length && _isLetter(src[i])) {
          i++;
        }
        out.add(src.substring(start, i));
      } else {
        throw 'Zeichen';
      }
    }
    return _insertImplicitMultiplication(out);
  }

  static const _fnNames = {
    'sin',
    'cos',
    'tan',
    'sqrt',
    'ln',
    'log',
    'abs',
    'asin',
    'acos',
    'atan',
    'exp',
    'floor',
    'ceil',
    'round',
    'fact',
  };

  static bool _isValueToken(String token) {
    if (token == 'x' || token == 'pi' || token == 'e' || token == ')' ||
        token == '!' ||
        token == '%') {
      return true;
    }
    return double.tryParse(token) != null;
  }

  static bool _startsValueToken(String token) {
    if (token == '(' || token == 'x' || token == 'pi' || token == 'e') {
      return true;
    }
    if (_fnNames.contains(token)) return true;
    return double.tryParse(token) != null;
  }

  List<String> _insertImplicitMultiplication(List<String> tokens) {
    if (tokens.length < 2) return tokens;
    final out = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      out.add(tokens[i]);
      if (i + 1 >= tokens.length) continue;
      final a = tokens[i];
      final b = tokens[i + 1];
      if (_fnNames.contains(a) && b == '(') continue;
      if (_isValueToken(a) && _startsValueToken(b)) {
        out.add('*');
      }
    }
    return out;
  }

  static bool _isDigit(String ch) => ch.codeUnitAt(0) ^ 0x30 <= 9;
  static bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 97 && c <= 122;
  }
}

class _Parser {
  _Parser(this.tokens, {this.x});

  final List<String> tokens;
  final double? x;
  var _i = 0;

  String? get _peek => _i < tokens.length ? tokens[_i] : null;

  String _take() => tokens[_i++];

  double parseExpression() {
    var value = _parseTerm();
    while (_peek == '+' || _peek == '-') {
      final op = _take();
      final rhs = _parseTerm();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parsePower();
    while (_peek == '*' || _peek == '/') {
      final op = _take();
      final rhs = _parsePower();
      value = op == '*' ? value * rhs : value / rhs;
    }
    return value;
  }

  double _parsePower() {
    final value = _parseUnary();
    if (_peek == '^') {
      _take();
      return math.pow(value, _parseUnary()).toDouble();
    }
    return value;
  }

  double _parseUnary() {
    if (_peek == '-') {
      _take();
      return -_parseUnary();
    }
    if (_peek == '+') {
      _take();
      return _parseUnary();
    }
    var value = _parsePrimary();
    if (_peek == '%') {
      _take();
      return value / 100;
    }
    if (_peek == '!') {
      _take();
      return _factorial(value);
    }
    return value;
  }

  double _parsePrimary() {
    final token = _peek;
    if (token == null) throw 'Syntax';
    if (token == '(') {
      _take();
      final value = parseExpression();
      if (_peek != ')') throw 'Klammer';
      _take();
      return value;
    }
    if (token == 'pi') {
      _take();
      return math.pi;
    }
    if (token == 'e') {
      _take();
      return math.e;
    }
    if (token == 'x') {
      _take();
      if (x == null) throw 'x';
      return x!;
    }
    if (_fn(token)) {
      _take();
      if (_peek != '(') throw 'Funktion';
      _take();
      final arg = parseExpression();
      if (_peek != ')') throw 'Klammer';
      _take();
      return _apply(token, arg);
    }
    _take();
    return double.parse(token);
  }

  bool _fn(String name) => const {
    'sin',
    'cos',
    'tan',
    'sqrt',
    'ln',
    'log',
    'abs',
    'asin',
    'acos',
    'atan',
    'exp',
    'floor',
    'ceil',
    'round',
    'fact',
  }.contains(name);

  double _apply(String name, double arg) => switch (name) {
    'sin' => math.sin(arg),
    'cos' => math.cos(arg),
    'tan' => math.tan(arg),
    'sqrt' => math.sqrt(arg),
    'ln' => math.log(arg),
    'log' => math.log(arg) / math.ln10,
    'abs' => arg.abs(),
    'asin' => math.asin(arg),
    'acos' => math.acos(arg),
    'atan' => math.atan(arg),
    'exp' => math.exp(arg),
    'floor' => arg.floorToDouble(),
    'ceil' => arg.ceilToDouble(),
    'round' => arg.roundToDouble(),
    'fact' => _factorial(arg),
    _ => throw 'Funktion',
  };

  static double _factorial(double arg) {
    if (arg < 0 || arg != arg.roundToDouble() || arg > 170) {
      throw 'Fakultät';
    }
    var n = 1.0;
    for (var i = 2; i <= arg.round(); i++) {
      n *= i;
    }
    return n;
  }
}

extension CalculatorSolve on CalculatorEngine {
  /// Evaluates `expr` or solves `left = right` for `x`.
  CalcResult evaluateOrSolve(String source) {
    final trimmed = source.trim();
    if (trimmed.contains('=')) return solve(trimmed);
    return evaluate(trimmed);
  }

  CalcResult solve(String source) {
    final parts = source.split('=');
    if (parts.length != 2) {
      return const CalcResult(ok: false, value: 0, error: 'solve: a=b');
    }
    final left = parts[0];
    final right = parts[1];
    final usesX =
        left.toLowerCase().contains('x') || right.toLowerCase().contains('x');
    if (!usesX) {
      final l = evaluate(left);
      final r = evaluate(right);
      if (!l.ok) return l;
      if (!r.ok) return r;
      return CalcResult(ok: true, value: l.value - r.value);
    }

    double? f(double x) {
      final l = evaluate(left, x: x);
      final r = evaluate(right, x: x);
      if (!l.ok || !r.ok) return null;
      return l.value - r.value;
    }

    for (final guess in const [0.0, 1.0, -1.0, 2.0, 10.0, -10.0, 0.5]) {
      final root = _newton(f, guess);
      if (root != null) return CalcResult(ok: true, value: root);
    }
    return const CalcResult(ok: false, value: 0, error: 'keine Lösung');
  }

  double? _newton(double? Function(double x) f, double x0) {
    var x = x0;
    for (var i = 0; i < 40; i++) {
      final y = f(x);
      if (y == null) return null;
      if (y.abs() < 1e-9) return x;
      final y2 = f(x + 1e-6);
      if (y2 == null) return null;
      final d = (y2 - y) / 1e-6;
      if (d.abs() < 1e-12) return null;
      x = x - y / d;
      if (!x.isFinite) return null;
    }
    final y = f(x);
    if (y == null || y.abs() > 1e-6) return null;
    return x;
  }
}
