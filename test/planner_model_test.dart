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
}
