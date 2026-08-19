import 'package:betternotes/features/library/notebook_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('suggestedNotebookTitle', () {
    test('uses folder and class when the name is empty', () {
      expect(
        suggestedNotebookTitle(
          untitled: 'Unbenanntes Notizbuch',
          folderName: 'Wirtschaft',
          schoolClass: 13,
        ),
        'Wirtschaft 13',
      );
    });

    test('appends a one-letter class suffix without a space', () {
      expect(
        suggestedNotebookTitle(
          untitled: 'Untitled',
          folderName: 'Wirtschaft',
          schoolClass: 13,
          classSpec: 'a',
        ),
        'Wirtschaft 13a',
      );
    });

    test('puts a space before longer class specs', () {
      expect(
        suggestedNotebookTitle(
          untitled: 'Untitled',
          folderName: 'Wirtschaft',
          schoolClass: 13,
          classSpec: 'LK',
        ),
        'Wirtschaft 13 LK',
      );
    });

    test('falls back to untitled without a folder', () {
      expect(
        suggestedNotebookTitle(
          untitled: 'Unbenanntes Notizbuch',
          schoolClass: 13,
        ),
        'Unbenanntes Notizbuch',
      );
    });

    test('uses the folder name when no class is set', () {
      expect(
        suggestedNotebookTitle(
          untitled: 'Untitled',
          folderName: 'Wirtschaft',
        ),
        'Wirtschaft',
      );
    });
  });
}
