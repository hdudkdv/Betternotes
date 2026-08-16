import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final CalculatorStore store;
  final String notebookId;
  final Future<void> Function(String expression) onInsertPlot;

  @override
  State<CalculatorPanel> createState() => _CalculatorPanelState();
}

enum _CalcPad { numbers, functions }

class _CalculatorPanelState extends State<CalculatorPanel> {
  final _engine = CalculatorEngine();
  final _input = TextEditingController();
  String _output = '';
  String _ans = '';
  late List<CalcHistoryEntry> _history;
  bool _plotting = false;
  _CalcPad _pad = _CalcPad.numbers;

  @override
  void initState() {
    super.initState();
    _history = widget.store.historyFor(widget.notebookId);
    if (_history.isNotEmpty) {
      _input.text = _history.first.expression;
      _output = _history.first.result;
      _ans = _history.first.result;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _eval({bool solve = false}) async {
    var expr = _input.text.trim();
    if (expr.isEmpty) return;
    if (expr.contains('ans') && _ans.isNotEmpty) {
      expr = expr.replaceAll('ans', _ans);
    }
    final result = solve || expr.contains('=')
        ? _engine.evaluateOrSolve(expr)
        : _engine.evaluate(expr);
    setState(() => _output = result.ok && expr.contains('=') && expr.contains('x')
        ? 'x = ${result.display}'
        : result.display);
    if (!result.ok) return;
    _ans = result.display;
    final entry = CalcHistoryEntry(
      expression: expr,
      result: _output,
      at: DateTime.now(),
    );
    await widget.store.add(widget.notebookId, entry);
    if (mounted) {
      setState(() => _history = widget.store.historyFor(widget.notebookId));
    }
  }

  Future<void> _plot() async {
    final expr = _input.text.trim();
    if (expr.isEmpty) return;
    setState(() => _plotting = true);
    try {
      await widget.onInsertPlot(expr);
    } finally {
      if (mounted) setState(() => _plotting = false);
    }
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
                RegExp(r"[0-9a-zA-Z+\-*/^()=.,x!% ]"),
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _output.isEmpty ? ' ' : _output,
              style: AppTheme.headline(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          SegmentedButton<_CalcPad>(
            segments: [
              ButtonSegment(value: _CalcPad.numbers, label: Text(l10n.calculatorBasic)),
              ButtonSegment(value: _CalcPad.functions, label: Text(l10n.calculatorFn)),
            ],
            selected: {_pad},
            onSelectionChanged: (next) => setState(() => _pad = next.first),
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 6),
          _Keypad(pad: _pad, onKey: _append),
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
                    setState(() => _output = item.result);
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

class _Keypad extends StatelessWidget {
  const _Keypad({required this.pad, required this.onKey});

  final _CalcPad pad;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final keys = pad == _CalcPad.numbers
        ? const [
            ['C', '⌫', '(', ')'],
            ['7', '8', '9', '/'],
            ['4', '5', '6', '*'],
            ['1', '2', '3', '-'],
            ['0', '.', '%', '+'],
          ]
        : const [
            ['sin(', 'cos(', 'tan(', '√('],
            ['ln(', 'log(', 'exp(', '^'],
            ['π', 'e', 'x', 'ans'],
            ['abs(', 'fact(', '=', '!'],
          ];
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
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => onKey(switch (key) {
                            '√(' => 'sqrt(',
                            'π' => 'pi',
                            _ => key,
                          }),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(key, style: const TextStyle(fontSize: 13)),
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
}
