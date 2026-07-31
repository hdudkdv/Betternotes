import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/paper_line_metrics.dart';
import '../../domain/rich_text_controller.dart';
import '../../domain/text_block_registry.dart';
import '../editor_chrome.dart';

/// Padding between a free block's frame and its text, and the width of the
/// band that stays grabbable while the caret is active.
const double _freeInsetX = 10;
const double _freeInsetY = 6;

/// Resolves a run into a concrete text style, honouring the paper grid for
/// line-bound blocks.
TextStyle resolveRunStyle({
  required TextSpanStyle run,
  required bool lineBound,
  required PaperLineMetrics metrics,
}) {
  final fontSize = lineBound ? metrics.fontSizeForLines() : run.fontSize;
  final decorations = <TextDecoration>[
    if (run.underline) TextDecoration.underline,
    if (run.strikethrough) TextDecoration.lineThrough,
  ];
  return GoogleFonts.sourceSans3(
    fontSize: fontSize,
    color: run.color,
    fontWeight: run.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: run.italic ? FontStyle.italic : FontStyle.normal,
    decoration: decorations.isEmpty
        ? TextDecoration.none
        : TextDecoration.combine(decorations),
    decorationColor: run.color,
    height: lineBound ? metrics.heightFactorForLines(fontSize) : 1.35,
  );
}

/// Forces every line onto the same advance as the ruled paper.
StrutStyle? _strutFor(TextStyle style, {required bool lineBound}) {
  if (!lineBound) return null;
  return StrutStyle(
    fontSize: style.fontSize,
    height: style.height,
    forceStrutHeight: true,
    leading: 0,
  );
}

/// Distance from the top of the first line box down to its alphabetic baseline.
double measureBaselineOffset({
  required PaperLineMetrics metrics,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: 'Hxg', style: style),
    strutStyle: _strutFor(style, lineBound: true),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter.dispose();
  return baseline;
}

TextAlign _textAlign(TextBlockAlign align) => switch (align) {
  TextBlockAlign.left => TextAlign.left,
  TextBlockAlign.center => TextAlign.center,
  TextBlockAlign.right => TextAlign.right,
  TextBlockAlign.justify => TextAlign.justify,
};

TextSpan _spanFor(TextBlock block, PaperLineMetrics metrics) {
  final lineBound = block.layoutMode == TextLayoutMode.lineBound;
  return TextSpan(
    children: [
      for (final run in block.spans)
        TextSpan(
          text: run.text,
          style: resolveRunStyle(
            run: run,
            lineBound: lineBound,
            metrics: metrics,
          ),
        ),
    ],
  );
}

TextStyle _baseStyle(TextBlock block, PaperLineMetrics metrics) {
  return resolveRunStyle(
    run: block.spans.isEmpty
        ? const TextSpanStyle(text: '')
        : block.spans.first,
    lineBound: block.layoutMode == TextLayoutMode.lineBound,
    metrics: metrics,
  );
}

/// Bounds of [block] in page coordinates, matching what the layer renders.
///
/// The canvas uses this to tell a touch on existing text apart from a touch on
/// blank paper.
Rect textBlockBounds({
  required TextBlock block,
  required PaperLineMetrics metrics,
}) {
  final lineBound = block.layoutMode == TextLayoutMode.lineBound;
  final style = _baseStyle(block, metrics);
  final width = lineBound ? metrics.contentWidth : block.width;
  final painter = TextPainter(
    text: _spanFor(block, metrics),
    strutStyle: _strutFor(style, lineBound: lineBound),
    textAlign: _textAlign(block.align),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: math.max(1, width - (lineBound ? 0 : _freeInsetX * 2)));
  final textHeight = painter.height;
  painter.dispose();

  if (lineBound) {
    return Rect.fromLTWH(
      metrics.marginLeft,
      block.y - measureBaselineOffset(metrics: metrics, style: style),
      width,
      math.max(textHeight, metrics.lineSpacing),
    );
  }
  return Rect.fromLTWH(
    block.x,
    block.y,
    width,
    math.max(block.height, textHeight + _freeInsetY * 2),
  );
}

class TextBlockLayer extends StatelessWidget {
  const TextBlockLayer({
    super.key,
    required this.blocks,
    required this.selectedId,
    required this.editingId,
    required this.editable,
    required this.onSelect,
    required this.onBeginEdit,
    required this.onChanged,
    required this.onDelete,
    required this.metrics,
    required this.registry,
    this.pageTextEnabled = true,
    this.onCaretPagePoint,
  });

  final List<TextBlock> blocks;
  final String? selectedId;

  /// Block whose caret is active; only this one shows a keyboard.
  final String? editingId;
  final bool editable;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onBeginEdit;
  final ValueChanged<TextBlock> onChanged;
  final ValueChanged<TextBlock> onDelete;
  final PaperLineMetrics metrics;
  final TextBlockRegistry registry;

  /// Whether the active text tool is the page document rather than free boxes.
  final bool pageTextEnabled;

  /// Page coordinates of the active caret — used to keep it on screen.
  final ValueChanged<Offset>? onCaretPagePoint;

  @override
  Widget build(BuildContext context) {
    // Line-bound text is positioned so its baseline lands on the ruled line.
    final lineStyle = resolveRunStyle(
      run: const TextSpanStyle(text: ''),
      lineBound: true,
      metrics: metrics,
    );
    final baselineOffset = measureBaselineOffset(
      metrics: metrics,
      style: lineStyle,
    );

    // The page is a fixed-size document, so the system font scale must not
    // stretch line heights away from the ruled lines. The transparent Material
    // makes the text fields work wherever the canvas is embedded.
    return MediaQuery.withNoTextScaling(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final block in blocks)
              Positioned(
                left: block.layoutMode == TextLayoutMode.lineBound
                    ? metrics.marginLeft
                    : block.x,
                top: block.layoutMode == TextLayoutMode.lineBound
                    ? block.y - baselineOffset
                    : block.y,
                width: block.layoutMode == TextLayoutMode.lineBound
                    ? metrics.contentWidth
                    : block.width,
                height: block.layoutMode == TextLayoutMode.lineBound
                    ? math.max(
                        metrics.lineSpacing,
                        metrics.pageHeight - (block.y - baselineOffset) - 16,
                      )
                    : null,
                child: _TextBlockWidget(
                  key: ValueKey(block.id),
                  block: block,
                  selected: block.id == selectedId,
                  editing: block.id == editingId,
                  editable: editable,
                  pageTextEnabled: pageTextEnabled,
                  metrics: metrics,
                  registry: registry,
                  onSelect: () => onSelect(block.id),
                  onBeginEdit: () => onBeginEdit(block.id),
                  onChanged: onChanged,
                  onDelete: () => onDelete(block),
                  onCaretPagePoint: onCaretPagePoint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextBlockWidget extends StatefulWidget {
  const _TextBlockWidget({
    super.key,
    required this.block,
    required this.selected,
    required this.editing,
    required this.editable,
    required this.metrics,
    required this.registry,
    required this.pageTextEnabled,
    required this.onSelect,
    required this.onBeginEdit,
    required this.onChanged,
    required this.onDelete,
    this.onCaretPagePoint,
  });

  final TextBlock block;
  final bool selected;
  final bool editing;
  final bool editable;
  final PaperLineMetrics metrics;
  final TextBlockRegistry registry;
  final bool pageTextEnabled;
  final VoidCallback onSelect;
  final VoidCallback onBeginEdit;
  final ValueChanged<TextBlock> onChanged;
  final VoidCallback onDelete;
  final ValueChanged<Offset>? onCaretPagePoint;

  @override
  State<_TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<_TextBlockWidget> {
  late final FocusNode _focus;
  Offset _drag = Offset.zero;
  bool _dragging = false;

  bool get _lineBound => widget.block.layoutMode == TextLayoutMode.lineBound;

  /// Switching to another tool must drop the caret and the keyboard with it.
  bool get _editing => widget.editing && widget.editable;

  /// Page text always owns its caret, like a word processor; a free box only
  /// does so once the user asked to type in it.
  bool get _liveField =>
      widget.editable &&
      ((_lineBound && widget.pageTextEnabled) || widget.editing);

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        widget.onSelect();
        _scheduleCaretReport();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync outside of build so an external change (undo, sync) cannot trigger a
    // rebuild while the tree is already building.
    if (oldWidget.block.spans != widget.block.spans) {
      _controller.syncFromBlock(widget.block.spans);
      _scheduleCaretReport();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  RichTextEditingController get _controller => widget.registry.obtain(
    block: widget.block,
    resolveStyle: (run) => resolveRunStyle(
      run: run,
      lineBound: _lineBound,
      metrics: widget.metrics,
    ),
    onRunsChanged: (runs) {
      widget.onChanged(widget.block.copyWith(spans: runs));
      _scheduleCaretReport();
    },
  );

  void _scheduleCaretReport() {
    if (widget.onCaretPagePoint == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      final point = _caretPagePoint();
      if (point != null) widget.onCaretPagePoint!(point);
    });
  }

  Offset? _caretPagePoint() {
    final selection = _controller.selection;
    if (!selection.isValid) return null;
    final style = _baseStyle(widget.block, widget.metrics);
    final width = _lineBound
        ? widget.metrics.contentWidth
        : math.max(1.0, widget.block.width - _freeInsetX * 2);
    final painter = TextPainter(
      text: _spanFor(widget.block, widget.metrics),
      strutStyle: _strutFor(style, lineBound: _lineBound),
      textAlign: _textAlign(widget.block.align),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final caret = painter.getOffsetForCaret(
      TextPosition(offset: selection.extentOffset),
      Rect.zero,
    );
    final caretHeight = painter.preferredLineHeight > 0
        ? painter.preferredLineHeight
        : (style.fontSize ?? 16);
    painter.dispose();

    if (_lineBound) {
      final baseline = measureBaselineOffset(
        metrics: widget.metrics,
        style: style,
      );
      return Offset(
        widget.metrics.marginLeft + caret.dx,
        widget.block.y - baseline + caret.dy + caretHeight * 0.2,
      );
    }
    return Offset(
      widget.block.x + _freeInsetX + caret.dx,
      widget.block.y + _freeInsetY + caret.dy + caretHeight * 0.2,
    );
  }

  /// Live offset while a finger is dragging, before the move is committed.
  Offset get _visualDrag {
    if (!_dragging) return Offset.zero;
    return Offset(
      _clampedX(widget.block.x + _drag.dx) - widget.block.x,
      _clampedY(widget.block.y + _drag.dy) - widget.block.y,
    );
  }

  double _clampedX(double x) =>
      x.clamp(0.0, math.max(0.0, widget.metrics.pageWidth - 40));

  double _clampedY(double y) =>
      y.clamp(0.0, math.max(0.0, widget.metrics.pageHeight - 24));

  void _beginDrag() {
    if (!widget.selected) widget.onSelect();
    setState(() {
      _dragging = true;
      _drag = Offset.zero;
    });
  }

  /// Drag deltas already arrive in local page coordinates, so canvas zoom needs
  /// no extra conversion.
  void _updateDrag(Offset delta) => setState(() => _drag += delta);

  void _endDrag() {
    final delta = _drag;
    setState(() {
      _dragging = false;
      _drag = Offset.zero;
    });
    if (delta == Offset.zero) return;
    widget.onChanged(
      widget.block.copyWith(
        x: _clampedX(widget.block.x + delta.dx),
        y: _clampedY(widget.block.y + delta.dy),
      ),
    );
  }

  void _resizeBy(Offset delta) {
    widget.onChanged(
      widget.block.copyWith(
        width: (widget.block.width + delta.dx).clamp(
          80.0,
          math.max(80.0, widget.metrics.pageWidth - widget.block.x),
        ),
        height: (widget.block.height + delta.dy).clamp(28.0, 2000.0),
      ),
    );
  }

  /// First tap selects and arms dragging, a second tap opens the keyboard.
  void _handleTap() {
    if (!widget.selected) {
      widget.onSelect();
      return;
    }
    widget.onBeginEdit();
  }

  @override
  Widget build(BuildContext context) {
    final content = _content();

    if (!widget.editable) {
      return IgnorePointer(child: content);
    }
    // Page text is a word processor: tap for a caret, select to format, no
    // frame and no dragging.
    if (_lineBound) return content;

    return Transform.translate(
      offset: _visualDrag,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sits below the text so an active caret keeps gesture priority; the
          // frame band around the text stays grabbable either way.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Start at the touch-down point so the block does not lag behind
              // the finger by the slop distance.
              dragStartBehavior: DragStartBehavior.down,
              onTap: _handleTap,
              onPanStart: (_) => _beginDrag(),
              onPanUpdate: (d) => _updateDrag(d.delta),
              onPanEnd: (_) => _endDrag(),
              onPanCancel: _endDrag,
            ),
          ),
          IgnorePointer(ignoring: !_editing, child: content),
          if (widget.selected) ..._handles(),
        ],
      ),
    );
  }

  Widget _content() {
    final style = _baseStyle(widget.block, widget.metrics);
    final strut = _strutFor(style, lineBound: _lineBound);

    final child = _liveField
        ? TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: _editing,
            maxLines: null,
            expands: _lineBound,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            textAlign: _textAlign(widget.block.align),
            style: style,
            cursorColor: EditorChrome.selected,
            strutStyle: strut,
            onTap: _scheduleCaretReport,
            onChanged: (_) => _scheduleCaretReport(),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          )
        : Text.rich(
            _spanFor(widget.block, widget.metrics),
            textAlign: _textAlign(widget.block.align),
            strutStyle: strut,
          );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _lineBound ? 0 : _freeInsetX,
        vertical: _lineBound ? 0 : _freeInsetY,
      ),
      child: _lineBound
          ? child
          : ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, widget.block.height - _freeInsetY * 2),
              ),
              child: child,
            ),
    );
  }

  List<Widget> _handles() {
    return [
      Positioned(
        left: -13,
        top: -13,
        child: _Handle(
          icon: Icons.open_with_rounded,
          onDragStart: _beginDrag,
          onDrag: _updateDrag,
          onDragEnd: _endDrag,
        ),
      ),
      Positioned(
        right: -13,
        top: -13,
        child: _Handle(
          icon: Icons.close_rounded,
          color: const Color(0xFFB42318),
          onTap: widget.onDelete,
        ),
      ),
      Positioned(
        right: -13,
        bottom: -13,
        child: _Handle(icon: Icons.open_in_full_rounded, onDrag: _resizeBy),
      ),
    ];
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.icon,
    this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final ValueChanged<Offset>? onDrag;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onTap;

  /// Defaults to the editor selection accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTap: onTap,
      onPanStart: onDrag == null ? null : (_) => onDragStart?.call(),
      onPanUpdate: onDrag == null ? null : (d) => onDrag!(d.delta),
      onPanEnd: onDrag == null ? null : (_) => onDragEnd?.call(),
      onPanCancel: onDrag == null ? null : () => onDragEnd?.call(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color ?? EditorChrome.selected,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}
