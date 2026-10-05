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
  });

  test('tapping beside an unused free text box deletes it', () async {
    final controller = await openEditor();
    controller.addTextBlock(at: const Offset(80, 100));
    expect(controller.textBlocks, hasLength(1));
    expect(controller.textBlocks.single.plainText, isEmpty);

    controller.onPointerDown(const Offset(400, 500), isStylus: true);
    expect(controller.textBlocks, isEmpty);
    expect(controller.selectedTextId, isNull);
    controller.dispose();
  });

  test('clearing selection drops unused free text boxes', () async {
    final controller = await openEditor();
    controller.addTextBlock(at: const Offset(80, 100));
    expect(controller.textBlocks, hasLength(1));

    controller.clearLassoSelection();
    expect(controller.textBlocks, isEmpty);
    controller.dispose();
  });

  test('typed text survives clearing the selection', () async {
    final controller = await openEditor();
    controller.addTextBlock(at: const Offset(80, 100));
    final written = controller.textBlocks.single.copyWith(
      spans: const [TextSpanStyle(text: 'Hallo')],
    );
    controller.updateTextBlock(written);

    controller.clearLassoSelection();
    expect(controller.textBlocks, hasLength(1));
    expect(controller.textBlocks.single.plainText, 'Hallo');
    controller.dispose();
  });

  test('empty sticky notes are kept', () async {
    final controller = await openEditor();
    controller.setTextLayoutMode(TextLayoutMode.sticky);
    controller.addTextBlock(at: const Offset(80, 100));
    expect(controller.textBlocks, hasLength(1));

    controller.clearLassoSelection();
    expect(controller.textBlocks, hasLength(1));
    expect(controller.textBlocks.single.isSticky, isTrue);
    controller.dispose();
  });

  test('empty page text is kept', () async {
    final controller = await openEditor();
    controller.addTextBlock(mode: TextLayoutMode.lineBound);
    expect(controller.textBlocks, hasLength(1));

    controller.clearLassoSelection();
    expect(controller.textBlocks, hasLength(1));
    expect(
      controller.textBlocks.single.layoutMode,
      TextLayoutMode.lineBound,
    );
    controller.dispose();
  });
}
