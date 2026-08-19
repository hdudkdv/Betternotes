import 'package:betternotes/features/planner/school_year.dart';
import 'package:betternotes/features/teacher/gradebook/gradebook_models.dart';
import 'package:betternotes/features/teacher/gradebook/gradebook_store.dart';
import 'package:betternotes/features/teacher/gradebook/notenspiegel_stats.dart';
import 'package:betternotes/features/teacher/picker/random_pick.dart';
import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('one teacher timetable keeps different classes on the grid', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = TimetableNotifier(prefs);
    await notifier.setSlot(
      const TimetableSlot(
        day: 0,
        period: 0,
        first: TimetableLesson(subject: 'Mathe', schoolClass: '8a'),
      ),
    );
    await notifier.setSlot(
      const TimetableSlot(
        day: 0,
        period: 1,
        first: TimetableLesson(subject: 'Englisch', schoolClass: '9b'),
      ),
    );

    expect(notifier.allTables, hasLength(1));
    expect(notifier.state.schoolClass, isEmpty);
    expect(notifier.state.slotAt(0, 0)?.first.schoolClass, '8a');
    expect(notifier.state.slotAt(0, 1)?.first.schoolClass, '9b');
    expect(notifier.state.distinctClassNames(), ['8a', '9b']);

    final reloaded = TimetableNotifier(prefs);
    expect(reloaded.allTables, hasLength(1));
    expect(reloaded.state.slotAt(0, 0)?.first.subject, 'Mathe');
    expect(reloaded.state.slotAt(0, 1)?.first.subject, 'Englisch');
  });

  test('legacy per-class plans merge into one grid', () {
    final eight = Timetable.empty(schoolClass: '8a', title: '8a').copyWith(
      slots: [
        const TimetableSlot(
          day: 0,
          period: 0,
          first: TimetableLesson(subject: 'Mathe'),
        ),
      ],
    );
    final nine = Timetable.empty(schoolClass: '9b', title: '9b').copyWith(
      slots: [
        const TimetableSlot(
          day: 0,
          period: 1,
          first: TimetableLesson(subject: 'Englisch'),
        ),
        const TimetableSlot(
          day: 1,
          period: 0,
          split: true,
          first: TimetableLesson(subject: 'Sport'),
          second: TimetableLesson(subject: 'Kunst'),
        ),
      ],
    );

    final merged = mergeClassPlans([eight, nine]);
    expect(merged.schoolClass, isEmpty);
    expect(merged.slotAt(0, 0)?.first.subject, 'Mathe');
    expect(merged.slotAt(0, 0)?.first.schoolClass, '8a');
    expect(merged.slotAt(0, 1)?.first.subject, 'Englisch');
    expect(merged.slotAt(0, 1)?.first.schoolClass, '9b');
    expect(merged.slotAt(1, 0)?.first.subject, 'Sport');
    expect(merged.slotAt(1, 0)?.first.schoolClass, '9b');
  });

  test('current lesson exposes the class taught in that period', () {
    final table = Timetable.empty().copyWith(
      periods: const [
        TimetablePeriod(
          label: '1',
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      ],
      slots: const [
        TimetableSlot(
          day: 0,
          period: 0,
          first: TimetableLesson(subject: 'Mathe', schoolClass: '8a', room: '204'),
        ),
      ],
    );
    final now = DateTime(2026, 8, 17, 8, 30); // Monday
    final lesson = table.lessonAt(now);
    expect(lesson, isNotNull);
    expect(lesson!.lesson.schoolClass, '8a');
    expect(lesson.lesson.subject, 'Mathe');
  });

  test('notenspiegel tracks year and topic averages plus trend', () async {
    final prefs = await SharedPreferences.getInstance();
    final book = GradebookNotifier(prefs);
    final roster = await book.ensureClass('8a');
    await book.addStudent(roster.id, 'Alex');
    await book.addStudent(roster.id, 'Kim');
    final year = SchoolYear.current().startYear;
    final fractions = await book.addTopic(
      classId: roster.id,
      name: 'Brüche',
      schoolYearStart: year,
    );
    final grammar = await book.addTopic(
      classId: roster.id,
      name: 'Grammatik',
      schoolYearStart: year,
    );
    final ka1 = await book.addAssessment(
      classId: roster.id,
      topicId: fractions.id,
      title: 'KA 1',
      date: DateTime(year, 9, 10),
    );
    final ka2 = await book.addAssessment(
      classId: roster.id,
      topicId: fractions.id,
      title: 'KA 2',
      date: DateTime(year, 11, 4),
    );
    final oral = await book.addAssessment(
      classId: roster.id,
      topicId: grammar.id,
      title: 'mündlich',
      date: DateTime(year, 10, 1),
    );

    final alex = book.state.classById(roster.id)!.students.first;
    final kim = book.state.classById(roster.id)!.students.last;
    await book.setGrades(
      assessmentId: ka1.id,
      values: {alex.id: 2, kim.id: 3},
    );
    await book.setGrades(
      assessmentId: ka2.id,
      values: {alex.id: 1, kim.id: 2},
    );
    await book.setGrades(
      assessmentId: oral.id,
      values: {alex.id: 2, kim.id: 4},
    );

    final hist = classHistogram(
      book: book.state,
      classId: roster.id,
      schoolYearStart: year,
    );
    expect(hist.total, 6);
    expect(hist.average, closeTo(14 / 6, 0.0001));
    expect(hist.countFor(1), 1);
    expect(hist.countFor(2), 3);

    final topicHist = classHistogram(
      book: book.state,
      classId: roster.id,
      schoolYearStart: year,
      topicId: fractions.id,
    );
    expect(topicHist.total, 4);
    expect(topicHist.average, closeTo(8 / 4, 0.0001));

    final trend = classTrend(
      book: book.state,
      classId: roster.id,
      schoolYearStart: year,
      topicId: fractions.id,
    );
    expect(trend, hasLength(2));
    expect(trend.first.assessment.title, 'KA 1');
    expect(trend.first.average, 2.5);
    expect(trend.last.average, 1.5);

    final topics = topicPerformances(
      book: book.state,
      classId: roster.id,
      schoolYearStart: year,
    );
    expect(topics.map((t) => t.topic.name), ['Brüche', 'Grammatik']);
    expect(topics.first.histogram.average, 2.0);
  });

  test('class groups persist and random pick matches a connected device', () async {
    final prefs = await SharedPreferences.getInstance();
    final book = GradebookNotifier(prefs);
    final roster = await book.ensureClass('8a');
    await book.addStudent(roster.id, 'Alex Berger');
    await book.addStudent(roster.id, 'Kim Lorenz');
    final group = await book.addGroup(roster.id, 'Gruppe A');
    expect(group, isNotNull);
    final alex = book.state.classById(roster.id)!.students.first;
    await book.setGroupMembers(
      classId: roster.id,
      groupId: group!.id,
      studentIds: [alex.id],
    );
    expect(
      book.state.classById(roster.id)!.studentsInGroup(
        book.state.classById(roster.id)!.groups.single,
      ).single.name,
      'Alex Berger',
    );

    final peers = [
      (id: 'dev-alex', name: 'Alex Berger'),
      (id: 'dev-kim', name: 'Kim Lorenz'),
    ];
    final pick = pickToClassroomPick(
      kind: 'student',
      name: 'Alex Berger',
      peers: peers,
    );
    expect(pick.deviceId, 'dev-alex');
    expect(
      pick.concernsYou(deviceId: 'dev-alex', deviceName: 'Alex Berger'),
      isTrue,
    );
    expect(
      pick.concernsYou(deviceId: 'dev-kim', deviceName: 'Kim Lorenz'),
      isFalse,
    );

    final remaining = poolWithoutRepeat(
      pool: book.state.classById(roster.id)!.students,
      drawnIds: {alex.id},
    );
    expect(remaining.single.name, 'Kim Lorenz');
  });

  test('named pickers keep independent datacheck progress', () async {
    final prefs = await SharedPreferences.getInstance();
    final book = GradebookNotifier(prefs);
    final roster = await book.ensureClass('8a');
    await book.addStudent(roster.id, 'Alex');
    await book.addStudent(roster.id, 'Kim');
    final alex = book.state.classById(roster.id)!.students.first;
    final kim = book.state.classById(roster.id)!.students.last;

    final check = await book.addPicker(
      name: 'Datencheck Stunde 1',
      classId: roster.id,
      kind: SavedPickerKind.datacheck,
    );
    await book.addPicker(
      name: 'Zuruf',
      classId: roster.id,
      kind: SavedPickerKind.flash,
    );
    await book.recordPickerDraw(
      pickerId: check.id,
      drawnId: alex.id,
      lastName: 'Alex',
    );

    expect(book.state.pickerById(check.id)!.drawnIds, [alex.id]);
    expect(book.state.pickerById(check.id)!.lastName, 'Alex');
    expect(
      book.state.pickers.where((p) => p.kind == SavedPickerKind.flash).single.drawnIds,
      isEmpty,
    );

    final remaining = poolWithoutRepeat(
      pool: book.state.classById(roster.id)!.students,
      drawnIds: book.state.pickerById(check.id)!.drawnIds.toSet(),
      resetWhenEmpty: false,
    );
    expect(remaining.single.id, kim.id);

    await book.recordPickerDraw(
      pickerId: check.id,
      drawnId: kim.id,
      lastName: 'Kim',
    );
    expect(
      poolWithoutRepeat(
        pool: book.state.classById(roster.id)!.students,
        drawnIds: book.state.pickerById(check.id)!.drawnIds.toSet(),
        resetWhenEmpty: false,
      ),
      isEmpty,
    );

    await book.resetPickerRound(check.id);
    expect(book.state.pickerById(check.id)!.drawnIds, isEmpty);
    expect(book.state.pickerById(check.id)!.lastName, isNull);
  });
}
