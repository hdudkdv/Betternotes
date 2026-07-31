import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('page revision survives JSON serialization', () {
    final updatedAt = DateTime.utc(2026, 7, 29, 12, 34, 56);
    final page = NotePage(
      id: 'page-1',
      notebookId: 'notebook-1',
      index: 0,
      template: PageTemplate.lined,
      updatedAt: updatedAt,
    );

    final restored = NotePage.fromJson(page.toJson());

    expect(restored.updatedAt, updatedAt);
  });

  test('older page JSON remains readable without a revision', () {
    final page = NotePage.fromJson({
      'id': 'page-1',
      'notebookId': 'notebook-1',
      'index': 0,
      'template': 'lined',
    });

    expect(page.updatedAt, isNull);
  });
}
