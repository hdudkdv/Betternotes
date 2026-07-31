import 'package:flutter/material.dart';

import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../editor_chrome.dart';
import 'ink_painter.dart';
import 'page_background_painter.dart';
import 'shape_painter.dart';

/// Collapsible page overview docked to the left of the workspace.
class PageSidebar extends StatelessWidget {
  const PageSidebar({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onDuplicate,
    required this.onDelete,
    required this.onClose,
  });

  static const width = 188.0;

  final List<NotePage> pages;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final Future<void> Function(int index) onDuplicate;
  final Future<void> Function(int index) onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: EditorChrome.sidebar,
        border: Border(right: BorderSide(color: EditorChrome.divider)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
            child: Row(
              children: [
                Text(
                  l10n.pages,
                  style: TextStyle(
                    color: EditorChrome.onDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.addPage,
                  onPressed: onAdd,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: EditorChrome.onDark,
                  ),
                ),
                IconButton(
                  tooltip: l10n.pageSidebar,
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: EditorChrome.onDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final selected = index == currentIndex;
                final page = pages[index];
                final pageSize = NotePageSize.resolve(
                  page.paperFormat,
                  page.orientation,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => onSelect(index),
                        onLongPress: () => _showActions(context, l10n, index),
                        child: AspectRatio(
                          aspectRatio: pageSize.width / pageSize.height,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? EditorChrome.selected
                                    : const Color(0xFF3C3C3E),
                                width: selected ? 2.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: pageSize.width,
                                height: pageSize.height,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CustomPaint(
                                      painter: PageBackgroundPainter(
                                        template: page.template,
                                        paper: page.customPaper,
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: InkPainter(
                                        strokes: page.strokes,
                                      ),
                                    ),
                                    CustomPaint(
                                      painter: ShapePainter(
                                        shapes: page.shapes,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: selected
                              ? EditorChrome.onDark
                              : EditorChrome.onDarkMuted,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    AppLocalizations l10n,
    int index,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.duplicatePage),
              onTap: () {
                Navigator.pop(sheetContext);
                onDuplicate(index);
              },
            ),
            ListTile(
              enabled: pages.length > 1,
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.deletePage),
              subtitle: pages.length == 1 ? Text(l10n.lastPageHint) : null,
              onTap: pages.length <= 1
                  ? null
                  : () {
                      Navigator.pop(sheetContext);
                      onDelete(index);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
