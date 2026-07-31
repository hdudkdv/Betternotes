import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../editor_chrome.dart';

/// Floating undo / redo control anchored to the top-left of the workspace.
class UndoRedoPill extends StatelessWidget {
  const UndoRedoPill({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HudIcon(
            icon: Icons.undo_rounded,
            tooltip: l10n.undo,
            onTap: canUndo ? onUndo : null,
          ),
          _HudIcon(
            icon: Icons.redo_rounded,
            tooltip: l10n.redo,
            onTap: canRedo ? onRedo : null,
          ),
        ],
      ),
    );
  }
}

/// Zoom controls anchored to the bottom-right of the workspace.
class ZoomControls extends StatelessWidget {
  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Pill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HudIcon(
            icon: Icons.remove_rounded,
            tooltip: l10n.zoomOut,
            onTap: onZoomOut,
          ),
          _HudIcon(
            icon: Icons.crop_free_rounded,
            tooltip: l10n.fitPage,
            onTap: onFit,
          ),
          _HudIcon(
            icon: Icons.add_rounded,
            tooltip: l10n.zoomIn,
            onTap: onZoomIn,
          ),
        ],
      ),
    );
  }
}

/// Compact page counter anchored to the bottom-left of the workspace.
class PageIndicatorPill extends StatelessWidget {
  const PageIndicatorPill({
    super.key,
    required this.current,
    required this.total,
    required this.onTap,
    this.locked = false,
  });

  final int current;
  final int total;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Pill(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(
                  Icons.lock_rounded,
                  size: 15,
                  color: EditorChrome.selected,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                l10n.pageOf(current, total),
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
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EditorChrome.floating,
      elevation: 0,
      borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
          border: Border.all(color: EditorChrome.floatingBorder),
        ),
        child: child,
      ),
    );
  }
}

class _HudIcon extends StatelessWidget {
  const _HudIcon({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 42,
          child: Icon(
            icon,
            size: 21,
            color: enabled
                ? EditorChrome.onDark
                : EditorChrome.onDarkMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
