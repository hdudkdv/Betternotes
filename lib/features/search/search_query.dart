import '../../data/models/notebook.dart';

/// `@Wirtschaft addition` → filter by subject/folder/year, then search text.
class ParsedSearchQuery {
  const ParsedSearchQuery({required this.filters, required this.text});

  final List<String> filters;
  final String text;

  bool get hasFilters => filters.isNotEmpty;
  bool get isEmpty => filters.isEmpty && text.trim().isEmpty;

  factory ParsedSearchQuery.parse(String raw) {
    final filters = <String>[];
    final words = <String>[];
    for (final part in raw.trim().split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      if (part.startsWith('@') && part.length > 1) {
        filters.add(_normalize(part.substring(1)));
      } else {
        words.add(part);
      }
    }
    return ParsedSearchQuery(filters: filters, text: words.join(' '));
  }

  bool matchesScope({
    required Notebook notebook,
    required String folderPath,
  }) {
    if (filters.isEmpty) return true;
    return filters.every(
      (filter) => _scopeHits(
        filter: filter,
        notebook: notebook,
        folderPath: folderPath,
      ),
    );
  }

  static bool _scopeHits({
    required String filter,
    required Notebook notebook,
    required String folderPath,
  }) {
    if (filter.isEmpty) return true;
    final title = _normalize(notebook.title);
    final subject = _normalize(notebook.subjectKey ?? '');
    final path = _normalize(folderPath);
    if (title.contains(filter) ||
        subject.contains(filter) ||
        path.contains(filter)) {
      return true;
    }
    final klass = notebook.schoolClass;
    if (klass != null) {
      final asClass = 'klasse$klass';
      final short = 'k$klass';
      if (filter == '$klass' ||
          filter == asClass ||
          filter == short ||
          asClass.contains(filter) ||
          filter.contains('$klass')) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
}
