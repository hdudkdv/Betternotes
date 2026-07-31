import '../../l10n/app_localizations.dart';
import 'planner_model.dart';
import 'school_year.dart';

/// School / study track — drives grade scale and exam vocabulary.
enum EducationLevel { sek1, sek2, university }

/// German federal states for school holidays.
enum GermanState {
  bw,
  by,
  be,
  bb,
  hb,
  hh,
  he,
  mv,
  ni,
  nw,
  rp,
  sl,
  sn,
  st,
  sh,
  th,
}

extension EducationLevelX on EducationLevel {
  GradeScale get defaultScale => switch (this) {
    EducationLevel.sek1 => GradeScale.german,
    EducationLevel.sek2 => GradeScale.points,
    EducationLevel.university => GradeScale.uni,
  };

  String majorLabel(AppLocalizations l10n) => switch (this) {
    EducationLevel.sek1 => l10n.gradeKindWritten,
    EducationLevel.sek2 => l10n.gradeKindKlausur,
    EducationLevel.university => l10n.gradeKindUniExam,
  };

  String minorLabel(AppLocalizations l10n) => switch (this) {
    EducationLevel.sek1 => l10n.gradeKindOral,
    EducationLevel.sek2 => l10n.gradeKindOtherParticipation,
    EducationLevel.university => l10n.gradeKindHomework,
  };

  String label(AppLocalizations l10n) => switch (this) {
    EducationLevel.sek1 => l10n.eduSek1,
    EducationLevel.sek2 => l10n.eduSek2,
    EducationLevel.university => l10n.eduUniversity,
  };

  String scaleHint(AppLocalizations l10n) => switch (this) {
    EducationLevel.sek1 => l10n.eduScaleSek1Hint,
    EducationLevel.sek2 => l10n.eduScaleSek2Hint,
    EducationLevel.university => l10n.eduScaleUniHint,
  };
}

extension GermanStateX on GermanState {
  String label(AppLocalizations l10n) => switch (this) {
    GermanState.bw => l10n.stateBw,
    GermanState.by => l10n.stateBy,
    GermanState.be => l10n.stateBe,
    GermanState.bb => l10n.stateBb,
    GermanState.hb => l10n.stateHb,
    GermanState.hh => l10n.stateHh,
    GermanState.he => l10n.stateHe,
    GermanState.mv => l10n.stateMv,
    GermanState.ni => l10n.stateNi,
    GermanState.nw => l10n.stateNw,
    GermanState.rp => l10n.stateRp,
    GermanState.sl => l10n.stateSl,
    GermanState.sn => l10n.stateSn,
    GermanState.st => l10n.stateSt,
    GermanState.sh => l10n.stateSh,
    GermanState.th => l10n.stateTh,
  };
}

class SchoolHoliday {
  const SchoolHoliday({
    required this.name,
    required this.start,
    required this.end,
  });

  final String name;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    return !d.isBefore(a) && !d.isAfter(b);
  }
}

/// Approximate school holidays 2025/26–2026/27 (official-ish windows).
class SchoolHolidays {
  static DateTime _d(int y, int m, int day) => DateTime(y, m, day);

  static String _name(String key, AppLocalizations l10n) => switch (key) {
    'autumn' => l10n.holidayAutumn,
    'christmas' => l10n.holidayChristmas,
    'winter' => l10n.holidayWinter,
    'easter' => l10n.holidayEaster,
    'pentecost' => l10n.holidayPentecost,
    'summer' => l10n.holidaySummer,
    _ => key,
  };

  static List<(String, DateTime, DateTime)> _nw() => [
    ('autumn', _d(2025, 10, 13), _d(2025, 10, 25)),
    ('christmas', _d(2025, 12, 22), _d(2026, 1, 6)),
    ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
    ('pentecost', _d(2026, 5, 26), _d(2026, 6, 6)),
    ('summer', _d(2026, 7, 20), _d(2026, 9, 1)),
    ('autumn', _d(2026, 10, 12), _d(2026, 10, 24)),
    ('christmas', _d(2026, 12, 23), _d(2027, 1, 6)),
  ];

  static final Map<GermanState, List<(String, DateTime, DateTime)>> _ranges = {
    GermanState.nw: _nw(),
    GermanState.by: [
      ('autumn', _d(2025, 11, 3), _d(2025, 11, 7)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 5)),
      ('winter', _d(2026, 2, 16), _d(2026, 2, 20)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 10)),
      ('pentecost', _d(2026, 5, 26), _d(2026, 6, 5)),
      ('summer', _d(2026, 8, 3), _d(2026, 9, 14)),
      ('autumn', _d(2026, 11, 2), _d(2026, 11, 6)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
    GermanState.bw: [
      ('autumn', _d(2025, 10, 27), _d(2025, 10, 31)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 10)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('pentecost', _d(2026, 5, 26), _d(2026, 6, 6)),
      ('summer', _d(2026, 7, 30), _d(2026, 9, 12)),
      ('autumn', _d(2026, 10, 26), _d(2026, 10, 31)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
    GermanState.be: [
      ('autumn', _d(2025, 10, 20), _d(2025, 11, 1)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 2)),
      ('winter', _d(2026, 2, 2), _d(2026, 2, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('summer', _d(2026, 7, 9), _d(2026, 8, 22)),
      ('autumn', _d(2026, 10, 19), _d(2026, 10, 31)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.bb: [
      ('autumn', _d(2025, 10, 20), _d(2025, 11, 1)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 2)),
      ('winter', _d(2026, 2, 2), _d(2026, 2, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('summer', _d(2026, 7, 16), _d(2026, 8, 29)),
      ('autumn', _d(2026, 10, 19), _d(2026, 10, 31)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.hh: [
      ('autumn', _d(2025, 10, 20), _d(2025, 10, 31)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 2)),
      ('winter', _d(2026, 1, 30), _d(2026, 2, 3)),
      ('easter', _d(2026, 3, 2), _d(2026, 3, 13)),
      ('pentecost', _d(2026, 5, 11), _d(2026, 5, 15)),
      ('summer', _d(2026, 7, 16), _d(2026, 8, 26)),
      ('autumn', _d(2026, 10, 5), _d(2026, 10, 16)),
      ('christmas', _d(2026, 12, 21), _d(2027, 1, 5)),
    ],
    GermanState.he: [
      ('autumn', _d(2025, 10, 6), _d(2025, 10, 18)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 10)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('summer', _d(2026, 7, 6), _d(2026, 8, 14)),
      ('autumn', _d(2026, 10, 5), _d(2026, 10, 17)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
    GermanState.ni: [
      ('autumn', _d(2025, 10, 4), _d(2025, 10, 15)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 5)),
      ('easter', _d(2026, 3, 23), _d(2026, 4, 7)),
      ('summer', _d(2026, 7, 2), _d(2026, 8, 12)),
      ('autumn', _d(2026, 10, 12), _d(2026, 10, 23)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
    GermanState.hb: [
      ('autumn', _d(2025, 10, 4), _d(2025, 10, 15)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 5)),
      ('easter', _d(2026, 3, 23), _d(2026, 4, 7)),
      ('summer', _d(2026, 7, 2), _d(2026, 8, 12)),
      ('autumn', _d(2026, 10, 12), _d(2026, 10, 23)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
    GermanState.rp: [
      ('autumn', _d(2025, 10, 13), _d(2025, 10, 24)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 10)),
      ('summer', _d(2026, 7, 6), _d(2026, 8, 14)),
      ('autumn', _d(2026, 10, 12), _d(2026, 10, 23)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 6)),
    ],
    GermanState.sl: [
      ('autumn', _d(2025, 10, 13), _d(2025, 10, 24)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 2)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 10)),
      ('summer', _d(2026, 7, 6), _d(2026, 8, 14)),
      ('autumn', _d(2026, 10, 12), _d(2026, 10, 23)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.sn: [
      ('autumn', _d(2025, 10, 6), _d(2025, 10, 18)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 3)),
      ('winter', _d(2026, 2, 9), _d(2026, 2, 21)),
      ('easter', _d(2026, 3, 28), _d(2026, 4, 10)),
      ('summer', _d(2026, 7, 4), _d(2026, 8, 14)),
      ('autumn', _d(2026, 10, 3), _d(2026, 10, 15)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.st: [
      ('autumn', _d(2025, 10, 6), _d(2025, 10, 18)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 3)),
      ('winter', _d(2026, 2, 2), _d(2026, 2, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('summer', _d(2026, 7, 16), _d(2026, 8, 26)),
      ('autumn', _d(2026, 10, 19), _d(2026, 10, 31)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.th: [
      ('autumn', _d(2025, 10, 6), _d(2025, 10, 18)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 3)),
      ('winter', _d(2026, 2, 2), _d(2026, 2, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 11)),
      ('summer', _d(2026, 7, 20), _d(2026, 8, 29)),
      ('autumn', _d(2026, 10, 5), _d(2026, 10, 17)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 2)),
    ],
    GermanState.mv: [
      ('autumn', _d(2025, 10, 20), _d(2025, 10, 25)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 3)),
      ('winter', _d(2026, 2, 2), _d(2026, 2, 7)),
      ('easter', _d(2026, 3, 30), _d(2026, 4, 7)),
      ('summer', _d(2026, 7, 13), _d(2026, 8, 22)),
      ('autumn', _d(2026, 10, 5), _d(2026, 10, 10)),
      ('christmas', _d(2026, 12, 21), _d(2027, 1, 2)),
    ],
    GermanState.sh: [
      ('autumn', _d(2025, 10, 4), _d(2025, 10, 15)),
      ('christmas', _d(2025, 12, 22), _d(2026, 1, 5)),
      ('easter', _d(2026, 3, 23), _d(2026, 4, 7)),
      ('summer', _d(2026, 7, 20), _d(2026, 8, 29)),
      ('autumn', _d(2026, 10, 12), _d(2026, 10, 23)),
      ('christmas', _d(2026, 12, 23), _d(2027, 1, 9)),
    ],
  };

  static List<SchoolHoliday> forState(
    GermanState state,
    AppLocalizations l10n,
  ) {
    final raw = _ranges[state] ?? _nw();
    return [
      for (final r in raw)
        SchoolHoliday(name: _name(r.$1, l10n), start: r.$2, end: r.$3),
    ];
  }

  static SchoolHoliday? holidayOn(
    GermanState state,
    DateTime day,
    AppLocalizations l10n,
  ) {
    for (final h in forState(state, l10n)) {
      if (h.contains(day)) return h;
    }
    return null;
  }

  /// End date of the summer break that opens [schoolYear] (Aug/Sep of startYear).
  static DateTime? summerEndForSchoolYear(GermanState state, SchoolYear year) {
    final raw = _ranges[state] ?? _nw();
    for (final r in raw) {
      if (r.$1 != 'summer') continue;
      final end = r.$3;
      if (end.year == year.startYear && end.month >= 7) {
        return DateTime(end.year, end.month, end.day);
      }
    }
    return null;
  }

  /// True once summer holidays for the current school year are over
  /// (falls back to 1 August).
  static bool hasNewSchoolYearStarted({
    required GermanState state,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final year = SchoolYear.fromDate(day);
    final summerEnd = summerEndForSchoolYear(state, year);
    if (summerEnd != null) {
      return !day.isBefore(summerEnd);
    }
    return !day.isBefore(DateTime(year.startYear, 8, 1));
  }
}
