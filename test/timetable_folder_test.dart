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
}
