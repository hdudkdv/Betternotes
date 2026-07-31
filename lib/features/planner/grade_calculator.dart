import 'dart:math' as math;

import 'education_settings.dart';
import 'grade_period.dart';
import 'planner_model.dart';

/// Allowed uni grade steps (everything > 4.0 is failed).
const uniGradeSteps = <double>[
  1.0,
  1.3,
  1.7,
  2.0,
  2.3,
  2.7,
  3.0,
  3.3,
  3.7,
  4.0,
  4.3,
  4.7,
  5.0,
];

bool isUniPassed(double grade) => grade <= 4.0;

/// Round half away from zero to nearest int (German school style for points).
int roundHalfUp(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return (value + 0.5).floor();
}

double? _weightedCategoryAvg(List<GradeEntry> list, GradeCategory category) {
  final filtered = [
    for (final g in list)
      if (g.category == category && g.value != null) g,
  ];
  if (filtered.isEmpty) return null;
  var wSum = 0.0;
  var vSum = 0.0;
  for (final g in filtered) {
    wSum += g.weight;
    vSum += g.value! * g.weight;
  }
  if (wSum <= 0) return null;
  return vSum / wSum;
}

double? _plainAvg(List<GradeEntry> list) {
  final graded = [
    for (final grade in list)
      if (grade.value != null) grade,
  ];
  if (graded.isEmpty) return null;
  var wSum = 0.0;
  var vSum = 0.0;
  for (final g in graded) {
    wSum += g.weight;
    vSum += g.value! * g.weight;
  }
  if (wSum <= 0) return null;
  return vSum / wSum;
}

/// Core grade math for Sek I / Sek II / Studium.
class GradeCalculator {
  const GradeCalculator({
    required this.level,
    required this.grades,
    required this.subjectWeights,
    this.subjects = const [],
    this.courseCount = 40,
    this.examCount = 4,
    this.examWeight = 5,
    this.targetEcts = 180,
  });

  final EducationLevel level;
  final List<GradeEntry> grades;
  final List<SubjectWeight> subjectWeights;
  final List<String> subjects;
  final int courseCount;
  final int examCount;
  final int examWeight;
  final int targetEcts;

  SubjectWeight weightFor(String subject) {
    final key = subjectKey(subject);
    for (final w in subjectWeights) {
      if (subjectKey(w.subject) == key) return w;
    }
    return SubjectWeight(subject: subject.trim(), majorPercent: 50);
  }

  List<GradeEntry> gradesFor({
    String? subject,
    GradePeriod? period,
    bool? abiOnly,
  }) {
    return [
      for (final g in grades)
        if (subject == null || subjectKey(g.subject) == subjectKey(subject))
          if (period == null || g.period == period)
            if (abiOnly != true || g.isAbiSubject) g,
    ];
  }

  /// Subject end grade for a period (or all periods if [period] is null).
  double? subjectAverage(String subject, {GradePeriod? period}) {
    final list = gradesFor(subject: subject, period: period);
    if (list.isEmpty) return null;

    switch (level) {
      case EducationLevel.sek1:
        return _sek1Subject(list, subject);
      case EducationLevel.sek2:
        final raw = _sek2SubjectRaw(list, subject);
        if (raw == null) return null;
        // Halbjahresergebnis: ganzzahlige Punkte
        return roundHalfUp(raw).toDouble();
      case EducationLevel.university:
        return _uniModuleAvg(list);
    }
  }

  double? _sek1Subject(List<GradeEntry> list, String subject) {
    final w = weightFor(subject);
    final written = _weightedCategoryAvg(list, GradeCategory.major);
    final oral = _weightedCategoryAvg(list, GradeCategory.minor);
    if (written != null && oral != null) {
      return written * (w.majorPercent / 100) + oral * (w.minorPercent / 100);
    }
    return written ?? oral;
  }

  double? _sek2SubjectRaw(List<GradeEntry> list, String subject) {
    final w = weightFor(subject);
    final klausuren = _weightedCategoryAvg(list, GradeCategory.major);
    final sonstige = _weightedCategoryAvg(list, GradeCategory.minor);
    if (klausuren != null && sonstige != null) {
      return klausuren * (w.majorPercent / 100) +
          sonstige * (w.minorPercent / 100);
    }
    return klausuren ?? sonstige;
  }

  double? _uniModuleAvg(List<GradeEntry> list) {
    // Each entry is typically one module grade; average if multiple.
    return _plainAvg(list);
  }

  /// Simple mean of all subject end grades (Sek I Gesamtschnitt).
  double? overallSubjectAverage({GradePeriod? period}) {
    final names = _subjectNames();
    final avgs = <double>[
      for (final s in names)
        if (subjectAverage(s, period: period) != null)
          subjectAverage(s, period: period)!,
    ];
    if (avgs.isEmpty) return null;
    return avgs.reduce((a, b) => a + b) / avgs.length;
  }

  List<String> _subjectNames() {
    final out = <String>[];
    final seen = <String>{};
    for (final s in subjects) {
      final t = s.trim();
      if (t.isEmpty) continue;
      if (seen.add(subjectKey(t))) out.add(t);
    }
    for (final g in grades) {
      final t = g.subject.trim();
      if (t.isEmpty) continue;
      if (seen.add(subjectKey(t))) out.add(t);
    }
    return out;
  }

  /// ECTS-weighted GPA (Studium). Failed modules (>4.0) still count if entered.
  UniPrognosis uniPrognosis() {
    final modules = [
      for (final g in grades)
        if ((g.scale == GradeScale.uni || level == EducationLevel.university) &&
            g.value != null)
          g,
    ];
    var ectsSum = 0.0;
    var weighted = 0.0;
    var earnedEcts = 0.0;
    for (final g in modules) {
      final ects = g.ects <= 0 ? 0.0 : g.ects;
      if (ects <= 0) continue;
      ectsSum += ects;
      weighted += g.value! * ects;
      if (isUniPassed(g.value!)) earnedEcts += ects;
    }
    return UniPrognosis(
      gpa: ectsSum > 0 ? weighted / ectsSum : null,
      earnedEcts: earnedEcts,
      gradedEcts: ectsSum,
      targetEcts: targetEcts.toDouble(),
    );
  }

  /// Live Abitur prognosis (5-block / 900-point model).
  AbiPrognosis abiPrognosis() {
    final courseGrades = [
      for (final g in grades)
        if (g.period.isSek2Course && g.value != null) g,
    ];
    final allPoints = [for (final g in courseGrades) g.value!];
    final currentAvg = allPoints.isEmpty
        ? null
        : allPoints.reduce((a, b) => a + b) / allPoints.length;

    final klausurGrades = [
      for (final g in grades)
        if (g.category == GradeCategory.major &&
            (g.isAbiSubject || g.period.isSek2Course) &&
            g.value != null)
          g.value!,
    ];
    // Prefer explicit Abitur subjects' Klausuren for exam projection.
    final abiKlausuren = [
      for (final g in grades)
        if (g.isAbiSubject &&
            g.category == GradeCategory.major &&
            g.value != null)
          g.value!,
    ];
    final examBaseList = abiKlausuren.isNotEmpty ? abiKlausuren : klausurGrades;
    final klausurAvg = examBaseList.isEmpty
        ? currentAvg
        : examBaseList.reduce((a, b) => a + b) / examBaseList.length;

    // Collected points so far: sum of rounded subject results per Q entry.
    // Approximation: each entered grade contributes; better: per subject/period.
    final collectedByBlock = List<double>.filled(5, 0);
    final countByBlock = List<int>.filled(5, 0);

    for (final name in _subjectNames()) {
      for (final p in const [
        GradePeriod.q1,
        GradePeriod.q2,
        GradePeriod.q3,
        GradePeriod.q4,
      ]) {
        final avg = subjectAverage(name, period: p);
        if (avg == null) continue;
        final idx = p.sek2BlockIndex;
        collectedByBlock[idx] += avg;
        countByBlock[idx]++;
      }
    }
    // Explicit abi exam entries
    for (final g in grades) {
      if (g.period != GradePeriod.abiExam || g.value == null) continue;
      collectedByBlock[4] += g.value! * (g.weight <= 0 ? 1 : g.weight);
      countByBlock[4]++;
    }

    final collectedTotal = collectedByBlock.fold<double>(0, (a, b) => a + b);
    final completedBlocks = countByBlock.where((c) => c > 0).length.clamp(0, 5);

    // Projection
    double? projectedTotal;
    double? blockI;
    double? blockII;
    double? projectedNote;

    if (currentAvg != null) {
      blockI = courseCount * currentAvg;
      final examAvg = klausurAvg ?? currentAvg;
      blockII = examAvg * examWeight * examCount;
      projectedTotal = blockI + blockII;
      // Cap to 900
      projectedTotal = math.min(900, projectedTotal);
      projectedNote = abiNoteFromPoints(projectedTotal);
    }

    const maxTotal = 900.0;
    const minPass = 300.0;
    const perBlockMax = 180.0;
    const perBlockMin = 60.0;

    return AbiPrognosis(
      currentPointAverage: currentAvg,
      klausurAverage: klausurAvg,
      collectedPoints: collectedTotal,
      projectedTotal: projectedTotal,
      projectedNote: projectedNote,
      blockIProjected: blockI,
      blockIIProjected: blockII,
      completedBlocks: completedBlocks,
      maxTotal: maxTotal,
      minPassTotal: minPass,
      perBlockMax: perBlockMax,
      perBlockMin: perBlockMin,
      courseCount: courseCount,
      examCount: examCount,
      examWeight: examWeight,
    );
  }

  /// KMK-style: N = 5⅔ − E/180, clamped to 1.0–4.0, one decimal.
  static double abiNoteFromPoints(double points) {
    final p = points.clamp(0.0, 900.0);
    final raw = (17.0 / 3.0) - (p / 180.0);
    final clamped = raw.clamp(1.0, 4.0);
    return (clamped * 10).roundToDouble() / 10.0;
  }
}

class AbiPrognosis {
  const AbiPrognosis({
    required this.currentPointAverage,
    required this.klausurAverage,
    required this.collectedPoints,
    required this.projectedTotal,
    required this.projectedNote,
    required this.blockIProjected,
    required this.blockIIProjected,
    required this.completedBlocks,
    required this.maxTotal,
    required this.minPassTotal,
    required this.perBlockMax,
    required this.perBlockMin,
    required this.courseCount,
    required this.examCount,
    required this.examWeight,
  });

  final double? currentPointAverage;
  final double? klausurAverage;
  final double collectedPoints;
  final double? projectedTotal;
  final double? projectedNote;
  final double? blockIProjected;
  final double? blockIIProjected;
  final int completedBlocks;
  final double maxTotal;
  final double minPassTotal;
  final double perBlockMax;
  final double perBlockMin;
  final int courseCount;
  final int examCount;
  final int examWeight;

  double get minPassProgress =>
      (collectedPoints / minPassTotal).clamp(0.0, 1.5);

  double get maxProgress =>
      ((projectedTotal ?? collectedPoints) / maxTotal).clamp(0.0, 1.0);
}

class UniPrognosis {
  const UniPrognosis({
    required this.gpa,
    required this.earnedEcts,
    required this.gradedEcts,
    required this.targetEcts,
  });

  final double? gpa;
  final double earnedEcts;
  final double gradedEcts;
  final double targetEcts;

  double get ectsProgress =>
      targetEcts <= 0 ? 0 : (earnedEcts / targetEcts).clamp(0.0, 1.5);
}
