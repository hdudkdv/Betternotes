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
}
