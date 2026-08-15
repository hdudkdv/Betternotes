import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/search/search_query.dart';

void main() {
  Notebook notebook({
    String title = 'Algebra',
    String? subject,
    int? klass,
  }) {
    final now = DateTime(2026, 1, 1);
    return Notebook(
      id: 'n1',
      title: title,
      coverColor: 0xFF000000,
      createdAt: now,
      updatedAt: now,
      subjectKey: subject,
      schoolClass: klass,
    );
  }

  test('parses @filters and remaining text', () {
    final q = ParsedSearchQuery.parse('@Wirtschaft addition @Klasse10');
    expect(q.filters, ['wirtschaft', 'klasse10']);
    expect(q.text, 'addition');
  });

  test('matches subject folder and class', () {
    final q = ParsedSearchQuery.parse('@Wirtschaft addition');
    expect(
      q.matchesScope(
        notebook: notebook(subject: 'Wirtschaft'),
        folderPath: 'Sek I/Wirtschaft',
      ),
      isTrue,
    );
    expect(
      q.matchesScope(
        notebook: notebook(subject: 'Mathe'),
        folderPath: 'Sek I/Mathe',
      ),
      isFalse,
    );

    final year = ParsedSearchQuery.parse('@10 Pythagoras');
    expect(
      year.matchesScope(
        notebook: notebook(klass: 10),
        folderPath: 'Klasse 10/Mathe',
      ),
      isTrue,
    );
  });
}
