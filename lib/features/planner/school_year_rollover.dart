import '../../data/models/notebook.dart';
import 'academic_term.dart';
import 'education_settings.dart';
import 'school_year.dart';

/// Source notebook that should offer a new-term / new-school-year card.
class SchoolYearRolloverCandidate {
  const SchoolYearRolloverCandidate({
    required this.source,
    required this.dismissKey,
    this.nextClass,
    this.term,
  });

  final Notebook source;
  final String dismissKey;
  final int? nextClass;
  final AcademicTerm? term;
}

abstract final class SchoolYearRollover {
  /// Sek I / Sek II use Klassenstufen for the summer promotion.
  static bool supportsClassPromotion(EducationLevel level) =>
      level == EducationLevel.sek1 || level == EducationLevel.sek2;

  static String dismissKey(String notebookId, SchoolYear year) =>
      '$notebookId:${year.startYear}';

  static String dismissTermKey(String notebookId, AcademicTerm term) =>
      '$notebookId:term:${term.id}';

  /// Notebooks in [folderNotebooks] that should offer a fresh notebook
  /// for the current school year, half-year, or semester.
  static List<SchoolYearRolloverCandidate> candidates({
    required List<Notebook> folderNotebooks,
    required EducationLevel level,
    required GermanState state,
    required Set<String> dismissedKeys,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final result = <SchoolYearRolloverCandidate>[];
    final promoted = <String>{};

    if (supportsClassPromotion(level) &&
        SchoolHolidays.hasNewSchoolYearStarted(state: state, now: today)) {
      final current = SchoolYear.fromDate(today);
      for (final source in folderNotebooks) {
        final schoolClass = source.schoolClass;
        if (schoolClass == null || schoolClass >= 13) continue;

        final sourceYear = SchoolYear.fromDate(
          source.lastOpenedAt ?? source.updatedAt,
        );
        if (sourceYear.startYear >= current.startYear) continue;

        final key = dismissKey(source.id, current);
        if (dismissedKeys.contains(key)) continue;

        final nextClass = schoolClass + 1;
        final hasSuccessor = folderNotebooks.any(
          (n) =>
              n.id != source.id &&
              n.schoolClass == nextClass &&
              n.title == source.title,
        );
        if (hasSuccessor) continue;

        promoted.add(source.id);
        result.add(
          SchoolYearRolloverCandidate(
            source: source,
            nextClass: nextClass,
            dismissKey: key,
          ),
        );
      }
    }

    final term = AcademicTerm.current(level, today);
    for (final source in folderNotebooks) {
      if (promoted.contains(source.id)) continue;
      final activity = source.lastOpenedAt ?? source.updatedAt;
      final sourceTerm = AcademicTerm.fromDate(level, activity);
      if (sourceTerm.id == term.id) continue;
      if (AcademicTerm.fromDate(level, source.createdAt).id == term.id) {
        continue;
      }

      final key = dismissTermKey(source.id, term);
      if (dismissedKeys.contains(key)) continue;

      final hasSuccessor = folderNotebooks.any((n) {
        if (n.id == source.id || n.title != source.title) return false;
        final createdTerm = AcademicTerm.fromDate(level, n.createdAt);
        return createdTerm.id == term.id;
      });
      if (hasSuccessor) continue;

      result.add(
        SchoolYearRolloverCandidate(
          source: source,
          nextClass: source.schoolClass,
          term: term,
          dismissKey: key,
        ),
      );
    }

    result.sort(
      (a, b) => a.source.title.toLowerCase().compareTo(
        b.source.title.toLowerCase(),
      ),
    );
    return result;
  }
}
