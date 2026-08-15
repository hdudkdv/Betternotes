import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'formula_book_models.dart';
import 'formula_book_store.dart';

class FormulaBookPanel extends StatefulWidget {
  const FormulaBookPanel({
    super.key,
    required this.store,
    required this.notebookId,
    this.initialChapterId,
  });

  final FormulaBookStore store;
  final String notebookId;
  final String? initialChapterId;

  @override
  State<FormulaBookPanel> createState() => _FormulaBookPanelState();
}

class _FormulaBookPanelState extends State<FormulaBookPanel> {
  late FormulaBook _book;
  late String _chapterId;

  @override
  void initState() {
    super.initState();
    _book = widget.store.load();
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.formulaTerm,
                  style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  l10n.formulaValue,
                  style: AppTheme.body(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _chapter.rows.length,
            itemBuilder: (context, index) {
              final row = _chapter.rows[index];
              return _FormulaRowEditor(
                key: ValueKey(row.id),
                row: row,
                onChanged: _updateRow,
                onDelete: () => _removeRow(row.id),
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
  });

  final FormulaRow row;
  final ValueChanged<FormulaRow> onChanged;
  final VoidCallback onDelete;

  @override
  State<_FormulaRowEditor> createState() => _FormulaRowEditorState();
}

class _FormulaRowEditorState extends State<_FormulaRowEditor> {
  late final TextEditingController _term;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _term = TextEditingController(text: widget.row.term);
    _value = TextEditingController(text: widget.row.value);
  }

  @override
  void dispose() {
    _term.dispose();
    _value.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onChanged(
      widget.row.copyWith(term: _term.text, value: _value.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _term,
              decoration: const InputDecoration(isDense: true),
              onEditingComplete: _commit,
              onTapOutside: (_) => _commit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _value,
              decoration: const InputDecoration(isDense: true),
              onEditingComplete: _commit,
              onTapOutside: (_) => _commit(),
            ),
          ),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
