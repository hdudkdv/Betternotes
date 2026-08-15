import 'catalog_models.dart';

class ParsedTaskDraft {
  const ParsedTaskDraft({
    required this.title,
    required this.text,
    required this.answerKind,
    this.options = const [],
    this.sourcePageIndexes = const [0],
  });

  final String title;
  final String text;
  final AnswerKind answerKind;
  final List<String> options;
  final List<int> sourcePageIndexes;
}

class _SrcLine {
  const _SrcLine(this.text, this.page);

  final String text;
  final int page;
}

/// Splits OCR / typed worksheet text into draft tasks the teacher can edit.
class CatalogPdfParser {
  static final _heading = RegExp(
    r'^\s*(?:Aufgabe|Aufg\.?|Task|Exercise)\s+(\d+[a-z]?)\s*[.:)]?\s*',
    caseSensitive: false,
  );
  static final _numbered = RegExp(r'^\s*(\d{1,2})[\.)]\s+');
  static final _mc = RegExp(r'^\s*[\(\[]?([a-hA-H])[\)\]\.\:]\s+(\S.*)$');

  static List<ParsedTaskDraft> split(String text, {int pageIndex = 0}) {
    return _splitLines([
      for (final line in text.replaceAll('\r\n', '\n').split('\n'))
        _SrcLine(line, pageIndex),
    ]);
  }

  /// Joins per-page OCR, splits globally, and keeps the source page images.
  static List<ParsedTaskDraft> splitPages(List<String> pageTexts) {
    if (pageTexts.isEmpty) return const [];
    final lines = <_SrcLine>[];
    for (var page = 0; page < pageTexts.length; page++) {
      for (final line in pageTexts[page].replaceAll('\r\n', '\n').split('\n')) {
        lines.add(_SrcLine(line, page));
      }
    }
    if (lines.every((line) => line.text.trim().isEmpty)) {
      return [
        for (var i = 0; i < pageTexts.length; i++)
          ParsedTaskDraft(
            title: '${i + 1}',
            text: '',
            answerKind: AnswerKind.text,
            sourcePageIndexes: [i],
          ),
      ];
    }
    final drafts = _splitLines(lines);
    final used = <int>{
      for (final draft in drafts) ...draft.sourcePageIndexes,
    };
    return [
      ...drafts,
      for (var i = 0; i < pageTexts.length; i++)
        if (!used.contains(i) && pageTexts[i].trim().isEmpty)
          ParsedTaskDraft(
            title: '${drafts.length + 1}',
            text: '',
            answerKind: AnswerKind.text,
            sourcePageIndexes: [i],
          ),
    ];
  }

  static List<ParsedTaskDraft> _splitLines(List<_SrcLine> lines) {
    var headingHits = 0;
    var numberedHits = 0;
    for (final line in lines) {
      if (_heading.hasMatch(line.text)) headingHits++;
      if (_numbered.hasMatch(line.text)) numberedHits++;
    }
    final useHeading = headingHits >= 2;
    final useNumbered = !useHeading && numberedHits >= 2;
    final starts = <int>[];
    if (useHeading || useNumbered) {
      for (var i = 0; i < lines.length; i++) {
        if (useHeading && _heading.hasMatch(lines[i].text)) starts.add(i);
        if (useNumbered && _numbered.hasMatch(lines[i].text)) starts.add(i);
      }
    }
    if (starts.isEmpty) {
      return [_draftFromLines(lines, title: '1')];
    }
    final drafts = <ParsedTaskDraft>[];
    for (var i = 0; i < starts.length; i++) {
      final from = starts[i];
      final to = i + 1 < starts.length ? starts[i + 1] : lines.length;
      final chunk = lines.sublist(from, to);
      final first = chunk.first.text;
      final headingMatch = _heading.firstMatch(first);
      final numberedMatch = _numbered.firstMatch(first);
      final title =
          headingMatch?.group(1) ?? numberedMatch?.group(1) ?? '${i + 1}';
      final restFirst = first
          .replaceFirst(_heading, '')
          .replaceFirst(_numbered, '')
          .trim();
      final body = [
        if (restFirst.isNotEmpty) _SrcLine(restFirst, chunk.first.page),
        ...chunk.skip(1),
      ];
      drafts.add(_draftFromLines(body, title: title));
    }
    return drafts;
  }

  static ParsedTaskDraft _draftFromLines(
    List<_SrcLine> lines, {
    required String title,
  }) {
    final pages = <int>[];
    final body = <String>[];
    final options = <String>[];
    for (final line in lines) {
      if (!pages.contains(line.page)) pages.add(line.page);
      final mc = _mc.firstMatch(line.text);
      if (mc != null) {
        options.add(mc.group(2)!.trim());
        continue;
      }
      body.add(line.text);
    }
    return ParsedTaskDraft(
      title: title,
      text: body.join('\n').trim(),
      answerKind: options.length >= 2
          ? AnswerKind.multipleChoice
          : AnswerKind.text,
      options: options,
      sourcePageIndexes: pages.isEmpty ? const [0] : pages,
    );
  }
}
