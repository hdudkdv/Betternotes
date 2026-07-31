import 'education_settings.dart';

/// Time bucket for a grade (depends on education level).
enum GradePeriod {
  /// Sek I Halbjahre
  h1,
  h2,

  /// Sek II Kurshalbjahre
  q1,
  q2,
  q3,
  q4,

  /// Abiturprüfung (Block II)
  abiExam,

  /// Studium (Semester-Einträge; Label frei über semesterLabel)
  semester,
}

extension GradePeriodX on GradePeriod {
  bool get isSek1 => this == GradePeriod.h1 || this == GradePeriod.h2;

  bool get isSek2Course =>
      this == GradePeriod.q1 ||
      this == GradePeriod.q2 ||
      this == GradePeriod.q3 ||
      this == GradePeriod.q4;

  bool get isSek2 => isSek2Course || this == GradePeriod.abiExam;

  int get sek2BlockIndex {
    switch (this) {
      case GradePeriod.q1:
        return 0;
      case GradePeriod.q2:
        return 1;
      case GradePeriod.q3:
        return 2;
      case GradePeriod.q4:
        return 3;
      case GradePeriod.abiExam:
        return 4;
      default:
        return -1;
    }
  }

  static List<GradePeriod> forLevel(EducationLevel level) => switch (level) {
    EducationLevel.sek1 => const [GradePeriod.h1, GradePeriod.h2],
    EducationLevel.sek2 => const [
      GradePeriod.q1,
      GradePeriod.q2,
      GradePeriod.q3,
      GradePeriod.q4,
      GradePeriod.abiExam,
    ],
    EducationLevel.university => const [GradePeriod.semester],
  };

  static GradePeriod defaultFor(EducationLevel level) => forLevel(level).first;
}
