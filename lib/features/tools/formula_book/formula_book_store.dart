import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'formula_book_models.dart';

class FormulaBookStore {
  FormulaBookStore(this._prefs);

  final SharedPreferences _prefs;
  static const _bookKey = 'tafelwerk_v1';

  FormulaBook load({bool plus = false}) {
    FormulaBook book;
    final raw = _prefs.getString(_bookKey);
    if (raw == null || raw.isEmpty) {
      book = FormulaBook.seeded();
    } else {
      try {
        final parsed = FormulaBook.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        book = parsed.chapters.isEmpty
            ? FormulaBook.seeded()
            : _mergeSeeded(parsed);
      } catch (_) {
        book = FormulaBook.seeded();
      }
    }
    if (!plus) return book;
    return _mergeExtra(book, FormulaBook.plusSeeded());
  }

  Future<void> save(FormulaBook book) async {
    await _prefs.setString(_bookKey, jsonEncode(book.toJson()));
  }

  String? lastChapterFor(String notebookId) {
    return _prefs.getString('tafelwerk_last_$notebookId');
  }

  Future<void> setLastChapter(String notebookId, String chapterId) async {
    await _prefs.setString('tafelwerk_last_$notebookId', chapterId);
  }

  static String? matchChapterId({
    required FormulaBook book,
    String? subjectKey,
    String? folderPath,
  }) {
    final hay = '${subjectKey ?? ''} ${folderPath ?? ''}'.toLowerCase();
    if (hay.trim().isEmpty) return null;
    const aliases = <String, List<String>>{
      'mathematik': ['mathe', 'math', 'maths'],
      'physik': ['physics'],
      'chemie': ['chemistry'],
      'biologie': ['bio', 'biology'],
      'geschichte': ['history', 'geo-geschichte'],
      'deutsch': ['german', 'de'],
      'englisch': ['english', 'en', 'eng'],
      'geographie': ['geo', 'geography', 'erdkunde'],
      'politik': ['powi', 'sowi', 'social'],
      'wirtschaft': ['wiwi', 'bwl', 'vwl', 'eco', 'economics'],
      'informatik': ['info', 'cs', 'it'],
    };
    for (final chapter in book.chapters) {
      final title = chapter.title.toLowerCase();
      if (hay.contains(chapter.id) || hay.contains(title)) {
        return chapter.id;
      }
      final extra = aliases[chapter.id] ?? const <String>[];
      if (extra.any(hay.contains)) return chapter.id;
    }
    return null;
  }

  FormulaBook _mergeSeeded(FormulaBook stored) {
    final seed = FormulaBook.seeded();
    final have = {for (final c in stored.chapters) c.id};
    final extra = [
      for (final c in seed.chapters)
        if (!have.contains(c.id)) c,
    ];
    if (extra.isEmpty) return stored;
    return FormulaBook(chapters: [...stored.chapters, ...extra]);
  }

  FormulaBook _mergeExtra(FormulaBook stored, FormulaBook extraBook) {
    final have = {for (final c in stored.chapters) c.id};
    final extra = [
      for (final c in extraBook.chapters)
        if (!have.contains(c.id)) c,
    ];
    if (extra.isEmpty) return stored;
    return FormulaBook(chapters: [...stored.chapters, ...extra]);
  }
}
