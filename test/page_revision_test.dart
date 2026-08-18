import 'package:betternotes/data/models/content_models.dart';
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

  test('page title, createdAt and stickers survive JSON', () {
    final created = DateTime.utc(2026, 8, 18, 9, 0);
    final page = NotePage(
      id: 'page-2',
      notebookId: 'notebook-1',
      index: 1,
      template: PageTemplate.blank,
      title: 'Montag',
      createdAt: created,
      updatedAt: created,
      stickers: [
        StickerElement.create(
          pageId: 'page-2',
          catalogId: 'star',
          x: 40,
          y: 50,
        ),
      ],
    );

    final restored = NotePage.fromJson(page.toJson());
    expect(restored.title, 'Montag');
    expect(restored.createdAt, created);
    expect(restored.stickers, hasLength(1));
    expect(restored.stickers.first.catalogId, 'star');
    expect(restored.displayTitle(2), 'Montag');
  });
}
