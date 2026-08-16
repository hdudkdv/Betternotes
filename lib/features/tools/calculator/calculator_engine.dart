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
  /// When true, trig functions take and return degrees.
  bool degrees = false;

  CalcResult evaluate(String source, {double? x}) {
    try {
      final tokens = _tokenize(source);
      if (tokens.isEmpty) {
        return const CalcResult(ok: false, value: 0, error: '');
      }
      final parser = _Parser(tokens, x: x, degrees: degrees);
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

  /// Turns Tafelwerk / handwritten math into evaluator syntax.
  static String prepareSource(String raw) {
    var text = raw
        .replaceAll('×', '*')
        .replaceAll('·', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('π', 'pi');
    text = text.replaceAllMapped(RegExp(r'√\s*\('), (_) => 'sqrt(');
    text = text.replaceAllMapped(
      RegExp(r'√\s*([A-Za-z0-9.]+)'),
      (m) => 'sqrt(${m[1]})',
    );
    return text;
  }

  List<String> tokenizePublic(String raw) => _tokenize(raw);

  List<String> _tokenize(String raw) {
    final src = prepareSource(raw)
        .replaceAll(';', ',')
        .replaceAll(' ', '')
        .toLowerCase();
    final out = <String>[];
    var i = 0;
    var depth = 0;
    while (i < src.length) {
      final ch = src[i];
      if (ch == '(') {
        depth++;
        out.add(ch);
        i++;
      } else if (ch == ')') {
        depth--;
        out.add(ch);
        i++;
      } else if ('+-*/^=!%'.contains(ch)) {
        out.add(ch);
        i++;
      } else if (ch == ',') {
        out.add(',');
        i++;
      } else if (ch == '.' || _isDigit(ch)) {
        final start = i;
        var seenDot = ch == '.';
        i++;
        while (i < src.length) {
          if (_isDigit(src[i])) {
            i++;
            continue;
          }
          if ((src[i] == '.' || (src[i] == ',' && depth == 0)) && !seenDot) {
            seenDot = true;
            i++;
            continue;
          }
          break;
        }
        out.add(src.substring(start, i).replaceAll(',', '.'));
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
    'cbrt',
    'ln',
    'log',
    'abs',
    'asin',
    'acos',
    'atan',
    'atan2',
    'sinh',
    'cosh',
    'tanh',
    'exp',
    'floor',
    'ceil',
    'round',
    'fact',
    'ncr',
    'npr',
    'min',
    'max',
    'mod',
    'gcd',
    'lcm',
    'root',
    'pow',
    'mean',
    'median',
    'stdev',
    'count',
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
  _Parser(this.tokens, {this.x, this.degrees = false});

  final List<String> tokens;
  final double? x;
  final bool degrees;
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
      final args = <double>[parseExpression()];
      while (_peek == ',') {
        _take();
        args.add(parseExpression());
      }
      if (_peek != ')') throw 'Klammer';
      _take();
      return _apply(token, args);
    }
    _take();
    return double.parse(token);
  }

  bool _fn(String name) => CalculatorEngine._fnNames.contains(name);

  double _trigIn(double arg) =>
      degrees ? arg * math.pi / 180 : arg;

  double _trigOut(double arg) =>
      degrees ? arg * 180 / math.pi : arg;

  double _apply(String name, List<double> args) {
    double one() {
      if (args.length != 1) throw 'Funktion';
      return args[0];
    }

    double two() {
      if (args.length != 2) throw 'Funktion';
      return args[0];
    }

    switch (name) {
      case 'sin':
        return math.sin(_trigIn(one()));
      case 'cos':
        return math.cos(_trigIn(one()));
      case 'tan':
        return math.tan(_trigIn(one()));
      case 'asin':
        return _trigOut(math.asin(one()));
      case 'acos':
        return _trigOut(math.acos(one()));
      case 'atan':
        return _trigOut(math.atan(one()));
      case 'atan2':
        two();
        return _trigOut(math.atan2(args[0], args[1]));
      case 'sinh':
        return _sinh(one());
      case 'cosh':
        return _cosh(one());
      case 'tanh':
        return _tanh(one());
      case 'sqrt':
        return math.sqrt(one());
      case 'cbrt':
        return _cbrt(one());
      case 'ln':
        return math.log(one());
      case 'log':
        return math.log(one()) / math.ln10;
      case 'abs':
        return one().abs();
      case 'exp':
        return math.exp(one());
      case 'floor':
        return one().floorToDouble();
      case 'ceil':
        return one().ceilToDouble();
      case 'round':
        return one().roundToDouble();
      case 'fact':
        return _factorial(one());
      case 'min':
        if (args.isEmpty) throw 'Funktion';
        return args.reduce(math.min);
      case 'max':
        if (args.isEmpty) throw 'Funktion';
        return args.reduce(math.max);
      case 'mod':
        two();
        return args[0] % args[1];
      case 'pow':
        two();
        return math.pow(args[0], args[1]).toDouble();
      case 'root':
        two();
        return math.pow(args[1], 1 / args[0]).toDouble();
      case 'ncr':
        two();
        return _ncr(args[0], args[1]);
      case 'npr':
        two();
        return _npr(args[0], args[1]);
      case 'gcd':
        two();
        return _gcd(args[0], args[1]).toDouble();
      case 'lcm':
        two();
        return _lcm(args[0], args[1]).toDouble();
      case 'mean':
        if (args.isEmpty) throw 'Funktion';
        return args.reduce((a, b) => a + b) / args.length;
      case 'median':
        if (args.isEmpty) throw 'Funktion';
        final sorted = [...args]..sort();
        final mid = sorted.length ~/ 2;
        if (sorted.length.isOdd) return sorted[mid];
        return (sorted[mid - 1] + sorted[mid]) / 2;
      case 'stdev':
        if (args.length < 2) throw 'Funktion';
        final mean = args.reduce((a, b) => a + b) / args.length;
        final varSum = args.fold<double>(
          0,
          (s, v) => s + (v - mean) * (v - mean),
        );
        return math.sqrt(varSum / (args.length - 1));
      case 'count':
        return args.length.toDouble();
      default:
        throw 'Funktion';
    }
  }

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
  static double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
  static double _tanh(double x) {
    final e = math.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  static double _cbrt(double x) {
    if (x < 0) return -math.pow(-x, 1 / 3).toDouble();
    return math.pow(x, 1 / 3).toDouble();
  }

  static double _ncr(double n, double k) {
    if (n < 0 || k < 0 || n != n.roundToDouble() || k != k.roundToDouble()) {
      throw 'nCr';
    }
    if (k > n) return 0;
    return _npr(n, k) / _factorial(k);
  }

  static double _npr(double n, double k) {
    if (n < 0 || k < 0 || n != n.roundToDouble() || k != k.roundToDouble()) {
      throw 'nPr';
    }
    if (k > n) return 0;
    var v = 1.0;
    for (var i = 0; i < k.round(); i++) {
      v *= n - i;
    }
    return v;
  }

  static int _gcd(double a, double b) {
    var x = a.round().abs();
    var y = b.round().abs();
    while (y != 0) {
      final t = x % y;
      x = y;
      y = t;
    }
    return x;
  }

  static int _lcm(double a, double b) {
    final g = _gcd(a, b);
    if (g == 0) return 0;
    return (a.round().abs() ~/ g) * b.round().abs();
  }

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
