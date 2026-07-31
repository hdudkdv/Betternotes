import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/data/models/notebook.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/presentation/widgets/notebook_pages_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _activeKey = ValueKey('active-page');

List<NotePage> _pages(int count) => [
  for (var i = 0; i < count; i++)
    NotePage(
      id: 'p$i',
      notebookId: 'nb',
      index: i,
      template: PageTemplate.lined,
    ),
];

Future<List<int>> _pumpViewport(
  WidgetTester tester, {
  required int pageIndex,
  required PageBrowseMode browseMode,
  int pageCount = 8,
}) async {
  final selected = <int>[];
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NotebookPagesViewport(
          pages: _pages(pageCount),
          pageIndex: pageIndex,
          browseMode: browseMode,
          canvasMode: CanvasMode.page,
          onPageChanged: selected.add,
          activePageBuilder: (context, index) =>
              const ColoredBox(key: _activeKey, color: Colors.red),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('vertical browsing starts on the current page', (tester) async {
    final selected = await _pumpViewport(
      tester,
      pageIndex: 5,
      browseMode: PageBrowseMode.scrollVertical,
    );

    final active = tester.getRect(find.byKey(_activeKey));
    expect(active.top, lessThan(1000));
    expect(active.bottom, greaterThan(0));
    // Landing on the page must not count as browsing to another one.
    expect(selected, isEmpty);
  });

  testWidgets('swiping starts on the current page', (tester) async {
    await _pumpViewport(
      tester,
      pageIndex: 5,
      browseMode: PageBrowseMode.swipeHorizontal,
    );

    final active = tester.getRect(find.byKey(_activeKey));
    expect(active.left, lessThan(800));
    expect(active.right, greaterThan(0));
  });
}
