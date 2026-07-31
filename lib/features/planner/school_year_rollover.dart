import '../../data/models/notebook.dart';
import 'education_settings.dart';
import 'school_year.dart';

/// Source notebook that should offer a new-school-year rollover card.
class SchoolYearRolloverCandidate {
  const SchoolYearRolloverCandidate({
    required this.source,
    required this.nextClass,
  });

  final Notebook source;
  final int nextClass;
}

abstract final class SchoolYearRollover {
  /// Sek I / Sek II only — university does not use Klassenstufen the same way.
  static bool supportsLevel(EducationLevel level) =>
      level == EducationLevel.sek1 || level == EducationLevel.sek2;

  static String dismissKey(String notebookId, SchoolYear year) =>
      '$notebookId:${year.startYear}';

  /// Notebooks in [folderNotebooks] that still need a +1 class notebook
  /// for the current school year.
  static List<SchoolYearRolloverCandidate> candidates({
    required List<Notebook> folderNotebooks,
    required EducationLevel level,
    required GermanState state,
    required Set<String> dismissedKeys,
    DateTime? now,
  }) {
    if (!supportsLevel(level)) return [];
    final today = now ?? DateTime.now();
    if (!SchoolHolidays.hasNewSchoolYearStarted(state: state, now: today)) {
      return [];
    }
    final current = SchoolYear.fromDate(today);
    final result = <SchoolYearRolloverCandidate>[];

    for (final source in folderNotebooks) {
      final schoolClass = source.schoolClass;
      if (schoolClass == null || schoolClass >= 13) continue;

      final sourceYear = SchoolYear.fromDate(
        source.lastOpenedAt ?? source.updatedAt,
      );
      // Only promote notebooks that belonged to an earlier school year.
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

      result.add(
        SchoolYearRolloverCandidate(source: source, nextClass: nextClass),
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
