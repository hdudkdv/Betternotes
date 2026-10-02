import '../../l10n/app_localizations.dart';
import 'planner_model.dart';
import 'school_year.dart';

/// School / study track — drives grade scale and exam vocabulary.
enum EducationLevel { sek1, sek2, university }

/// Length of the Gymnasium Oberstufe (Sek II).
enum OberstufeDuration {
  /// Qualifikationsphase only — points 0–15 from the first half-year.
  twoYears,

  /// Einführungsphase (Klasse 11, grades 1–6) plus Q-phase (12/13, 0–15).
  threeYears,
}

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

  String scaleHint(
    AppLocalizations l10n, {
    OberstufeDuration duration = OberstufeDuration.twoYears,
  }) => switch (this) {
    EducationLevel.sek1 => l10n.eduScaleSek1Hint,
    EducationLevel.sek2 =>
      duration == OberstufeDuration.threeYears
          ? l10n.eduScaleSek2ThreeYearHint
          : l10n.eduScaleSek2TwoYearHint,
    EducationLevel.university => l10n.eduScaleUniHint,
  };
}

extension OberstufeDurationX on OberstufeDuration {
  String label(AppLocalizations l10n) => switch (this) {
    OberstufeDuration.twoYears => l10n.oberstufeTwoYears,
    OberstufeDuration.threeYears => l10n.oberstufeThreeYears,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    OberstufeDuration.twoYears => l10n.oberstufeTwoYearsHint,
    OberstufeDuration.threeYears => l10n.oberstufeThreeYearsHint,
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

/// Official KMK first/last holiday days (stand 09.10.2025) for 2025/26–2026/27.
class SchoolHolidays {
  static DateTime _d(int y, int m, int day) => DateTime(y, m, day);

  static (String, DateTime, DateTime) _h(
    String key,
    int y1,
    int m1,
    int d1,
    int y2,
    int m2,
    int d2,
  ) => (key, _d(y1, m1, d1), _d(y2, m2, d2));

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
    _h('autumn', 2025, 10, 13, 2025, 10, 25),
    _h('christmas', 2025, 12, 22, 2026, 1, 6),
    _h('easter', 2026, 3, 30, 2026, 4, 11),
    _h('pentecost', 2026, 5, 26, 2026, 5, 26),
    _h('summer', 2026, 7, 20, 2026, 9, 1),
    _h('autumn', 2026, 10, 17, 2026, 10, 31),
    _h('christmas', 2026, 12, 23, 2027, 1, 6),
    _h('easter', 2027, 3, 22, 2027, 4, 3),
    _h('pentecost', 2027, 5, 18, 2027, 5, 18),
    _h('summer', 2027, 7, 19, 2027, 8, 31),
  ];

  static final Map<GermanState, List<(String, DateTime, DateTime)>> _ranges = {
    GermanState.nw: _nw(),
    GermanState.bw: [
      _h('autumn', 2025, 10, 27, 2025, 10, 31),
      _h('christmas', 2025, 12, 22, 2026, 1, 5),
      _h('easter', 2026, 3, 30, 2026, 4, 11),
      _h('pentecost', 2026, 5, 26, 2026, 6, 5),
      _h('summer', 2026, 7, 30, 2026, 9, 12),
      _h('autumn', 2026, 10, 26, 2026, 10, 31),
      _h('christmas', 2026, 12, 23, 2027, 1, 9),
      _h('easter', 2027, 3, 25, 2027, 3, 25),
      _h('easter', 2027, 3, 30, 2027, 4, 3),
      _h('pentecost', 2027, 5, 18, 2027, 5, 29),
      _h('summer', 2027, 7, 29, 2027, 9, 11),
    ],
    GermanState.by: [
      _h('autumn', 2025, 11, 3, 2025, 11, 7),
      _h('christmas', 2025, 12, 22, 2026, 1, 5),
      _h('winter', 2026, 2, 16, 2026, 2, 20),
      _h('easter', 2026, 3, 30, 2026, 4, 10),
      _h('pentecost', 2026, 5, 26, 2026, 6, 5),
      _h('summer', 2026, 8, 3, 2026, 9, 14),
      _h('autumn', 2026, 11, 2, 2026, 11, 6),
      _h('christmas', 2026, 12, 24, 2027, 1, 8),
      _h('winter', 2027, 2, 8, 2027, 2, 12),
      _h('easter', 2027, 3, 22, 2027, 4, 2),
      _h('pentecost', 2027, 5, 18, 2027, 5, 28),
      _h('summer', 2027, 8, 2, 2027, 9, 13),
    ],
    GermanState.be: [
      _h('autumn', 2025, 10, 20, 2025, 11, 1),
      _h('christmas', 2025, 12, 22, 2026, 1, 2),
      _h('winter', 2026, 2, 2, 2026, 2, 7),
      _h('easter', 2026, 3, 30, 2026, 4, 10),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('pentecost', 2026, 5, 26, 2026, 5, 26),
      _h('summer', 2026, 7, 9, 2026, 8, 22),
      _h('autumn', 2026, 10, 19, 2026, 10, 31),
      _h('christmas', 2026, 12, 23, 2027, 1, 2),
      _h('winter', 2027, 2, 1, 2027, 2, 6),
      _h('easter', 2027, 3, 22, 2027, 4, 2),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('pentecost', 2027, 5, 18, 2027, 5, 19),
      _h('summer', 2027, 7, 1, 2027, 8, 14),
    ],
    GermanState.bb: [
      _h('autumn', 2025, 10, 20, 2025, 11, 1),
      _h('christmas', 2025, 12, 22, 2026, 1, 2),
      _h('winter', 2026, 2, 2, 2026, 2, 7),
      _h('easter', 2026, 3, 30, 2026, 4, 10),
      _h('pentecost', 2026, 5, 26, 2026, 5, 26),
      _h('summer', 2026, 7, 9, 2026, 8, 22),
      _h('autumn', 2026, 10, 19, 2026, 10, 30),
      _h('christmas', 2026, 12, 23, 2027, 1, 2),
      _h('winter', 2027, 2, 1, 2027, 2, 6),
      _h('easter', 2027, 3, 22, 2027, 4, 3),
      _h('pentecost', 2027, 5, 18, 2027, 5, 18),
      _h('summer', 2027, 7, 1, 2027, 8, 14),
    ],
    GermanState.hb: [
      _h('autumn', 2025, 10, 13, 2025, 10, 25),
      _h('christmas', 2025, 12, 22, 2026, 1, 5),
      _h('winter', 2026, 2, 2, 2026, 2, 3),
      _h('easter', 2026, 3, 23, 2026, 4, 7),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('pentecost', 2026, 5, 26, 2026, 5, 26),
      _h('summer', 2026, 7, 2, 2026, 8, 12),
      _h('autumn', 2026, 10, 12, 2026, 10, 24),
      _h('christmas', 2026, 12, 23, 2027, 1, 9),
      _h('winter', 2027, 2, 1, 2027, 2, 2),
      _h('easter', 2027, 3, 22, 2027, 4, 3),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('pentecost', 2027, 5, 18, 2027, 5, 18),
      _h('summer', 2027, 7, 8, 2027, 8, 18),
    ],
    GermanState.hh: [
      _h('autumn', 2025, 10, 20, 2025, 10, 31),
      _h('christmas', 2025, 12, 17, 2026, 1, 2),
      _h('winter', 2026, 1, 30, 2026, 1, 30),
      _h('easter', 2026, 3, 2, 2026, 3, 13),
      _h('pentecost', 2026, 5, 11, 2026, 5, 15),
      _h('summer', 2026, 7, 9, 2026, 8, 19),
      _h('autumn', 2026, 10, 19, 2026, 10, 30),
      _h('christmas', 2026, 12, 21, 2027, 1, 1),
      _h('winter', 2027, 1, 29, 2027, 1, 29),
      _h('easter', 2027, 3, 1, 2027, 3, 12),
      _h('pentecost', 2027, 5, 7, 2027, 5, 14),
      _h('summer', 2027, 7, 1, 2027, 8, 11),
    ],
    GermanState.he: [
      _h('autumn', 2025, 10, 6, 2025, 10, 18),
      _h('christmas', 2025, 12, 22, 2026, 1, 10),
      _h('easter', 2026, 3, 30, 2026, 4, 10),
      _h('summer', 2026, 6, 29, 2026, 8, 7),
      _h('autumn', 2026, 10, 5, 2026, 10, 17),
      _h('christmas', 2026, 12, 23, 2027, 1, 12),
      _h('easter', 2027, 3, 22, 2027, 4, 2),
      _h('summer', 2027, 6, 28, 2027, 8, 6),
    ],
    GermanState.ni: [
      _h('autumn', 2025, 10, 13, 2025, 10, 25),
      _h('christmas', 2025, 12, 22, 2026, 1, 5),
      _h('winter', 2026, 2, 2, 2026, 2, 3),
      _h('easter', 2026, 3, 23, 2026, 4, 7),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('pentecost', 2026, 5, 26, 2026, 5, 26),
      _h('summer', 2026, 7, 2, 2026, 8, 12),
      _h('autumn', 2026, 10, 12, 2026, 10, 24),
      _h('christmas', 2026, 12, 23, 2027, 1, 9),
      _h('winter', 2027, 2, 1, 2027, 2, 2),
      _h('easter', 2027, 3, 22, 2027, 4, 3),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('pentecost', 2027, 5, 18, 2027, 5, 18),
      _h('summer', 2027, 7, 8, 2027, 8, 18),
    ],
    GermanState.rp: [
      _h('autumn', 2025, 10, 13, 2025, 10, 24),
      _h('christmas', 2025, 12, 22, 2026, 1, 7),
      _h('easter', 2026, 3, 30, 2026, 4, 10),
      _h('summer', 2026, 6, 29, 2026, 8, 7),
      _h('autumn', 2026, 10, 5, 2026, 10, 16),
      _h('christmas', 2026, 12, 23, 2027, 1, 8),
      _h('easter', 2027, 3, 22, 2027, 4, 2),
      _h('summer', 2027, 6, 28, 2027, 8, 6),
    ],
    GermanState.sl: [
      _h('autumn', 2025, 10, 13, 2025, 10, 24),
      _h('christmas', 2025, 12, 22, 2026, 1, 2),
      _h('winter', 2026, 2, 16, 2026, 2, 20),
      _h('easter', 2026, 4, 7, 2026, 4, 17),
      _h('summer', 2026, 6, 29, 2026, 8, 7),
      _h('autumn', 2026, 10, 5, 2026, 10, 16),
      _h('christmas', 2026, 12, 21, 2026, 12, 31),
      _h('winter', 2027, 2, 8, 2027, 2, 12),
      _h('easter', 2027, 3, 30, 2027, 4, 9),
      _h('summer', 2027, 6, 28, 2027, 8, 6),
    ],
    GermanState.sn: [
      _h('autumn', 2025, 10, 6, 2025, 10, 18),
      _h('christmas', 2025, 12, 22, 2026, 1, 2),
      _h('winter', 2026, 2, 9, 2026, 2, 21),
      _h('easter', 2026, 4, 3, 2026, 4, 10),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('summer', 2026, 7, 4, 2026, 8, 14),
      _h('autumn', 2026, 10, 12, 2026, 10, 24),
      _h('christmas', 2026, 12, 23, 2027, 1, 2),
      _h('winter', 2027, 2, 8, 2027, 2, 19),
      _h('easter', 2027, 3, 26, 2027, 4, 2),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('pentecost', 2027, 5, 15, 2027, 5, 18),
      _h('summer', 2027, 7, 10, 2027, 8, 20),
    ],
    GermanState.st: [
      _h('autumn', 2025, 10, 13, 2025, 10, 25),
      _h('christmas', 2025, 12, 22, 2026, 1, 5),
      _h('winter', 2026, 1, 31, 2026, 2, 6),
      _h('easter', 2026, 3, 30, 2026, 4, 4),
      _h('pentecost', 2026, 5, 26, 2026, 5, 29),
      _h('summer', 2026, 7, 4, 2026, 8, 14),
      _h('autumn', 2026, 10, 19, 2026, 10, 30),
      _h('christmas', 2026, 12, 21, 2027, 1, 2),
      _h('winter', 2027, 2, 1, 2027, 2, 6),
      _h('easter', 2027, 3, 22, 2027, 3, 27),
      _h('pentecost', 2027, 5, 15, 2027, 5, 22),
      _h('summer', 2027, 7, 10, 2027, 8, 20),
    ],
    GermanState.th: [
      _h('autumn', 2025, 10, 6, 2025, 10, 18),
      _h('christmas', 2025, 12, 22, 2026, 1, 3),
      _h('winter', 2026, 2, 16, 2026, 2, 21),
      _h('easter', 2026, 4, 7, 2026, 4, 17),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('summer', 2026, 7, 4, 2026, 8, 14),
      _h('autumn', 2026, 10, 12, 2026, 10, 24),
      _h('christmas', 2026, 12, 23, 2027, 1, 2),
      _h('winter', 2027, 2, 1, 2027, 2, 6),
      _h('easter', 2027, 3, 22, 2027, 4, 3),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('summer', 2027, 7, 10, 2027, 8, 20),
    ],
    GermanState.mv: [
      _h('autumn', 2025, 10, 20, 2025, 10, 24),
      _h('christmas', 2025, 12, 20, 2026, 1, 3),
      _h('winter', 2026, 2, 9, 2026, 2, 20),
      _h('easter', 2026, 3, 30, 2026, 4, 8),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('pentecost', 2026, 5, 22, 2026, 5, 26),
      _h('summer', 2026, 7, 13, 2026, 8, 22),
      _h('autumn', 2026, 10, 15, 2026, 10, 24),
      _h('christmas', 2026, 12, 21, 2027, 1, 2),
      _h('winter', 2027, 2, 8, 2027, 2, 19),
      _h('easter', 2027, 3, 24, 2027, 4, 2),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('pentecost', 2027, 5, 14, 2027, 5, 18),
      _h('summer', 2027, 7, 5, 2027, 8, 14),
    ],
    GermanState.sh: [
      _h('autumn', 2025, 10, 20, 2025, 10, 30),
      _h('christmas', 2025, 12, 19, 2026, 1, 6),
      _h('easter', 2026, 3, 26, 2026, 4, 10),
      _h('pentecost', 2026, 5, 15, 2026, 5, 15),
      _h('summer', 2026, 7, 4, 2026, 8, 15),
      _h('autumn', 2026, 10, 12, 2026, 10, 24),
      _h('christmas', 2026, 12, 21, 2027, 1, 6),
      _h('easter', 2027, 3, 30, 2027, 4, 10),
      _h('pentecost', 2027, 5, 7, 2027, 5, 7),
      _h('summer', 2027, 7, 3, 2027, 8, 14),
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

  static String? holidayKeyOn(GermanState state, DateTime day) {
    final raw = _ranges[state] ?? _nw();
    for (final r in raw) {
      if (SchoolHoliday(name: r.$1, start: r.$2, end: r.$3).contains(day)) {
        return r.$1;
      }
    }
    return null;
  }

  static SchoolHoliday? holidayOn(
    GermanState state,
    DateTime day,
    AppLocalizations l10n,
  ) {
    final key = holidayKeyOn(state, day);
    if (key == null) return null;
    final raw = _ranges[state] ?? _nw();
    for (final r in raw) {
      if (r.$1 != key) continue;
      final holiday = SchoolHoliday(name: _name(r.$1, l10n), start: r.$2, end: r.$3);
      if (holiday.contains(day)) return holiday;
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
