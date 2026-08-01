import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/ink_models.dart';
import '../editor_chrome.dart';

/// Radial tool picker opened by Apple Pencil squeeze (or a configured gesture).
class ToolWheelOverlay extends StatelessWidget {
  const ToolWheelOverlay({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onDismiss,
  });

  final InkTool current;
  final ValueChanged<InkTool> onSelect;
  final VoidCallback onDismiss;

  static const _tools = <InkTool>[
    InkTool.pen,
    InkTool.pencil,
    InkTool.fountain,
    InkTool.marker,
    InkTool.eraser,
    InkTool.lasso,
    InkTool.text,
    InkTool.shape,
  ];

  IconData _icon(InkTool tool) {
    switch (tool) {
      case InkTool.pen:
        return Icons.edit_outlined;
      case InkTool.pencil:
        return Icons.draw_outlined;
      case InkTool.fountain:
        return Icons.brush_outlined;
      case InkTool.marker:
        return Icons.highlight_outlined;
      case InkTool.eraser:
        return Icons.auto_fix_high_outlined;
      case InkTool.lasso:
        return Icons.gesture_outlined;
      case InkTool.text:
        return Icons.text_fields_rounded;
      case InkTool.shape:
        return Icons.category_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  String _label(AppLocalizations l10n, InkTool tool) {
    switch (tool) {
      case InkTool.pen:
        return l10n.pen;
      case InkTool.pencil:
        return l10n.pencil;
      case InkTool.fountain:
        return l10n.fountainPen;
      case InkTool.marker:
        return l10n.marker;
      case InkTool.eraser:
        return l10n.eraser;
      case InkTool.lasso:
        return l10n.lasso;
      case InkTool.text:
        return l10n.textTool;
      case InkTool.shape:
        return l10n.shapes;
      default:
        return tool.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(constraints.maxWidth, constraints.maxHeight);
            final radius = size * 0.28;
            final center = Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight / 2,
            );
            return Stack(
              children: [
                for (var i = 0; i < _tools.length; i++)
                  Builder(
                    builder: (context) {
                      final angle =
                          -math.pi / 2 + (2 * math.pi * i / _tools.length);
                      final pos = Offset(
                        center.dx + radius * math.cos(angle),
                        center.dy + radius * math.sin(angle),
                      );
                      final tool = _tools[i];
                      final selected = tool == current;
                      return Positioned(
                        left: pos.dx - 36,
                        top: pos.dy - 36,
                        child: _WheelButton(
                          icon: _icon(tool),
                          label: _label(l10n, tool),
                          selected: selected,
                          onTap: () => onSelect(tool),
                        ),
                      );
                    },
                  ),
                Positioned(
                  left: center.dx - 40,
                  top: center.dy - 40,
                  child: Material(
                    color: EditorChrome.toolBar,
                    shape: const CircleBorder(),
                    elevation: 6,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDismiss,
                      child: const SizedBox(
                        width: 80,
                        height: 80,
                        child: Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WheelButton extends StatelessWidget {
  const _WheelButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EditorChrome.selected : EditorChrome.toolBar,
      shape: const CircleBorder(),
      elevation: selected ? 8 : 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
