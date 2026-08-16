import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/ink_models.dart';

String contentKindLabel(AppLocalizations l10n, ContentKind kind) {
  return switch (kind) {
    ContentKind.pen => l10n.pen,
    ContentKind.pencil => l10n.pencil,
    ContentKind.marker => l10n.marker,
    ContentKind.shapes => l10n.shapes,
    ContentKind.text => l10n.textTool,
    ContentKind.images => l10n.contentImages,
  };
}

IconData contentKindIcon(ContentKind kind) {
  return switch (kind) {
    ContentKind.pen => Icons.edit_rounded,
    ContentKind.pencil => Icons.create_rounded,
    ContentKind.marker => Icons.highlight_rounded,
    ContentKind.shapes => Icons.change_history_rounded,
    ContentKind.text => Icons.title_rounded,
    ContentKind.images => Icons.image_outlined,
  };
}

Future<void> showContentTargetsSheet(
  BuildContext context, {
  required String title,
  required Set<ContentKind> selected,
  required ValueChanged<Set<ContentKind>> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ContentTargetsSheet(
      title: title,
      selected: selected,
      onChanged: onChanged,
    ),
  );
}

class _ContentTargetsSheet extends StatefulWidget {
  const _ContentTargetsSheet({
    required this.title,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final Set<ContentKind> selected;
  final ValueChanged<Set<ContentKind>> onChanged;

  @override
  State<_ContentTargetsSheet> createState() => _ContentTargetsSheetState();
}

class _ContentTargetsSheetState extends State<_ContentTargetsSheet> {
  late final Set<ContentKind> _selected = Set<ContentKind>.of(widget.selected);

  void _toggle(ContentKind kind) {
    setState(() {
      if (_selected.contains(kind)) {
        _selected.remove(kind);
      } else {
        _selected.add(kind);
      }
    });
    widget.onChanged(Set<ContentKind>.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(palette.radius + 8),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: Text(
                widget.title,
                style: AppTheme.headline(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ),
            for (final kind in ContentKind.values)
              CheckboxListTile(
                value: _selected.contains(kind),
                onChanged: (_) => _toggle(kind),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(contentKindIcon(kind), color: palette.ink),
                title: Text(contentKindLabel(l10n, kind)),
              ),
          ],
        ),
      ),
    );
  }
}
