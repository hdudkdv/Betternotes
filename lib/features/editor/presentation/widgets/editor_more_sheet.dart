import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../../domain/ink_models.dart';
import '../editor_chrome.dart';
import 'editor_sheet.dart';
import 'editor_top_bar.dart';

/// Grouped menu behind the three dots in the editor header.
///
/// Switches apply right away and leave the sheet open; everything that opens
/// another surface closes it first.
Future<void> showEditorMoreSheet(
  BuildContext context, {
  required PageTemplate template,
  required PageBrowseMode browseMode,
  required CanvasMode canvasMode,
  required PaperFormat defaultPaperFormat,
  required PageOrientation defaultOrientation,
  required ValueChanged<EditorMenuAction> onAction,
  bool studyModeUnlocked = false,
}) {
  return showEditorSheet<void>(
    context,
    builder: (context) => _EditorMoreSheet(
      template: template,
      browseMode: browseMode,
      canvasMode: canvasMode,
      defaultPaperFormat: defaultPaperFormat,
      defaultOrientation: defaultOrientation,
      onAction: onAction,
      studyModeUnlocked: studyModeUnlocked,
    ),
  );
}

class _EditorMoreSheet extends StatefulWidget {
  const _EditorMoreSheet({
    required this.template,
    required this.browseMode,
    required this.canvasMode,
    required this.defaultPaperFormat,
    required this.defaultOrientation,
    required this.onAction,
    this.studyModeUnlocked = false,
  });

  final PageTemplate template;
  final PageBrowseMode browseMode;
  final CanvasMode canvasMode;
  final PaperFormat defaultPaperFormat;
  final PageOrientation defaultOrientation;
  final ValueChanged<EditorMenuAction> onAction;
  final bool studyModeUnlocked;

  @override
  State<_EditorMoreSheet> createState() => _EditorMoreSheetState();
}

class _EditorMoreSheetState extends State<_EditorMoreSheet> {
  late PageTemplate _template = widget.template;
  late PageBrowseMode _browseMode = widget.browseMode;
  late PaperFormat _paperFormat = widget.defaultPaperFormat;
  late PageOrientation _orientation = widget.defaultOrientation;

  /// Applies an action without closing, for the toggles and paper tiles.
  void _keepOpen(EditorMenuAction action) => widget.onAction(action);

  void _close(EditorMenuAction action) {
    Navigator.pop(context);
    widget.onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final infinite = widget.canvasMode == CanvasMode.infinite;

    return EditorSheet(
      title: l10n.moreOptions,
      children: [
        EditorSheetGroup(l10n.menuPaperGroup),
        Row(
          children: [
            _PaperTile(
              label: l10n.blank,
              template: PageTemplate.blank,
              selected: _template == PageTemplate.blank,
              onTap: () {
                setState(() => _template = PageTemplate.blank);
                _keepOpen(EditorMenuAction.templateBlank);
              },
            ),
            _PaperTile(
              label: l10n.lined,
              template: PageTemplate.lined,
              selected: _template == PageTemplate.lined,
              onTap: () {
                setState(() => _template = PageTemplate.lined);
                _keepOpen(EditorMenuAction.templateLined);
              },
            ),
            _PaperTile(
              label: l10n.grid,
              template: PageTemplate.grid,
              selected: _template == PageTemplate.grid,
              onTap: () {
                setState(() => _template = PageTemplate.grid);
                _keepOpen(EditorMenuAction.templateGrid);
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        EditorSheetTile(
          icon: Icons.grid_on_rounded,
          label: l10n.paperCreator,
          onTap: () => _close(EditorMenuAction.paperCreator),
        ),
        const SizedBox(height: 14),
        EditorSheetGroup(l10n.menuViewGroup),
        EditorSheetTile(
          icon: Icons.visibility_outlined,
          label: l10n.presentView,
          onTap: () => _close(EditorMenuAction.presentView),
        ),
        if (!infinite)
          EditorSheetSegments(
            icon: Icons.swap_horiz_rounded,
            label: l10n.scrollDirection,
            options: [l10n.browseSwipe, l10n.browseScroll],
            selectedIndex: _browseMode == PageBrowseMode.swipeHorizontal
                ? 0
                : 1,
            onSelect: (index) {
              final next = index == 0
                  ? PageBrowseMode.swipeHorizontal
                  : PageBrowseMode.scrollVertical;
              if (next == _browseMode) return;
              setState(() => _browseMode = next);
              _keepOpen(EditorMenuAction.scrollDirection);
            },
          ),
        // The document type is fixed when the notebook is created; converting
        // an existing notebook would break its page layout.
        EditorSheetInfoRow(
          icon: infinite ? Icons.all_out_rounded : Icons.article_outlined,
          label: l10n.documentType,
          value: infinite ? l10n.infiniteDocument : l10n.pageMode,
          hint: l10n.documentTypeFixedHint,
        ),
        if (!infinite) ...[
          const SizedBox(height: 6),
          EditorSheetGroup(l10n.paperSize),
          DropdownButtonFormField<PaperFormat>(
            initialValue: _paperFormat,
            items: [
              for (final format in PaperFormat.values)
                DropdownMenuItem(
                  value: format,
                  child: Text(_paperFormatLabel(l10n, format)),
                ),
            ],
            onChanged: (format) {
              if (format == null || format == _paperFormat) return;
              setState(() => _paperFormat = format);
              _keepOpen(_paperFormatAction(format));
            },
          ),
          const SizedBox(height: 12),
          EditorSheetSegments(
            icon: Icons.screen_rotation_alt_rounded,
            label: l10n.pageOrientation,
            options: [l10n.portrait, l10n.landscape],
            selectedIndex: _orientation == PageOrientation.portrait ? 0 : 1,
            onSelect: (index) {
              final orientation = index == 0
                  ? PageOrientation.portrait
                  : PageOrientation.landscape;
              if (orientation == _orientation) return;
              setState(() => _orientation = orientation);
              _keepOpen(
                orientation == PageOrientation.portrait
                    ? EditorMenuAction.orientationPortrait
                    : EditorMenuAction.orientationLandscape,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              l10n.newPagesOnlyHint,
              style: AppTheme.body(
                fontSize: 12,
                color: EditorChrome.onDarkMuted,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        EditorSheetGroup(l10n.menuDocumentGroup),
        if (widget.studyModeUnlocked)
          EditorSheetTile(
            icon: Icons.school_outlined,
            label: l10n.studyMode,
            onTap: () => _close(EditorMenuAction.studyMode),
          ),
        EditorSheetTile(
          icon: Icons.style_outlined,
          label: l10n.noteToFlashcard,
          onTap: () => _close(EditorMenuAction.makeFlashcard),
        ),
        EditorSheetTile(
          icon: Icons.bookmark_add_outlined,
          label: l10n.saveSnapshot,
          onTap: () => _close(EditorMenuAction.saveSnapshot),
        ),
        EditorSheetTile(
          icon: Icons.history_rounded,
          label: l10n.restoreSnapshot,
          onTap: () => _close(EditorMenuAction.restoreSnapshot),
        ),
        EditorSheetTile(
          icon: Icons.list_alt_rounded,
          label: l10n.outline,
          onTap: () => _close(EditorMenuAction.outline),
        ),
        EditorSheetTile(
          icon: Icons.sell_outlined,
          label: l10n.addTag,
          onTap: () => _close(EditorMenuAction.addTag),
        ),
        EditorSheetTile(
          icon: Icons.groups_outlined,
          label: l10n.collaborate,
          onTap: () => _close(EditorMenuAction.collaborate),
        ),
        EditorSheetTile(
          icon: Icons.wifi_tethering_rounded,
          label: l10n.nearbySyncTitle,
          onTap: () => _close(EditorMenuAction.nearbySync),
        ),
        EditorSheetTile(
          icon: Icons.picture_as_pdf_outlined,
          label: l10n.importPdf,
          onTap: () => _close(EditorMenuAction.importPdf),
        ),
        EditorSheetTile(
          icon: Icons.document_scanner_outlined,
          label: l10n.scanPages,
          onTap: () => _close(EditorMenuAction.scanPages),
        ),
        EditorSheetTile(
          icon: Icons.html_outlined,
          label: l10n.importHtml,
          onTap: () => _close(EditorMenuAction.importHtml),
        ),
        EditorSheetTile(
          icon: Icons.file_open_outlined,
          label: l10n.importAnyFile,
          onTap: () => _close(EditorMenuAction.importAnyFile),
        ),
        EditorSheetTile(
          icon: Icons.ios_share_rounded,
          label: l10n.shareExport,
          onTap: () => _close(EditorMenuAction.share),
        ),
        const SizedBox(height: 14),
        EditorSheetTile(
          icon: Icons.tune_rounded,
          label: l10n.settings,
          onTap: () => _close(EditorMenuAction.settings),
        ),
      ],
    );
  }

  EditorMenuAction _paperFormatAction(PaperFormat format) => switch (format) {
    PaperFormat.a2 => EditorMenuAction.paperA2,
    PaperFormat.a3 => EditorMenuAction.paperA3,
    PaperFormat.a4 => EditorMenuAction.paperA4,
    PaperFormat.a5 => EditorMenuAction.paperA5,
    PaperFormat.a6 => EditorMenuAction.paperA6,
    PaperFormat.letter => EditorMenuAction.paperLetter,
    PaperFormat.legal => EditorMenuAction.paperLegal,
    PaperFormat.tabloid => EditorMenuAction.paperTabloid,
  };
}

String _paperFormatLabel(AppLocalizations l10n, PaperFormat format) =>
    switch (format) {
      PaperFormat.a2 => 'A2',
      PaperFormat.a3 => 'A3',
      PaperFormat.a4 => 'A4',
      PaperFormat.a5 => 'A5',
      PaperFormat.a6 => 'A6',
      PaperFormat.letter => l10n.paperLetter,
      PaperFormat.legal => l10n.paperLegal,
      PaperFormat.tabloid => l10n.paperTabloid,
    };

/// Paper choice with a miniature of the ruling.
class _PaperTile extends StatelessWidget {
  const _PaperTile({
    required this.label,
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PageTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: selected ? EditorChrome.selectedSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? EditorChrome.selected
                    : EditorChrome.floatingBorder,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.35,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: _PaperMiniature(template),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: AppTheme.body(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: EditorChrome.onDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperMiniature extends CustomPainter {
  const _PaperMiniature(this.template);

  final PageTemplate template;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF7F5F0),
    );
    if (template == PageTemplate.blank) return;

    final line = Paint()
      ..color = const Color(0xFFA9BCD0)
      ..strokeWidth = 1;
    const step = 7.0;
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(2, y), Offset(size.width - 2, y), line);
    }
    if (template == PageTemplate.grid) {
      for (var x = step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 2), Offset(x, size.height - 2), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperMiniature oldDelegate) =>
      oldDelegate.template != template;
}
