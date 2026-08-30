import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/color_picker_sheet.dart';
import '../../domain/ink_engine.dart';
import '../../domain/ink_models.dart';
import '../../domain/rich_text_controller.dart';
import '../../providers/tool_presets.dart';
import '../editor_chrome.dart';
import 'content_targets_sheet.dart';
import 'text_format_bar.dart';

/// Floating pill below the header that shows options for the active tool.
///
/// It stays hidden while no tool is selected so the page is fully visible.
class ToolOptionsBar extends ConsumerWidget {
  const ToolOptionsBar({
    super.key,
    required this.engine,
    required this.shapeKind,
    required this.textLayoutMode,
    required this.onShapeKindChanged,
    required this.onTextLayoutModeChanged,
    required this.onAddText,
    this.onAddSticky,
    this.onDeleteText,
    required this.onPickImage,
    this.onScanPages,
    this.onPickSticker,
    this.onDeleteImage,
    this.onDeleteSticker,
    this.hasSelectedImage = false,
    this.hasSelectedSticker = false,
    this.onDeleteSelection,
    this.hasLassoSelection = false,
    this.selectionCanRecolor = false,
    this.onPickColor,
    this.onToggleRuler,
    this.onToggleCompass,
    this.rulerActive = false,
    this.compassActive = false,
    this.formatBlock,
    this.formatController,
    this.onFormatBlockChanged,
  });

  final InkEngine engine;
  final ShapeKind shapeKind;
  final TextLayoutMode textLayoutMode;
  final ValueChanged<ShapeKind> onShapeKindChanged;
  final ValueChanged<TextLayoutMode> onTextLayoutModeChanged;
  final VoidCallback onAddText;
  final VoidCallback? onAddSticky;
  final VoidCallback? onDeleteText;
  final VoidCallback onPickImage;
  final VoidCallback? onScanPages;
  final VoidCallback? onPickSticker;
  final VoidCallback? onDeleteImage;
  final VoidCallback? onDeleteSticker;
  final VoidCallback? onDeleteSelection;
  final bool hasLassoSelection;
  final bool selectionCanRecolor;
  final ValueChanged<int>? onPickColor;
  final bool hasSelectedImage;
  final bool hasSelectedSticker;
  final VoidCallback? onToggleRuler;
  final VoidCallback? onToggleCompass;
  final bool rulerActive;
  final bool compassActive;
  final TextBlock? formatBlock;
  final RichTextEditingController? formatController;
  final ValueChanged<TextBlock>? onFormatBlockChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final presets = ref.watch(toolPresetsProvider);

    _syncPresets(presets);

    return AnimatedBuilder(
      animation: Listenable.merge([engine, presets]),
      builder: (context, _) {
        final options = _decorateSelection(
          context,
          l10n,
          presets,
          _optionsFor(context, l10n, presets),
        );
        final formatBlock = this.formatBlock;
        final formatController = this.formatController;
        final onFormatBlockChanged = this.onFormatBlockChanged;
        final showFormat =
            formatBlock != null &&
            formatController != null &&
            onFormatBlockChanged != null;

        if (options.isEmpty && !showFormat) {
          return const SizedBox.shrink();
        }

        Widget row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...options,
            if (showFormat) ...[
              if (options.isNotEmpty) _divider(),
              ...buildTextFormatControls(
                context: context,
                block: formatBlock,
                controller: formatController,
                onBlockChanged: onFormatBlockChanged,
              ),
            ],
          ],
        );
        if (showFormat) {
          row = AnimatedBuilder(
            animation: formatController,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...options,
                if (options.isNotEmpty) _divider(),
                ...buildTextFormatControls(
                  context: context,
                  block: formatBlock,
                  controller: formatController,
                  onBlockChanged: onFormatBlockChanged,
                ),
              ],
            ),
          );
        }

        Widget bar = Container(
          key: ValueKey(
            '${engine.tool}-${showFormat ? formatBlock.id : 'x'}',
          ),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: EditorChrome.floating,
            borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
            border: Border.all(color: EditorChrome.floatingBorder),
            boxShadow: EditorChrome.pillShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: row,
            ),
          ),
        );
        if (showFormat) {
          bar = TextFieldTapRegion(child: bar);
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: bar,
        );
      },
    );
  }

  /// Keeps the engine aligned with the persisted per-tool presets.
  void _syncPresets(ToolPresets presets) {
    final expectedWidth = presets.widthFor(engine.tool);
    final tracksWidth =
        engine.tool == InkTool.pen ||
        engine.tool == InkTool.pencil ||
        engine.tool == InkTool.fountain ||
        engine.tool == InkTool.marker ||
        engine.tool == InkTool.eraser ||
        engine.tool == InkTool.shape;
    if (tracksWidth && (engine.width - expectedWidth).abs() > 0.01) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (engine.width != expectedWidth) engine.setWidth(expectedWidth);
      });
    }
    if (engine.tool == InkTool.eraser &&
        engine.eraserMode != presets.eraserMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (engine.eraserMode != presets.eraserMode) {
          engine.setEraserMode(presets.eraserMode);
        }
      });
    }
    if (!_sameKinds(engine.eraseTargets, presets.eraseTargets)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_sameKinds(engine.eraseTargets, presets.eraseTargets)) {
          engine.setEraseTargets(presets.eraseTargets);
        }
      });
    }
    if (!_sameKinds(engine.lassoTargets, presets.lassoTargets)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_sameKinds(engine.lassoTargets, presets.lassoTargets)) {
          engine.setLassoTargets(presets.lassoTargets);
        }
      });
    }
  }

  bool _sameKinds(Set<ContentKind> a, Set<ContentKind> b) =>
      a.length == b.length && a.containsAll(b);

  void _applyColor(int value) {
    if (onPickColor != null) {
      onPickColor!(value);
    } else {
      engine.setColor(value);
    }
  }

  List<Widget> _decorateSelection(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
    List<Widget> options,
  ) {
    final showDelete =
        hasLassoSelection &&
        engine.tool != InkTool.lasso &&
        engine.tool != InkTool.image &&
        engine.tool != InkTool.sticker;
    final toolHasColors = switch (engine.tool) {
      InkTool.pen ||
      InkTool.fountain ||
      InkTool.pencil ||
      InkTool.marker ||
      InkTool.shape ||
      InkTool.ruler ||
      InkTool.compass => true,
      _ => false,
    };
    final showColors =
        hasLassoSelection &&
        selectionCanRecolor &&
        !toolHasColors &&
        engine.tool != InkTool.eraser &&
        engine.tool != InkTool.lasso;
    if (!showDelete && !showColors) return options;
    return [
      if (showDelete)
        _pillAction(
          icon: Icons.delete_outline_rounded,
          label: l10n.deleteSelection,
          onTap: onDeleteSelection ?? engine.deleteSelected,
        ),
      if (showDelete && showColors) _divider(),
      if (showColors) ..._colorDots(context, l10n, presets),
      if (options.isNotEmpty && (showDelete || showColors)) _divider(),
      ...options,
    ];
  }

  List<Widget> _optionsFor(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
  ) {
    switch (engine.tool) {
      case InkTool.none:
        if (rulerActive || compassActive) {
          return _guideChips(context, l10n);
        }
        return const [];
      case InkTool.pen:
      case InkTool.fountain:
        return [
          ..._guideChips(context, l10n),
          _divider(),
          _labelChip(
            selected: engine.tool == InkTool.pen,
            icon: Icons.edit_rounded,
            label: l10n.ballpointPen,
            onTap: () => engine.setPenSubtype(fountain: false),
          ),
          _labelChip(
            selected: engine.tool == InkTool.fountain,
            icon: Icons.brush_rounded,
            label: l10n.fountainPen,
            onTap: () => engine.setPenSubtype(fountain: true),
          ),
          _divider(),
          ..._strokeStyleChips(context, l10n),
          _divider(),
          ..._pressureSlider(context, l10n),
          _divider(),
          ..._widthChips(context, l10n, presets, InkTool.pen),
          _divider(),
          ..._colorDots(context, l10n, presets),
        ];
      case InkTool.pencil:
        return [
          ..._guideChips(context, l10n),
          _divider(),
          ..._strokeStyleChips(context, l10n),
          _divider(),
          ..._pressureSlider(context, l10n),
          _divider(),
          ..._widthChips(context, l10n, presets, engine.tool),
          _divider(),
          ..._colorDots(context, l10n, presets),
        ];
      case InkTool.marker:
        return [
          ..._guideChips(context, l10n),
          _divider(),
          ..._strokeStyleChips(context, l10n),
          _divider(),
          ..._widthChips(context, l10n, presets, engine.tool),
          _divider(),
          ..._colorDots(context, l10n, presets),
        ];
      case InkTool.eraser:
        return [
          _eraserModeChip(context, l10n, presets),
          _divider(),
          _targetsChip(
            context,
            l10n,
            presets,
            eraser: true,
          ),
          _divider(),
          ..._eraserSizes(context, l10n, presets),
        ];
      case InkTool.lasso:
        return [
          _targetsChip(
            context,
            l10n,
            presets,
            eraser: false,
          ),
          _divider(),
          if (engine.selectedIds.isEmpty && !hasLassoSelection)
            _hint(l10n.lasso)
          else
            _pillAction(
              icon: Icons.delete_outline_rounded,
              label: l10n.deleteSelection,
              onTap: onDeleteSelection ?? engine.deleteSelected,
            ),
          if (hasLassoSelection && selectionCanRecolor) ...[
            _divider(),
            ..._colorDots(context, l10n, presets),
          ],
        ];
      case InkTool.text:
        return [
          _labelChip(
            selected: textLayoutMode == TextLayoutMode.free,
            icon: Icons.open_with_rounded,
            label: l10n.freeTextBox,
            onTap: () => onTextLayoutModeChanged(TextLayoutMode.free),
          ),
          _labelChip(
            selected: textLayoutMode == TextLayoutMode.lineBound,
            icon: Icons.notes_rounded,
            label: l10n.pageText,
            onTap: () => onTextLayoutModeChanged(TextLayoutMode.lineBound),
          ),
          _labelChip(
            selected: textLayoutMode == TextLayoutMode.sticky,
            icon: Icons.sticky_note_2_outlined,
            label: l10n.stickyNote,
            onTap: () => onTextLayoutModeChanged(TextLayoutMode.sticky),
          ),
          _divider(),
          _pillAction(
            icon: Icons.add_rounded,
            label: l10n.addTextBox,
            onTap: onAddText,
          ),
          if (onAddSticky != null)
            _pillAction(
              icon: Icons.sticky_note_2_outlined,
              label: l10n.stickyNote,
              onTap: onAddSticky!,
            ),
          if (onDeleteText != null)
            _pillAction(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              onTap: onDeleteText!,
            ),
        ];
      case InkTool.shape:
        return [
          _iconChip(
            selected: shapeKind == ShapeKind.line,
            icon: Icons.horizontal_rule_rounded,
            tooltip: l10n.shapeLine,
            onTap: () => onShapeKindChanged(ShapeKind.line),
          ),
          _iconChip(
            selected: shapeKind == ShapeKind.rect,
            icon: Icons.crop_square_rounded,
            tooltip: l10n.shapeRect,
            onTap: () => onShapeKindChanged(ShapeKind.rect),
          ),
          _iconChip(
            selected: shapeKind == ShapeKind.ellipse,
            icon: Icons.circle_outlined,
            tooltip: l10n.shapeEllipse,
            onTap: () => onShapeKindChanged(ShapeKind.ellipse),
          ),
          _iconChip(
            selected: shapeKind == ShapeKind.arrow,
            icon: Icons.arrow_right_alt_rounded,
            tooltip: l10n.shapeArrow,
            onTap: () => onShapeKindChanged(ShapeKind.arrow),
          ),
          _iconChip(
            selected: shapeKind == ShapeKind.circle,
            icon: Icons.radio_button_unchecked_rounded,
            tooltip: l10n.compass,
            onTap: () => onShapeKindChanged(ShapeKind.circle),
          ),
          _divider(),
          ..._widthChips(context, l10n, presets, InkTool.pen),
          _divider(),
          ..._colorDots(context, l10n, presets),
        ];
      case InkTool.ruler:
      case InkTool.compass:
        // Migrated into guide chips on freehand tools.
        return [
          ..._guideChips(context, l10n),
          _divider(),
          ..._widthChips(context, l10n, presets, InkTool.pen),
          _divider(),
          ..._colorDots(context, l10n, presets),
        ];
      case InkTool.image:
        return [
          if (onScanPages != null)
            _pillAction(
              icon: Icons.document_scanner_outlined,
              label: l10n.scanPages,
              onTap: onScanPages!,
            ),
          _pillAction(
            icon: Icons.add_photo_alternate_outlined,
            label: l10n.insertImage,
            onTap: onPickImage,
          ),
          if (hasSelectedImage && onDeleteImage != null)
            _pillAction(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              onTap: onDeleteImage!,
            ),
        ];
      case InkTool.sticker:
        return [
          _pillAction(
            icon: Icons.emoji_emotions_outlined,
            label: l10n.stickers,
            onTap: onPickSticker ?? () {},
          ),
          if (hasSelectedSticker && onDeleteSticker != null)
            _pillAction(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              onTap: onDeleteSticker!,
            ),
        ];
    }
  }

  List<Widget> _guideChips(BuildContext context, AppLocalizations l10n) {
    return [
      _labelChip(
        selected: rulerActive || engine.guide == DrawingGuide.ruler,
        icon: Icons.straighten_rounded,
        label: l10n.ruler,
        onTap: () => (onToggleRuler ?? () => engine.setGuide(DrawingGuide.ruler))(),
      ),
      _labelChip(
        selected: compassActive || engine.guide == DrawingGuide.compass,
        icon: Icons.architecture_rounded,
        label: l10n.compass,
        onTap: () =>
            (onToggleCompass ?? () => engine.setGuide(DrawingGuide.compass))(),
      ),
    ];
  }

  List<Widget> _strokeStyleChips(BuildContext context, AppLocalizations l10n) {
    return [
      _iconChip(
        selected: engine.strokeStyle == StrokeStyle.solid,
        icon: Icons.horizontal_rule_rounded,
        tooltip: l10n.strokeStyleSolid,
        onTap: () => engine.setStrokeStyle(StrokeStyle.solid),
      ),
      _iconChip(
        selected: engine.strokeStyle == StrokeStyle.dashed,
        icon: Icons.power_input_rounded,
        tooltip: l10n.strokeStyleDashed,
        onTap: () => engine.setStrokeStyle(StrokeStyle.dashed),
      ),
      _iconChip(
        selected: engine.strokeStyle == StrokeStyle.dotted,
        icon: Icons.more_horiz_rounded,
        tooltip: l10n.strokeStyleDotted,
        onTap: () => engine.setStrokeStyle(StrokeStyle.dotted),
      ),
      _iconChip(
        selected: engine.strokeStyle == StrokeStyle.dashDot,
        icon: Icons.linear_scale_rounded,
        tooltip: l10n.strokeStyleDashDot,
        onTap: () => engine.setStrokeStyle(StrokeStyle.dashDot),
      ),
    ];
  }

  List<Widget> _pressureSlider(BuildContext context, AppLocalizations l10n) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 4, right: 2),
        child: Text(
          l10n.pressureSensitivity,
          style: TextStyle(
            color: EditorChrome.onDarkMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      SizedBox(
        width: 110,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: engine.pressureSensitivity,
            onChanged: engine.setPressureSensitivity,
            activeColor: EditorChrome.onDark,
            inactiveColor: EditorChrome.onDarkMuted.withValues(alpha: 0.35),
          ),
        ),
      ),
    ];
  }

  // --- building blocks -------------------------------------------------

  Widget _divider() => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: EditorChrome.divider,
  );

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      text,
      style: TextStyle(
        color: EditorChrome.onDarkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  List<Widget> _widthChips(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
    InkTool tool,
  ) {
    final widths = presets.widthsFor(tool);
    return [
      for (var i = 0; i < widths.length; i++)
        _WidthChip(
          width: widths[i],
          selected: presets.widthIndexFor(tool) == i,
          tooltip: l10n.editWidthHint,
          onTap: () {
            presets.selectWidthIndex(tool, i);
            engine.setWidth(presets.widthFor(tool));
          },
          onLongPress: () => _editWidth(context, l10n, presets, tool, i),
        ),
    ];
  }

  List<Widget> _eraserSizes(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
  ) {
    final widths = presets.widthsFor(InkTool.eraser);
    return [
      for (var i = 0; i < widths.length; i++)
        _EraserSizeDot(
          diameter: 12 + i * 7,
          selected: presets.widthIndexFor(InkTool.eraser) == i,
          tooltip: l10n.editWidthHint,
          onTap: () {
            presets.selectWidthIndex(InkTool.eraser, i);
            engine.setWidth(presets.widthFor(InkTool.eraser));
          },
          onLongPress: () =>
              _editWidth(context, l10n, presets, InkTool.eraser, i),
        ),
    ];
  }

  List<Widget> _colorDots(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
  ) => [
    for (final value in presets.colors)
      _ColorDot(
        value: value,
        selected: engine.colorValue == value,
        tooltip: l10n.editColorHint,
        onTap: () => _applyColor(value),
        onLongPress: () => _editColor(context, l10n, presets, value),
      ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: l10n.addColor,
        child: InkWell(
          onTap: () => _pickNewColor(context, l10n, presets),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: EditorChrome.onDark.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.add,
              size: 15,
              color: EditorChrome.onDark.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    ),
  ];

  Widget _eraserModeChip(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
  ) {
    String label(EraserMode mode) => switch (mode) {
      EraserMode.stroke => l10n.eraserStroke,
      EraserMode.section => l10n.eraserSection,
      EraserMode.precise => l10n.eraserPrecise,
    };

    return PopupMenuButton<EraserMode>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (mode) {
        presets.setEraserMode(mode);
        engine.setEraserMode(mode);
      },
      itemBuilder: (context) => [
        for (final mode in EraserMode.values)
          PopupMenuItem(value: mode, child: Text(label(mode))),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_normal_outlined,
              size: 17,
              color: EditorChrome.onDark,
            ),
            const SizedBox(width: 6),
            Text(
              label(presets.eraserMode),
              style: TextStyle(
                color: EditorChrome.onDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: EditorChrome.onDarkMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetsChip(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets, {
    required bool eraser,
  }) {
    final selected = eraser ? engine.eraseTargets : engine.lassoTargets;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: l10n.editTargetsHint,
        child: InkWell(
          onTap: () => _editTargets(context, l10n, presets, eraser: eraser),
          onLongPress: () =>
              _editTargets(context, l10n, presets, eraser: eraser),
          borderRadius: BorderRadius.circular(17),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  eraser
                      ? Icons.filter_alt_outlined
                      : Icons.filter_center_focus_outlined,
                  size: 17,
                  color: EditorChrome.onDark,
                ),
                const SizedBox(width: 6),
                Text(
                  eraser ? l10n.eraserTargets : l10n.lassoTargets,
                  style: TextStyle(
                    color: EditorChrome.onDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${selected.length}',
                  style: TextStyle(
                    color: EditorChrome.onDarkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editTargets(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets, {
    required bool eraser,
  }) {
    return showContentTargetsSheet(
      context,
      title: eraser ? l10n.eraserTargetsTitle : l10n.lassoTargetsTitle,
      selected: eraser ? engine.eraseTargets : engine.lassoTargets,
      onChanged: (value) {
        if (eraser) {
          presets.setEraseTargets(value);
          engine.setEraseTargets(value);
        } else {
          presets.setLassoTargets(value);
          engine.setLassoTargets(value);
        }
      },
    );
  }

  Widget _labelChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? EditorChrome.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: EditorChrome.onDark),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: EditorChrome.onDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _iconChip({
    required bool selected,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? EditorChrome.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: EditorChrome.onDark),
        ),
      ),
    ),
  );

  Widget _pillAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: EditorChrome.onDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: EditorChrome.onDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // --- dialogs ---------------------------------------------------------

  Future<void> _editWidth(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
    InkTool tool,
    int index,
  ) async {
    var value = presets.widthsFor(tool)[index];
    final max = tool == InkTool.eraser ? 64.0 : 32.0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(l10n.editWidth),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toStringAsFixed(1)} pt'),
              Slider(
                value: value.clamp(0.5, max),
                min: 0.5,
                max: max,
                onChanged: (v) => setLocal(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.apply),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    presets.setWidthSlot(tool, index, value);
    presets.selectWidthIndex(tool, index);
    engine.setWidth(presets.widthFor(tool));
  }

  /// Long press on a swatch: change it in place or drop it from the row.
  Future<void> _editColor(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
    int value,
  ) async {
    void remove() {
      presets.removeColor(value);
      if (engine.colorValue == value && presets.colors.isNotEmpty) {
        engine.setColor(presets.colors.first);
      }
    }

    final picked = await showColorPickerSheet(
      context,
      initialValue: value,
      recents: presets.colors,
      onDelete: presets.colors.length > 1 ? remove : null,
    );
    if (picked == null || picked == value) return;
    presets.replaceColor(value, picked);
    _applyColor(picked);
  }

  Future<void> _pickNewColor(
    BuildContext context,
    AppLocalizations l10n,
    ToolPresets presets,
  ) async {
    final picked = await showColorPickerSheet(
      context,
      initialValue: engine.colorValue,
      title: l10n.addColor,
      recents: presets.colors,
    );
    if (picked == null) return;
    presets.addColor(picked);
    _applyColor(picked);
  }
}

class _WidthChip extends StatelessWidget {
  const _WidthChip({
    required this.width,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final double width;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0x2EFFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              width: 24,
              height: width.clamp(1.5, 12),
              decoration: BoxDecoration(
                color: EditorChrome.onDark,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EraserSizeDot extends StatelessWidget {
  const _EraserSizeDot({
    required this.diameter,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final double diameter;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? EditorChrome.selected : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? EditorChrome.selected
                      : EditorChrome.divider,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.value,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final int value;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? EditorChrome.onDark
                    : EditorChrome.onDark.withValues(alpha: 0.25),
                width: selected ? 2.5 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
