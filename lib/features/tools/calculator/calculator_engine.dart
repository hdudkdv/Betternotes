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
      if ('+-*/^()'.contains(ch)) {
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
    return _parsePrimary();
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
    _ => throw 'Funktion',
  };
}
