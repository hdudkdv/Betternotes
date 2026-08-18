import '../../planner/school_year.dart';
import 'gradebook_models.dart';

class GradeHistogram {
  const GradeHistogram({
    required this.counts,
    required this.total,
    this.average,
  });

  /// Index 1–6 = number of grades. Index 0 unused.
  final List<int> counts;
  final int total;
  final double? average;

  int countFor(int grade) =>
      grade >= 1 && grade <= 6 ? counts[grade] : 0;
}

class AssessmentTrendPoint {
  const AssessmentTrendPoint({
    required this.assessment,
    required this.average,
    required this.count,
  });

  final ClassAssessment assessment;
  final double average;
  final int count;
}

class TopicPerformance {
  const TopicPerformance({
    required this.topic,
    required this.histogram,
    required this.trend,
  });

  final ClassTopic topic;
  final GradeHistogram histogram;
  final List<AssessmentTrendPoint> trend;
}

GradeHistogram histogramOf(Iterable<int> grades) {
  final counts = List<int>.filled(7, 0);
  var sum = 0;
  var n = 0;
  for (final raw in grades) {
    final grade = raw.clamp(1, 6);
    counts[grade]++;
    sum += grade;
    n++;
  }
  return GradeHistogram(
    counts: counts,
    total: n,
    average: n == 0 ? null : sum / n,
  );
}

List<ClassGrade> gradesMatching({
  required TeacherGradebook book,
  required String classId,
  required int schoolYearStart,
  String? topicId,
  String? assessmentId,
}) {
  final assessmentIds = {
    for (final item in book.assessments)
      if (item.classId == classId &&
          item.schoolYearStart == schoolYearStart &&
          (topicId == null || item.topicId == topicId) &&
          (assessmentId == null || item.id == assessmentId))
        item.id,
  };
  return [
    for (final grade in book.grades)
      if (assessmentIds.contains(grade.assessmentId)) grade,
  ];
}

GradeHistogram classHistogram({
  required TeacherGradebook book,
  required String classId,
  required int schoolYearStart,
  String? topicId,
  String? assessmentId,
}) {
  return histogramOf(
    gradesMatching(
      book: book,
      classId: classId,
      schoolYearStart: schoolYearStart,
      topicId: topicId,
      assessmentId: assessmentId,
    ).map((g) => g.value),
  );
}

List<AssessmentTrendPoint> classTrend({
  required TeacherGradebook book,
  required String classId,
  required int schoolYearStart,
  String? topicId,
}) {
  final assessments = [
    for (final item in book.assessments)
      if (item.classId == classId &&
          item.schoolYearStart == schoolYearStart &&
          (topicId == null || item.topicId == topicId))
        item,
  ]..sort((a, b) => a.date.compareTo(b.date));

  final out = <AssessmentTrendPoint>[];
  for (final assessment in assessments) {
    final hist = histogramOf([
      for (final grade in book.grades)
        if (grade.assessmentId == assessment.id) grade.value,
    ]);
    if (hist.average == null) continue;
    out.add(
      AssessmentTrendPoint(
        assessment: assessment,
        average: hist.average!,
        count: hist.total,
      ),
    );
  }
  return out;
}

List<TopicPerformance> topicPerformances({
  required TeacherGradebook book,
  required String classId,
  required int schoolYearStart,
}) {
  final topics = [
    for (final topic in book.topics)
      if (topic.classId == classId && topic.schoolYearStart == schoolYearStart)
        topic,
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return [
    for (final topic in topics)
      TopicPerformance(
        topic: topic,
        histogram: classHistogram(
          book: book,
          classId: classId,
          schoolYearStart: schoolYearStart,
          topicId: topic.id,
        ),
        trend: classTrend(
          book: book,
          classId: classId,
          schoolYearStart: schoolYearStart,
          topicId: topic.id,
        ),
      ),
  ];
}

double? studentAverage({
  required TeacherGradebook book,
  required String studentId,
  required String classId,
  required int schoolYearStart,
  String? topicId,
}) {
  return histogramOf(
    gradesMatching(
      book: book,
      classId: classId,
      schoolYearStart: schoolYearStart,
      topicId: topicId,
    ).where((g) => g.studentId == studentId).map((g) => g.value),
  ).average;
}

List<int> availableSchoolYears(TeacherGradebook book, {String? classId}) {
  final years = <int>{
    SchoolYear.current().startYear,
    for (final topic in book.topics)
      if (classId == null || topic.classId == classId) topic.schoolYearStart,
    for (final assessment in book.assessments)
      if (classId == null || assessment.classId == classId)
        assessment.schoolYearStart,
  };
  final list = years.toList()..sort();
  return list.reversed.toList();
}
