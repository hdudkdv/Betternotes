import 'package:betternotes/features/library/providers/library_providers.dart';
import 'package:betternotes/features/teacher/teacher_models.dart';
import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('cancelled lesson shifts later lessons in the same subject', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = TeacherNotifier(prefs);
    final first = LessonJournalEntry(
      id: '1',
      subject: 'Mathe',
      title: 'Brüche',
      scheduledAt: DateTime(2026, 8, 3),
    );
    final second = LessonJournalEntry(
      id: '2',
      subject: 'Mathe',
      title: 'Prozentrechnung',
      scheduledAt: DateTime(2026, 8, 10),
    );
    final otherSubject = LessonJournalEntry(
      id: '3',
      subject: 'Deutsch',
      title: 'Lyrik',
      scheduledAt: DateTime(2026, 8, 10),
    );

    await notifier.addLesson(first);
    await notifier.addLesson(second);
    await notifier.addLesson(otherSubject);
    await notifier.markLessonCancelledAndShift(first.id);

    expect(notifier.state.lessons[0].status, LessonStatus.cancelled);
    expect(
      notifier.state.lessons[1].scheduledAt,
      DateTime(2026, 8, 17),
    );
    expect(
      notifier.state.lessons[2].scheduledAt,
      DateTime(2026, 8, 10),
    );
  });

  test('classroom signals update participant progress and focus', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = TeacherNotifier(prefs);
    await notifier.startSession(title: 'Test');

    await notifier.applyNetworkSignal(
      deviceId: 'student-1',
      deviceName: 'Alex',
      kind: 'progress',
      value: 60,
    );
    await notifier.applyNetworkSignal(
      deviceId: 'student-1',
      deviceName: 'Alex',
      kind: 'focus',
      value: false,
    );

    final participant = notifier.state.session!.participants.single;
    expect(participant.progress, 60);
    expect(participant.focused, isFalse);
  });

  test('first-start role is persisted', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    expect(notifier.state.userRole, isNull);

    await notifier.setUserRole(AppUserRole.teacher);
    final restored = SettingsNotifier(prefs);

    expect(restored.state.userRole, AppUserRole.teacher);
    expect(restored.state.isTeacher, isTrue);
  });

  test('timetable day creates editable lesson slots with attachments', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = TeacherNotifier(prefs);
    final day = DateTime(2026, 8, 3); // Monday
    final timetable = Timetable.empty().upsertSlot(
      const TimetableSlot(
        day: 0,
        period: 0,
        first: TimetableLesson(subject: 'Mathe', room: 'B12'),
      ),
    );

    await notifier.ensureLessonsForDay(day, timetable);
    expect(notifier.lessonsOn(day), hasLength(1));

    final lesson = notifier.lessonsOn(day).single;
    await notifier.updateLesson(
      lesson.copyWith(title: 'Brüche', notes: 'Einführung'),
    );
    await notifier.attachToLesson(
      lesson.id,
      LessonAttachment(
        id: 'a1',
        kind: LessonAttachmentKind.material,
        title: 'Arbeitsblatt 1',
        createdAt: DateTime(2026, 8, 3, 9),
      ),
    );

    final updated = notifier.lessonsOn(day).single;
    expect(updated.title, 'Brüche');
    expect(updated.notes, 'Einführung');
    expect(updated.attachments, hasLength(1));
  });
}
