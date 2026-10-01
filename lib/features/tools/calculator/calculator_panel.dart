import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'calculator_engine.dart';
import 'calculator_store.dart';

class CalculatorPanel extends StatefulWidget {
  const CalculatorPanel({
    super.key,
    required this.store,
    required this.notebookId,
    required this.onInsertPlot,
    this.calcPlus = false,
  });

  final CalculatorStore store;
  final String notebookId;
  final Future<bool> Function(String expression, {required bool degrees})
      onInsertPlot;
  final bool calcPlus;

  @override
  State<CalculatorPanel> createState() => _CalculatorPanelState();
}

enum _CalcPad { numbers, functions, more }

class _CalculatorPanelState extends State<CalculatorPanel> {
  final _engine = CalculatorEngine();
  final _input = TextEditingController();
  String _output = '';
  String _ans = '';
  late List<CalcHistoryEntry> _history;
  bool _plotting = false;
  bool _degrees = true;
  bool _shift = false;
  String? _plotError;
  _CalcPad _pad = _CalcPad.numbers;

  @override
  void initState() {
    super.initState();
    _history = widget.store.historyFor(widget.notebookId);
    if (_history.isNotEmpty) {
      _input.text = _history.first.expression;
      _output = _history.first.result;
      _ans = _numericAns(_history.first.result);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _numericAns(String display) {
    final cleaned = display.replaceFirst(RegExp(r'^x\s*=\s*'), '');
    if (cleaned.startsWith('±')) return cleaned.substring(1);
    final first = cleaned.split(';').first.trim();
    return first.isEmpty ? display : first;
  }

  Future<void> _eval({bool solve = false}) async {
    final raw = _input.text.trim();
    if (raw.isEmpty) return;
    var expr = raw;
    if (expr.contains('ans') && _ans.isNotEmpty) {
      expr = expr.replaceAll('ans', _ans);
    }
    expr = CalculatorEngine.balanceParens(expr);
    final usesX = RegExp(r'(^|[^a-zA-Z])x([^a-zA-Z]|$)').hasMatch(expr);
    if (!solve && usesX && !expr.contains('=')) {
      _input.text = expr;
      await _plot();
      return;
    }
    _engine.degrees = _degrees;
    final result = solve || expr.contains('=')
        ? _engine.evaluateOrSolve(expr)
        : _engine.evaluate(expr);
    final display = result.ok && expr.contains('=') && expr.toLowerCase().contains('x')
        ? 'x = ${result.display}'
        : result.display;
    setState(() => _output = display);
    if (!result.ok) return;
    _ans = result.ok ? _numericAns(result.display) : _ans;
    final entry = CalcHistoryEntry(
      expression: raw,
      result: display,
      at: DateTime.now(),
    );
    await widget.store.add(widget.notebookId, entry);
    if (mounted) {
      setState(() => _history = widget.store.historyFor(widget.notebookId));
    }
  }

  Future<void> _plot() async {
    var expr = _input.text.trim();
    if (expr.isEmpty) return;
    if (expr.contains('ans') && _ans.isNotEmpty) {
      expr = expr.replaceAll('ans', _ans);
    }
    expr = CalculatorEngine.balanceParens(expr);
    setState(() {
      _plotting = true;
      _plotError = null;
    });
    try {
      final ok = await widget.onInsertPlot(expr, degrees: _degrees);
      if (mounted && !ok) setState(() => _plotError = 'plot');
    } catch (_) {
      if (mounted) setState(() => _plotError = 'plot');
    } finally {
      if (mounted) setState(() => _plotting = false);
    }
  }

  void _onKey(String value) {
    if (value == 'SHIFT') {
      setState(() => _shift = !_shift);
      return;
    }
    if (value == '±') {
      _onPlusMinus();
      return;
    }
    if (value == '=') {
      _eval();
      return;
    }
    if (value == 'AC') {
      _append('C');
      return;
    }
    if (value == 'DEL') {
      _append('⌫');
      return;
    }
    final shifted = _shift ? _shifted(value) : value;
    if (_shift) setState(() => _shift = false);
    _append(shifted);
  }

  String _shifted(String value) {
    return switch (value) {
      'sin(' => 'asin(',
      'cos(' => 'acos(',
      'tan(' => 'atan(',
      'ln(' => 'exp(',
      'log(' => '10^(',
      '√(' => '^2',
      'x^2' => '^3',
      'x^-1' => '^(-1)',
      _ => value,
    };
  }

  void _onPlusMinus() {
    final text = _input.text;
    if (text.trim().isEmpty) {
      _toggleSign(_ans.isEmpty ? '' : _ans);
      return;
    }
    final trimmed = text.trimRight();
    final last = trimmed.isEmpty ? '' : trimmed[trimmed.length - 1];
    if (RegExp(r'[0-9)]').hasMatch(last)) {
      _append('±');
      return;
    }
    _toggleSign(text);
  }

  void _toggleSign(String source) {
    final text = source.trim();
    if (text.isEmpty) {
      _input.value = const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
      return;
    }
    final simple = RegExp(r'^-?[0-9]+([.,][0-9]+)?$');
    late final String next;
    if (simple.hasMatch(text)) {
      next = text.startsWith('-') ? text.substring(1) : '-$text';
    } else if (text.startsWith('-(') && text.endsWith(')')) {
      next = text.substring(2, text.length - 1);
    } else if (text.startsWith('-')) {
      next = text.substring(1);
    } else {
      next = '-($text)';
    }
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _useOutput() {
    if (_output.isEmpty || _output == 'Error') return;
    final next = _output.replaceFirst(RegExp(r'^x\s*=\s*'), '');
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _append(String value) {
    if (value == 'C') {
      _input.clear();
      setState(() => _output = '');
      return;
    }
    if (value == '⌫') {
      final text = _input.text;
      if (text.isEmpty) return;
      _input.text = text.substring(0, text.length - 1);
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
      return;
    }
    final sel = _input.selection;
    final text = _input.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final next = text.replaceRange(start, end, value);
    _input.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        children: [
          TextField(
            controller: _input,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[0-9a-zA-Z+\-*/^()=.,;x!%' ±\u00B1]"),
              ),
            ],
            decoration: InputDecoration(
              hintText: l10n.calculatorHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _eval(),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _useOutput,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _output.isEmpty ? ' ' : _output,
                      style: AppTheme.headline(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.calculatorCopyResult,
                onPressed: _output.isEmpty
                    ? null
                    : () => Clipboard.setData(ClipboardData(text: _output)),
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SegmentedButton<_CalcPad>(
            segments: [
              ButtonSegment(
                value: _CalcPad.numbers,
                label: Text(l10n.calculatorBasic),
              ),
              ButtonSegment(
                value: _CalcPad.functions,
                label: Text(l10n.calculatorFn),
              ),
              ButtonSegment(
                value: _CalcPad.more,
                label: Text(l10n.calculatorMore),
              ),
            ],
            selected: {_pad},
            onSelectionChanged: (next) => setState(() => _pad = next.first),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l10n.calculatorDeg)),
                ButtonSegment(value: false, label: Text(l10n.calculatorRad)),
              ],
              selected: {_degrees},
              onSelectionChanged: (next) =>
                  setState(() => _degrees = next.first),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const SizedBox(height: 6),
          if (_pad == _CalcPad.more && !widget.calcPlus)
            _CalcPlusLock(onOpen: () => context.push('/marketplace'))
          else
            _Keypad(
              pad: _pad,
              plus: widget.calcPlus,
              shift: _shift,
              onKey: _onKey,
            ),
          if (_plotError != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.plotFailed,
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB42318),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _eval(),
                  child: Text(l10n.calculatorEquals),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _eval(solve: true),
                  child: Text(l10n.calculatorSolve),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: _plotting ? null : _plot,
                  child: _plotting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.calculatorPlot, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.calculatorHistory,
              style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.expression, maxLines: 1),
                  trailing: Text(item.result),
                  onTap: () {
                    _input.text = item.expression;
                    setState(() {
                      _output = item.result;
                      _ans = _numericAns(item.result);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcPlusLock extends StatelessWidget {
  const _CalcPlusLock({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            l10n.calcPlusLocked,
            textAlign: TextAlign.center,
            style: AppTheme.body(fontSize: 13, color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(l10n.marketplace),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.pad,
    required this.onKey,
    this.plus = false,
    this.shift = false,
  });

  final _CalcPad pad;
  final ValueChanged<String> onKey;
  final bool plus;
  final bool shift;

  @override
  Widget build(BuildContext context) {
    final keys = switch (pad) {
      _CalcPad.numbers => [
        [shift ? 'SHIFT*' : 'SHIFT', 'x^2', '√(', 'x^-1'],
        ['7', '8', '9', 'DEL'],
        ['4', '5', '6', '×'],
        ['1', '2', '3', '−'],
        ['0', '.', '±', '+'],
        ['AC', '(', ')', '='],
      ],
      _CalcPad.functions => [
        [shift ? 'sin⁻¹' : 'sin', shift ? 'cos⁻¹' : 'cos', shift ? 'tan⁻¹' : 'tan', 'π'],
        [shift ? 'e^' : 'ln', shift ? '10^' : 'log', 'x', 'Ans'],
        ['^', 'e', '%', '!'],
        ['÷', '×', '−', '+'],
      ],
      _CalcPad.more => [
        const ['sinh(', 'cosh(', 'tanh(', '10^('],
        const ['nCr(', 'nPr(', 'min(', 'max('],
        if (plus) const ['mean(', 'median(', 'stdev(', 'count('],
        const ['mod(', 'gcd(', 'lcm(', 'root('],
        const ['abs(', 'fact(', '=', '!'],
      ],
    };
    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => onKey(_emit(key)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: _keyColor(key),
                            foregroundColor: _keyFg(key),
                            side: BorderSide(
                              color: _keyFg(key).withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            _label(key),
                            style: TextStyle(
                              fontSize: key == 'SHIFT' || key == 'SHIFT*'
                                  ? 11
                                  : 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _emit(String key) {
    return switch (key) {
      'SHIFT*' => 'SHIFT',
      'sin' => 'sin(',
      'cos' => 'cos(',
      'tan' => 'tan(',
      'sin⁻¹' => 'asin(',
      'cos⁻¹' => 'acos(',
      'tan⁻¹' => 'atan(',
      'ln' => 'ln(',
      'log' => 'log(',
      'e^' => 'exp(',
      '10^' => '10^(',
      '√(' => 'sqrt(',
      'x^2' => '^2',
      'x^-1' => '^(-1)',
      'π' => 'pi',
      'Ans' => 'ans',
      'nCr(' => 'ncr(',
      'nPr(' => 'npr(',
      '×' => '*',
      '÷' => '/',
      '−' => '-',
      _ => key,
    };
  }

  String _label(String key) {
    if (key == 'SHIFT*') return 'SHIFT';
    if (key == 'x^2') return 'x²';
    if (key == 'x^-1') return 'x⁻¹';
    return key;
  }

  Color _keyColor(String key) {
    if (key == 'SHIFT' || key == 'SHIFT*') {
      return shift ? const Color(0xFF1D4E89) : const Color(0xFFE8EEF7);
    }
    if (key == '=' || key == 'AC') return const Color(0xFFFFE8C2);
    if (key == 'DEL') return const Color(0xFFF3D6D0);
    if ('+-×÷−*/'.contains(key) && key.length == 1) {
      return const Color(0xFFFFF4D6);
    }
    if (key == 'sin' ||
        key == 'cos' ||
        key == 'tan' ||
        key == 'ln' ||
        key == 'log' ||
        key == '√(' ||
        key.startsWith('sin') ||
        key.startsWith('cos') ||
        key.startsWith('tan')) {
      return const Color(0xFFE4EEF8);
    }
    return const Color(0xFFF7F4EE);
  }

  Color _keyFg(String key) {
    if (key == 'SHIFT*') return Colors.white;
    return const Color(0xFF1A1A1A);
  }
}
