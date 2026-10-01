import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../formula_book/formula_book_models.dart';
import '../formula_book/formula_book_store.dart';
import 'function_plotter.dart';
import 'plot_series.dart';

class _Row {
  _Row({String expression = ''})
      : controller = TextEditingController(text: expression);

  final TextEditingController controller;
  bool derivative = false;

  void dispose() => controller.dispose();
}

Future<Uint8List?> showGraphStudioSheet(
  BuildContext context, {
  String? initialExpression,
  required bool degrees,
  required FormulaBookStore formulaStore,
}) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _GraphStudioSheet(
      initialExpression: initialExpression,
      degrees: degrees,
      formulaStore: formulaStore,
    ),
  );
}

class _GraphStudioSheet extends StatefulWidget {
  const _GraphStudioSheet({
    this.initialExpression,
    required this.degrees,
    required this.formulaStore,
  });

  final String? initialExpression;
  final bool degrees;
  final FormulaBookStore formulaStore;

  @override
  State<_GraphStudioSheet> createState() => _GraphStudioSheetState();
}

class _GraphStudioSheetState extends State<_GraphStudioSheet> {
  late final List<_Row> _rows;
  bool _busy = false;
  String? _error;
  late final TextEditingController _xMin;
  late final TextEditingController _xMax;
  late final TextEditingController _yMin;
  late final TextEditingController _yMax;
  late final TextEditingController _xStep;
  late final TextEditingController _yStep;

  static const _quickFns = [
    'sin(x)',
    'x^2',
    'sqrt(1-x^2)',
    'e^x',
    'ln(x)',
    '1/x',
  ];

  @override
  void initState() {
    super.initState();
    final parts = FunctionPlotPrep.splitExpressions(
      widget.initialExpression ?? '',
    );
    _rows = [
      if (parts.isEmpty) _Row() else
        for (final part in parts) _Row(expression: part),
    ];
    final def = widget.degrees ? 360 : 8;
    _xMin = TextEditingController(text: widget.degrees ? '-360' : '-8');
    _xMax = TextEditingController(text: '$def');
    _yMin = TextEditingController();
    _yMax = TextEditingController();
    _xStep = TextEditingController();
    _yStep = TextEditingController();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _xMin.dispose();
    _xMax.dispose();
    _yMin.dispose();
    _yMax.dispose();
    _xStep.dispose();
    _yStep.dispose();
    super.dispose();
  }

  Future<void> _insert() async {
    final series = <PlotSeries>[];
    for (var i = 0; i < _rows.length; i++) {
      final text = _rows[i].controller.text.trim();
      if (text.isEmpty) continue;
      series.add(
        PlotSeries(
          expression: text,
          label: FunctionPlotPrep.prettyLabel(text) == 'f(x)'
              ? FunctionPlotPrep.nextFnName(i)
              : FunctionPlotPrep.prettyLabel(text),
          color: kPlotColors[i % kPlotColors.length],
          plotDerivative: _rows[i].derivative,
        ),
      );
    }
    if (series.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await FunctionPlotter.renderPng(
        series,
        degrees: widget.degrees,
        xMin: double.tryParse(_xMin.text.replaceAll(',', '.')),
        xMax: double.tryParse(_xMax.text.replaceAll(',', '.')),
        yMin: double.tryParse(_yMin.text.replaceAll(',', '.')),
        yMax: double.tryParse(_yMax.text.replaceAll(',', '.')),
        xStep: double.tryParse(_xStep.text.replaceAll(',', '.')),
        yStep: double.tryParse(_yStep.text.replaceAll(',', '.')),
      );
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _error = 'plot');
        return;
      }
      Navigator.pop(context, bytes);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _numField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _fromBook() async {
    final book = widget.formulaStore.load();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FormulaPickSheet(book: book),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final empty = _rows.indexWhere((r) => r.controller.text.trim().isEmpty);
      if (empty >= 0) {
        _rows[empty].controller.text = picked;
      } else {
        _rows.add(_Row(expression: picked));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(palette.radius + 8),
            border: Border.all(color: palette.outline),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.graphStudioTitle,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.graphStudioHint,
                  style: AppTheme.body(fontSize: 13, color: palette.ink),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: kPlotColors[i % kPlotColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _rows[i].controller,
                            decoration: InputDecoration(
                              labelText: FunctionPlotPrep.nextFnName(i),
                              hintText: 'sin(x)',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        FilterChip(
                          label: Text(l10n.graphDerivative),
                          selected: _rows[i].derivative,
                          onSelected: (v) =>
                              setState(() => _rows[i].derivative = v),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: _rows.length <= 1
                              ? null
                              : () => setState(() {
                                  _rows[i].dispose();
                                  _rows.removeAt(i);
                                }),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final fn in _quickFns)
                      ActionChip(
                        label: Text(fn, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() {
                          final empty = _rows.indexWhere(
                            (r) => r.controller.text.trim().isEmpty,
                          );
                          if (empty >= 0) {
                            _rows[empty].controller.text = fn;
                          } else {
                            _rows.add(_Row(expression: fn));
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _rows.add(_Row())),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.graphAddFunction),
                    ),
                    TextButton.icon(
                      onPressed: _fromBook,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l10n.graphFromBook),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.graphRange,
                  style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _numField(_xMin, l10n.graphXMin)),
                    const SizedBox(width: 6),
                    Expanded(child: _numField(_xMax, l10n.graphXMax)),
                    const SizedBox(width: 6),
                    Expanded(child: _numField(_yMin, l10n.graphYMin)),
                    const SizedBox(width: 6),
                    Expanded(child: _numField(_yMax, l10n.graphYMax)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _numField(_xStep, l10n.graphTickX)),
                    const SizedBox(width: 6),
                    Expanded(child: _numField(_yStep, l10n.graphTickY)),
                  ],
                ),
                if (_error != null)
                  Text(
                    l10n.plotFailed,
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _insert,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.calculatorPlot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormulaPickSheet extends StatelessWidget {
  const _FormulaPickSheet({required this.book});

  final FormulaBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    final items = <({String title, String expr})>[];
    for (final chapter in book.chapters) {
      for (final row in chapter.rows) {
        final expr = FunctionPlotPrep.fromFormula(
          term: row.term,
          value: row.value,
        );
        if (expr == null) continue;
        items.add((
          title: row.term.isEmpty ? expr : row.term,
          expr: expr,
        ));
      }
    }
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(palette.radius + 8),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Text(
                l10n.graphFromBook,
                style: AppTheme.headline(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.graphNoBookFormulas),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.title),
                      subtitle: Text(item.expr),
                      onTap: () => Navigator.pop(context, item.expr),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
