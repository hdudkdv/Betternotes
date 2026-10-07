import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Asks for the password of an encrypted PDF. Returns null if cancelled.
Future<String?> promptPdfPassword(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.pdfPasswordTitle),
          content: TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.pdfPasswordLabel,
              hintText: l10n.pdfPasswordHint,
            ),
            onSubmitted: (value) => Navigator.pop(ctx, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(l10n.pdfPasswordUnlock),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}
