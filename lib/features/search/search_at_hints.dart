import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../l10n/app_localizations.dart';

class SearchAtHints extends StatelessWidget {
  const SearchAtHints({
    super.key,
    required this.query,
    required this.folders,
    required this.notebooks,
    required this.onInsert,
  });

  final String query;
  final List<LibraryFolder> folders;
  final List<Notebook> notebooks;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    if (!query.contains('@')) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final typed = _currentAtToken(query);
    final suggestions = <String>{
      for (final folder in folders) folder.name,
      for (final nb in notebooks)
        if (nb.subjectKey != null && nb.subjectKey!.trim().isNotEmpty)
          nb.subjectKey!,
      for (final nb in notebooks)
        if (nb.schoolClass != null) 'Klasse${nb.schoolClass}',
    }.where((name) {
      if (typed.isEmpty) return true;
      return name.toLowerCase().startsWith(typed) ||
          name.toLowerCase().contains(typed);
    }).take(8);

    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchAtHint,
            style: AppTheme.body(fontSize: 12, color: AppTheme.inkMuted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in suggestions)
                ActionChip(
                  label: Text('@$name'),
                  onPressed: () => onInsert(_replaceAtToken(query, name)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _currentAtToken(String query) {
    final at = query.lastIndexOf('@');
    if (at < 0) return '';
    return query.substring(at + 1).split(RegExp(r'\s')).first.toLowerCase();
  }

  static String _replaceAtToken(String query, String name) {
    final at = query.lastIndexOf('@');
    if (at < 0) return '${query.trim()} @$name ';
    final after = query.substring(at + 1);
    final space = after.indexOf(' ');
    final end = space < 0 ? query.length : at + 1 + space;
    return '${query.substring(0, at)}@$name ${query.substring(end).trimLeft()}';
  }
}
