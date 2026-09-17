import 'package:betternotes/features/planner/grade_period.dart';
import 'package:betternotes/features/planner/planner_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly recurrence expands to selected weekdays until its end date', () {
    final event = PlannerEvent.create(
      title: 'Mathe',
      subject: 'Mathe',
      start: DateTime(2026, 8, 3, 9), // Monday
      recurrence: EventRecurrence(
        frequency: RecurrenceFrequency.weekly,
        weekdays: const [DateTime.monday, DateTime.wednesday],
        until: DateTime(2026, 8, 19),
      ),
    );
    final state = PlannerState(events: [event]);

    expect(state.eventsOn(DateTime(2026, 8, 3)), hasLength(1));
    expect(state.eventsOn(DateTime(2026, 8, 5)), hasLength(1));
    expect(state.eventsOn(DateTime(2026, 8, 10)), hasLength(1));
    expect(state.eventsOn(DateTime(2026, 8, 20)), isEmpty);
  });

  test('past events for a subject are ordered newest first', () {
    final state = PlannerState(
      events: [
        PlannerEvent.create(
          title: 'Klausur 1',
          subject: 'Chemie',
          start: DateTime(2026, 1, 10),
        ),
        PlannerEvent.create(
          title: 'Klausur 2',
          subject: 'Chemie',
          start: DateTime(2026, 2, 10),
        ),
      ],
    );

    expect(
      state
          .pastEventsForSubject('chemie', before: DateTime(2026, 3, 1))
          .map((event) => event.title),
      ['Klausur 2', 'Klausur 1'],
    );
  });

  test('calendar label prefers the title', () {
    final titled = PlannerEvent.create(
      title: 'Abi Probe',
      subject: 'Mathe',
      start: DateTime(2026, 9, 13),
    );
    final untitled = PlannerEvent.create(
      title: '  ',
      subject: 'Deutsch',
      start: DateTime(2026, 9, 14),
    );
    expect(titled.calendarLabel(), 'Abi Probe');
    expect(untitled.calendarLabel(), 'Deutsch');
  });

  test('exam events show subject plus Klausur when title matches the subject', () {
    final exam = PlannerEvent.create(
      title: 'Mathe',
      subject: 'Mathe',
      kind: PlannerEventKind.exam,
      start: DateTime(2026, 9, 17),
    );
    final custom = PlannerEvent.create(
      title: 'Abi Probe',
      subject: 'Mathe',
      kind: PlannerEventKind.exam,
      start: DateTime(2026, 9, 18),
    );
    expect(exam.calendarLabel(), 'Mathe Klausur');
    expect(exam.calendarLabel(examKindLabel: 'Exam'), 'Mathe Exam');
    expect(custom.calendarLabel(), 'Abi Probe');
  });

  test('grade quota is met only after the configured counts', () {
    final subject = 'Englisch';
    final weight = SubjectWeight(subject: subject).withQuota(
      period: GradePeriod.h1,
      minMajor: 2,
      minMinor: 5,
    );
    final state = PlannerState(
      subjectWeights: [weight],
      grades: [
        GradeEntry.create(
          value: 2,
          date: DateTime(2026, 9, 1),
          subject: subject,
          category: GradeCategory.major,
          period: GradePeriod.h1,
        ),
        GradeEntry.create(
          value: 3,
          date: DateTime(2026, 9, 2),
          subject: subject,
          category: GradeCategory.minor,
          period: GradePeriod.h1,
        ),
      ],
    );
    expect(state.quotaFor(subject, period: GradePeriod.h1).isMet, isFalse);

    final enough = PlannerState(
      subjectWeights: [weight],
      grades: [
        for (var i = 0; i < 2; i++)
          GradeEntry.create(
            value: 2,
            date: DateTime(2026, 9, 1 + i),
            subject: subject,
            category: GradeCategory.major,
            period: GradePeriod.h1,
          ),
        for (var i = 0; i < 5; i++)
          GradeEntry.create(
            value: 3,
            date: DateTime(2026, 10, 1 + i),
            subject: subject,
            category: GradeCategory.minor,
            period: GradePeriod.h1,
          ),
      ],
    );
    expect(enough.quotaFor(subject, period: GradePeriod.h1).isMet, isTrue);
    expect(enough.quotaFor(subject, period: GradePeriod.h2).isMet, isFalse);
  });
}
