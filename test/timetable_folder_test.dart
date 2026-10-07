import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('folderMatchingSubject reuses an existing folder by name', () {
    final english = LibraryFolder.create(name: 'Englisch');
    final math = LibraryFolder.create(name: 'Mathe');
    final folders = [english, math];

    expect(folderMatchingSubject(folders, 'englisch')?.id, english.id);
    expect(folderMatchingSubject(folders, '  Mathe ')?.id, math.id);
    expect(folderMatchingSubject(folders, 'Sport'), isNull);
    expect(folderMatchingSubject(folders, ''), isNull);
  });

  test('timetable lesson keeps school class through json', () {
    const lesson = TimetableLesson(
      subject: 'Mathe',
      room: 'R204',
      schoolClass: '8a',
    );
    final roundTrip = TimetableLesson.fromJson(lesson.toJson());
    expect(roundTrip.schoolClass, '8a');
    expect(roundTrip.room, 'R204');

    final legacy = TimetableLesson.fromJson({
      'subject': 'Englisch',
      'room': 'A1',
    });
    expect(legacy.schoolClass, isEmpty);
  });

  test('timetable lesson keeps hour kind through json', () {
    const lesson = TimetableLesson(
      subject: 'Mathe',
      hourKind: TimetableHourKind.lecture,
    );
    final roundTrip = TimetableLesson.fromJson(lesson.toJson());
    expect(roundTrip.hourKind, TimetableHourKind.lecture);

    final legacy = TimetableLesson.fromJson({'subject': 'Mathe'});
    expect(legacy.hourKind, TimetableHourKind.none);
  });

  test('timetable lesson keeps professor and website through json', () {
    const lesson = TimetableLesson(
      subject: 'Mathe',
      professor: 'Prof. Müller',
      website: 'htw-dresden.de/mathe',
    );
    final roundTrip = TimetableLesson.fromJson(lesson.toJson());
    expect(roundTrip.professor, 'Prof. Müller');
    expect(roundTrip.website, 'htw-dresden.de/mathe');
    expect(roundTrip.websiteUri?.host, 'htw-dresden.de');

    final legacy = TimetableLesson.fromJson({'subject': 'Mathe'});
    expect(legacy.professor, isEmpty);
    expect(legacy.website, isEmpty);
    expect(legacy.websiteUri, isNull);
  });

  test('parseLessonWebsite accepts host-only and http(s) links', () {
    expect(parseLessonWebsite('htw-dresden.de/foo')?.scheme, 'https');
    expect(parseLessonWebsite('https://example.com')?.host, 'example.com');
    expect(parseLessonWebsite('mailto:a@b.c'), isNull);
    expect(parseLessonWebsite('   '), isNull);
  });

  test('A/B week lookup prefers the matching week over a shared slot', () {
    const weekA = TimetableSlot(
      day: 0,
      period: 0,
      week: TimetableWeek.a,
      first: TimetableLesson(subject: 'Mathe'),
    );
    const weekB = TimetableSlot(
      day: 0,
      period: 0,
      week: TimetableWeek.b,
      first: TimetableLesson(subject: 'Sport'),
    );
    const both = TimetableSlot(
      day: 1,
      period: 0,
      first: TimetableLesson(subject: 'Englisch'),
    );
    final table = Timetable.empty().copyWith(slots: [weekA, weekB, both]);

    expect(table.slotAt(0, 0, week: TimetableWeek.a)!.first.subject, 'Mathe');
    expect(table.slotAt(0, 0, week: TimetableWeek.b)!.first.subject, 'Sport');
    expect(table.slotAt(1, 0, week: TimetableWeek.a)!.first.subject, 'Englisch');
  });

  test('each lesson can keep its own start and end time', () {
    const monday = TimetableSlot(
      day: 0,
      period: 0,
      first: TimetableLesson(subject: 'Mathe'),
      startMinutes: 7 * 60 + 45,
      endMinutes: 8 * 60 + 30,
    );
    const tuesday = TimetableSlot(
      day: 1,
      period: 0,
      first: TimetableLesson(subject: 'Englisch'),
      startMinutes: 8 * 60,
      endMinutes: 8 * 60 + 45,
    );
    final table = Timetable.empty().copyWith(slots: [monday, tuesday]);
    final roundTrip = TimetableSlot.fromJson(monday.toJson());

    expect(roundTrip.startMinutes, 7 * 60 + 45);
    expect(roundTrip.timeRange, '07:45–08:30');
    expect(table.periodFor(0, 0).timeRange, '07:45–08:30');
    expect(table.periodFor(1, 0).timeRange, '08:00–08:45');
    expect(table.periodFor(2, 0).timeRange, table.periods[0].timeRange);

    final nowMonday = DateTime(2026, 9, 21, 8, 0); // Monday
    final nowTuesday = DateTime(2026, 9, 22, 8, 10); // Tuesday
    expect(table.lessonAt(nowMonday)?.lesson.subject, 'Mathe');
    expect(table.lessonAt(nowTuesday)?.lesson.subject, 'Englisch');
    expect(table.lessonAt(DateTime(2026, 9, 21, 7, 40)), isNull);
  });

  test('an empty overlapping row does not hide the filled midday lesson', () {
    final table = Timetable.empty(
      periods: Timetable.universitySemesterPeriods(),
    ).copyWith(
      slots: const [
        TimetableSlot(
          day: 0,
          period: 3,
          first: TimetableLesson(subject: 'BS Pr'),
          startMinutes: 12 * 60,
          endMinutes: 13 * 60 + 30,
        ),
      ],
    );
    expect(table.periodOverlapsAnother(3), isTrue);
    expect(
      table.lessonAt(DateTime(2026, 10, 5, 12, 15))?.lesson.subject,
      'BS Pr',
    );
  });

  test('odd ISO weeks are A unless swapped', () {
    final week1 = DateTime(2026, 1, 1);
    expect(isoWeekNumber(week1), 1);
    expect(currentAbWeek(week1, swapped: false), TimetableWeek.a);
    expect(currentAbWeek(week1, swapped: true), TimetableWeek.b);
  });
}
