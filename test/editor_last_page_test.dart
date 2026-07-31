import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/data/repositories/prefs_notebook_repository.dart';
import 'package:betternotes/features/editor/domain/last_page_store.dart';
import 'package:betternotes/features/editor/presentation/editor_screen.dart';
import 'package:betternotes/features/pdf/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefsNotebookRepository repo;
  late LastPageStore store;
  late String notebookId;

  Future<EditorController> openEditor() async {
    final controller = EditorController(
      notebookId: notebookId,
      repository: repo,
      pdfService: PdfService(repo),
      lastPageStore: store,
      fingerPanZoom: false,
    );
    while (controller.loading) {
      await pumpEventQueue();
    }
    return controller;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = PrefsNotebookRepository(prefs);
    store = LastPageStore(prefs);
    final notebook = await repo.createNotebook(title: 'Test', coverColor: 0);
    notebookId = notebook.id;
    for (var i = 0; i < 3; i++) {
      await repo.addPage(notebookId: notebookId);
    }
  });

  test('reopens the notebook on the page it was left on', () async {
    final first = await openEditor();
    expect(first.pageIndex, 0);

    await first.selectPage(2);
    final expectedId = first.pages[2].id;
    first.dispose();

    final second = await openEditor();
    expect(second.pageIndex, 2);
    expect(second.currentPage?.id, expectedId);
    second.dispose();
  });

  test('a deep link wins over the remembered page', () async {
    final first = await openEditor();
    await first.selectPage(1);
    final targetId = first.pages[2].id;
    first.dispose();

    final second = EditorController(
      notebookId: notebookId,
      repository: repo,
      pdfService: PdfService(repo),
      lastPageStore: store,
      fingerPanZoom: false,
      initialPageId: targetId,
    );
    while (second.loading) {
      await pumpEventQueue();
    }

    expect(second.pageIndex, 2);
    second.dispose();
  });

  test(
    'falls back to the first page when the remembered one is gone',
    () async {
      await store.write(notebookId, 'missing-page');

      final controller = await openEditor();
      expect(controller.pageIndex, 0);
      controller.dispose();
    },
  );

  test(
    'page text stays a single document anchored on the first rule',
    () async {
      final controller = await openEditor();
      controller.addTextBlock(
        mode: TextLayoutMode.lineBound,
        at: const Offset(120, 400),
      );
      final first = controller.textBlocks.single;
      controller.updateTextBlock(
        first.copyWith(
          spans: const [TextSpanStyle(text: 'Oben\nNach Enter weiter')],
        ),
      );
      controller.addTextBlock(
        mode: TextLayoutMode.lineBound,
        at: const Offset(120, 700),
      );

      final pageDocuments = controller.textBlocks
          .where((block) => block.layoutMode == TextLayoutMode.lineBound)
          .toList();
      expect(pageDocuments, hasLength(1));
      expect(pageDocuments.single.id, first.id);
      expect(pageDocuments.single.y, 48);
      expect(pageDocuments.single.plainText, 'Oben\nNach Enter weiter');
      controller.dispose();
    },
  );

  test('legacy page text blocks merge into one document on open', () async {
    final page = (await repo.getPages(notebookId)).first;
    await repo.savePage(
      page.copyWith(
        textBlocks: [
          TextBlock(
            id: 'first',
            pageId: page.id,
            x: 72,
            y: 48,
            width: 500,
            height: 50,
            layoutMode: TextLayoutMode.lineBound,
            spans: const [TextSpanStyle(text: 'Oben')],
          ),
          TextBlock(
            id: 'second',
            pageId: page.id,
            x: 72,
            y: 132,
            width: 500,
            height: 50,
            layoutMode: TextLayoutMode.lineBound,
            spans: const [TextSpanStyle(text: 'Unten')],
          ),
        ],
      ),
    );

    final controller = await openEditor();
    final pageDocuments = controller.textBlocks
        .where((block) => block.layoutMode == TextLayoutMode.lineBound)
        .toList();
    expect(pageDocuments, hasLength(1));
    expect(pageDocuments.single.plainText, 'Oben\nUnten');
    controller.dispose();
  });
}
