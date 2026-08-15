import '../../l10n/app_localizations.dart';
import 'education_settings.dart';
import 'school_year.dart';

enum TermKind { winterHalbjahr, summerHalbjahr, winterSemester, summerSemester }

/// Current school half-year or university semester.
class AcademicTerm {
  const AcademicTerm(this.kind, this.anchorYear);

  final TermKind kind;

  /// School-year start (Halbjahr) or calendar year the term begins (Semester).
  final int anchorYear;

  String get id => '${kind.name}-$anchorYear';

  bool get isUniversity =>
      kind == TermKind.winterSemester || kind == TermKind.summerSemester;

  static AcademicTerm fromDate(EducationLevel level, DateTime date) {
    if (level == EducationLevel.university) {
      if (date.month >= 10) {
        return AcademicTerm(TermKind.winterSemester, date.year);
      }
      if (date.month <= 3) {
        return AcademicTerm(TermKind.winterSemester, date.year - 1);
      }
      return AcademicTerm(TermKind.summerSemester, date.year);
    }
    final year = SchoolYear.fromDate(date);
    if (date.month >= 8 || date.month == 1) {
      return AcademicTerm(TermKind.winterHalbjahr, year.startYear);
    }
    return AcademicTerm(TermKind.summerHalbjahr, year.startYear);
  }

  static AcademicTerm current(EducationLevel level, [DateTime? now]) =>
      fromDate(level, now ?? DateTime.now());

  DateTime get start {
    switch (kind) {
      case TermKind.winterHalbjahr:
        return DateTime(anchorYear, 8, 1);
      case TermKind.summerHalbjahr:
        return DateTime(anchorYear + 1, 2, 1);
      case TermKind.winterSemester:
        return DateTime(anchorYear, 10, 1);
      case TermKind.summerSemester:
        return DateTime(anchorYear, 4, 1);
    }
  }

  String label(AppLocalizations l10n) {
    final school = SchoolYear(anchorYear).label;
    return switch (kind) {
      TermKind.winterHalbjahr => l10n.termWinterHalbjahr(school),
      TermKind.summerHalbjahr => l10n.termSummerHalbjahr(school),
      TermKind.winterSemester => l10n.termWinterSemester(school),
      TermKind.summerSemester => l10n.termSummerSemester('$anchorYear'),
    };
  }
}
