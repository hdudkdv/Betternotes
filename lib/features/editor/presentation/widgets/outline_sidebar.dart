import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../editor_chrome.dart';
import 'editor_sheet.dart';

class ImportableChapter {
  const ImportableChapter({
    required this.title,
    required this.sourceNotebookTitle,
    required this.sourceNode,
  });

  final String title;
  final String sourceNotebookTitle;
  final OutlineNode sourceNode;
}

class OutlineSidebar extends StatefulWidget {
  const OutlineSidebar({
    super.key,
    required this.nodes,
    required this.onAdd,
    required this.onAddSubchapter,
    required this.onRename,
    required this.onDelete,
    required this.onTap,
    required this.onIndent,
    this.importable = const [],
    this.onImport,
    this.previousClassLabel,
  });

  final List<OutlineNode> nodes;
  final Future<void> Function(String title) onAdd;
  final Future<void> Function(OutlineNode parent, String title) onAddSubchapter;
  final void Function(OutlineNode node) onRename;
  final void Function(OutlineNode node) onDelete;
  final void Function(OutlineNode node) onTap;
  final void Function(OutlineNode node, int delta) onIndent;
  final List<ImportableChapter> importable;
  final Future<void> Function(ImportableChapter chapter)? onImport;
  final String? previousClassLabel;

  @override
  State<OutlineSidebar> createState() => _OutlineSidebarState();
}

class _OutlineSidebarState extends State<OutlineSidebar> {
  final _composeController = TextEditingController();
  final _composeFocus = FocusNode();
  OutlineNode? _composeParent;
  bool _composing = false;
  final Set<String> _importedKeys = {};

  @override
  void dispose() {
    _composeController.dispose();
    _composeFocus.dispose();
    super.dispose();
  }

  void _startCompose({OutlineNode? parent}) {
    setState(() {
      _composing = true;
      _composeParent = parent;
      _composeController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composeFocus.requestFocus();
    });
  }

  /// Parent for a higher-level chapter relative to [node] (sibling of parent,
  /// or top-level when [node] is depth 0/1).
  OutlineNode? _superiorComposeParent(OutlineNode node) {
    if (node.parentId == null) return null;
    OutlineNode? parent;
    for (final n in widget.nodes) {
      if (n.id == node.parentId) {
        parent = n;
        break;
      }
    }
    if (parent == null || parent.parentId == null) return null;
    for (final n in widget.nodes) {
      if (n.id == parent!.parentId) return n;
    }
    return null;
  }

  void _startComposeSuperior(OutlineNode node) {
    _startCompose(parent: _superiorComposeParent(node));
  }

  void _cancelCompose() {
    setState(() {
      _composing = false;
      _composeParent = null;
      _composeController.clear();
    });
  }

  Future<void> _submitCompose() async {
    final title = _composeController.text.trim();
    if (title.isEmpty) {
      _cancelCompose();
      return;
    }
    final parent = _composeParent;
    _cancelCompose();
    if (parent != null) {
      await widget.onAddSubchapter(parent, title);
    } else {
      await widget.onAdd(title);
    }
  }

  void _showActions(
    BuildContext context,
    OutlineNode node,
    AppLocalizations l10n,
  ) {
    showEditorSheet<void>(
      context,
      builder: (sheetContext) => EditorSheet(
        title: node.title,
        children: [
          EditorSheetTile(
            icon: Icons.account_tree_outlined,
            label: l10n.addSubchapter,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              _startCompose(parent: node);
            },
          ),
          EditorSheetTile(
            icon: Icons.keyboard_double_arrow_up_rounded,
            label: l10n.addParentChapter,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              _startComposeSuperior(node);
            },
          ),
          EditorSheetTile(
            icon: Icons.edit_outlined,
            label: l10n.rename,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onRename(node);
            },
          ),
          EditorSheetTile(
            icon: Icons.format_indent_increase_rounded,
            label: l10n.indent,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onIndent(node, 1);
            },
          ),
          EditorSheetTile(
            icon: Icons.format_indent_decrease_rounded,
            label: l10n.outdent,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onIndent(node, -1);
            },
          ),
          EditorSheetTile(
            icon: Icons.delete_outline_rounded,
            label: l10n.delete,
            chevron: false,
            onTap: () {
              Navigator.pop(sheetContext);
              widget.onDelete(node);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existingTitles = {
      for (final n in widget.nodes) n.title.trim().toLowerCase(),
    };
    final imports = widget.importable
        .where(
          (c) =>
              !existingTitles.contains(c.title.trim().toLowerCase()) &&
              !_importedKeys.contains('${c.sourceNode.notebookId}:${c.sourceNode.id}'),
        )
        .toList();

    return Material(
      color: EditorChrome.floating,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 300,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: EditorChrome.floating,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EditorChrome.floatingBorder),
          boxShadow: EditorChrome.pillShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.outline,
                      style: AppTheme.headline(
                        fontWeight: FontWeight.w700,
                        color: EditorChrome.onDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addSection,
                    onPressed: () => _startCompose(),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: EditorChrome.floatingBorder),
            if (_composing)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12.0 +
                      (_composeParent == null
                          ? 0
                          : (_composeParent!.depth + 1) * 14.0),
                  8,
                  12,
                  4,
                ),
                child: TextField(
                  controller: _composeController,
                  focusNode: _composeFocus,
                  autofocus: true,
                  style: AppTheme.body(color: EditorChrome.onDark),
                  cursorColor: EditorChrome.selected,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitCompose(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: _composeParent == null
                        ? l10n.nameChapterHint
                        : l10n.nameSubchapterHint,
                    hintStyle: AppTheme.body(color: EditorChrome.onDarkMuted),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: EditorChrome.floatingBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: EditorChrome.floatingBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: EditorChrome.selected),
                    ),
                    suffixIcon: IconButton(
                      tooltip: l10n.save,
                      onPressed: _submitCompose,
                      icon: Icon(
                        Icons.check_rounded,
                        color: EditorChrome.selected,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: widget.nodes.isEmpty && !_composing && imports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.outlineEmpty,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(color: EditorChrome.onDarkMuted),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        for (final node in widget.nodes)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.only(
                              left: 12.0 + node.depth * 14,
                              right: 0,
                            ),
                            title: Text(
                              node.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontWeight: node.depth == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: node.depth == 0 ? 14 : 13,
                                color: EditorChrome.onDark,
                              ),
                            ),
                            onTap: () => widget.onTap(node),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (node.depth < 4)
                                  IconButton(
                                    tooltip: l10n.addSubchapter,
                                    icon: Icon(
                                      Icons.add_rounded,
                                      color: EditorChrome.onDarkMuted,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _startCompose(parent: node),
                                  ),
                                IconButton(
                                  tooltip: l10n.moreOptions,
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: EditorChrome.onDarkMuted,
                                  ),
                                  onPressed: () =>
                                      _showActions(context, node, l10n),
                                ),
                              ],
                            ),
                          ),
                        if (imports.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              widget.previousClassLabel ??
                                  l10n.importFromPreviousClass,
                              style: AppTheme.body(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: EditorChrome.onDarkMuted,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: Text(
                              l10n.importChapterHint,
                              style: AppTheme.body(
                                fontSize: 11,
                                color: EditorChrome.onDarkMuted,
                              ),
                            ),
                          ),
                          for (final chapter in imports)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.history_edu_outlined,
                                color: EditorChrome.selected,
                                size: 20,
                              ),
                              title: Text(
                                chapter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.body(
                                  fontWeight: FontWeight.w600,
                                  color: EditorChrome.onDark,
                                ),
                              ),
                              subtitle: Text(
                                chapter.sourceNotebookTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.body(
                                  fontSize: 11,
                                  color: EditorChrome.onDarkMuted,
                                ),
                              ),
                              onTap: widget.onImport == null
                                  ? null
                                  : () async {
                                      final key =
                                          '${chapter.sourceNode.notebookId}:${chapter.sourceNode.id}';
                                      setState(() => _importedKeys.add(key));
                                      await widget.onImport!(chapter);
                                    },
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
