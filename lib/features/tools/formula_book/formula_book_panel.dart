import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../calculator/plot_series.dart';
import 'formula_book_models.dart';
import 'formula_book_store.dart';

class FormulaBookPanel extends StatefulWidget {
  const FormulaBookPanel({
    super.key,
    required this.store,
    required this.notebookId,
    this.initialChapterId,
    this.onUseFormula,
    this.includePlus = false,
  });

  final FormulaBookStore store;
  final String notebookId;
  final String? initialChapterId;
  final ValueChanged<String>? onUseFormula;
  final bool includePlus;

  @override
  State<FormulaBookPanel> createState() => _FormulaBookPanelState();
}

class _FormulaBookPanelState extends State<FormulaBookPanel> {
  late FormulaBook _book;
  late String _chapterId;

  @override
  void initState() {
    super.initState();
    _book = widget.store.load(plus: widget.includePlus);
    _chapterId =
        widget.initialChapterId ??
        widget.store.lastChapterFor(widget.notebookId) ??
        _book.chapters.first.id;
    if (_book.byId(_chapterId) == null) {
      _chapterId = _book.chapters.first.id;
    }
  }

  FormulaChapter get _chapter =>
      _book.byId(_chapterId) ?? _book.chapters.first;

  Future<void> _persist(FormulaBook book) async {
    setState(() => _book = book);
    await widget.store.save(book);
  }

  Future<void> _select(String id) async {
    setState(() => _chapterId = id);
    await widget.store.setLastChapter(widget.notebookId, id);
  }

  Future<void> _updateRow(FormulaRow row) async {
    final next = _chapter.copyWith(
      rows: [
        for (final r in _chapter.rows)
          if (r.id == row.id) row else r,
      ],
    );
    await _persist(_book.replaceChapter(next));
  }

  Future<void> _addRow() async {
    final next = _chapter.copyWith(
      rows: [..._chapter.rows, FormulaRow.create()],
    );
    await _persist(_book.replaceChapter(next));
  }

  Future<void> _removeRow(String id) async {
    final next = _chapter.copyWith(
      rows: [for (final r in _chapter.rows) if (r.id != id) r],
    );
    await _persist(_book.replaceChapter(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final chapter in _book.chapters)
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(chapter.title),
                    selected: chapter.id == _chapterId,
                    onSelected: (_) => _select(chapter.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            itemCount: _chapter.rows.length,
            itemBuilder: (context, index) {
              final row = _chapter.rows[index];
              return _FormulaRowEditor(
                key: ValueKey(row.id),
                row: row,
                onChanged: _updateRow,
                onDelete: () => _removeRow(row.id),
                onUseFormula: widget.onUseFormula,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: OutlinedButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.formulaAddRow),
          ),
        ),
      ],
    );
  }
}

class _FormulaRowEditor extends StatefulWidget {
  const _FormulaRowEditor({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onDelete,
    this.onUseFormula,
  });

  final FormulaRow row;
  final ValueChanged<FormulaRow> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<String>? onUseFormula;

  @override
  State<_FormulaRowEditor> createState() => _FormulaRowEditorState();
}

class _FormulaRowEditorState extends State<_FormulaRowEditor> {
  late final TextEditingController _symbol;
  late final TextEditingController _term;
  late final TextEditingController _meaning;
  late final TextEditingController _pronunciation;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _symbol = TextEditingController(text: widget.row.symbol);
    _term = TextEditingController(text: widget.row.term);
    _meaning = TextEditingController(text: widget.row.meaning);
    _pronunciation = TextEditingController(text: widget.row.pronunciation);
    _value = TextEditingController(text: widget.row.value);
  }

  @override
  void dispose() {
    _symbol.dispose();
    _term.dispose();
    _meaning.dispose();
    _pronunciation.dispose();
    _value.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onChanged(
      widget.row.copyWith(
        symbol: _symbol.text,
        term: _term.text,
        meaning: _meaning.text,
        pronunciation: _pronunciation.text,
        value: _value.text,
      ),
    );
  }

  Color _symbolColor(String symbol) {
    final s = symbol.trim();
    if (s.isEmpty) return AppTheme.ink;
    return switch (s) {
      'π' || 'φ' || 'Ω' || 'ω' => const Color(0xFF1D4E89),
      '∑' || '∫' || '∪' || '∩' || '∈' => const Color(0xFF7C3AED),
      '√' || '±' || '≈' || '≠' || '≤' || '≥' => const Color(0xFF0F766E),
      '∞' || 'Δ' => const Color(0xFFB42318),
      'α' || 'β' || 'γ' || 'θ' || 'λ' || 'μ' || 'σ' || 'ρ' =>
        const Color(0xFF9A3412),
      _ => AppTheme.ink,
    };
  }

  InputDecoration _field(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: AppTheme.paperDeep,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _symbol,
                    textAlign: TextAlign.center,
                    style: AppTheme.headline(
                      fontSize: 22,
                      color: _symbolColor(_symbol.text),
                    ),
                    decoration: _field(l10n.formulaSymbol),
                    onChanged: (_) => setState(() {}),
                    onEditingComplete: _commit,
                    onTapOutside: (_) => _commit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _term,
                    decoration: _field(l10n.formulaTerm),
                    onEditingComplete: _commit,
                    onTapOutside: (_) => _commit(),
                  ),
                ),
                if (widget.onUseFormula != null &&
                    FunctionPlotPrep.looksPlottable(
                      widget.row.term,
                      widget.row.value,
                    ))
                  IconButton(
                    tooltip: l10n.graphFromBook,
                    onPressed: () {
                      final expr = FunctionPlotPrep.fromFormula(
                        term: _term.text,
                        value: _value.text,
                      );
                      if (expr != null) widget.onUseFormula!(expr);
                    },
                    icon: const Icon(Icons.show_chart_rounded, size: 18),
                  ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _meaning,
              decoration: _field(l10n.formulaMeaning),
              onEditingComplete: _commit,
              onTapOutside: (_) => _commit(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pronunciation,
              decoration: _field(l10n.formulaPronunciation),
              onEditingComplete: _commit,
              onTapOutside: (_) => _commit(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _value,
              decoration: _field(l10n.formulaValue),
              onEditingComplete: _commit,
              onTapOutside: (_) => _commit(),
            ),
          ],
        ),
      ),
    );
  }
}
