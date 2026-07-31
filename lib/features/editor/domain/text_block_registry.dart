import 'package:flutter/material.dart';

import '../../../data/models/content_models.dart';
import 'rich_text_controller.dart';

/// Keeps one [RichTextEditingController] alive per text block on the page.
///
/// The formatting bar lives outside the text layer, so it needs a stable way to
/// reach the controller that currently owns the caret.
class TextBlockRegistry {
  final Map<String, RichTextEditingController> _controllers = {};

  RichTextEditingController obtain({
    required TextBlock block,
    required TextStyle Function(TextSpanStyle run) resolveStyle,
    required ValueChanged<List<TextSpanStyle>> onRunsChanged,
  }) {
    final existing = _controllers[block.id];
    if (existing != null) {
      existing.onRunsChanged = onRunsChanged;
      existing.resolveStyle = resolveStyle;
      return existing;
    }
    final created = RichTextEditingController(
      runs: block.spans,
      resolveStyle: resolveStyle,
    )..onRunsChanged = onRunsChanged;
    _controllers[block.id] = created;
    return created;
  }

  RichTextEditingController? find(String? blockId) =>
      blockId == null ? null : _controllers[blockId];

  /// Drops controllers for blocks that no longer exist.
  void retainOnly(Set<String> blockIds) {
    final stale = _controllers.keys
        .where((id) => !blockIds.contains(id))
        .toList();
    for (final id in stale) {
      _controllers.remove(id)?.dispose();
    }
  }

  void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}
