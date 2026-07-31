import 'package:flutter/material.dart';

import '../../../data/models/content_models.dart';

/// Text controller that keeps per-character formatting while editing.
///
/// The block's [TextSpanStyle] runs are the source of truth. Every text change
/// is mapped onto those runs so formatting survives typing, pasting and
/// deleting, and [applyToSelection] can restyle just part of the text.
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({
    required List<TextSpanStyle> runs,
    required this.resolveStyle,
  }) : _runs = _merge(runs.isEmpty ? [const TextSpanStyle(text: '')] : runs),
       super(text: runs.map((run) => run.text).join());

  /// Maps a run onto a concrete [TextStyle]; supplied by the rendering widget
  /// so line-bound blocks can enforce the paper's font size. Reassigned when
  /// the layout mode or the paper template changes.
  TextStyle Function(TextSpanStyle run) resolveStyle;

  /// Called whenever the runs change so the owner can persist the block.
  ValueChanged<List<TextSpanStyle>>? onRunsChanged;

  List<TextSpanStyle> _runs;

  List<TextSpanStyle> get runs => List.unmodifiable(_runs);

  /// Formatting that a toolbar should display for [selection].
  TextSpanStyle styleForSelection(TextSelection selection) {
    if (_runs.isEmpty) return const TextSpanStyle(text: '');
    if (!selection.isValid || selection.isCollapsed) {
      final offset = selection.isValid ? selection.baseOffset : 0;
      return _runAt(offset > 0 ? offset - 1 : 0);
    }
    return _runAt(selection.start);
  }

  TextSpanStyle _runAt(int offset) {
    var position = 0;
    for (final run in _runs) {
      final end = position + run.text.length;
      if (offset < end) return run;
      position = end;
    }
    return _runs.last;
  }

  /// Applies [transform] to [selection], or to the whole block when the
  /// selection is collapsed.
  void applyToSelection(
    TextSelection selection,
    TextSpanStyle Function(TextSpanStyle run) transform,
  ) {
    final length = text.length;
    var start = 0;
    var end = length;
    if (selection.isValid && !selection.isCollapsed) {
      start = selection.start.clamp(0, length);
      end = selection.end.clamp(0, length);
    }
    if (length == 0) {
      _setRuns([transform(_runs.first).copyWith(text: '')]);
      return;
    }
    if (start >= end) return;

    final expanded = _expand(_runs);
    for (var i = start; i < end && i < expanded.styles.length; i++) {
      expanded.styles[i] = transform(expanded.styles[i]);
    }
    _setRuns(_collapse(expanded));
  }

  /// Replaces every run's formatting, keeping the text intact.
  void applyToAll(TextSpanStyle Function(TextSpanStyle run) transform) {
    _setRuns([for (final run in _runs) transform(run)]);
  }

  /// Re-syncs from the model when the block changed elsewhere.
  void syncFromBlock(List<TextSpanStyle> runs) {
    final incoming = _merge(
      runs.isEmpty ? [const TextSpanStyle(text: '')] : runs,
    );
    if (_sameRuns(incoming, _runs)) return;
    _runs = incoming;
    final plain = incoming.map((run) => run.text).join();
    if (plain != text) {
      super.value = TextEditingValue(
        text: plain,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset.clamp(0, plain.length),
        ),
      );
    } else {
      notifyListeners();
    }
  }

  void _setRuns(List<TextSpanStyle> runs) {
    _runs = _merge(runs);
    onRunsChanged?.call(this.runs);
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = super.value.text;
    if (newValue.text != oldText) {
      _runs = _merge(_splice(oldText, newValue.text));
      onRunsChanged?.call(runs);
    }
    super.value = newValue;
  }

  /// Rebuilds the runs after an arbitrary edit by diffing old and new text.
  List<TextSpanStyle> _splice(String oldText, String newText) {
    var prefix = 0;
    final maxPrefix = oldText.length < newText.length
        ? oldText.length
        : newText.length;
    while (prefix < maxPrefix && oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < maxPrefix - prefix &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }
    final removeEnd = oldText.length - suffix;
    final inserted = newText.substring(prefix, newText.length - suffix);

    final expanded = _expand(_runs);
    // Typed text inherits the formatting left of the caret.
    final inheritFrom = prefix > 0 && prefix <= expanded.styles.length
        ? expanded.styles[prefix - 1]
        : (expanded.styles.isNotEmpty
              ? expanded.styles.first
              : _runs.first.copyWith(text: ''));

    final units = expanded.units;
    final styles = expanded.styles;
    final safeStart = prefix.clamp(0, units.length);
    final safeEnd = removeEnd.clamp(safeStart, units.length);
    units.replaceRange(safeStart, safeEnd, inserted.codeUnits);
    styles.replaceRange(
      safeStart,
      safeEnd,
      List.filled(inserted.length, inheritFrom),
    );
    return _collapse(_Expanded(units, styles));
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_runs.length == 1) {
      return TextSpan(text: text, style: resolveStyle(_runs.first));
    }
    return TextSpan(
      style: style,
      children: [
        for (final run in _runs)
          TextSpan(text: run.text, style: resolveStyle(run)),
      ],
    );
  }

  static _Expanded _expand(List<TextSpanStyle> runs) {
    final units = <int>[];
    final styles = <TextSpanStyle>[];
    for (final run in runs) {
      for (final unit in run.text.codeUnits) {
        units.add(unit);
        styles.add(run);
      }
    }
    return _Expanded(units, styles);
  }

  static List<TextSpanStyle> _collapse(_Expanded expanded) {
    if (expanded.units.isEmpty) {
      final base = expanded.styles.isNotEmpty
          ? expanded.styles.first
          : const TextSpanStyle(text: '');
      return [base.copyWith(text: '')];
    }
    final result = <TextSpanStyle>[];
    var runStart = 0;
    for (var i = 1; i <= expanded.units.length; i++) {
      final atEnd = i == expanded.units.length;
      if (atEnd ||
          !expanded.styles[i].sameFormatting(expanded.styles[runStart])) {
        result.add(
          expanded.styles[runStart].copyWith(
            text: String.fromCharCodes(expanded.units.sublist(runStart, i)),
          ),
        );
        runStart = i;
      }
    }
    return result;
  }

  static List<TextSpanStyle> _merge(List<TextSpanStyle> runs) {
    final result = <TextSpanStyle>[];
    for (final run in runs) {
      if (result.isNotEmpty && result.last.sameFormatting(run)) {
        result[result.length - 1] = result.last.copyWith(
          text: result.last.text + run.text,
        );
      } else {
        result.add(run);
      }
    }
    return result.isEmpty ? [const TextSpanStyle(text: '')] : result;
  }

  static bool _sameRuns(List<TextSpanStyle> a, List<TextSpanStyle> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Expanded {
  _Expanded(this.units, this.styles);

  final List<int> units;
  final List<TextSpanStyle> styles;
}
