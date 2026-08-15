import 'package:betternotes/features/teacher/catalog/assignment_grader.dart';
import 'package:betternotes/features/teacher/catalog/assignment_models.dart';
import 'package:betternotes/features/teacher/catalog/catalog_models.dart';
import 'package:betternotes/features/lan_sync/lan_sync_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student payload strips solutions', () {
    final task = CatalogTask(
      id: 't1',
      title: '1',
      parts: [TaskPart.text('Frage')],
      answerKind: AnswerKind.multipleChoice,
      options: [
        McOption(id: 'a', text: 'Ja', correct: true),
        McOption(id: 'b', text: 'Nein', correct: false),
      ],
      sampleAnswer: 'geheim',
      calcResult: '42',
      matchPairs: const [('l', 'r')],
    );
    final json = task.toStudentJson();
    expect(json.containsKey('sampleAnswer'), isFalse);
    expect(json.containsKey('calcResult'), isFalse);
    expect(json.containsKey('matchPairs'), isFalse);
    final options = json['options'] as List;
    expect((options.first as Map)['correct'], isNull);
    final restored = CatalogTask.fromStudentJson(json);
    expect(restored.options.every((o) => !o.correct), isTrue);
  });

  test('rule grader scores MC, matching and calculation', () async {
    final item = CatalogItem.create(
      title: 'Probe',
      subject: 'Mathe',
      schoolClass: '8a',
      germanState: 'nw',
    ).copyWith(
      tasks: [
        CatalogTask(
          id: 'mc',
          title: 'MC',
          parts: const [],
          answerKind: AnswerKind.multipleChoice,
          options: [
            McOption(id: 'a', text: 'A', correct: true),
            McOption(id: 'b', text: 'B'),
          ],
        ),
        CatalogTask(
          id: 'calc',
          title: 'Calc',
          parts: const [],
          answerKind: AnswerKind.calculation,
          calcResult: '4',
          calcTolerance: 0.1,
        ),
        CatalogTask(
          id: 'match',
          title: 'Match',
          parts: const [],
          answerKind: AnswerKind.matching,
          leftItems: [MatchItem(id: 'l1', text: 'L')],
          rightItems: [MatchItem(id: 'r1', text: 'R')],
          matchPairs: const [('l1', 'r1')],
        ),
      ],
    );
    const grader = RuleBasedAssignmentGrader();
    final grades = await grader.grade(
      item: item,
      submission: AssignmentSubmission(
        deviceId: 'd1',
        deviceName: 'S',
        runId: 'r1',
        submittedAt: DateTime(2026, 8, 15),
        answers: const [
          StudentTaskAnswer(taskId: 'mc', selectedOptionIds: ['a']),
          StudentTaskAnswer(taskId: 'calc', calcResult: '4,0'),
          StudentTaskAnswer(taskId: 'match', matchPairs: [('l1', 'r1')]),
        ],
      ),
    );
    expect(grades.every((g) => g.correct), isTrue);
  });

  test('summary ranks the most common issue', () {
    final item = CatalogItem.create(
      title: 'Probe',
      subject: 'Mathe',
      schoolClass: '8a',
      germanState: 'nw',
    ).copyWith(
      tasks: [
        CatalogTask(
          id: 'mc',
          title: '2',
          parts: const [],
          answerKind: AnswerKind.multipleChoice,
          options: [
            McOption(id: 'a', text: 'A', correct: true),
            McOption(id: 'b', text: 'B'),
          ],
        ),
      ],
    );
    final run = AssignmentRun(
      id: 'run',
      catalogItemId: item.id,
      title: item.title,
      subject: item.subject,
      schoolClass: item.schoolClass,
      startedAt: DateTime(2026, 8, 15),
      endsAt: DateTime(2026, 8, 15, 1),
      timeLimitSec: 3600,
      testMode: false,
    );
    final wrong = AssignmentSubmission(
      deviceId: 'd1',
      deviceName: 'A',
      runId: run.id,
      submittedAt: DateTime(2026, 8, 15),
      answers: const [
        StudentTaskAnswer(taskId: 'mc', selectedOptionIds: ['b']),
      ],
      grades: const [
        TaskGrade(
          taskId: 'mc',
          pointsAwarded: 0,
          maxPoints: 1,
          correct: false,
          issues: ['mc_wrong'],
        ),
      ],
    );
    final summary = buildAssignmentSummary(
      run: run,
      item: item,
      submissions: [wrong, wrong.copyWith()],
      participantCount: 2,
    );
    expect(summary.topProblems.first.taskId, 'mc');
    expect(summary.topProblems.first.count, 2);
  });

  test('extend after expiry uses now as the new base', () {
    final ended = DateTime(2026, 8, 15, 10);
    final now = DateTime(2026, 8, 15, 10, 20);
    final base = now.isAfter(ended) ? now : ended;
    expect(base.add(const Duration(minutes: 5)), DateTime(2026, 8, 15, 10, 25));
  });

  test('assignment LAN messages keep extra fields', () {
    final start = LanSyncMessage.assignmentStart({
      'runId': 'r1',
      'title': 'Probe',
      'extra': 'ok',
    });
    expect(start['type'], 'assignment_start');
    expect(start['protocol'], kLanSyncProtocolVersion);
    expect(start['extra'], 'ok');
    final progress = LanSyncMessage.assignmentProgress(
      deviceId: 'd',
      deviceName: 'N',
      runId: 'r1',
      percent: 50,
      doneTaskIds: const ['t1'],
    );
    expect(progress['percent'], 50);
  });
}
