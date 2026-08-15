import 'catalog_models.dart';
import 'assignment_models.dart';

/// Grades one submission. Rule-based first; free text falls back to manual.
abstract class AssignmentGrader {
  Future<List<TaskGrade>> grade({
    required CatalogItem item,
    required AssignmentSubmission submission,
  });
}

class RuleBasedAssignmentGrader implements AssignmentGrader {
  const RuleBasedAssignmentGrader();

  @override
  Future<List<TaskGrade>> grade({
    required CatalogItem item,
    required AssignmentSubmission submission,
  }) async {
    return [
      for (final task in item.tasks)
        _gradeTask(
          task,
          submission.answers
              .where((a) => a.taskId == task.id)
              .firstOrNull,
        ),
    ];
  }

  TaskGrade _gradeTask(CatalogTask task, StudentTaskAnswer? answer) {
    final empty = answer ?? StudentTaskAnswer(taskId: task.id);
    return switch (task.answerKind) {
      AnswerKind.multipleChoice => _gradeMc(task, empty),
      AnswerKind.matching => _gradeMatch(task, empty),
      AnswerKind.calculation => _gradeCalc(task, empty),
      AnswerKind.text => _gradeText(task, empty),
    };
  }

  TaskGrade _gradeMc(CatalogTask task, StudentTaskAnswer answer) {
    final correct = {
      for (final option in task.options)
        if (option.correct) option.id,
    };
    final chosen = answer.selectedOptionIds.toSet();
    final ok = correct.isNotEmpty &&
        chosen.length == correct.length &&
        chosen.containsAll(correct);
    return TaskGrade(
      taskId: task.id,
      pointsAwarded: ok ? task.maxPoints.toDouble() : 0,
      maxPoints: task.maxPoints,
      correct: ok,
      issues: ok ? const [] : const ['mc_wrong'],
    );
  }

  TaskGrade _gradeMatch(CatalogTask task, StudentTaskAnswer answer) {
    final expected = {
      for (final pair in task.matchPairs) '${pair.$1}:${pair.$2}',
    };
    final given = {
      for (final pair in answer.matchPairs) '${pair.$1}:${pair.$2}',
    };
    final ok = expected.isNotEmpty &&
        given.length == expected.length &&
        given.containsAll(expected);
    return TaskGrade(
      taskId: task.id,
      pointsAwarded: ok ? task.maxPoints.toDouble() : 0,
      maxPoints: task.maxPoints,
      correct: ok,
      issues: ok ? const [] : const ['match_wrong'],
    );
  }

  TaskGrade _gradeCalc(CatalogTask task, StudentTaskAnswer answer) {
    final expected = _parseNumber(task.calcResult);
    final given = _parseNumber(answer.calcResult);
    if (expected == null || given == null) {
      return TaskGrade(
        taskId: task.id,
        pointsAwarded: 0,
        maxPoints: task.maxPoints,
        correct: false,
        issues: const ['calc_unparsed'],
        method: GradeMethod.pending,
      );
    }
    final ok = (given - expected).abs() <= task.calcTolerance;
    return TaskGrade(
      taskId: task.id,
      pointsAwarded: ok ? task.maxPoints.toDouble() : 0,
      maxPoints: task.maxPoints,
      correct: ok,
      issues: ok ? const [] : const ['calc_wrong'],
    );
  }

  TaskGrade _gradeText(CatalogTask task, StudentTaskAnswer answer) {
    final sample = _normalize(task.sampleAnswer);
    final given = _normalize(answer.text);
    if (sample.isEmpty) {
      return TaskGrade(
        taskId: task.id,
        pointsAwarded: 0,
        maxPoints: task.maxPoints,
        correct: false,
        issues: const ['needs_manual'],
        method: GradeMethod.manual,
      );
    }
    final ok = given.isNotEmpty &&
        (given == sample || given.contains(sample) || sample.contains(given));
    return TaskGrade(
      taskId: task.id,
      pointsAwarded: ok ? task.maxPoints.toDouble() : 0,
      maxPoints: task.maxPoints,
      correct: ok,
      issues: ok ? const [] : const ['text_mismatch'],
      method: GradeMethod.manual,
    );
  }

  static double? _parseNumber(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  static String _normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

AssignmentSummary buildAssignmentSummary({
  required AssignmentRun run,
  required CatalogItem item,
  required List<AssignmentSubmission> submissions,
  required int participantCount,
}) {
  final problems = <String, AssignmentProblem>{};
  final groups = <String, AssignmentProblem>{};
  var percentSum = 0.0;
  for (final submission in submissions) {
    final max = submission.grades.fold<int>(0, (s, g) => s + g.maxPoints);
    final got = submission.grades.fold<double>(0, (s, g) => s + g.pointsAwarded);
    percentSum += max == 0 ? 0 : (got / max) * 100;
    for (final grade in submission.grades) {
      if (grade.correct || grade.issues.isEmpty) continue;
      final task = item.tasks.where((t) => t.id == grade.taskId).firstOrNull;
      final title = task?.title ?? grade.taskId;
      for (final issue in grade.issues) {
        final key = '${grade.taskId}:$issue';
        final prev = problems[key];
        problems[key] = AssignmentProblem(
          taskId: grade.taskId,
          title: title,
          label: issue,
          count: (prev?.count ?? 0) + 1,
        );
      }
      if (task?.answerKind == AnswerKind.multipleChoice) {
        final answer = submission.answers
            .where((a) => a.taskId == grade.taskId)
            .firstOrNull;
        final chosen = (answer?.selectedOptionIds ?? const []).join(',');
        if (chosen.isNotEmpty) {
          final key = '${grade.taskId}:opt:$chosen';
          final prev = groups[key];
          groups[key] = AssignmentProblem(
            taskId: grade.taskId,
            title: title,
            label: chosen,
            count: (prev?.count ?? 0) + 1,
          );
        }
      }
    }
  }
  final ranked = problems.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  final clustered = groups.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return AssignmentSummary(
    runId: run.id,
    averagePercent: submissions.isEmpty ? 0 : percentSum / submissions.length,
    submittedCount: submissions.length,
    participantCount: participantCount,
    topProblems: ranked.take(5).toList(),
    groups: clustered.take(8).toList(),
    updatedAt: DateTime.now(),
  );
}
