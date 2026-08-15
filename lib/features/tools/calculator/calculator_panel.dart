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

class _CalculatorPanelState extends State<CalculatorPanel> {
  final _engine = CalculatorEngine();
  final _input = TextEditingController();
  String _output = '';
  late List<CalcHistoryEntry> _history;
  bool _plotting = false;

  @override
  void initState() {
    super.initState();
    _history = widget.store.historyFor(widget.notebookId);
    if (_history.isNotEmpty) {
      _input.text = _history.first.expression;
      _output = _history.first.result;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _eval() async {
    final expr = _input.text.trim();
    if (expr.isEmpty) return;
    final result = _engine.evaluate(expr);
    setState(() => _output = result.display);
    if (!result.ok) return;
    final entry = CalcHistoryEntry(
      expression: expr,
      result: result.display,
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          TextField(
            controller: _input,
            autofocus: false,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z+\-*/^().,x ]')),
            ],
            decoration: InputDecoration(
              hintText: l10n.calculatorHint,
              isDense: true,
            ),
            onSubmitted: (_) => _eval(),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _output,
              style: AppTheme.headline(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final key in const [
                '7',
                '8',
                '9',
                '/',
                '4',
                '5',
                '6',
                '*',
                '1',
                '2',
                '3',
                '-',
                '0',
                '.',
                '(',
                '+',
                ')',
                '^',
                'x',
                'sin(',
                'cos(',
                'sqrt(',
              ])
                SizedBox(
                  width: 52,
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => _append(key),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(key, style: const TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _eval,
                  child: Text(l10n.calculatorEquals),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _plotting ? null : _plot,
                  child: _plotting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.calculatorPlot),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.calculatorHistory,
              style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.expression),
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
