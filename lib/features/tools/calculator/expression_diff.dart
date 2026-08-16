import 'calculator_engine.dart';

/// Symbolic d/dx for the expressions the calculator understands.
abstract final class ExpressionDiff {
  static String? differentiate(String source) {
    try {
      final tokens = CalculatorEngine().tokenizePublic(source);
      if (tokens.isEmpty) return null;
      final parser = _DiffParser(tokens);
      final node = parser.parse();
      if (parser.leftover) return null;
      return _simplify(node.diff()).src();
    } catch (_) {
      return null;
    }
  }

  static double numeric(
    CalculatorEngine engine,
    String expression,
    double x, {
    double h = 1e-4,
  }) {
    final a = engine.evaluate(expression, x: x - h);
    final b = engine.evaluate(expression, x: x + h);
    if (!a.ok || !b.ok) return double.nan;
    return (b.value - a.value) / (2 * h);
  }
}

class _N {
  const _N(this.op, {this.v, this.name, this.a, this.b, this.args = const []});

  final String op;
  final double? v;
  final String? name;
  final _N? a;
  final _N? b;
  final List<_N> args;

  _N diff() {
    switch (op) {
      case 'num':
        return const _N('num', v: 0);
      case 'x':
        return const _N('num', v: 1);
      case 'neg':
        return _N('neg', a: a!.diff());
      case '+':
        return _N('+', a: a!.diff(), b: b!.diff());
      case '-':
        return _N('-', a: a!.diff(), b: b!.diff());
      case '*':
        return _N(
          '+',
          a: _N('*', a: a!.diff(), b: b),
          b: _N('*', a: a, b: b!.diff()),
        );
      case '/':
        return _N(
          '/',
          a: _N(
            '-',
            a: _N('*', a: a!.diff(), b: b),
            b: _N('*', a: a, b: b!.diff()),
          ),
          b: _N('^', a: b, b: const _N('num', v: 2)),
        );
      case '^':
        final base = a!;
        final exp = b!;
        if (exp.op == 'num') {
          return _N(
            '*',
            a: _N(
              '*',
              a: exp,
              b: _N('^', a: base, b: _N('num', v: (exp.v ?? 0) - 1)),
            ),
            b: base.diff(),
          );
        }
        return _N(
          '*',
          a: _N('^', a: base, b: exp),
          b: _N(
            '+',
            a: _N('*', a: exp.diff(), b: _N('call', name: 'ln', args: [base])),
            b: _N(
              '*',
              a: exp,
              b: _N('/', a: base.diff(), b: base),
            ),
          ),
        );
      case 'call':
        return _diffCall(name!, args);
      default:
        return const _N('num', v: 0);
    }
  }

  _N _diffCall(String fn, List<_N> xs) {
    final u = xs.isEmpty ? const _N('num', v: 0) : xs.first;
    final du = u.diff();
    _N chain(_N outer) => _N('*', a: outer, b: du);
    switch (fn) {
      case 'sin':
        return chain(_N('call', name: 'cos', args: [u]));
      case 'cos':
        return chain(_N('neg', a: _N('call', name: 'sin', args: [u])));
      case 'tan':
        return chain(
          _N(
            '^',
            a: _N('call', name: 'cos', args: [u]),
            b: const _N('num', v: -2),
          ),
        );
      case 'exp':
        return chain(_N('call', name: 'exp', args: [u]));
      case 'ln':
        return _N('/', a: du, b: u);
      case 'log':
        return _N(
          '/',
          a: du,
          b: _N('*', a: u, b: _N('call', name: 'ln', args: [const _N('num', v: 10)])),
        );
      case 'sqrt':
        return _N(
          '/',
          a: du,
          b: _N('*', a: const _N('num', v: 2), b: _N('call', name: 'sqrt', args: [u])),
        );
      case 'cbrt':
        return _N(
          '/',
          a: du,
          b: _N(
            '*',
            a: const _N('num', v: 3),
            b: _N('^', a: u, b: const _N('num', v: 2 / 3)),
          ),
        );
      case 'abs':
        return _N(
          '*',
          a: _N('/', a: u, b: _N('call', name: 'abs', args: [u])),
          b: du,
        );
      case 'sinh':
        return chain(_N('call', name: 'cosh', args: [u]));
      case 'cosh':
        return chain(_N('call', name: 'sinh', args: [u]));
      default:
        return const _N('num', v: 0);
    }
  }

  String src() {
    switch (op) {
      case 'num':
        final n = v ?? 0;
        if (n == n.roundToDouble()) return n.round().toString();
        return n.toString();
      case 'x':
        return 'x';
      case 'neg':
        return '-(${a!.src()})';
      case '+' || '-' || '*' || '/' || '^':
        return '(${a!.src()}$op${b!.src()})';
      case 'call':
        final inner = args.map((e) => e.src()).join(',');
        return '${name ?? ''}($inner)';
      default:
        return '0';
    }
  }
}

_N _simplify(_N n) {
  _N s(_N x) => _simplify(x);
  switch (n.op) {
    case '+' || '-' || '*' || '/' || '^':
      final a = s(n.a!);
      final b = s(n.b!);
      if (n.op == '+' && _isZero(a)) return b;
      if (n.op == '+' && _isZero(b)) return a;
      if (n.op == '-' && _isZero(b)) return a;
      if (n.op == '*' && (_isZero(a) || _isZero(b))) return const _N('num', v: 0);
      if (n.op == '*' && _isOne(a)) return b;
      if (n.op == '*' && _isOne(b)) return a;
      if (n.op == '/' && _isZero(a)) return const _N('num', v: 0);
      if (n.op == '/' && _isOne(b)) return a;
      if (n.op == '^' && _isOne(b)) return a;
      if (n.op == '^' && _isZero(b)) return const _N('num', v: 1);
      return _N(n.op, a: a, b: b);
    case 'neg':
      final a = s(n.a!);
      if (_isZero(a)) return const _N('num', v: 0);
      return _N('neg', a: a);
    case 'call':
      return _N(
        'call',
        name: n.name,
        args: [for (final a in n.args) s(a)],
      );
    default:
      return n;
  }
}

bool _isZero(_N n) => n.op == 'num' && (n.v ?? 1) == 0;
bool _isOne(_N n) => n.op == 'num' && (n.v ?? 0) == 1;

class _DiffParser {
  _DiffParser(this.tokens);

  final List<String> tokens;
  var _i = 0;

  bool get leftover => _i < tokens.length;
  String? get _peek => _i < tokens.length ? tokens[_i] : null;
  String _take() => tokens[_i++];

  _N parse() => _expr();

  _N _expr() {
    var v = _term();
    while (_peek == '+' || _peek == '-') {
      final op = _take();
      v = _N(op, a: v, b: _term());
    }
    return v;
  }

  _N _term() {
    var v = _power();
    while (_peek == '*' || _peek == '/') {
      final op = _take();
      v = _N(op, a: v, b: _power());
    }
    return v;
  }

  _N _power() {
    final v = _unary();
    if (_peek == '^') {
      _take();
      return _N('^', a: v, b: _unary());
    }
    return v;
  }

  _N _unary() {
    if (_peek == '-') {
      _take();
      return _N('neg', a: _unary());
    }
    if (_peek == '+') {
      _take();
      return _unary();
    }
    return _primary();
  }

  _N _primary() {
    final t = _peek;
    if (t == null) throw 'Syntax';
    if (t == '(') {
      _take();
      final v = _expr();
      if (_peek != ')') throw 'Klammer';
      _take();
      return v;
    }
    if (t == 'x') {
      _take();
      return const _N('x');
    }
    if (t == 'pi' || t == 'e') {
      _take();
      return _N('num', v: t == 'pi' ? 3.141592653589793 : 2.718281828459045);
    }
    if (RegExp(r'^[a-z]').hasMatch(t) && double.tryParse(t) == null) {
      _take();
      if (_peek != '(') throw 'Funktion';
      _take();
      final args = <_N>[_expr()];
      while (_peek == ',') {
        _take();
        args.add(_expr());
      }
      if (_peek != ')') throw 'Klammer';
      _take();
      return _N('call', name: t, args: args);
    }
    _take();
    return _N('num', v: double.parse(t));
  }
}
