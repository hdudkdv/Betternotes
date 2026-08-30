import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

enum ImageImportMode { asPage, asImage }

/// Asks whether a scan or photo should become a full page or an overlay image.
Future<ImageImportMode?> showImageImportChoice(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<ImageImportMode>(
    context: context,
    backgroundColor: AppTheme.card,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  l10n.imageImportTitle,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  l10n.imageImportBody,
                  style: AppTheme.body(color: AppTheme.inkMuted, height: 1.35),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: Text(l10n.importAsPage),
                subtitle: Text(l10n.importAsPageHint),
                onTap: () => Navigator.pop(context, ImageImportMode.asPage),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.importAsImage),
                subtitle: Text(l10n.importAsImageHint),
                onTap: () => Navigator.pop(context, ImageImportMode.asImage),
              ),
            ],
          ),
        ),
      );
    },
  );
}
