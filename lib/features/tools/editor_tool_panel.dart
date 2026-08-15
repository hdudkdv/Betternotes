import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// Floating, non-blocking tool window used by calculator and formula book.
class EditorToolPanel extends StatelessWidget {
  const EditorToolPanel({
    super.key,
    required this.title,
    required this.pinned,
    required this.onPin,
    required this.onClose,
    required this.child,
    this.width = 340,
    this.height = 460,
  });

  final String title;
  final bool pinned;
  final VoidCallback onPin;
  final VoidCallback onClose;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      elevation: 10,
      color: AppTheme.paper,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: AppTheme.card,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.body(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.pinTool,
                    onPressed: onPin,
                    icon: Icon(
                      pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
