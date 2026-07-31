import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/color_picker_sheet.dart';
import '../../domain/rich_text_controller.dart';
import '../editor_chrome.dart';

/// Formatting chips shared by the unified text tool bar.
List<Widget> buildTextFormatControls({
  required BuildContext context,
  required TextBlock block,
  required RichTextEditingController controller,
  required ValueChanged<TextBlock> onBlockChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  final current = controller.styleForSelection(controller.selection);
  final lineBound = block.layoutMode == TextLayoutMode.lineBound;

  void apply(TextSpanStyle Function(TextSpanStyle run) transform) {
    controller.applyToSelection(controller.selection, transform);
  }

  Widget divider() => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 7),
    color: EditorChrome.divider,
  );

  Widget toggle({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1),
    child: Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 36,
          height: 34,
          decoration: BoxDecoration(
            color: active ? EditorChrome.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 19, color: EditorChrome.onDark),
        ),
      ),
    ),
  );

  Widget colorDot({
    required int value,
    required bool selected,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
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
  );

  const palette = [
    0xFF1A1A1A,
    0xFF1D4E89,
    0xFFB42318,
    0xFF157347,
    0xFFD4A017,
  ];

  final custom = !palette.contains(current.colorValue);

  return [
    toggle(
      icon: Icons.format_bold_rounded,
      tooltip: l10n.bold,
      active: current.bold,
      onTap: () => apply((run) => run.copyWith(bold: !current.bold)),
    ),
    toggle(
      icon: Icons.format_italic_rounded,
      tooltip: l10n.italic,
      active: current.italic,
      onTap: () => apply((run) => run.copyWith(italic: !current.italic)),
    ),
    toggle(
      icon: Icons.format_underlined_rounded,
      tooltip: l10n.underline,
      active: current.underline,
      onTap: () => apply((run) => run.copyWith(underline: !current.underline)),
    ),
    toggle(
      icon: Icons.strikethrough_s_rounded,
      tooltip: l10n.strikethrough,
      active: current.strikethrough,
      onTap: () =>
          apply((run) => run.copyWith(strikethrough: !current.strikethrough)),
    ),
    divider(),
    if (!lineBound) ...[
      toggle(
        icon: Icons.text_decrease_rounded,
        tooltip: l10n.decreaseFontSize,
        active: false,
        onTap: () => apply(
          (run) =>
              run.copyWith(fontSize: (run.fontSize - 2).clamp(8.0, 96.0)),
        ),
      ),
      SizedBox(
        width: 34,
        child: Text(
          current.fontSize.round().toString(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditorChrome.onDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      toggle(
        icon: Icons.text_increase_rounded,
        tooltip: l10n.increaseFontSize,
        active: false,
        onTap: () => apply(
          (run) =>
              run.copyWith(fontSize: (run.fontSize + 2).clamp(8.0, 96.0)),
        ),
      ),
      divider(),
    ],
    for (final value in palette)
      colorDot(
        value: value,
        selected: current.colorValue == value,
        onTap: () => apply((run) => run.copyWith(colorValue: value)),
      ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Tooltip(
        message: l10n.customColor,
        child: GestureDetector(
          onTap: () async {
            final selection = controller.selection;
            final picked = await showColorPickerSheet(
              context,
              initialValue: current.colorValue,
              title: l10n.customColor,
              recents: palette,
            );
            if (picked == null) return;
            controller.applyToSelection(
              selection,
              (run) => run.copyWith(colorValue: picked),
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: custom ? Color(current.colorValue) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: custom
                    ? EditorChrome.onDark
                    : EditorChrome.onDark.withValues(alpha: 0.35),
                width: custom ? 2.5 : 1,
              ),
            ),
            child: custom
                ? null
                : Icon(
                    Icons.colorize_rounded,
                    size: 13,
                    color: EditorChrome.onDark.withValues(alpha: 0.8),
                  ),
          ),
        ),
      ),
    ),
    divider(),
    toggle(
      icon: Icons.format_align_left_rounded,
      tooltip: l10n.alignLeft,
      active: block.align == TextBlockAlign.left,
      onTap: () => onBlockChanged(block.copyWith(align: TextBlockAlign.left)),
    ),
    toggle(
      icon: Icons.format_align_center_rounded,
      tooltip: l10n.alignCenter,
      active: block.align == TextBlockAlign.center,
      onTap: () =>
          onBlockChanged(block.copyWith(align: TextBlockAlign.center)),
    ),
    toggle(
      icon: Icons.format_align_right_rounded,
      tooltip: l10n.alignRight,
      active: block.align == TextBlockAlign.right,
      onTap: () => onBlockChanged(block.copyWith(align: TextBlockAlign.right)),
    ),
    toggle(
      icon: Icons.format_align_justify_rounded,
      tooltip: l10n.alignJustify,
      active: block.align == TextBlockAlign.justify,
      onTap: () =>
          onBlockChanged(block.copyWith(align: TextBlockAlign.justify)),
    ),
  ];
}

/// Standalone compatibility wrapper used by compact layouts and widget tests.
class TextFormatBar extends StatelessWidget {
  const TextFormatBar({
    super.key,
    required this.block,
    required this.controller,
    required this.onBlockChanged,
  });

  final TextBlock block;
  final RichTextEditingController controller;
  final ValueChanged<TextBlock> onBlockChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EditorChrome.floating,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: buildTextFormatControls(
            context: context,
            block: block,
            controller: controller,
            onBlockChanged: onBlockChanged,
          ),
        ),
      ),
    );
  }
}
