import 'package:betternotes/features/planner/education_settings.dart';
import 'package:betternotes/features/planner/grade_calculator.dart';
import 'package:betternotes/features/planner/grade_period.dart';
import 'package:betternotes/features/planner/planner_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GradeCalculator Sek I', () {
    test('pending grades do not affect an average', () {
      final calc = GradeCalculator(
        level: EducationLevel.sek1,
        grades: [
          GradeEntry.create(
            value: 2,
            date: DateTime(2026, 1, 1),
            subject: 'Mathe',
          ),
          GradeEntry.create(
            value: null,
            date: DateTime(2026, 1, 2),
            subject: 'Mathe',
          ),
        ],
        subjectWeights: const [],
        subjects: const ['Mathe'],
      );

      expect(calc.subjectAverage('Mathe'), 2);
    });

    test('weighted schriftlich/mündlich', () {
      final grades = [
        GradeEntry.create(
          value: 2.0,
          date: DateTime(2026, 1, 1),
          subject: 'Mathe',
          category: GradeCategory.major,
          period: GradePeriod.h1,
        ),
        GradeEntry.create(
          value: 3.0,
          date: DateTime(2026, 1, 2),
          subject: 'Mathe',
          category: GradeCategory.minor,
          period: GradePeriod.h1,
        ),
      ];
      final calc = GradeCalculator(
        level: EducationLevel.sek1,
        grades: grades,
        subjectWeights: const [
          SubjectWeight(subject: 'Mathe', majorPercent: 60),
        ],
        subjects: const ['Mathe'],
      );
      // 2*0.6 + 3*0.4 = 2.4
      expect(
        calc.subjectAverage('Mathe', period: GradePeriod.h1),
        closeTo(2.4, 1e-9),
      );
      expect(
        calc.overallSubjectAverage(period: GradePeriod.h1),
        closeTo(2.4, 1e-9),
      );
    });
  });

  group('GradeCalculator Sek II', () {
    test('rounds half up to whole points', () {
      final grades = [
        GradeEntry.create(
          value: 10,
          date: DateTime(2026, 1, 1),
          subject: 'Deutsch',
          category: GradeCategory.major,
          period: GradePeriod.q1,
          scale: GradeScale.points,
        ),
        GradeEntry.create(
          value: 11,
          date: DateTime(2026, 1, 2),
          subject: 'Deutsch',
          category: GradeCategory.minor,
          period: GradePeriod.q1,
          scale: GradeScale.points,
        ),
      ];
      final calc = GradeCalculator(
        level: EducationLevel.sek2,
        grades: grades,
        subjectWeights: const [
          SubjectWeight(subject: 'Deutsch', majorPercent: 50),
        ],
        subjects: const ['Deutsch'],
      );
      // raw 10.5 -> 11
      expect(calc.subjectAverage('Deutsch', period: GradePeriod.q1), 11);
    });

    test('abi note from points', () {
      expect(GradeCalculator.abiNoteFromPoints(900), 1.0);
      expect(GradeCalculator.abiNoteFromPoints(300), 4.0);
    });

    test('prognosis projects block I + II', () {
      final grades = [
        for (var i = 0; i < 5; i++)
          GradeEntry.create(
            value: 10,
            date: DateTime(2026, 1, i + 1),
            subject: 'Mathe',
            category: GradeCategory.major,
            period: GradePeriod.q1,
            scale: GradeScale.points,
            isAbiSubject: true,
          ),
      ];
      final calc = GradeCalculator(
        level: EducationLevel.sek2,
        grades: grades,
        subjectWeights: const [],
        subjects: const ['Mathe'],
        courseCount: 40,
        examCount: 4,
        examWeight: 5,
      );
      final p = calc.abiPrognosis();
      expect(p.currentPointAverage, 10);
      expect(p.blockIProjected, 400); // 40*10
      expect(p.blockIIProjected, 200); // 10*5*4
      expect(p.projectedTotal, 600);
      expect(p.projectedNote, isNotNull);
    });
  });

  group('GradeCalculator Studium', () {
    test('ECTS weighted GPA', () {
      final grades = [
        GradeEntry.create(
          value: 1.0,
          date: DateTime(2026, 1, 1),
          subject: 'Algo',
          scale: GradeScale.uni,
          ects: 10,
          period: GradePeriod.semester,
        ),
        GradeEntry.create(
          value: 3.0,
          date: DateTime(2026, 1, 2),
          subject: 'DB',
          scale: GradeScale.uni,
          ects: 5,
          period: GradePeriod.semester,
        ),
      ];
      final calc = GradeCalculator(
        level: EducationLevel.university,
        grades: grades,
        subjectWeights: const [],
        targetEcts: 180,
      );
      final uni = calc.uniPrognosis();
      // (1*10 + 3*5) / 15 = 25/15 = 1.666...
      expect(uni.gpa, closeTo(25 / 15, 1e-9));
      expect(uni.earnedEcts, 15);
      expect(uni.targetEcts, 180);
    });
  });
}
