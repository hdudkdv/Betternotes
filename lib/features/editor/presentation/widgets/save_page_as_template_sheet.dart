import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/content_models.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../../domain/ink_models.dart';
import '../editor_chrome.dart';
import 'page_background_painter.dart';

/// Result of the "save page as template" flow.
class SavePageAsTemplateResult {
  const SavePageAsTemplateResult(this.template);
  final PaperTemplate template;
}

Future<SavePageAsTemplateResult?> showSavePageAsTemplateDialog({
  required BuildContext context,
  required NotePage page,
  PaperTemplate? currentPaper,
}) {
  return showModalBottomSheet<SavePageAsTemplateResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return _SavePageAsTemplateSheet(page: page, currentPaper: currentPaper);
    },
  );
}

enum _LineSource { none, fromPage, custom }

class _SavePageAsTemplateSheet extends StatefulWidget {
  const _SavePageAsTemplateSheet({required this.page, this.currentPaper});

  final NotePage page;
  final PaperTemplate? currentPaper;

  @override
  State<_SavePageAsTemplateSheet> createState() =>
      _SavePageAsTemplateSheetState();
}

class _SavePageAsTemplateSheetState extends State<_SavePageAsTemplateSheet> {
  late final TextEditingController _name;
  _LineSource _source = _LineSource.fromPage;
  late List<double> _hLines;
  late List<double> _vLines;
  late int _bg;
  late int _lineColor;

  Size get _pageSize => NotePageSize.defaultSize;

  @override
  void initState() {
    super.initState();
    final paper = widget.currentPaper;
    _name = TextEditingController(text: paper?.name ?? '');
    _bg = paper?.backgroundColor ?? 0xFFFFFBF5;
    _lineColor = paper?.lineColor ?? 0xFFD7D2C8;
    _hLines = _linesFromPaper(paper);
    _vLines =
        paper?.verticalLines?.toList() ??
        (paper != null && paper.style == 'lined'
            ? [paper.marginLeft]
            : paper != null && paper.style == 'custom'
            ? (paper.verticalLines?.toList() ?? [])
            : paper != null &&
                  (paper.style == 'lined' ||
                      widget.page.template == PageTemplate.lined)
            ? [paper.marginLeft]
            : widget.page.template == PageTemplate.lined
            ? [72.0]
            : <double>[]);
    if (paper == null || paper.style == 'blank') {
      _source = _LineSource.none;
    } else if (paper.style == 'custom') {
      _source = _LineSource.custom;
    } else {
      _source = _LineSource.fromPage;
    }
  }

  List<double> _linesFromPaper(PaperTemplate? paper) {
    if (paper == null) {
      if (widget.page.template == PageTemplate.lined) {
        return PaperTemplate.evenlySpacedLines(
          start: 48,
          spacing: 28,
          end: _pageSize.height,
        );
      }
      if (widget.page.template == PageTemplate.grid) {
        return PaperTemplate.evenlySpacedLines(
          start: 0,
          spacing: 24,
          end: _pageSize.height,
        );
      }
      return [];
    }
    if (paper.horizontalLines != null && paper.horizontalLines!.isNotEmpty) {
      return List.of(paper.horizontalLines!);
    }
    if (paper.style == 'blank') return [];
    if (paper.style == 'grid') {
      return PaperTemplate.evenlySpacedLines(
        start: 0,
        spacing: paper.gridSize,
        end: _pageSize.height,
      );
    }
    return PaperTemplate.evenlySpacedLines(
      start: paper.marginTop,
      spacing: paper.lineSpacing,
      end: _pageSize.height,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  PaperTemplate _buildDraft() {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim().isEmpty ? l10n.myPaper : _name.text.trim();
    switch (_source) {
      case _LineSource.none:
        return PaperTemplate.create(
          name: name,
          backgroundColor: _bg,
          lineColor: _lineColor,
          style: 'blank',
        );
      case _LineSource.fromPage:
        final paper = widget.currentPaper;
        if (paper != null && paper.style != 'custom') {
          return PaperTemplate.create(
            name: name,
            lineSpacing: paper.lineSpacing,
            gridSize: paper.gridSize,
            marginLeft: paper.marginLeft,
            marginTop: paper.marginTop,
            backgroundColor: paper.backgroundColor,
            lineColor: paper.lineColor,
            style: paper.style == 'blank' ? 'blank' : paper.style,
          );
        }
        // Fall through to custom snapshot of current generated lines.
        return PaperTemplate.create(
          name: name,
          backgroundColor: _bg,
          lineColor: _lineColor,
          style: _hLines.isEmpty && _vLines.isEmpty ? 'blank' : 'custom',
          horizontalLines: _hLines.isEmpty ? null : (List.of(_hLines)..sort()),
          verticalLines: _vLines.isEmpty ? null : (List.of(_vLines)..sort()),
          marginLeft: _vLines.isEmpty ? 72 : _vLines.first,
          marginTop: _hLines.isEmpty ? 48 : _hLines.first,
          lineSpacing: _hLines.length >= 2
              ? (_hLines[1] - _hLines[0]).abs().clamp(12, 64)
              : 28,
        );
      case _LineSource.custom:
        final hs = List.of(_hLines)..sort();
        final vs = List.of(_vLines)..sort();
        return PaperTemplate.create(
          name: name,
          backgroundColor: _bg,
          lineColor: _lineColor,
          style: hs.isEmpty && vs.isEmpty ? 'blank' : 'custom',
          horizontalLines: hs.isEmpty ? null : hs,
          verticalLines: vs.isEmpty ? null : vs,
          marginLeft: vs.isEmpty ? 72 : vs.first,
          marginTop: hs.isEmpty ? 48 : hs.first,
          lineSpacing: hs.length >= 2
              ? (hs[1] - hs[0]).abs().clamp(12, 64)
              : 28,
        );
    }
  }

  void _onPreviewTap(Offset local, Size previewSize) {
    if (_source != _LineSource.custom) return;
    final scaleX = _pageSize.width / previewSize.width;
    final scaleY = _pageSize.height / previewSize.height;
    final pageY = local.dy * scaleY;
    final pageX = local.dx * scaleX;

    // Near a vertical strip on the left third → toggle vertical margin.
    if (local.dx < previewSize.width * 0.28) {
      setState(() {
        const tol = 14.0;
        final existing = _vLines.indexWhere((x) => (x - pageX).abs() < tol);
        if (existing >= 0) {
          _vLines.removeAt(existing);
        } else {
          _vLines = [pageX.clamp(12.0, _pageSize.width - 12)];
        }
      });
      return;
    }

    setState(() {
      const tol = 12.0;
      final existing = _hLines.indexWhere((y) => (y - pageY).abs() < tol);
      if (existing >= 0) {
        _hLines.removeAt(existing);
      } else {
        _hLines.add(pageY.clamp(8.0, _pageSize.height - 8));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = _buildDraft();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.savePageAsTemplate,
                style: AppTheme.headline(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.savePageAsTemplateHint,
                style: AppTheme.body(
                  fontSize: 13,
                  color: AppTheme.ink.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  hintText: l10n.myPaper,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.lineLayout,
                style: AppTheme.body(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_LineSource>(
                segments: [
                  ButtonSegment(
                    value: _LineSource.none,
                    label: Text(l10n.noLines),
                    icon: const Icon(Icons.crop_portrait, size: 16),
                  ),
                  ButtonSegment(
                    value: _LineSource.fromPage,
                    label: Text(l10n.fromPage),
                    icon: const Icon(Icons.copy_all_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: _LineSource.custom,
                    label: Text(l10n.customLines),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                  ),
                ],
                selected: {_source},
                onSelectionChanged: (s) {
                  setState(() {
                    _source = s.first;
                    if (_source == _LineSource.custom &&
                        _hLines.isEmpty &&
                        widget.currentPaper?.style != 'blank') {
                      _hLines = _linesFromPaper(widget.currentPaper);
                      if (_vLines.isEmpty &&
                          (widget.currentPaper?.style == 'lined' ||
                              widget.page.template == PageTemplate.lined)) {
                        _vLines = [widget.currentPaper?.marginLeft ?? 72];
                      }
                    }
                  });
                },
              ),
              if (_source == _LineSource.custom) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.customLinesHint,
                  style: AppTheme.body(
                    fontSize: 12,
                    color: AppTheme.ink.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _hLines = PaperTemplate.evenlySpacedLines(
                          start: 48,
                          spacing: 28,
                          end: _pageSize.height,
                        );
                        _vLines = [72];
                      }),
                      icon: const Icon(Icons.reorder, size: 18),
                      label: Text(l10n.fillRuled),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _hLines = [];
                        _vLines = [];
                      }),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: Text(l10n.clearLines),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 200,
                  child: AspectRatio(
                    aspectRatio: _pageSize.width / _pageSize.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final previewSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: _source == _LineSource.custom
                                ? (d) => _onPreviewTap(
                                    d.localPosition,
                                    previewSize,
                                  )
                                : null,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _pageSize.width,
                                height: _pageSize.height,
                                child: CustomPaint(
                                  size: _pageSize,
                                  painter: PageBackgroundPainter(
                                    template: PageTemplate.blank,
                                    paper: draft,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: EditorChrome.toolbarSelected,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        SavePageAsTemplateResult(_buildDraft()),
                      );
                    },
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
