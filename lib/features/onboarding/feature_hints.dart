import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../library/providers/library_providers.dart';

enum FeatureHintId {
  calculator,
  formulaBook,
  assistant,
  colorPicker,
  scanImport,
  htmlImport,
}

const _hintKeys = <FeatureHintId, String>{
  FeatureHintId.calculator: 'hint_calculator',
  FeatureHintId.formulaBook: 'hint_formula_book',
  FeatureHintId.assistant: 'hint_assistant',
  FeatureHintId.colorPicker: 'hint_color_picker',
  FeatureHintId.scanImport: 'hint_scan_import',
  FeatureHintId.htmlImport: 'hint_html_import',
};

Future<void> resetFeatureHints(WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  for (final key in _hintKeys.values) {
    await prefs.remove(key);
  }
}

Future<void> maybeShowFeatureHint(
  BuildContext context,
  WidgetRef ref,
  FeatureHintId id,
) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final key = _hintKeys[id]!;
  if (prefs.getBool(key) == true) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final (title, body) = switch (id) {
    FeatureHintId.calculator => (l10n.hintCalculatorTitle, l10n.hintCalculatorBody),
    FeatureHintId.formulaBook => (
      l10n.hintFormulaBookTitle,
      l10n.hintFormulaBookBody,
    ),
    FeatureHintId.assistant => (l10n.hintAssistantTitle, l10n.hintAssistantBody),
    FeatureHintId.colorPicker => (l10n.hintColorsTitle, l10n.hintColorsBody),
    FeatureHintId.scanImport => (l10n.hintScanTitle, l10n.hintScanBody),
    FeatureHintId.htmlImport => (l10n.hintHtmlTitle, l10n.hintHtmlBody),
  };
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.hintGotIt),
          ),
        ],
      );
    },
  );
}
