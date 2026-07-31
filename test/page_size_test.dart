import 'dart:ui';

import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/shared/utils/page_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paper presets resolve to portrait and landscape dimensions', () {
    expect(
      NotePageSize.resolve(PaperFormat.a4, PageOrientation.portrait),
      const Size(595, 842),
    );
    expect(
      NotePageSize.resolve(PaperFormat.a4, PageOrientation.landscape),
      const Size(842, 595),
    );
    expect(
      NotePageSize.resolve(PaperFormat.letter, PageOrientation.portrait),
      const Size(612, 792),
    );
    expect(
      NotePageSize.resolve(PaperFormat.a2, PageOrientation.portrait),
      const Size(1191, 1684),
    );
    expect(
      NotePageSize.resolve(PaperFormat.a6, PageOrientation.portrait),
      const Size(298, 420),
    );
  });

  test('old notebook and page JSON default to A4 portrait', () {
    final notebook = Notebook.fromJson({
      'id': 'notebook-1',
      'title': 'Old notebook',
      'coverColor': 0,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
    });
    final page = NotePage.fromJson({
      'id': 'page-1',
      'notebookId': 'notebook-1',
      'index': 0,
      'template': 'lined',
    });

    expect(notebook.defaultPaperFormat, PaperFormat.a4);
    expect(notebook.defaultOrientation, PageOrientation.portrait);
    expect(notebook.defaultTemplate, PageTemplate.blank);
    expect(page.paperFormat, PaperFormat.a4);
    expect(page.orientation, PageOrientation.portrait);
  });
}
