import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/content_models.dart';
import '../../../data/models/notebook.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../auth/current_uid.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/file_store.dart';
import '../../../shared/utils/page_size.dart';
import '../../../shared/widgets/image_import_choice.dart';
import '../../lan_sync/lan_sync_controller.dart';
import '../../lan_sync/lan_sync_protocol.dart';
import '../../lan_sync/classroom_auto_connect.dart';
import '../../teacher/catalog/assignment_session.dart';
import '../../teacher/picker/classroom_pick_overlay.dart';
import '../../teacher/teacher_models.dart';
import '../../timetable/timetable_model.dart';
import '../../library/providers/library_providers.dart';
import '../../pdf/pdf_service.dart';
import '../../scanner/document_scanner_service.dart';
import '../../search/recognition/recognition_service.dart';
import '../domain/drawing_aids.dart';
import '../domain/editor_gestures.dart';
import '../domain/ink_engine.dart';
import '../domain/ink_models.dart';
import '../domain/last_page_store.dart';
import '../domain/paper_line_metrics.dart';
import '../domain/shape_recognition.dart';
import 'page_preview_cache.dart';
import '../domain/text_block_registry.dart';
import '../platform/pencil_gestures.dart';
import '../providers/open_tabs_provider.dart';
import '../providers/tool_presets.dart';
import 'editor_chrome.dart';
import 'paper_creator_screen.dart';
import 'widgets/editor_hud.dart';
import 'widgets/content_targets_sheet.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/editor_top_bar.dart';
import 'widgets/image_elements_layer.dart';
import 'widgets/ink_canvas.dart';
import 'widgets/notebook_pages_viewport.dart';
import 'widgets/overlay_hit_stack.dart';
import 'widgets/outline_sidebar.dart';
import 'widgets/page_meta_overlay.dart';
import 'widgets/page_sidebar.dart';
import 'widgets/sticker_layer.dart';
import 'widgets/sticker_picker_sheet.dart';
import 'widgets/page_snapshots_sheet.dart';
import 'widgets/save_page_as_template_sheet.dart';
import 'widgets/share_export_sheet.dart';
import 'widgets/shape_painter.dart';
import 'widgets/study_pomodoro_chip.dart';
import 'widgets/text_block_layer.dart';
import 'widgets/compass_overlay.dart';
import 'widgets/ruler_overlay.dart';
import 'widgets/tool_wheel.dart';
import '../../flashcards/create_flashcard_dialog.dart';
import '../../import_export/import_export_providers.dart';
import '../../import_export/import_models.dart';
import '../../onboarding/app_tour.dart';
import '../../onboarding/feature_hints.dart';
import '../../tools/calculator/calculator_panel.dart';
import '../../tools/calculator/calculator_store.dart';
import '../../tools/calculator/graph_studio_sheet.dart';
import '../../tools/charts/chart_builder.dart';
import '../../tools/editor_tool_panel.dart';
import '../../tools/formula_book/formula_book_panel.dart';
import '../../tools/formula_book/formula_book_store.dart';
import '../../tools/assistant/assistant_panel.dart';
import '../../packs/pack_studio_sheet.dart';
import '../../entitlements/entitlement_model.dart';
import '../../sync/sync_engine.dart';

final editorControllerProvider = ChangeNotifierProvider.autoDispose
    .family<EditorController, String>((ref, notebookId) {
      final controller = EditorController(
        notebookId: notebookId,
        repository: ref.watch(notebookRepositoryProvider),
        pdfService: ref.watch(pdfServiceProvider),
        lastPageStore: ref.watch(lastPageStoreProvider),
        fingerPanZoom: ref.watch(settingsProvider).fingerPanZoom,
      );
      _bindCloudLive(ref, controller, notebookId);
      return controller;
    });

/// Family key includes optional deep-link targets so search can open a chapter.
final editorControllerDeepLinkProvider = ChangeNotifierProvider.autoDispose
    .family<EditorController, ({String id, String? pageId, String? outlineId})>(
      (ref, args) {
        final controller = EditorController(
          notebookId: args.id,
          repository: ref.watch(notebookRepositoryProvider),
          pdfService: ref.watch(pdfServiceProvider),
          lastPageStore: ref.watch(lastPageStoreProvider),
          fingerPanZoom: ref.watch(settingsProvider).fingerPanZoom,
          initialPageId: args.pageId,
          initialOutlineId: args.outlineId,
        );
        _bindCloudLive(ref, controller, args.id);
        return controller;
      },
    );

void _bindCloudLive(Ref ref, EditorController controller, String notebookId) {
  final engine = ref.read(syncEngineProvider);
  controller.onLocalEdit = (previous, next) {
    unawaited(engine.publishLocalEdit(previous: previous, next: next));
  };
  engine.watchNotebook(notebookId, onRemotePage: controller.applyRemotePage);
  ref.onDispose(() => engine.unwatchNotebook(notebookId));
}

class EditorController extends ChangeNotifier {
  EditorController({
    required this.notebookId,
    required this.repository,
    required this.pdfService,
    required this.lastPageStore,
    required this.fingerPanZoom,
    this.initialPageId,
    this.initialOutlineId,
  }) {
    ink.addListener(_onInkChanged);
    drawingAids.addListener(_onAidsChanged);
    ink.pointConstraint = drawingAids.activeConstraint;
    _load();
  }

  final String notebookId;
  final NotebookRepository repository;
  final PdfService pdfService;
  final LastPageStore lastPageStore;
  final bool fingerPanZoom;
  final String? initialPageId;
  final String? initialOutlineId;

  final DrawingAidsController drawingAids = DrawingAidsController();

  /// Optional hook used by nearby LAN sync after a local page save.
  void Function(NotePage page)? onPagePersisted;
  void Function(String pageId)? onPageDeleted;
  void Function(NotePage? previous, NotePage next)? onLocalEdit;

  Notebook? notebook;
  List<NotePage> pages = [];
  List<OutlineNode> outline = [];
  List<NoteTag> tags = [];
  int pageIndex = 0;
  final InkEngine ink = InkEngine();
  List<TextBlock> textBlocks = [];
  List<ShapeElement> shapes = [];
  List<ImageElement> images = [];
  List<StickerElement> stickers = [];
  String? selectedTextId;

  /// Text block with an active caret. Selection alone only arms dragging.
  String? editingTextId;
  String? selectedImageId;
  String? selectedStickerId;
  Set<String> selectedShapeIds = {};
  Set<String> selectedImageIds = {};
  Set<String> selectedTextIds = {};
  Set<String> selectedStickerIds = {};
  ShapeKind shapeKind = ShapeKind.rect;
  ShapeElement? draftShape;
  final TextBlockRegistry textRegistry = TextBlockRegistry();
  InteractionMode interactionMode = InteractionMode.edit;
  bool presentationMode = false;
  bool studyMode = false;
  bool studyInkRevealed = false;
  TextLayoutMode textLayoutMode = TextLayoutMode.free;
  ui.Image? backgroundImage;
  bool loading = true;
  String? error;
  Timer? _saveTimer;

  /// Guards background decoding against fast page flips.
  int _bindToken = 0;
  bool _disposed = false;
  Offset? _lassoDragStart;
  Offset _lassoAccum = Offset.zero;
  List<InkStroke>? _lassoBeforeMove;
  Offset? _shapeStart;
  Timer? _shapeHoldTimer;
  bool _convertedByHold = false;

  NotePage? get currentPage =>
      pages.isEmpty ? null : pages[pageIndex.clamp(0, pages.length - 1)];

  void applyRemotePage(NotePage page) {
    if (_disposed) return;
    final index = pages.indexWhere((item) => item.id == page.id);
    if (index < 0) {
      pages = [...pages, page]..sort((a, b) => a.index.compareTo(b.index));
    } else {
      pages[index] = page;
    }
    if (currentPage?.id == page.id) {
      ink.replaceStrokes(page.strokes, quiet: true);
      textBlocks = page.textBlocks;
      shapes = page.shapes;
      images = page.images;
      stickers = page.stickers;
    }
    notifyListeners();
  }

  PaperTemplate? get activePaper => currentPage?.customPaper;

  PaperLineMetrics _metricsForPage(NotePage page) => PaperLineMetrics.from(
    paper: page.customPaper,
    template: page.template,
    pageSize: NotePageSize.resolve(page.paperFormat, page.orientation),
  );

  Future<void> _load() async {
    try {
      final loaded = await repository.getNotebook(notebookId);
      notebook = loaded;
      if (loaded != null &&
          loaded.isLockedFor(currentAuthUid())) {
        error = 'notebook_locked';
        loading = false;
        notifyListeners();
        return;
      }
      pages = await repository.getPages(notebookId);
      outline = await repository.getOutline(notebookId);
      tags = await repository.getTags(notebookId: notebookId);
      if (pages.isEmpty) {
        final page = await repository.addPage(notebookId: notebookId);
        pages = [page];
      }
      await repository.touchOpened(notebookId);
      var startIndex = 0;
      if (initialPageId != null) {
        final idx = pages.indexWhere((p) => p.id == initialPageId);
        if (idx >= 0) startIndex = idx;
      } else if (initialOutlineId != null) {
        OutlineNode? node;
        for (final n in outline) {
          if (n.id == initialOutlineId) {
            node = n;
            break;
          }
        }
        if (node?.pageId != null) {
          final idx = pages.indexWhere((p) => p.id == node!.pageId);
          if (idx >= 0) startIndex = idx;
        }
      } else {
        // Reopen where the notebook was left off.
        final lastId = lastPageStore.read(notebookId);
        if (lastId != null) {
          final idx = pages.indexWhere((p) => p.id == lastId);
          if (idx >= 0) startIndex = idx;
        }
      }
      await _bindPage(startIndex);
      loading = false;
      notifyListeners();
      PagePreviewCache.instance.scheduleNeighbors(pages, pageIndex);
    } catch (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _bindPage(int index) async {
    _bindPageContent(index);
    await _loadBackground();
  }

  /// Swaps in everything that is already in memory, so a page change shows up
  /// in the next frame instead of after the background image has decoded.
  void _bindPageContent(int index) {
    pageIndex = index;
    _bindToken++;
    var page = pages[index];
    drawingAids.bindPage(page.id, notify: false);
    // Quiet: avoid a second full-editor rebuild from the ink listener while
    // selectPage is already about to notify.
    ink.replaceStrokes(page.strokes, quiet: true);
    final normalizedText = _normalizePageText(page);
    if (normalizedText != page.textBlocks) {
      page = page.copyWith(textBlocks: normalizedText);
      pages[index] = page;
      // Persist the compatible one-document representation in the background.
      unawaited(repository.savePage(page));
    }
    textBlocks = List.of(normalizedText);
    // Defer controller teardown so it never races the page-flip frame.
    final keepIds = {for (final b in textBlocks) b.id};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) textRegistry.retainOnly(keepIds);
    });
    shapes = List.of(page.shapes);
    images = List.of(page.images);
    stickers = List.of(page.stickers);
    selectedTextId = null;
    editingTextId = null;
    selectedImageId = null;
    selectedStickerId = null;
    selectedShapeIds = {};
    selectedImageIds = {};
    selectedTextIds = {};
    selectedStickerIds = {};
    draftShape = null;
    _shapeStart = null;
    unawaited(lastPageStore.write(notebookId, page.id));
  }

  /// Older pages may contain several separately placed page-text blocks.
  /// Merge those into one flow so subsequent Enter presses can never collide
  /// with text that was previously placed on a lower rule.
  List<TextBlock> _normalizePageText(NotePage page) {
    final pageBlocks = [
      for (final block in page.textBlocks)
        if (block.layoutMode == TextLayoutMode.lineBound) block,
    ]..sort((a, b) => a.y.compareTo(b.y));
    if (pageBlocks.length <= 1) return page.textBlocks;

    final runs = <TextSpanStyle>[];
    for (var i = 0; i < pageBlocks.length; i++) {
      final block = pageBlocks[i];
      if (i > 0) {
        final style = runs.isEmpty ? const TextSpanStyle(text: '') : runs.last;
        runs.add(style.copyWith(text: '\n'));
      }
      runs.addAll(block.spans);
    }
    final document = pageBlocks.first.copyWith(
      x: _metricsForPage(page).marginLeft,
      width: _metricsForPage(page).contentWidth,
      height: _metricsForPage(page).pageHeight,
      spans: runs,
    );
    return [
      for (final block in page.textBlocks)
        if (block.layoutMode != TextLayoutMode.lineBound) block,
      document,
    ];
  }

  Future<void> _loadBackground() async {
    final token = _bindToken;
    final path = pages[pageIndex].backgroundPdfPath;
    if (path == null && backgroundImage == null) return;
    final image = await pdfService.loadBackgroundImage(path);
    if (token != _bindToken || _disposed) {
      image?.dispose();
      return;
    }
    backgroundImage?.dispose();
    backgroundImage = image;
  }

  void _onInkChanged() {
    // The canvas repaints itself from the engine, so while a stroke is still
    // being drawn the surrounding chrome does not have to rebuild with it.
    // Object selection stays until the user taps empty paper or deletes it —
    // switching pens must not drop a selected sticky / stroke.
    if (ink.activeStroke == null) notifyListeners();
    _scheduleSave();
  }

  bool get hasLassoSelection =>
      ink.selectedIds.isNotEmpty ||
      selectedShapeIds.isNotEmpty ||
      selectedImageIds.isNotEmpty ||
      selectedTextIds.isNotEmpty ||
      selectedStickerIds.isNotEmpty;

  bool get selectionCanRecolor =>
      ink.selectedIds.isNotEmpty ||
      selectedShapeIds.isNotEmpty ||
      textBlocks.any((b) => selectedTextIds.contains(b.id) && b.isSticky);

  void _clearLassoObjects({bool notify = true}) {
    if (selectedShapeIds.isEmpty &&
        selectedImageIds.isEmpty &&
        selectedTextIds.isEmpty &&
        selectedStickerIds.isEmpty) {
      return;
    }
    selectedShapeIds = {};
    selectedImageIds = {};
    selectedTextIds = {};
    selectedStickerIds = {};
    if (notify) notifyListeners();
  }

  void clearLassoSelection() {
    ink.clearSelection();
    selectedTextId = null;
    editingTextId = null;
    selectedImageId = null;
    selectedStickerId = null;
    _clearLassoObjects();
  }

  void deleteLassoSelection() {
    ink.deleteSelected();
    var changed = false;
    if (selectedShapeIds.isNotEmpty) {
      shapes = [
        for (final s in shapes)
          if (!selectedShapeIds.contains(s.id)) s,
      ];
      selectedShapeIds = {};
      changed = true;
    }
    if (selectedImageIds.isNotEmpty) {
      images = [
        for (final i in images)
          if (!selectedImageIds.contains(i.id)) i,
      ];
      if (selectedImageId != null &&
          selectedImageIds.contains(selectedImageId)) {
        selectedImageId = null;
      }
      selectedImageIds = {};
      changed = true;
    }
    if (selectedTextIds.isNotEmpty) {
      textBlocks = [
        for (final b in textBlocks)
          if (!selectedTextIds.contains(b.id)) b,
      ];
      if (selectedTextId != null && selectedTextIds.contains(selectedTextId)) {
        selectedTextId = null;
        editingTextId = null;
      }
      selectedTextIds = {};
      textRegistry.retainOnly({for (final b in textBlocks) b.id});
      changed = true;
    }
    if (selectedStickerIds.isNotEmpty) {
      stickers = [
        for (final s in stickers)
          if (!selectedStickerIds.contains(s.id)) s,
      ];
      if (selectedStickerId != null &&
          selectedStickerIds.contains(selectedStickerId)) {
        selectedStickerId = null;
      }
      selectedStickerIds = {};
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _scheduleSave();
    }
  }

  bool _lassoSelectionContains(Offset pagePoint) {
    if (ink.selectionHits(pagePoint)) return true;
    for (final shape in shapes) {
      if (selectedShapeIds.contains(shape.id) &&
          _shapeHits(shape, pagePoint, 10)) {
        return true;
      }
    }
    for (final image in images) {
      if (selectedImageIds.contains(image.id) &&
          image.bounds.inflate(8).contains(pagePoint)) {
        return true;
      }
    }
    final page = currentPage;
    if (page != null) {
      final metrics = _metricsForPage(page);
      for (final block in textBlocks) {
        if (!selectedTextIds.contains(block.id)) continue;
        if (textBlockBounds(
          block: block,
          metrics: metrics,
        ).inflate(8).contains(pagePoint)) {
          return true;
        }
      }
    }
    for (final sticker in stickers) {
      if (selectedStickerIds.contains(sticker.id) &&
          sticker.bounds.inflate(8).contains(pagePoint)) {
        return true;
      }
    }
    return false;
  }

  void _moveLassoObjects(Offset delta) {
    var changed = false;
    if (selectedShapeIds.isNotEmpty) {
      shapes = [
        for (final s in shapes)
          if (selectedShapeIds.contains(s.id))
            s.copyWith(
              x1: s.x1 + delta.dx,
              y1: s.y1 + delta.dy,
              x2: s.x2 + delta.dx,
              y2: s.y2 + delta.dy,
            )
          else
            s,
      ];
      changed = true;
    }
    if (selectedImageIds.isNotEmpty) {
      images = [
        for (final i in images)
          if (selectedImageIds.contains(i.id))
            i.copyWith(x: i.x + delta.dx, y: i.y + delta.dy)
          else
            i,
      ];
      changed = true;
    }
    if (selectedTextIds.isNotEmpty) {
      textBlocks = [
        for (final b in textBlocks)
          if (selectedTextIds.contains(b.id))
            b.copyWith(x: b.x + delta.dx, y: b.y + delta.dy)
          else
            b,
      ];
      changed = true;
    }
    if (selectedStickerIds.isNotEmpty) {
      stickers = [
        for (final s in stickers)
          if (selectedStickerIds.contains(s.id))
            s.copyWith(x: s.x + delta.dx, y: s.y + delta.dy)
          else
            s,
      ];
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _selectObjectsInLasso(List<Offset> polygon) {
    if (polygon.length < 3) {
      _clearLassoObjects();
      return;
    }
    final targets = ink.lassoTargets;
    final nextShapes = <String>{};
    final nextImages = <String>{};
    final nextText = <String>{};
    final nextStickers = <String>{};
    if (targets.contains(ContentKind.shapes)) {
      for (final shape in shapes) {
        if (rectIntersectsPolygon(shape.bounds, polygon)) {
          nextShapes.add(shape.id);
        }
      }
    }
    if (targets.contains(ContentKind.images)) {
      for (final image in images) {
        if (rectIntersectsPolygon(image.bounds, polygon)) {
          nextImages.add(image.id);
        }
      }
      for (final sticker in stickers) {
        if (rectIntersectsPolygon(sticker.bounds, polygon)) {
          nextStickers.add(sticker.id);
        }
      }
    }
    if (targets.contains(ContentKind.text)) {
      final page = currentPage;
      if (page != null) {
        final metrics = _metricsForPage(page);
        for (final block in textBlocks) {
          if (rectIntersectsPolygon(
            textBlockBounds(block: block, metrics: metrics),
            polygon,
          )) {
            nextText.add(block.id);
          }
        }
      }
    }
    selectedShapeIds = nextShapes;
    selectedImageIds = nextImages;
    selectedTextIds = nextText;
    selectedStickerIds = nextStickers;
    selectedImageId = nextImages.length == 1 ? nextImages.first : null;
    selectedStickerId = nextStickers.length == 1 ? nextStickers.first : null;
    if (nextText.length == 1) {
      selectedTextId = nextText.first;
    } else if (selectedTextId != null && !nextText.contains(selectedTextId)) {
      selectedTextId = null;
      editingTextId = null;
    }
    notifyListeners();
  }

  void _erasePageObjects(Offset point) {
    final radius = ink.eraseRadius;
    final targets = ink.eraseTargets;
    var changed = false;
    if (targets.contains(ContentKind.shapes)) {
      final next = [
        for (final s in shapes)
          if (!_shapeHits(s, point, radius)) s,
      ];
      if (next.length != shapes.length) {
        shapes = next;
        changed = true;
      }
    }
    if (targets.contains(ContentKind.images)) {
      final next = [
        for (final i in images)
          if (!i.bounds.inflate(radius).contains(point)) i,
      ];
      if (next.length != images.length) {
        if (selectedImageId != null &&
            !next.any((i) => i.id == selectedImageId)) {
          selectedImageId = null;
        }
        images = next;
        changed = true;
      }
    }
    if (targets.contains(ContentKind.text)) {
      final page = currentPage;
      if (page != null) {
        final metrics = _metricsForPage(page);
        final next = [
          for (final b in textBlocks)
            if (!textBlockBounds(
              block: b,
              metrics: metrics,
            ).inflate(radius).contains(point))
              b,
        ];
        if (next.length != textBlocks.length) {
          if (selectedTextId != null &&
              !next.any((b) => b.id == selectedTextId)) {
            selectedTextId = null;
            editingTextId = null;
          }
          textBlocks = next;
          textRegistry.retainOnly({for (final b in textBlocks) b.id});
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
      _scheduleSave();
    }
  }

  bool _shapeHits(ShapeElement shape, Offset point, double radius) {
    final pad = radius + shape.strokeWidth / 2;
    if (shape.kind == ShapeKind.line || shape.kind == ShapeKind.arrow) {
      return _distanceToSegment(
            point,
            Offset(shape.x1, shape.y1),
            Offset(shape.x2, shape.y2),
          ) <=
          pad;
    }
    return shape.bounds.inflate(pad).contains(point);
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    t = t.clamp(0.0, 1.0);
    return (p - Offset(a.dx + ab.dx * t, a.dy + ab.dy * t)).distance;
  }

  void _onAidsChanged() {
    ink.pointConstraint = drawingAids.activeConstraint;
    // Keep guide chips in sync with overlay visibility.
    if (drawingAids.hasRuler) {
      ink.guide = DrawingGuide.ruler;
    } else if (drawingAids.hasVisibleCompass) {
      ink.guide = DrawingGuide.compass;
    } else if (ink.guide != DrawingGuide.none) {
      ink.guide = DrawingGuide.none;
    }
    notifyListeners();
  }

  void toggleRulerAid() {
    final page = currentPage;
    if (page == null) return;
    final size = NotePageSize.resolve(page.paperFormat, page.orientation);
    drawingAids.toggleRuler(size);
  }

  void toggleCompassAid() {
    final page = currentPage;
    if (page == null) return;
    final size = NotePageSize.resolve(page.paperFormat, page.orientation);
    drawingAids.toggleCompass(size);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), _persistCurrent);
  }

  Future<void> _persistCurrent({bool warmPreview = true}) async {
    _saveTimer?.cancel();
    final page = currentPage;
    if (page == null) return;
    final previous = currentPage;
    final updated = page.copyWith(
      strokes: ink.strokes,
      textBlocks: textBlocks,
      shapes: shapes,
      images: images,
      stickers: stickers,
      updatedAt: DateTime.now(),
    );
    pages[pageIndex] = updated;
    // Don't rasterize during a page flip — that fights the swipe animation.
    if (warmPreview) {
      unawaited(PagePreviewCache.instance.ensure(updated, force: true));
    }
    await repository.savePage(updated);
    onPagePersisted?.call(updated);
    onLocalEdit?.call(previous?.id == updated.id ? previous : null, updated);
    unawaited(_refreshSearchIndex(updated));
  }

  Future<void> persistForSearchIndex() => _persistCurrent();

  Future<void> _refreshSearchIndex(NotePage page) async {
    final indexed = await RecognitionService.instance.indexPage(page);
    if (indexed == null || _disposed) return;
    final i = pages.indexWhere((p) => p.id == page.id);
    if (i < 0) return;
    pages[i] = indexed;
    await repository.savePage(indexed);
  }

  /// Re-reads pages from disk after a nearby-sync remote update.
  Future<void> reloadFromRemote({String? pageId}) async {
    if (_disposed) return;
    final keepIndex = pageIndex;
    pages = await repository.getPages(notebookId);
    notebook = await repository.getNotebook(notebookId);
    outline = await repository.getOutline(notebookId);
    if (pages.isEmpty) return;
    var index = keepIndex.clamp(0, pages.length - 1);
    if (pageId != null) {
      final found = pages.indexWhere((p) => p.id == pageId);
      if (found >= 0) index = found;
    }
    await _bindPage(index);
    notifyListeners();
  }

  /// Copy live ink into [pages] without disk I/O so the leaving snapshot
  /// matches the canvas the moment a swipe hides it.
  void syncActivePageMemory() {
    final page = currentPage;
    if (page == null) return;
    final dirty =
        page.strokes.length != ink.strokes.length ||
        page.shapes.length != shapes.length ||
        page.images.length != images.length ||
        page.stickers.length != stickers.length ||
        page.textBlocks.length != textBlocks.length;
    pages[pageIndex] = page.copyWith(
      strokes: List.of(ink.strokes),
      textBlocks: List.of(textBlocks),
      shapes: List.of(shapes),
      images: List.of(images),
      stickers: List.of(stickers),
      updatedAt: dirty ? DateTime.now() : page.updatedAt,
    );
    if (dirty) {
      PagePreviewCache.instance.invalidate(page.id);
    }
  }

  Future<void> selectPage(int index) async {
    if (interactionMode == InteractionMode.read) return;
    if (index == pageIndex || index < 0 || index >= pages.length) return;
    final leavingPath = currentPage?.backgroundPdfPath;
    // Saving the page we leave takes its snapshot synchronously, so the swap
    // does not have to wait for the write to land.
    unawaited(_persistCurrent(warmPreview: false));
    // bindPage inside _bindPageContent parks a fixed compass on other pages.
    _bindPageContent(index);
    final page = currentPage;
    final arrivingPath = page?.backgroundPdfPath;
    // Only drop the PDF bitmap when the path actually changes — keeps flips
    // between plain pages from thrashing the background cache.
    if (leavingPath != arrivingPath) {
      backgroundImage?.dispose();
      backgroundImage = null;
    }
    if (page != null && drawingAids.ruler?.fixed == true) {
      drawingAids.updateRuler(
        drawingAids.ruler!.copyWith(
          pageSize: NotePageSize.resolve(page.paperFormat, page.orientation),
        ),
      );
    }
    // One chrome rebuild after the in-memory swap — decode PDF off the
    // critical path and only notify again if a background actually arrives.
    notifyListeners();
    PagePreviewCache.instance.scheduleNeighbors(pages, pageIndex);
    if (arrivingPath != null && leavingPath != arrivingPath) {
      await _loadBackground();
      if (_disposed) return;
      if (backgroundImage != null) notifyListeners();
    }
  }

  bool get currentPageHasImportedBackground =>
      currentPage?.backgroundPdfPath != null;

  /// Adds a page with the previous page's paper by default. Import backgrounds
  /// are only copied after the user explicitly confirms that choice.
  Future<void> addPage({
    PageTemplate? template,
    bool useNotebookDefault = false,
    bool keepImportedBackground = false,
  }) async {
    await _persistCurrent();
    final source = currentPage;
    final defaultTemplate = notebook?.defaultTemplate ?? PageTemplate.blank;
    final useSource = !useNotebookDefault && source != null;
    final page = await repository.addPage(
      notebookId: notebookId,
      template: template ?? (useSource ? source.template : defaultTemplate),
      backgroundPdfPath: useSource && keepImportedBackground
          ? source.backgroundPdfPath
          : null,
      paperTemplateId: useSource ? source.paperTemplateId : null,
      customPaper: useSource ? source.customPaper : null,
      paperFormat: notebook?.defaultPaperFormat ?? PaperFormat.a4,
      orientation: notebook?.defaultOrientation ?? PageOrientation.portrait,
    );
    pages = await repository.getPages(notebookId);
    notebook = await repository.getNotebook(notebookId);
    final idx = pages.indexWhere((p) => p.id == page.id);
    await _bindPage(idx < 0 ? pages.length - 1 : idx);
    notifyListeners();
  }

  Future<void> duplicatePage(int index) async {
    if (index < 0 || index >= pages.length) return;
    await _persistCurrent();
    final source = pages[index];
    final copy = NotePage(
      id: const Uuid().v4(),
      notebookId: notebookId,
      index: pages.length,
      template: source.template,
      backgroundPdfPath: source.backgroundPdfPath,
      strokes: source.strokes,
      textBlocks: source.textBlocks,
      shapes: source.shapes,
      images: source.images,
      stickers: source.stickers,
      title: source.title,
      paperTemplateId: source.paperTemplateId,
      customPaper: source.customPaper,
      createdAt: DateTime.now(),
      paperFormat: source.paperFormat,
      orientation: source.orientation,
    );
    await repository.savePage(copy);
    pages = await repository.getPages(notebookId);
    final copyIndex = pages.indexWhere((page) => page.id == copy.id);
    await _bindPage(copyIndex < 0 ? pages.length - 1 : copyIndex);
    notifyListeners();
  }

  Future<void> deletePage(int index) async {
    if (pages.length <= 1 || index < 0 || index >= pages.length) return;
    await _persistCurrent();
    final pageId = pages[index].id;
    PagePreviewCache.instance.invalidate(pageId);
    await repository.deletePage(pageId);
    onPageDeleted?.call(pageId);
    pages = await repository.getPages(notebookId);
    await _bindPage(index.clamp(0, pages.length - 1));
    notifyListeners();
  }

  Future<void> renamePage(int index, String? title) async {
    if (index < 0 || index >= pages.length) return;
    final trimmed = title?.trim();
    final page = pages[index];
    final updated = page.copyWith(
      title: trimmed,
      clearTitle: trimmed == null || trimmed.isEmpty,
      updatedAt: DateTime.now(),
    );
    pages[index] = updated;
    await repository.savePage(updated);
    notifyListeners();
  }

  Future<void> setTemplate(PageTemplate template) async {
    final page = currentPage;
    if (page == null) return;
    final updated = page.copyWith(template: template, clearCustomPaper: true);
    pages[pageIndex] = updated;
    await repository.savePage(updated);
    notifyListeners();
  }

  /// Updates the notebook default used for pages added from now on. Existing
  /// pages keep their own physical size so their ink and text never shift.
  Future<void> updateNewPageDefaults({
    PaperFormat? paperFormat,
    PageOrientation? orientation,
  }) async {
    final current = notebook;
    if (current == null || current.canvasMode == CanvasMode.infinite) return;
    notebook = current.copyWith(
      defaultPaperFormat: paperFormat,
      defaultOrientation: orientation,
      updatedAt: DateTime.now(),
    );
    await repository.updateNotebook(notebook!);
    notifyListeners();
  }

  void toggleInteractionMode() {
    interactionMode = interactionMode == InteractionMode.edit
        ? InteractionMode.read
        : InteractionMode.edit;
    notifyListeners();
  }

  void togglePresentationMode() {
    presentationMode = !presentationMode;
    notifyListeners();
  }

  void toggleStudyMode() {
    studyMode = !studyMode;
    studyInkRevealed = false;
    if (studyMode) {
      ink.setTool(InkTool.none);
      if (presentationMode) presentationMode = false;
    }
    notifyListeners();
  }

  void toggleStudyInkReveal() {
    if (!studyMode) return;
    studyInkRevealed = !studyInkRevealed;
    notifyListeners();
  }

  Future<PageLocalSnapshot?> saveCurrentSnapshot({String? label}) async {
    await _persistCurrent();
    final page = currentPage;
    if (page == null) return null;
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final snapshot = PageLocalSnapshot(
      id: const Uuid().v4(),
      pageId: page.id,
      notebookId: notebookId,
      label: label ?? stamp,
      createdAt: now,
      pageJson: jsonEncode(page.toJson()),
    );
    await repository.savePageSnapshot(snapshot);
    return snapshot;
  }

  Future<void> restoreSnapshot(PageLocalSnapshot snapshot) async {
    await _persistCurrent();
    final page = currentPage;
    if (page == null || page.id != snapshot.pageId) return;
    // Keep a safety copy of the live page before replacing it.
    await saveCurrentSnapshot(label: 'auto');
    final restored = NotePage.fromJson(
      Map<String, dynamic>.from(jsonDecode(snapshot.pageJson) as Map),
    ).copyWith(index: page.index, updatedAt: DateTime.now());
    await repository.savePage(restored);
    pages[pageIndex] = restored;
    await _bindPage(pageIndex);
    notifyListeners();
  }

  void setShapeKind(ShapeKind kind) {
    shapeKind = kind;
    ink.setTool(InkTool.shape);
    notifyListeners();
  }

  Future<int> importScannedImages(List<String> imagePaths) async {
    await _persistCurrent();
    final created = await pdfService.importScannedImages(
      notebookId: notebookId,
      imagePaths: imagePaths,
    );
    if (created.isEmpty) return 0;
    pages = await repository.getPages(notebookId);
    notebook = await repository.getNotebook(notebookId);
    final idx = pages.indexWhere((p) => p.id == created.first.id);
    await _bindPage(idx < 0 ? pageIndex : idx);
    notifyListeners();
    return created.length;
  }

  Future<void> importPdf() async {
    await _persistCurrent();
    final created = await pdfService.importPdfAsPages(notebookId: notebookId);
    if (created.isEmpty) return;
    pages = await repository.getPages(notebookId);
    notebook = await repository.getNotebook(notebookId);
    final idx = pages.indexWhere((p) => p.id == created.first.id);
    await _bindPage(idx < 0 ? pageIndex : idx);
    notifyListeners();
  }

  /// Import with a progress dialog owned by the screen.
  Future<void> importPdfWithProgress(
    void Function(int done, int total) onProgress,
  ) async {
    await _persistCurrent();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final created = await pdfService.importPdfFromBytes(
      notebookId: notebookId,
      bytes: bytes,
      onProgress: onProgress,
    );
    if (created.isEmpty) return;
    pages = await repository.getPages(notebookId);
    notebook = await repository.getNotebook(notebookId);
    final idx = pages.indexWhere((p) => p.id == created.first.id);
    await _bindPage(idx < 0 ? pageIndex : idx);
    notifyListeners();
  }

  Future<void> exportPdf() async {
    await _persistCurrent();
    final nb = notebook;
    if (nb == null) return;
    await pdfService.printNotebook(nb, pages);
  }

  Future<void> sharePdf() async {
    await _persistCurrent();
    final nb = notebook;
    if (nb == null) return;
    await pdfService.shareNotebookPdf(nb, pages);
  }

  Future<void> shareCurrentPage() async {
    await _persistCurrent();
    final nb = notebook;
    if (nb == null) return;
    await pdfService.shareCurrentPagePdf(nb, pages, pageIndex);
  }

  void addTextBlock({
    TextLayoutMode? mode,
    String text = 'New text',
    Offset? at,
  }) {
    final page = currentPage;
    if (page == null) return;
    final layout = mode ?? textLayoutMode;
    final metrics = _metricsForPage(page);
    late final double x;
    late final double y;
    late final double width;
    late final double height;
    late final String initialText;
    if (layout == TextLayoutMode.lineBound) {
      final document = textBlocks.where(
        (block) => block.layoutMode == TextLayoutMode.lineBound,
      );
      if (document.isNotEmpty) {
        final existing = document.first;
        selectedTextId = existing.id;
        editingTextId = existing.id;
        ink.setTool(InkTool.text);
        notifyListeners();
        return;
      }
      x = metrics.marginLeft;
      // A page document always starts on the first ruled line. Tapping a
      // lower line later moves the caret; it never creates another document.
      y = metrics.snapToLine(metrics.marginTop);
      width = metrics.contentWidth;
      height = metrics.pageHeight;
      initialText = text == 'New text' || text == 'Neuer Text' ? '' : text;
    } else if (layout == TextLayoutMode.sticky) {
      x = (at?.dx ?? 72).clamp(16, 420);
      y = (at?.dy ?? 88 + textBlocks.where((b) => b.isSticky).length * 24.0)
          .clamp(16, 700);
      width = 200;
      height = 168;
      initialText = at == null ? text : '';
    } else {
      x = (at?.dx ?? 80).clamp(16, 400);
      y = (at?.dy ?? 100 + textBlocks.length * 28.0).clamp(16, 700);
      width = 220;
      height = 48;
      // Tapping the paper means "type here", so no placeholder gets in the way.
      initialText = at == null ? text : '';
    }
    _pruneEmptyText();
    final block = TextBlock.create(
      pageId: page.id,
      x: x,
      y: y,
      layoutMode: layout,
      text: initialText,
    ).copyWith(
      width: width,
      height: height,
      fillColor: layout == TextLayoutMode.sticky ? 0xFFFFF59D : null,
    );
    textBlocks = [...textBlocks, block];
    selectedTextId = block.id;
    // A fresh block goes straight to the keyboard so typing needs no extra tap.
    editingTextId = block.id;
    selectedTextIds = {block.id};
    selectedImageId = null;
    selectedStickerId = null;
    selectedImageIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    ink.selectIds({});
    ink.setTool(InkTool.text);
    notifyListeners();
    _scheduleSave();
  }

  /// Drops text blocks the user left without any content, except [keepId].
  void _pruneEmptyText([String? keepId]) {
    final kept = [
      for (final block in textBlocks)
        if (block.id == keepId ||
            block.isSticky ||
            block.plainText.trim().isNotEmpty)
          block,
    ];
    if (kept.length == textBlocks.length) return;
    textBlocks = kept;
    textRegistry.retainOnly({for (final block in kept) block.id});
    _scheduleSave();
  }

  /// The block under [pagePoint], if any. Used so touching existing text never
  /// spawns another block.
  TextBlock? textBlockAt(Offset pagePoint) {
    final page = currentPage;
    if (page == null) return null;
    final metrics = _metricsForPage(page);
    for (final block in textBlocks.reversed) {
      if (block.layoutMode == TextLayoutMode.lineBound &&
          textLayoutMode != TextLayoutMode.lineBound) {
        continue;
      }
      final bounds = textBlockBounds(block: block, metrics: metrics);
      // The page document owns the whole writing column. This ensures a tap
      // below existing text is still a caret interaction, never a new block.
      final halo = block.layoutMode == TextLayoutMode.lineBound
          ? metrics.pageHeight
          : 14.0;
      if (bounds.inflate(halo).contains(pagePoint)) return block;
    }
    return null;
  }

  void setTextLayoutMode(TextLayoutMode mode) {
    textLayoutMode = mode;
    notifyListeners();
  }

  void updateTextBlock(TextBlock block) {
    textBlocks = [
      for (final b in textBlocks)
        if (b.id == block.id) block else b,
    ];
    notifyListeners();
    _scheduleSave();
  }

  void selectText(String? id) {
    if (id != selectedTextId) _pruneEmptyText(id);
    selectedTextId = id;
    if (editingTextId != id) editingTextId = null;
    selectedImageId = null;
    selectedStickerId = null;
    selectedImageIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    selectedTextIds = id == null ? {} : {id};
    ink.selectIds({});
    notifyListeners();
  }

  void beginTextEdit(String id) {
    _pruneEmptyText(id);
    selectedTextId = id;
    editingTextId = id;
    selectedImageId = null;
    selectedStickerId = null;
    selectedImageIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    selectedTextIds = {id};
    ink.selectIds({});
    notifyListeners();
  }

  void deleteTextBlock(TextBlock block) {
    textBlocks = [
      for (final candidate in textBlocks)
        if (candidate.id != block.id) candidate,
    ];
    if (selectedTextId == block.id) selectedTextId = null;
    if (editingTextId == block.id) editingTextId = null;
    selectedTextIds = {
      for (final id in selectedTextIds)
        if (id != block.id) id,
    };
    textRegistry.retainOnly({for (final b in textBlocks) b.id});
    notifyListeners();
    _scheduleSave();
  }

  void updateImage(ImageElement image) {
    images = [
      for (final i in images)
        if (i.id == image.id) image else i,
    ];
    notifyListeners();
    _scheduleSave();
  }

  void selectImage(String? id) {
    selectedImageId = id;
    selectedTextId = null;
    editingTextId = null;
    selectedStickerId = null;
    selectedTextIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    selectedImageIds = id == null ? {} : {id};
    ink.selectIds({});
    notifyListeners();
  }

  void deleteImage(String id) {
    images = [
      for (final i in images)
        if (i.id != id) i,
    ];
    if (selectedImageId == id) selectedImageId = null;
    selectedImageIds = {
      for (final item in selectedImageIds)
        if (item != id) item,
    };
    notifyListeners();
    _scheduleSave();
  }

  Future<void> pickAndInsertImage() async {
    await pickAndImportImages(asPages: false);
  }

  Future<int> pickAndImportImages({required bool asPages}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: asPages,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return 0;
    final dir = await repository.resolveFilesDir();
    final store = createFileStore();
    final dests = <String>[];
    for (final file in result.files) {
      final name = '${const Uuid().v4()}_${file.name}';
      final dest = p.join(dir, 'images', name);
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        await store.writeBytes(dest, bytes);
      } else {
        final path = file.path;
        if (path == null) continue;
        await store.writeBytes(dest, await store.readBytes(path));
      }
      dests.add(dest);
    }
    if (dests.isEmpty) return 0;
    if (asPages) return importScannedImages(dests);
    var added = 0;
    for (final dest in dests) {
      await _insertStoredImage(dest, offset: added);
      added++;
    }
    return added;
  }

  Future<int> insertImagesFromPaths(List<String> paths) async {
    var added = 0;
    final dir = await repository.resolveFilesDir();
    final store = createFileStore();
    for (final path in paths) {
      final name = '${const Uuid().v4()}_${p.basename(path)}';
      final dest = p.join(dir, 'images', name);
      try {
        await store.writeBytes(dest, await store.readBytes(path));
        await _insertStoredImage(dest, offset: added);
        added++;
      } catch (_) {}
    }
    return added;
  }

  Future<void> _insertStoredImage(String dest, {int offset = 0}) async {
    final page = currentPage;
    if (page == null) return;
    final element = ImageElement.create(
      pageId: page.id,
      localPath: dest,
      x: 80 + offset * 24,
      y: 100 + offset * 24,
    );
    images = [...images, element];
    selectedImageId = element.id;
    selectedImageIds = {element.id};
    selectedTextId = null;
    editingTextId = null;
    selectedStickerId = null;
    selectedTextIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    ink.selectIds({});
    ink.setTool(InkTool.image);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> insertPngBytes(
    Uint8List bytes, {
    double width = 320,
    double height = 214,
  }) async {
    final page = currentPage;
    if (page == null) return;
    final dir = await repository.resolveFilesDir();
    final dest = p.join(dir, 'images', '${const Uuid().v4()}_plot.png');
    await createFileStore().writeBytes(dest, bytes);
    final element = ImageElement.create(
      pageId: page.id,
      localPath: dest,
      x: 72,
      y: 88,
      width: width,
      height: height,
    );
    images = [...images, element];
    selectedImageId = element.id;
    selectedImageIds = {element.id};
    selectedTextId = null;
    editingTextId = null;
    selectedStickerId = null;
    selectedTextIds = {};
    selectedStickerIds = {};
    selectedShapeIds = {};
    ink.selectIds({});
    ink.setTool(InkTool.image);
    notifyListeners();
    _scheduleSave();
  }

  void insertSticker(String catalogId, {Offset? at}) {
    final page = currentPage;
    if (page == null) return;
    final element = StickerElement.create(
      pageId: page.id,
      catalogId: catalogId,
      x: (at?.dx ?? 96).clamp(16, 500),
      y: (at?.dy ?? 120 + stickers.length * 16.0).clamp(16, 700),
    );
    stickers = [...stickers, element];
    selectedStickerId = element.id;
    selectedStickerIds = {element.id};
    selectedImageId = null;
    selectedTextId = null;
    editingTextId = null;
    selectedImageIds = {};
    selectedTextIds = {};
    selectedShapeIds = {};
    ink.selectIds({});
    ink.setTool(InkTool.sticker);
    notifyListeners();
    _scheduleSave();
  }

  void updateSticker(StickerElement sticker) {
    stickers = [
      for (final s in stickers)
        if (s.id == sticker.id) sticker else s,
    ];
    notifyListeners();
    _scheduleSave();
  }

  void selectSticker(String? id) {
    selectedStickerId = id;
    selectedImageId = null;
    selectedTextId = null;
    editingTextId = null;
    selectedImageIds = {};
    selectedTextIds = {};
    selectedShapeIds = {};
    selectedStickerIds = id == null ? {} : {id};
    ink.selectIds({});
    notifyListeners();
  }

  void deleteSticker(String id) {
    stickers = [
      for (final s in stickers)
        if (s.id != id) s,
    ];
    if (selectedStickerId == id) selectedStickerId = null;
    selectedStickerIds = {
      for (final item in selectedStickerIds)
        if (item != id) item,
    };
    notifyListeners();
    _scheduleSave();
  }

  Future<void> applyPaper(PaperTemplate paper) async {
    final page = currentPage;
    if (page == null) return;
    final saved = paper.id == 'draft'
        ? PaperTemplate.create(
            name: paper.name,
            lineSpacing: paper.lineSpacing,
            gridSize: paper.gridSize,
            marginLeft: paper.marginLeft,
            marginTop: paper.marginTop,
            backgroundColor: paper.backgroundColor,
            lineColor: paper.lineColor,
            style: paper.style,
            horizontalLines: paper.horizontalLines,
            verticalLines: paper.verticalLines,
          )
        : paper;
    if (!saved.isBuiltin) {
      await repository.savePaperTemplate(saved);
    }
    final pageTemplate = switch (saved.style) {
      'grid' || 'dotted' => PageTemplate.grid,
      'lined' => PageTemplate.lined,
      'custom' => saved.hasRuledLines ? PageTemplate.lined : PageTemplate.blank,
      _ => PageTemplate.blank,
    };
    final updated = page.copyWith(
      customPaper: saved,
      paperTemplateId: saved.id,
      template: pageTemplate,
    );
    pages[pageIndex] = updated;
    await repository.savePage(updated);
    notifyListeners();
  }

  Future<void> saveCurrentPageAsTemplate(PaperTemplate template) async {
    await repository.savePaperTemplate(template);
    await applyPaper(template);
  }

  Future<void> addOutlineNode({String? parentId, String? title}) async {
    final page = currentPage;
    OutlineNode? parent;
    if (parentId != null) {
      for (final n in outline) {
        if (n.id == parentId) {
          parent = n;
          break;
        }
      }
    }
    final depth = parent == null ? 0 : (parent.depth + 1).clamp(0, 4);
    final node = OutlineNode.create(
      notebookId: notebookId,
      title:
          title ??
          (depth == 0
              ? 'Chapter ${outline.where((n) => n.depth == 0).length + 1}'
              : 'Section'),
      parentId: parent?.id,
      depth: depth,
      pageId: page?.id,
      sortIndex: outline.length,
    );
    if (parent == null) {
      outline = [...outline, node];
    } else {
      final parentIndex = outline.indexWhere((n) => n.id == parent!.id);
      var insertAt = parentIndex + 1;
      while (insertAt < outline.length &&
          outline[insertAt].depth > parent.depth) {
        insertAt++;
      }
      final next = List<OutlineNode>.of(outline);
      next.insert(insertAt, node);
      outline = [
        for (var i = 0; i < next.length; i++) next[i].copyWith(sortIndex: i),
      ];
    }
    notifyListeners();
    await repository.saveOutline(notebookId, outline);
  }

  Future<void> renameOutline(OutlineNode node, String title) async {
    outline = [
      for (final n in outline)
        if (n.id == node.id) n.copyWith(title: title) else n,
    ];
    notifyListeners();
    await repository.saveOutline(notebookId, outline);
  }

  Future<void> deleteOutline(OutlineNode node) async {
    final remove = <String>{node.id};
    var grew = true;
    while (grew) {
      grew = false;
      for (final n in outline) {
        if (n.parentId != null &&
            remove.contains(n.parentId) &&
            remove.add(n.id)) {
          grew = true;
        }
      }
    }
    // Legacy indent-only children (no parentId): drop contiguous deeper nodes.
    final start = outline.indexWhere((n) => n.id == node.id);
    if (start >= 0) {
      for (var i = start + 1; i < outline.length; i++) {
        if (outline[i].depth <= node.depth) break;
        if (outline[i].parentId == null) remove.add(outline[i].id);
      }
    }
    outline = outline.where((n) => !remove.contains(n.id)).toList();
    notifyListeners();
    await repository.saveOutline(notebookId, outline);
  }

  Future<void> indentOutline(OutlineNode node, int delta) async {
    final index = outline.indexWhere((n) => n.id == node.id);
    if (index < 0) return;
    final depth = (node.depth + delta).clamp(0, 4);
    String? parentId;
    if (depth == 0) {
      parentId = null;
    } else {
      for (var i = index - 1; i >= 0; i--) {
        if (outline[i].depth == depth - 1) {
          parentId = outline[i].id;
          break;
        }
        if (outline[i].depth < depth - 1) break;
      }
    }
    outline = [
      for (final n in outline)
        if (n.id == node.id)
          n.copyWith(
            depth: depth,
            parentId: parentId,
            clearParent: parentId == null,
          )
        else
          n,
    ];
    notifyListeners();
    await repository.saveOutline(notebookId, outline);
  }

  Future<void> importOutlineTitle(String title) async {
    await addOutlineNode(title: title);
  }

  Future<List<ImportableChapter>> loadPreviousClassChapters() async {
    final current = notebook;
    final schoolClass = current?.schoolClass;
    if (schoolClass == null || schoolClass <= 1) return [];
    final previous = schoolClass - 1;
    final notebooks = await repository.getNotebooks();
    final candidates = notebooks.where((n) {
      if (n.id == notebookId) return false;
      if (n.schoolClass != previous) return false;
      if (current?.folderId != null && n.folderId != current!.folderId) {
        return false;
      }
      return true;
    });
    final result = <ImportableChapter>[];
    final seen = <String>{};
    for (final nb in candidates) {
      final nodes = await repository.getOutline(nb.id);
      for (final node in nodes.where((n) => n.depth == 0)) {
        final key = node.title.trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        result.add(
          ImportableChapter(
            title: node.title,
            sourceNotebookTitle: nb.title,
            sourceNode: node,
          ),
        );
      }
    }
    result.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return result;
  }

  Future<void> jumpToOutline(OutlineNode node) async {
    if (node.pageId == null) return;
    final idx = pages.indexWhere((p) => p.id == node.pageId);
    if (idx >= 0) await selectPage(idx);
  }

  Future<void> addTag(String label) async {
    final tag = NoteTag.create(notebookId: notebookId, label: label.trim());
    await repository.saveTag(tag);
    tags = await repository.getTags(notebookId: notebookId);
    notifyListeners();
  }

  void _startSelectionMove(Offset pagePoint) {
    _lassoDragStart = pagePoint;
    _lassoAccum = Offset.zero;
    _lassoBeforeMove = List.of(ink.strokes);
  }

  void applyColorToSelection(int value) {
    ink.setColor(value);
    var changed = false;
    if (ink.selectedIds.isNotEmpty) {
      ink.recolorSelected(value);
      changed = true;
    }
    if (selectedShapeIds.isNotEmpty) {
      shapes = [
        for (final s in shapes)
          if (selectedShapeIds.contains(s.id))
            s.copyWith(colorValue: value)
          else
            s,
      ];
      changed = true;
    }
    if (selectedTextIds.isNotEmpty) {
      textBlocks = [
        for (final b in textBlocks)
          if (selectedTextIds.contains(b.id) && b.isSticky)
            b.copyWith(fillColor: value)
          else
            b,
      ];
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _scheduleSave();
    }
  }

  /// Tap / right-click hit test used even when the lasso tool is not active.
  ///
  /// Overlay widgets (stickies, images, stickers) usually consume the pointer
  /// first; this path covers strokes and shapes, and is a fallback for overlays.
  bool trySelectAt(
    Offset pagePoint, {
    required bool beginMove,
    bool onlyExisting = false,
  }) {
    if (interactionMode == InteractionMode.read) return false;

    if (hasLassoSelection && _lassoSelectionContains(pagePoint)) {
      if (beginMove) _startSelectionMove(pagePoint);
      return true;
    }
    if (onlyExisting) return false;

    for (final block in textBlocks.reversed) {
      if (block.layoutMode == TextLayoutMode.lineBound) continue;
      final page = currentPage;
      if (page == null) break;
      final bounds = textBlockBounds(
        block: block,
        metrics: _metricsForPage(page),
      );
      if (bounds.inflate(14).contains(pagePoint)) {
        selectText(block.id);
        if (beginMove) _startSelectionMove(pagePoint);
        return true;
      }
    }
    for (final sticker in stickers.reversed) {
      if (sticker.bounds.inflate(8).contains(pagePoint)) {
        selectSticker(sticker.id);
        if (beginMove) _startSelectionMove(pagePoint);
        return true;
      }
    }
    for (final image in images.reversed) {
      if (image.bounds.inflate(8).contains(pagePoint)) {
        selectImage(image.id);
        if (beginMove) _startSelectionMove(pagePoint);
        return true;
      }
    }
    for (final shape in shapes.reversed) {
      if (_shapeHits(shape, pagePoint, 10)) {
        selectedTextId = null;
        editingTextId = null;
        selectedImageId = null;
        selectedStickerId = null;
        selectedTextIds = {};
        selectedImageIds = {};
        selectedStickerIds = {};
        selectedShapeIds = {shape.id};
        ink.selectIds({});
        if (beginMove) _startSelectionMove(pagePoint);
        notifyListeners();
        return true;
      }
    }
    final stroke = ink.strokeAt(pagePoint);
    if (stroke != null) {
      selectedTextId = null;
      editingTextId = null;
      selectedImageId = null;
      selectedStickerId = null;
      selectedTextIds = {};
      selectedImageIds = {};
      selectedStickerIds = {};
      selectedShapeIds = {};
      ink.selectIds({stroke.id});
      if (beginMove) _startSelectionMove(pagePoint);
      notifyListeners();
      return true;
    }
    return false;
  }

  void onPointerDown(
    Offset pagePoint, {
    required bool isStylus,
    double pressure = 0.5,
  }) {
    if (interactionMode == InteractionMode.read) return;

    // A miss: drop the current object selection, then start the active tool.
    if (hasLassoSelection ||
        selectedTextId != null ||
        selectedImageId != null ||
        selectedStickerId != null) {
      clearLassoSelection();
    }

    if (ink.tool == InkTool.text) {
      if (textLayoutMode == TextLayoutMode.lineBound) {
        // Once present, the page document's full writing column receives the
        // pointer and calculates its own caret. Avoid a controller rebuild
        // here so that native TextField selection remains precise.
        final hasDocument = textBlocks.any(
          (block) => block.layoutMode == TextLayoutMode.lineBound,
        );
        if (!hasDocument) {
          addTextBlock(mode: TextLayoutMode.lineBound);
        }
        return;
      }
      // Touches on existing free text belong to that block's own drag handling.
      if (textBlockAt(pagePoint) == null) addTextBlock(at: pagePoint);
      return;
    }
    if (ink.tool == InkTool.image || ink.tool == InkTool.sticker) {
      return;
    }
    if (ink.tool == InkTool.shape) {
      _shapeStart = pagePoint;
      draftShape = ShapeElement.create(
        pageId: currentPage!.id,
        kind: shapeKind,
        x1: pagePoint.dx,
        y1: pagePoint.dy,
        x2: pagePoint.dx,
        y2: pagePoint.dy,
        colorValue: ink.colorValue,
        strokeWidth: ink.width,
        style: ink.strokeStyle.name,
      );
      notifyListeners();
      return;
    }
    _shapeHoldTimer?.cancel();
    _convertedByHold = false;
    ink.beginStroke(pagePoint, pressure: pressure);
    if (ink.tool == InkTool.eraser) {
      _erasePageObjects(pagePoint);
    }
  }

  void onPointerMove(Offset pagePoint, {double pressure = 0.5}) {
    if (interactionMode == InteractionMode.read) return;

    if (_shapeStart != null && draftShape != null) {
      var end = pagePoint;
      if (draftShape!.kind == ShapeKind.line) {
        end = snapRulerEndpoint(_shapeStart!, pagePoint);
      }
      draftShape = draftShape!.copyWith(x2: end.dx, y2: end.dy);
      notifyListeners();
      return;
    }
    if (_lassoDragStart != null && hasLassoSelection) {
      final delta = pagePoint - _lassoDragStart! - _lassoAccum;
      if (delta.distance > 0) {
        ink.moveSelected(delta);
        _moveLassoObjects(delta);
        _lassoAccum += delta;
      }
      return;
    }
    ink.appendStroke(pagePoint, pressure: pressure);
    if (ink.tool == InkTool.eraser) {
      _erasePageObjects(pagePoint);
    }
    _armShapeHold();
  }

  void _armShapeHold() {
    _shapeHoldTimer?.cancel();
    if (!ink.tool.isFreehand) return;
    if (ink.activeStroke == null) return;
    _shapeHoldTimer = Timer(kLongPressTimeout, _tryHoldRecognize);
  }

  void _tryHoldRecognize() {
    if (_disposed) return;
    if (_beginRecognizedShapePreview()) {
      _convertedByHold = true;
    }
  }

  /// Snap the in-progress stroke to a draft shape. Pointer-up commits it;
  /// further movement resizes from the anchor (same as the shape tool).
  bool _beginRecognizedShapePreview() {
    final page = currentPage;
    final stroke = ink.activeStroke;
    if (page == null || stroke == null || !ink.tool.isFreehand) return false;
    if (stroke.points.length < 5) return false;
    final pointer = stroke.points.last.offset;
    final shape = ShapeRecognition.recognize(
      stroke.points,
      pageId: page.id,
      colorValue: stroke.colorValue,
      strokeWidth: stroke.width,
      style: stroke.style,
      loose: true,
    );
    if (shape == null) return false;
    ink.cancelStroke();
    final preview = _resizeAnchorForPointer(shape, pointer);
    _shapeStart = preview.$1;
    draftShape = preview.$2;
    notifyListeners();
    return true;
  }

  /// Anchor stays put; the live pointer becomes the opposite corner / end / radius.
  (Offset, ShapeElement) _resizeAnchorForPointer(
    ShapeElement shape,
    Offset pointer,
  ) {
    switch (shape.kind) {
      case ShapeKind.circle:
        return (
          Offset(shape.x1, shape.y1),
          shape.copyWith(x2: pointer.dx, y2: pointer.dy),
        );
      case ShapeKind.line:
      case ShapeKind.arrow:
        return (
          Offset(shape.x1, shape.y1),
          shape.copyWith(x2: pointer.dx, y2: pointer.dy),
        );
      case ShapeKind.rect:
      case ShapeKind.ellipse:
        final a = Offset(shape.x1, shape.y1);
        final b = Offset(shape.x2, shape.y2);
        final corners = <Offset>[
          a,
          Offset(b.dx, a.dy),
          b,
          Offset(a.dx, b.dy),
        ];
        var farthest = corners.first;
        var best = -1.0;
        for (final corner in corners) {
          final d = (corner - pointer).distance;
          if (d > best) {
            best = d;
            farthest = corner;
          }
        }
        return (
          farthest,
          shape.copyWith(
            x1: farthest.dx,
            y1: farthest.dy,
            x2: pointer.dx,
            y2: pointer.dy,
          ),
        );
    }
  }

  void onPointerUp() {
    if (interactionMode == InteractionMode.read) return;
    _shapeHoldTimer?.cancel();
    if (_convertedByHold) {
      _convertedByHold = false;
    }

    if (_shapeStart != null && draftShape != null) {
      final shape = draftShape!;
      final commit = shape.kind == ShapeKind.circle
          ? (Offset(shape.x2 - shape.x1, shape.y2 - shape.y1).distance > 4)
          : ((shape.x2 - shape.x1).abs() > 4 ||
                (shape.y2 - shape.y1).abs() > 4);
      if (commit) {
        shapes = [...shapes, shape];
        _scheduleSave();
      }
      draftShape = null;
      _shapeStart = null;
      notifyListeners();
      return;
    }
    if (_lassoDragStart != null) {
      if (_lassoAccum != Offset.zero) {
        if (_lassoBeforeMove != null && ink.selectedIds.isNotEmpty) {
          ink.commitSelectionMove(_lassoBeforeMove!);
        }
        _scheduleSave();
      }
      _lassoDragStart = null;
      _lassoAccum = Offset.zero;
      _lassoBeforeMove = null;
      return;
    }
    // Shape snap is hold-only (same duration as a toolbar long-press).
    ink.endStroke();
    if (ink.tool == InkTool.lasso) {
      _selectObjectsInLasso(ink.lastClosedLasso);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    _shapeHoldTimer?.cancel();
    ink.removeListener(_onInkChanged);
    drawingAids.removeListener(_onAidsChanged);
    unawaited(_persistCurrent());
    backgroundImage?.dispose();
    textRegistry.disposeAll();
    ink.pointConstraint = null;
    ink.dispose();
    drawingAids.dispose();
    super.dispose();
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.notebookId,
    this.initialPageId,
    this.initialOutlineId,
  });

  final String notebookId;
  final String? initialPageId;
  final String? initialOutlineId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  final _pagesViewportKey = GlobalKey<NotebookPagesViewportState>();
  final _canvasKey = GlobalKey<InkCanvasState>();
  bool _sidebarOpen = false;
  int _handledLanEventSeq = 0;
  int _lastClassroomProgress = -1;
  bool _autoConnectPromptScheduled = false;
  String? _dismissedPickKey;
  bool _toolWheelOpen = false;
  InkTool _previousTool = InkTool.pen;
  StreamSubscription<PencilHardwareEvent>? _pencilSub;
  String? _nearbyOpenedId;
  bool _calcOpen = false;
  bool _calcPinned = false;
  bool _bookOpen = false;
  bool _bookPinned = false;
  bool _assistantOpen = false;
  bool _assistantPinned = false;
  String? _toolPageId;
  String? _bookChapterId;
  int _editorTourIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pencilSub = PencilGestures.events.listen(_onPencilHardware);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(openNotebookTabsProvider.notifier).open(widget.notebookId);
    });
  }

  @override
  void dispose() {
    unawaited(_pencilSub?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    final assignment = ref.read(studentAssignmentProvider);
    if (assignment.active && assignment.testMode && !assignment.submitted) {
      unawaited(ref.read(studentAssignmentProvider.notifier).leave('notebook'));
    }
    unawaited(ref.read(lanSyncProvider).onNotebookClosed(widget.notebookId));
    super.dispose();
  }

  void _onPencilHardware(PencilHardwareEvent event) {
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    final action = switch (event) {
      PencilHardwareEvent.doubleTap => settings.pencilDoubleTapAction,
      PencilHardwareEvent.squeeze => settings.pencilSqueezeAction,
    };
    unawaited(_runGestureAction(action));
  }

  EditorController get _controller => ref.read(
    editorControllerDeepLinkProvider((
      id: widget.notebookId,
      pageId: widget.initialPageId,
      outlineId: widget.initialOutlineId,
    )),
  );

  String _folderPath(List<LibraryFolder> folders, String? folderId) {
    if (folderId == null) return '';
    final byId = {for (final f in folders) f.id: f};
    final parts = <String>[];
    var current = byId[folderId];
    final seen = <String>{};
    while (current != null && seen.add(current.id)) {
      parts.add(current.name);
      current = current.parentId == null ? null : byId[current.parentId];
    }
    return parts.reversed.join('/');
  }

  void _closeEditorTools() {
    if (!_calcOpen && !_bookOpen && !_assistantOpen) return;
    setState(() {
      _calcOpen = false;
      _bookOpen = false;
      _assistantOpen = false;
      _calcPinned = false;
      _bookPinned = false;
      _assistantPinned = false;
      _toolPageId = null;
    });
  }

  void _dismissUnpinnedTools() {
    if ((_calcOpen && !_calcPinned) ||
        (_bookOpen && !_bookPinned) ||
        (_assistantOpen && !_assistantPinned)) {
      setState(() {
        if (!_calcPinned) _calcOpen = false;
        if (!_bookPinned) _bookOpen = false;
        if (!_assistantPinned) _assistantOpen = false;
        if (!_calcOpen && !_bookOpen && !_assistantOpen) {
          _toolPageId = null;
          _calcPinned = false;
          _bookPinned = false;
          _assistantPinned = false;
        }
      });
    }
  }

  void _openCalculator(EditorController controller, {bool forceOpen = false}) {
    final opening = forceOpen ? true : !_calcOpen;
    setState(() {
      _calcOpen = opening;
      if (_calcOpen) {
        _calcPinned = false;
        _toolPageId = controller.currentPage?.id;
      } else if (!_bookOpen && !_assistantOpen) {
        _toolPageId = null;
        _calcPinned = false;
      }
    });
    if (opening && mounted) {
      unawaited(
        maybeShowFeatureHint(context, ref, FeatureHintId.calculator),
      );
    }
  }

  void _openFormulaBook(
    EditorController controller, {
    String? chapterId,
    bool forceOpen = false,
  }) {
    if (_bookOpen && !forceOpen && chapterId == null) {
      setState(() {
        _bookOpen = false;
        _bookPinned = false;
        if (!_calcOpen && !_assistantOpen) _toolPageId = null;
      });
      return;
    }
    final plus = ref.read(entitlementProvider).hasAccess(FeatureKeys.formulaPack);
    final store = FormulaBookStore(ref.read(sharedPreferencesProvider));
    final book = store.load(plus: plus);
    final last = store.lastChapterFor(controller.notebookId);
    final folders = ref.read(allFoldersProvider).valueOrNull ?? const [];
    final matched = FormulaBookStore.matchChapterId(
      book: book,
      subjectKey: controller.notebook?.subjectKey,
      folderPath: _folderPath(folders, controller.notebook?.folderId),
    );
    var resolved = chapterId ?? last ?? matched;
    if (resolved != null && book.byId(resolved) == null) {
      if (resolved == 'analysis') {
        resolved = book.byId('funktionen')?.id ?? book.byId('mathematik')?.id;
      } else {
        resolved = book.byId('mathematik')?.id ?? book.chapters.firstOrNull?.id;
      }
    }
    if (resolved != null) {
      unawaited(store.setLastChapter(controller.notebookId, resolved));
    }
    setState(() {
      _bookOpen = true;
      _bookPinned = false;
      _bookChapterId = resolved;
      _toolPageId = controller.currentPage?.id;
    });
    if (mounted) {
      unawaited(
        maybeShowFeatureHint(context, ref, FeatureHintId.formulaBook),
      );
    }
  }

  void _handleEditorBack(EditorController controller) {
    if (controller.presentationMode) {
      controller.togglePresentationMode();
      return;
    }
    if (_toolWheelOpen) {
      setState(() => _toolWheelOpen = false);
      return;
    }
    if ((_calcOpen && !_calcPinned) ||
        (_bookOpen && !_bookPinned) ||
        (_assistantOpen && !_assistantPinned)) {
      _dismissUnpinnedTools();
      return;
    }
    if (_sidebarOpen) {
      setState(() => _sidebarOpen = false);
      return;
    }
    final assignment = ref.read(studentAssignmentProvider);
    final examLock =
        assignment.active && assignment.testMode && !assignment.submitted;
    if (examLock) {
      unawaited(ref.read(studentAssignmentProvider.notifier).leave('home'));
    }
    refreshLibraryLists(ref);
    if (mounted) context.go('/');
  }

  Future<void> _deleteCurrentPage(
    BuildContext context,
    EditorController controller,
    AppLocalizations l10n,
  ) async {
    if (controller.pages.length <= 1) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.lastPageHint)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePageTitle),
        content: Text(l10n.deletePageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await controller.deletePage(controller.pageIndex);
  }

  Future<void> _scanAndInsert(EditorController controller) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await maybeShowFeatureHint(context, ref, FeatureHintId.scanImport);
      if (!mounted) return;
      final paths = await const DocumentScannerService().scanPages();
      if (paths.isEmpty) return;
      if (!mounted) return;
      final mode = await showImageImportChoice(context);
      if (mode == null || !mounted) return;
      if (mode == ImageImportMode.asPage) {
        final added = await controller.importScannedImages(paths);
        if (!mounted || added == 0) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.scanAddedPages(added))));
      } else {
        final added = await controller.insertImagesFromPaths(paths);
        if (!mounted || added == 0) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.imagesInserted(added))));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scanFailed)));
    }
  }

  Future<void> _importImages(EditorController controller) async {
    await maybeShowFeatureHint(context, ref, FeatureHintId.scanImport);
    if (!mounted) return;
    final mode = await showImageImportChoice(context);
    if (mode == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (mode == ImageImportMode.asPage) {
      final added = await controller.pickAndImportImages(asPages: true);
      if (!mounted || added == 0) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.scanAddedPages(added))));
    } else {
      final added = await controller.pickAndImportImages(asPages: false);
      if (!mounted || added == 0) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.imagesInserted(added))));
    }
  }

  Future<void> _importHtml(
    BuildContext context,
    EditorController controller,
    AppLocalizations l10n,
  ) async {
    await maybeShowFeatureHint(context, ref, FeatureHintId.htmlImport);
    if (!context.mounted) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm', 'xhtml'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await createFileStore().readBytes(file.path!);
    }
    if (bytes == null) return;
    try {
      await controller.persistForSearchIndex();
      final imported = await ref.read(importPipelineProvider).importFile(
        notebookId: widget.notebookId,
        file: InboxFile(
          path: file.path ?? file.name,
          name: file.name,
          bytes: bytes,
          mimeType: 'text/html',
        ),
      );
      await controller.reloadFromRemote(pageId: imported.firstPageId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.htmlImported(imported.pageIds.length))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.htmlImportFailed)));
    }
  }

  List<AppTourStep> _editorTourSteps(AppLocalizations l10n) {
    return [
      AppTourStep(
        title: l10n.editorTourWelcomeTitle,
        body: l10n.editorTourWelcomeBody,
      ),
      AppTourStep(title: l10n.editorTourToolsTitle, body: l10n.editorTourToolsBody),
      AppTourStep(title: l10n.editorTourPagesTitle, body: l10n.editorTourPagesBody),
      AppTourStep(
        title: l10n.editorTourImportTitle,
        body: l10n.editorTourImportBody,
      ),
      AppTourStep(
        title: l10n.editorTourAssistTitle,
        body: l10n.editorTourAssistBody,
      ),
    ];
  }

  void _openAssistant(EditorController controller) {
    final opening = !_assistantOpen;
    setState(() {
      _assistantOpen = opening;
      if (_assistantOpen) {
        _assistantPinned = false;
        _toolPageId = controller.currentPage?.id;
      } else if (!_calcOpen && !_bookOpen) {
        _toolPageId = null;
        _assistantPinned = false;
      }
    });
    if (opening && mounted) {
      unawaited(maybeShowFeatureHint(context, ref, FeatureHintId.assistant));
    }
  }

  Future<bool> _insertFunctionPlot(
    EditorController controller,
    String expression, {
    required bool degrees,
  }) async {
    final bytes = await showGraphStudioSheet(
      context,
      initialExpression: expression,
      degrees: degrees,
      formulaStore: FormulaBookStore(ref.read(sharedPreferencesProvider)),
    );
    if (!mounted) return true;
    if (bytes == null) return true;
    await controller.insertPngBytes(bytes, width: 390, height: 260);
    return true;
  }

  Future<void> _useFormulaInGraph(
    EditorController controller,
    String expression,
  ) async {
    if (!_calcOpen) {
      setState(() {
        _calcOpen = true;
        _calcPinned = false;
        _toolPageId = controller.currentPage?.id;
      });
    }
    await _insertFunctionPlot(controller, expression, degrees: true);
  }

  Future<void> _createDiagram(EditorController controller) async {
    final bytes = await showChartBuilderSheet(
      context,
      chartPack: ref.read(entitlementProvider).hasAccess(FeatureKeys.chartPack),
      helperPack: ref
          .read(entitlementProvider)
          .hasAccess(FeatureKeys.helperPack),
    );
    if (bytes == null || !mounted) return;
    await controller.insertPngBytes(bytes, width: 360, height: 240);
  }

  Future<void> _openPacks(EditorController controller) async {
    final bytes = await showPackStudioSheet(
      context,
      notebookId: widget.notebookId,
    );
    if (bytes == null || !mounted) return;
    await controller.insertPngBytes(bytes, width: 390, height: 240);
  }

  Future<void> _runGestureAction(EditorGestureAction action) async {
    if (action == EditorGestureAction.none) return;
    final c = _controller;

    switch (action) {
      case EditorGestureAction.none:
        return;
      case EditorGestureAction.toggleEraser:
        if (c.ink.tool == InkTool.eraser) {
          c.ink.setTool(_previousTool);
        } else {
          _previousTool = c.ink.tool.isFreehand ? c.ink.tool : InkTool.pen;
          c.ink.setTool(InkTool.eraser);
        }
      case EditorGestureAction.previousTool:
        final next = _previousTool;
        _previousTool = c.ink.tool;
        c.ink.setTool(next);
      case EditorGestureAction.openToolWheel:
        setState(() => _toolWheelOpen = !_toolWheelOpen);
      case EditorGestureAction.undo:
        c.ink.undo();
      case EditorGestureAction.redo:
        c.ink.redo();
      case EditorGestureAction.nextPage:
        if (c.interactionMode == InteractionMode.read) return;
        _pagesViewportKey.currentState?.goToAdjacent(1);
      case EditorGestureAction.previousPage:
        if (c.interactionMode == InteractionMode.read) return;
        _pagesViewportKey.currentState?.goToAdjacent(-1);
      case EditorGestureAction.exportPage:
        await c.shareCurrentPage();
      case EditorGestureAction.cyclePenColor:
        final presets = ref.read(toolPresetsProvider);
        if (presets.colors.isEmpty) return;
        final idx = presets.colors.indexOf(c.ink.colorValue);
        final next = presets.colors[(idx + 1) % presets.colors.length];
        c.ink.setColor(next);
      case EditorGestureAction.fitZoom:
        _canvasKey.currentState?.fitToViewport();
      case EditorGestureAction.goBack:
        _handleEditorBack(c);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final assignment = ref.read(studentAssignmentProvider);
    if (assignment.active &&
        assignment.testMode &&
        !assignment.submitted &&
        state != AppLifecycleState.resumed) {
      unawaited(ref.read(studentAssignmentProvider.notifier).leave('pause'));
    }
    final lan = ref.read(lanSyncProvider);
    if (lan.role != LanSyncRole.guest ||
        !lan.classroomFocusCheckEnabled ||
        !lan.classroomFocusConsent ||
        !lan.isActive) {
      return;
    }
    final focused = state == AppLifecycleState.resumed;
    unawaited(lan.sendClassroomSignal('focus', focused));
  }

  Future<void> _offerClassroomAutoConnect(LanSyncController lan) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(ClassroomAutoConnect.askedKey) == true || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final criteria = [
      if (lan.classroomSubject?.isNotEmpty == true) lan.classroomSubject!,
      if (lan.classroomRoom?.isNotEmpty == true) lan.classroomRoom!,
    ].join(' · ');
    final enabled = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.classroomAutoConnectTitle),
        content: Text(l10n.classroomAutoConnectBody(criteria)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.enable),
          ),
        ],
      ),
    );
    if (enabled == true) {
      await ClassroomAutoConnect.enable(
        prefs,
        subject: lan.classroomSubject,
        room: lan.classroomRoom,
      );
      ref.read(classroomAutoConnectEnabledProvider.notifier).state = true;
    } else {
      await ClassroomAutoConnect.decline(prefs);
      ref.read(classroomAutoConnectEnabledProvider.notifier).state = false;
    }
  }

  Future<void> _pickSticker(EditorController controller) async {
    controller.ink.setTool(InkTool.sticker);
    final sticker = await showStickerPicker(context);
    if (sticker == null || !mounted) return;
    controller.insertSticker(sticker.id);
  }

  Future<void> _renamePage(EditorController controller, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final page = controller.pages[index];
    final field = TextEditingController(text: page.title ?? '');
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renamePage),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.pageNameHint),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, field.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    field.dispose();
    if (next == null) return;
    await controller.renamePage(index, next);
  }

  Future<void> _addPage(EditorController controller) async {
    if (!controller.currentPageHasImportedBackground) {
      await controller.addPage();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importedPageTemplateTitle),
        content: Text(l10n.importedPageTemplateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.useNotebookDefault),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.keepCurrentTemplate),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await controller.addPage(
      useNotebookDefault: !choice,
      keepImportedBackground: choice,
    );
  }

  Future<void> _handleShareAction(
    BuildContext context,
    EditorController controller,
    ShareExportAction action,
  ) async {
    switch (action) {
      case ShareExportAction.printPdf:
        await controller.exportPdf();
      case ShareExportAction.sharePdf:
        await controller.sharePdf();
      case ShareExportAction.shareCurrentPage:
        await controller.shareCurrentPage();
      case ShareExportAction.sharePageAsImage:
        final nb = controller.notebook;
        if (nb == null) return;
        await ref
            .read(exportServiceProvider)
            .sharePageAsImage(
              notebook: nb,
              pages: controller.pages,
              pageIndex: controller.pageIndex,
            );
      case ShareExportAction.indexHandwriting:
        final page = controller.currentPage;
        if (page == null) return;
        await controller.persistForSearchIndex();
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.marketplaceInkOcrHint)));
      case ShareExportAction.savePageAsTemplate:
        final page = controller.currentPage;
        if (page == null) return;
        final result = await showSavePageAsTemplateDialog(
          context: context,
          page: page,
          currentPaper: controller.activePaper,
        );
        if (result == null) return;
        await controller.saveCurrentPageAsTemplate(result.template);
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.templateSaved)));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      editorControllerDeepLinkProvider((
        id: widget.notebookId,
        pageId: widget.initialPageId,
        outlineId: widget.initialOutlineId,
      )),
    );
    final tabs = ref.watch(openNotebookTabsProvider);
    final browseMode = ref.watch(settingsProvider).pageBrowseMode;
    final lan = ref.watch(lanSyncProvider);
    final notebook = controller.notebook;
    if (!controller.loading &&
        notebook != null &&
        _nearbyOpenedId != notebook.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _nearbyOpenedId == notebook.id) return;
        _nearbyOpenedId = notebook.id;
        unawaited(ref.read(lanSyncProvider).onNotebookOpened(notebook));
      });
    }

    controller.onPagePersisted = (page) {
      unawaited(ref.read(lanSyncProvider).noteLocalPageSaved(page));
    };
    controller.onPageDeleted = (pageId) {
      unawaited(
        ref
            .read(lanSyncProvider)
            .noteLocalPageDeleted(
              pageId: pageId,
              notebookId: widget.notebookId,
            ),
      );
    };

    ref.listen<LanSyncController>(lanSyncProvider, (previous, next) {
      final event = next.lastEvent;
      if (event == null || next.eventSeq == _handledLanEventSeq) return;
      _handledLanEventSeq = next.eventSeq;
      if (event.notebookId != null && event.notebookId != widget.notebookId) {
        return;
      }
      if (event.kind == LanSyncEventKind.pageUpdated ||
          event.kind == LanSyncEventKind.snapshotApplied ||
          event.kind == LanSyncEventKind.notebookUpdated) {
        unawaited(controller.reloadFromRemote(pageId: event.pageId));
      }
    });

    if (controller.loading) {
      return Scaffold(
        backgroundColor: EditorChrome.workspace,
        body: Center(
          child: CircularProgressIndicator(color: EditorChrome.onDark),
        ),
      );
    }
    if (controller.error != null) {
      return Scaffold(
        backgroundColor: EditorChrome.workspace,
        appBar: AppBar(backgroundColor: EditorChrome.topBar),
        body: Center(
          child: Text(
            controller.error == 'notebook_locked'
                ? AppLocalizations.of(context)!.accountNotebookLocked
                : controller.error!,
            style: TextStyle(color: EditorChrome.onDark),
          ),
        ),
      );
    }

    final page = controller.currentPage!;
    if ((_calcOpen || _bookOpen) &&
        _toolPageId != null &&
        page.id != _toolPageId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _closeEditorTools();
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final reading = controller.interactionMode == InteractionMode.read;
    final classroomGuest =
        lan.role == LanSyncRole.guest && lan.phase == LanSyncPhase.connected;
    final classroomLocked = classroomGuest && !lan.classroomCanWrite;
    final readOnly = reading || classroomLocked;
    if (classroomGuest &&
        lan.classroomMode &&
        !_autoConnectPromptScheduled &&
        (lan.classroomSubject?.isNotEmpty == true ||
            lan.classroomRoom?.isNotEmpty == true)) {
      _autoConnectPromptScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_offerClassroomAutoConnect(lan));
      });
    }
    if (classroomGuest && controller.pages.isNotEmpty) {
      final progress =
          (((controller.pageIndex + 1) / controller.pages.length) * 100)
              .round();
      if (progress != _lastClassroomProgress) {
        _lastClassroomProgress = progress;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(
              ref
                  .read(lanSyncProvider)
                  .sendClassroomSignal('progress', progress),
            );
          }
        });
      }
    }
    final presenting = controller.presentationMode;
    final assignment = ref.watch(studentAssignmentProvider);
    final examLock =
        assignment.active && assignment.testMode && !assignment.submitted;
    final studying = controller.studyMode || examLock;
    final hideInk = studying && !controller.studyInkRevealed;
    final canvasMode = controller.notebook?.canvasMode ?? CanvasMode.page;

    final editingText =
        !readOnly &&
        !presenting &&
        !studying &&
        controller.selectedTextId != null;
    TextBlock? textFormatTarget;
    if (editingText && controller.selectedTextId != null) {
      for (final block in controller.textBlocks) {
        if (block.id == controller.selectedTextId) {
          textFormatTarget = block;
          break;
        }
      }
    }
    final textFormatController = textFormatTarget == null
        ? null
        : controller.textRegistry.find(textFormatTarget.id);

    final workspace = Stack(
      children: [
        Positioned.fill(
          child: Row(
            children: [
              if (_sidebarOpen && !presenting)
                PageSidebar(
                  pages: controller.pages,
                  currentIndex: controller.pageIndex,
                  onSelect: controller.selectPage,
                  onAdd: () => _addPage(controller),
                  onDuplicate: controller.duplicatePage,
                  onDelete: controller.deletePage,
                  onRename: (index) => _renamePage(controller, index),
                  onClose: () => setState(() => _sidebarOpen = false),
                ),
              Expanded(
                child: NotebookPagesViewport(
                  key: _pagesViewportKey,
                  pages: controller.pages,
                  pageIndex: controller.pageIndex,
                  browseMode: browseMode,
                  canvasMode: canvasMode,
                  readOnly: readOnly,
                  navigationLocked: reading,
                  onPageChanged: controller.selectPage,
                  onReachEnd: () => _addPage(controller),
                  onFlipStart: controller.syncActivePageMemory,
                  activePageBuilder: (context, index) {
                    final metrics = PaperLineMetrics.from(
                      paper: controller.activePaper,
                      template: page.template,
                      pageSize: NotePageSize.resolve(
                        page.paperFormat,
                        page.orientation,
                      ),
                    );
                    return InkCanvas(
                      key: index == controller.pageIndex ? _canvasKey : null,
                      pageId: page.id,
                      engine: controller.ink,
                      template: page.template,
                      pageSize: NotePageSize.resolve(
                        page.paperFormat,
                        page.orientation,
                      ),
                      backgroundImage: controller.backgroundImage,
                      paper: controller.activePaper,
                      canvasMode: canvasMode,
                      browseMode: browseMode,
                      // Read/study: fingers always browse. Otherwise honour
                      // the setting so mouse / finger can still write on
                      // desktop and phones (default is off).
                      fingerPanZoom:
                          readOnly || studying || controller.fingerPanZoom,
                      readOnly: readOnly || presenting || studying,
                      hideInk: hideInk,
                      onDoubleTap: presenting
                          ? controller.togglePresentationMode
                          : studying
                          ? controller.toggleStudyInkReveal
                          : null,
                      onBrowsePan: (delta) =>
                          _pagesViewportKey.currentState?.handleBrowsePan(
                            delta,
                          ) ??
                          false,
                      onBrowsePanEnd: () =>
                          _pagesViewportKey.currentState?.handleBrowsePanEnd(),
                      onScrollLockChanged: (locked) =>
                          _pagesViewportKey.currentState?.setScrollLock(locked),
                      onZoomedChanged: (zoomed) =>
                          _pagesViewportKey.currentState?.setZoomed(zoomed),
                      onTwoFingerTap: () => unawaited(
                        _runGestureAction(
                          ref.read(settingsProvider).twoFingerTapAction,
                        ),
                      ),
                      onThreeFingerSwipe: (dir) => unawaited(
                        _runGestureAction(
                          dir < 0
                              ? ref
                                    .read(settingsProvider)
                                    .threeFingerSwipeLeftAction
                              : ref
                                    .read(settingsProvider)
                                    .threeFingerSwipeRightAction,
                        ),
                      ),
                      onTrySelect: (point, {required beginMove, onlyExisting = false}) {
                        _dismissUnpinnedTools();
                        return controller.trySelectAt(
                          point,
                          beginMove: beginMove,
                          onlyExisting: onlyExisting,
                        );
                      },
                      onPointerDown:
                          (point, {required isStylus, pressure = 0.5}) {
                            _dismissUnpinnedTools();
                            controller.onPointerDown(
                              point,
                              isStylus: isStylus,
                              pressure: pressure,
                            );
                          },
                      onPointerMove: controller.onPointerMove,
                      onPointerUp: controller.onPointerUp,
                      overlay: OverlayHitStack(
                        fit: StackFit.expand,
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ShapePainter(
                                  shapes: controller.shapes,
                                  draft: controller.draftShape,
                                ),
                              ),
                            ),
                          ),
                          if (controller.hasLassoSelection)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _LassoObjectHighlightPainter(
                                    shapes: [
                                      for (final s in controller.shapes)
                                        if (controller.selectedShapeIds
                                            .contains(s.id))
                                          s.bounds,
                                    ],
                                    images: [
                                      for (final i in controller.images)
                                        if (controller.selectedImageIds
                                            .contains(i.id))
                                          i.bounds,
                                    ],
                                    texts: [
                                      for (final b in controller.textBlocks)
                                        if (controller.selectedTextIds.contains(
                                          b.id,
                                        ))
                                          textBlockBounds(
                                            block: b,
                                            metrics: metrics,
                                          ),
                                    ],
                                    stickers: [
                                      for (final s in controller.stickers)
                                        if (controller.selectedStickerIds
                                            .contains(s.id))
                                          s.bounds,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (controller.drawingAids.ruler != null)
                            RulerOverlay(
                              aid: controller.drawingAids.ruler!,
                              readOnly: readOnly || presenting,
                              onChanged: controller.drawingAids.updateRuler,
                              onToggleFixed: () =>
                                  controller.drawingAids.setRulerFixed(
                                    !controller.drawingAids.ruler!.fixed,
                                  ),
                            ),
                          if (controller.drawingAids.hasVisibleCompass)
                            CompassOverlay(
                              aid: controller.drawingAids.compass!,
                              pageSize: NotePageSize.resolve(
                                page.paperFormat,
                                page.orientation,
                              ),
                              readOnly: readOnly || presenting,
                              onChanged: controller.drawingAids.updateCompass,
                              onToggleFixed: () =>
                                  controller.drawingAids.setCompassFixed(
                                    !controller.drawingAids.compass!.fixed,
                                  ),
                            ),
                          Positioned.fill(
                            child: PageMetaOverlay(
                              page: page,
                              pageNumber: index + 1,
                            ),
                          ),
                          IgnorePointer(
                            ignoring: readOnly || presenting,
                            child: ImageElementsLayer(
                              images: controller.images,
                              selectedId: controller.selectedImageId,
                              editable: !readOnly && !presenting,
                              onSelect: controller.selectImage,
                              onChanged: controller.updateImage,
                              onDelete: controller.deleteImage,
                            ),
                          ),
                          IgnorePointer(
                            ignoring: readOnly || presenting,
                            child: StickerLayer(
                              stickers: controller.stickers,
                              selectedId: controller.selectedStickerId,
                              editable: !readOnly && !presenting,
                              onSelect: controller.selectSticker,
                              onChanged: controller.updateSticker,
                              onDelete: controller.deleteSticker,
                            ),
                          ),
                          IgnorePointer(
                            ignoring: readOnly || presenting,
                            child: TextBlockLayer(
                              blocks: controller.textBlocks,
                              selectedId: controller.selectedTextId,
                              editingId: controller.editingTextId,
                              editable: !readOnly && !presenting,
                              pageTextEnabled:
                                  !readOnly &&
                                  !presenting &&
                                  controller.ink.tool == InkTool.text &&
                                  controller.textLayoutMode ==
                                      TextLayoutMode.lineBound,
                              metrics: metrics,
                              registry: controller.textRegistry,
                              onSelect: controller.selectText,
                              onBeginEdit: controller.beginTextEdit,
                              onChanged: controller.updateTextBlock,
                              onDelete: controller.deleteTextBlock,
                              onCaretPagePoint: (point) {
                                _canvasKey.currentState?.ensurePagePointVisible(
                                  point,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (!presenting) ...[
          Positioned(
            left: _sidebarOpen ? PageSidebar.width + 12 : 12,
            top: 58,
            child: UndoRedoPill(
              canUndo: controller.ink.canUndo,
              canRedo: controller.ink.canRedo,
              onUndo: controller.ink.undo,
              onRedo: controller.ink.redo,
            ),
          ),
          if (!studying)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: ToolOptionsBar(
                  engine: controller.ink,
                  shapeKind: controller.shapeKind,
                  textLayoutMode: controller.textLayoutMode,
                  onShapeKindChanged: controller.setShapeKind,
                  onTextLayoutModeChanged: controller.setTextLayoutMode,
                  onAddText: () => controller.addTextBlock(text: l10n.newText),
                  onDeleteText: controller.selectedTextId == null
                      ? null
                      : () {
                          final id = controller.selectedTextId;
                          final block = controller.textBlocks
                              .where((b) => b.id == id)
                              .firstOrNull;
                          if (block != null) controller.deleteTextBlock(block);
                        },
                  onAddSticky: () {
                    controller.setTextLayoutMode(TextLayoutMode.sticky);
                    controller.addTextBlock(
                      mode: TextLayoutMode.sticky,
                      text: '',
                    );
                  },
                  onPickImage: () => _importImages(controller),
                  onScanPages: () => _scanAndInsert(controller),
                  onPickSticker: () => _pickSticker(controller),
                  hasSelectedSticker: controller.selectedStickerId != null,
                  onDeleteSticker: controller.selectedStickerId == null
                      ? null
                      : () => controller.deleteSticker(
                          controller.selectedStickerId!,
                        ),
                  hasLassoSelection: controller.hasLassoSelection,
                  selectionCanRecolor: controller.selectionCanRecolor,
                  onDeleteSelection: controller.deleteLassoSelection,
                  onPickColor: controller.applyColorToSelection,
                  hasSelectedImage: controller.selectedImageId != null,
                  onDeleteImage: controller.selectedImageId == null
                      ? null
                      : () =>
                            controller.deleteImage(controller.selectedImageId!),
                  onToggleRuler: controller.toggleRulerAid,
                  onToggleCompass: controller.toggleCompassAid,
                  rulerActive: controller.drawingAids.hasRuler,
                  compassActive: controller.drawingAids.hasVisibleCompass,
                  formatBlock: textFormatTarget,
                  formatController: textFormatController,
                  onFormatBlockChanged: controller.updateTextBlock,
                ),
              ),
            ),
          if (studying)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EditorChrome.floating,
                    borderRadius: BorderRadius.circular(
                      EditorChrome.pillRadius,
                    ),
                    border: Border.all(color: EditorChrome.floatingBorder),
                    boxShadow: EditorChrome.pillShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: EditorChrome.onDark,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.studyModeHint,
                            style: TextStyle(
                              color: EditorChrome.onDarkMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StudyPomodoroChip(),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: controller.toggleStudyInkReveal,
                          child: Text(
                            hideInk ? l10n.revealInk : l10n.hideInk,
                            style: TextStyle(
                              color: EditorChrome.onDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: controller.toggleStudyMode,
                          child: Text(
                            l10n.exitStudyMode,
                            style: TextStyle(
                              color: EditorChrome.selected,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: _sidebarOpen ? PageSidebar.width + 12 : 12,
            bottom: 12,
            child: PageIndicatorPill(
              current: controller.pageIndex + 1,
              total: controller.pages.length,
              locked: readOnly,
              onTap: () => setState(() => _sidebarOpen = !_sidebarOpen),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: ZoomControls(
              onZoomIn: () => _canvasKey.currentState?.zoomBy(1.25),
              onZoomOut: () => _canvasKey.currentState?.zoomBy(0.8),
              onFit: () => _canvasKey.currentState?.fitToViewport(),
            ),
          ),
          if (lan.isActive &&
              (lan.notebookId == null || lan.notebookId == widget.notebookId))
            Positioned(
              right: 12,
              top: 10,
              child: Material(
                color: EditorChrome.floating,
                borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(
                          EditorChrome.pillRadius,
                        ),
                        onTap: () =>
                            context.push('/nearby-sync/${widget.notebookId}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_tethering_rounded,
                                size: 16,
                                color: lan.phase == LanSyncPhase.connected
                                    ? EditorChrome.selected
                                    : EditorChrome.onDarkMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lan.phase == LanSyncPhase.connected
                                    ? l10n.nearbySyncStatusConnected
                                    : l10n.nearbySyncTitle,
                                style: TextStyle(
                                  color: EditorChrome.onDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (lan.classroomMode &&
                          lan.role == LanSyncRole.host &&
                          lan.notebookId == widget.notebookId)
                        IconButton(
                          tooltip: l10n.teacherSaveLessonMaterials,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final snapshot = await controller
                                .saveCurrentSnapshot(
                                  label: l10n.teacherSavedMaterialsLabel(
                                    TimeOfDay.now().format(context),
                                  ),
                                );
                            if (snapshot == null || !context.mounted) return;
                            final session = ref.read(teacherProvider).session;
                            await ref
                                .read(teacherProvider.notifier)
                                .attachToCurrentLesson(
                                  timetable: ref.read(timetableProvider),
                                  subject: session?.subject,
                                  room: session?.room,
                                  notebookId: widget.notebookId,
                                  attachment: LessonAttachment(
                                    id: const Uuid().v4(),
                                    kind: LessonAttachmentKind.whiteboard,
                                    title: snapshot.label,
                                    createdAt: snapshot.createdAt,
                                    notebookId: snapshot.notebookId,
                                    pageId: snapshot.pageId,
                                    snapshotId: snapshot.id,
                                  ),
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.teacherMaterialsSavedToLesson,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.bookmark_add_outlined,
                            size: 18,
                            color: EditorChrome.selected,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (classroomGuest)
            Positioned(
              left: 12,
              right: 12,
              top: 52,
              child: Center(
                child: Material(
                  color: EditorChrome.floating,
                  borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          classroomLocked
                              ? Icons.lock_outline
                              : Icons.edit_outlined,
                          size: 17,
                          color: classroomLocked
                              ? EditorChrome.onDarkMuted
                              : EditorChrome.selected,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          classroomLocked
                              ? l10n.teacherWaitingForWritePermission
                              : l10n.teacherWritingAllowed,
                          style: TextStyle(
                            color: EditorChrome.onDark,
                            fontSize: 12,
                          ),
                        ),
                        if (lan.classroomFocusCheckEnabled &&
                            !lan.classroomFocusConsent)
                          TextButton(
                            onPressed: () => lan.setClassroomFocusConsent(true),
                            child: Text(
                              l10n.teacherAllowFocusCheck,
                              style: TextStyle(
                                color: EditorChrome.selected,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (lan.classroomMuted)
                          Icon(
                            Icons.volume_off_outlined,
                            color: EditorChrome.onDarkMuted,
                            size: 18,
                          ),
                        if (lan.classroomMaterialUrl != null)
                          IconButton(
                            tooltip: lan.classroomMaterialTitle,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => launchUrl(
                              Uri.parse(lan.classroomMaterialUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: Icon(
                              Icons.download_rounded,
                              color: EditorChrome.selected,
                              size: 19,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (lan.classroomMode &&
              lan.classroomPick != null &&
              '${lan.classroomPick!.kind}|${lan.classroomPick!.name}|${lan.classroomPick!.members.join(',')}' !=
                  _dismissedPickKey)
            Positioned.fill(
              child: ClassroomPickOverlay(
                pick: lan.classroomPick!,
                you: lan.classroomPick!.concernsYou(
                  deviceId: lan.deviceId,
                  deviceName: lan.deviceName,
                ),
                onDismiss: () {
                  if (lan.role == LanSyncRole.host) {
                    unawaited(lan.clearClassroomPick());
                    return;
                  }
                  setState(() {
                    _dismissedPickKey =
                        '${lan.classroomPick!.kind}|${lan.classroomPick!.name}|${lan.classroomPick!.members.join(',')}';
                  });
                },
              ),
            ),
        ],
        if (presenting)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: EditorChrome.floating.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(EditorChrome.pillRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.exitPresentViewHint,
                    style: TextStyle(
                      color: EditorChrome.onDarkMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_calcOpen && !presenting)
          Positioned(
            right: 12,
            top: 56,
            child: EditorToolPanel(
              title: l10n.calculator,
              pinned: _calcPinned,
              onPin: () => setState(() => _calcPinned = !_calcPinned),
              onClose: () => setState(() {
                _calcOpen = false;
                _calcPinned = false;
                if (!_bookOpen) _toolPageId = null;
              }),
              height: 520,
              child: CalculatorPanel(
                key: ValueKey('calc_${widget.notebookId}'),
                store: CalculatorStore(ref.read(sharedPreferencesProvider)),
                notebookId: widget.notebookId,
                calcPlus: ref
                    .watch(entitlementProvider)
                    .hasAccess(FeatureKeys.calcPlus),
                onInsertPlot: (expr, {required degrees}) =>
                    _insertFunctionPlot(controller, expr, degrees: degrees),
              ),
            ),
          ),
        if (_assistantOpen && !presenting)
          Positioned(
            right: 12,
            top: _calcOpen ? 530 : 56,
            child: EditorToolPanel(
              title: l10n.assistant,
              width: 360,
              pinned: _assistantPinned,
              onPin: () => setState(() => _assistantPinned = !_assistantPinned),
              onClose: () => setState(() {
                _assistantOpen = false;
                _assistantPinned = false;
                if (!_calcOpen && !_bookOpen) _toolPageId = null;
              }),
              child: AssistantPanel(
                unlocked: ref
                    .watch(entitlementProvider)
                    .hasAccess(FeatureKeys.aiAssistant),
                pageImagePaths: [
                  for (final image in controller.images)
                    if (image.pageId == controller.currentPage?.id)
                      image.localPath,
                ],
                onOpenCalculator: () =>
                    _openCalculator(controller, forceOpen: true),
                onOpenFormulaBook: (chapterId) => _openFormulaBook(
                  controller,
                  chapterId: chapterId,
                  forceOpen: true,
                ),
              ),
            ),
          ),
        if (_bookOpen && !presenting)
          Positioned(
            left: _sidebarOpen ? PageSidebar.width + 12 : 12,
            top: 56,
            child: EditorToolPanel(
              title: l10n.formulaBook,
              width: 400,
              pinned: _bookPinned,
              onPin: () => setState(() => _bookPinned = !_bookPinned),
              onClose: () => setState(() {
                _bookOpen = false;
                _bookPinned = false;
                if (!_calcOpen) _toolPageId = null;
              }),
              child: FormulaBookPanel(
                key: ValueKey(
                  'book_${widget.notebookId}_${_bookChapterId ?? ''}',
                ),
                store: FormulaBookStore(ref.read(sharedPreferencesProvider)),
                notebookId: widget.notebookId,
                includePlus: ref
                    .watch(entitlementProvider)
                    .hasAccess(FeatureKeys.formulaPack),
                initialChapterId: _bookChapterId,
                onUseFormula: (expr) => _useFormulaInGraph(controller, expr),
              ),
            ),
          ),
        if (_toolWheelOpen && !readOnly && !presenting)
          Positioned.fill(
            child: ToolWheelOverlay(
              current: controller.ink.tool,
              onDismiss: () => setState(() => _toolWheelOpen = false),
              onSelect: (tool) {
                _previousTool = controller.ink.tool;
                controller.ink.setTool(tool);
                setState(() => _toolWheelOpen = false);
              },
            ),
          ),
      ],
    );

    final editorTour = ref.watch(pendingEditorTourProvider) && !presenting;
    final editorSteps = _editorTourSteps(l10n);
    final scaffold = Scaffold(
      backgroundColor: EditorChrome.workspace,
      body: SafeArea(
        child: Column(
          children: [
            if (!presenting)
              Expanded(
                child: EditorTopBar(
                body: workspace,
                notebookId: widget.notebookId,
                tabIds: tabs.ids.isEmpty ? [widget.notebookId] : tabs.ids,
                engine: controller.ink,
                locked: readOnly,
                studyMode: studying,
                browseMode: browseMode,
                canvasMode: canvasMode,
                pageTemplate: page.template,
                defaultPaperFormat:
                    controller.notebook?.defaultPaperFormat ?? PaperFormat.a4,
                defaultOrientation:
                    controller.notebook?.defaultOrientation ??
                    PageOrientation.portrait,
                onSelectTab: (id) {
                  if (examLock) {
                    unawaited(
                      ref
                          .read(studentAssignmentProvider.notifier)
                          .leave('notebook'),
                    );
                  }
                  ref.read(openNotebookTabsProvider.notifier).select(id);
                  context.go('/notebook/$id');
                },
                onCloseTab: (id) {
                  final next = ref
                      .read(openNotebookTabsProvider.notifier)
                      .close(id);
                  if (next == null) {
                    refreshLibraryLists(ref);
                    context.go('/');
                  } else if (id == widget.notebookId) {
                    context.go('/notebook/$next');
                  }
                },
                onHome: () {
                  if (examLock) {
                    unawaited(
                      ref
                          .read(studentAssignmentProvider.notifier)
                          .leave('home'),
                    );
                  }
                  refreshLibraryLists(ref);
                  context.go('/');
                },
                onToggleSidebar: () =>
                    setState(() => _sidebarOpen = !_sidebarOpen),
                onSearch: () => context.push('/search'),
                onOutline: () => _openOutline(context, controller, l10n),
                onPickImage: () => _importImages(controller),
                onScanPages: () => _scanAndInsert(controller),
                onPickSticker: () => _pickSticker(controller),
                onCalculator: () => _openCalculator(controller),
                onFormulaBook: () => _openFormulaBook(controller),
                calculatorOpen: _calcOpen,
                formulaBookOpen: _bookOpen,
                assistantOpen: _assistantOpen,
                onAssistant: () => _openAssistant(controller),
                onAddPage: () => _addPage(controller),
                onToggleLock: controller.toggleInteractionMode,
                studyModeUnlocked: ref
                    .watch(entitlementProvider)
                    .hasAccess(FeatureKeys.studyMode),
                onToggleStudy: controller.toggleStudyMode,
                onMenuAction: (action) =>
                    _handleMenuAction(context, controller, action),
                onConfigureEraser: () =>
                    _configureContentTargets(context, controller, eraser: true),
                onConfigureLasso: () => _configureContentTargets(
                  context,
                  controller,
                  eraser: false,
                ),
                rulerActive: controller.drawingAids.hasRuler,
                compassActive: controller.drawingAids.hasVisibleCompass,
                onToggleRuler: controller.toggleRulerAid,
                onToggleCompass: controller.toggleCompassAid,
                onCreateDiagram: () => _createDiagram(controller),
                onOpenPacks: () => _openPacks(controller),
                ),
              )
            else
              Expanded(child: workspace),
          ],
        ),
      ),
    );

    Widget body = scaffold;
    if (editorTour) {
      final index = _editorTourIndex.clamp(0, editorSteps.length - 1);
      body = Stack(
        children: [
          scaffold,
          AppTourOverlay(
            steps: editorSteps,
            index: index,
            onSkip: () {
              setState(() => _editorTourIndex = 0);
              unawaited(markEditorTourSeen(ref));
            },
            onNext: () {
              if (index >= editorSteps.length - 1) {
                setState(() => _editorTourIndex = 0);
                unawaited(markEditorTourSeen(ref));
              } else {
                setState(() => _editorTourIndex = index + 1);
              }
            },
          ),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleEditorBack(controller);
      },
      child: body,
    );
  }

  void _configureContentTargets(
    BuildContext context,
    EditorController controller, {
    required bool eraser,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final presets = ref.read(toolPresetsProvider);
    showContentTargetsSheet(
      context,
      title: eraser ? l10n.eraserTargetsTitle : l10n.lassoTargetsTitle,
      selected: eraser
          ? controller.ink.eraseTargets
          : controller.ink.lassoTargets,
      onChanged: (value) {
        if (eraser) {
          presets.setEraseTargets(value);
          controller.ink.setEraseTargets(value);
        } else {
          presets.setLassoTargets(value);
          controller.ink.setLassoTargets(value);
        }
      },
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    EditorController controller,
    EditorMenuAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case EditorMenuAction.share:
        final selected = await showShareExportSheet(context);
        if (selected == null || !context.mounted) return;
        await _handleShareAction(context, controller, selected);
      case EditorMenuAction.outline:
        await _openOutline(context, controller, l10n);
      case EditorMenuAction.paperCreator:
        final result = await Navigator.of(context).push<PaperTemplate>(
          MaterialPageRoute(
            builder: (_) => PaperCreatorScreen(initial: controller.activePaper),
          ),
        );
        if (result != null) await controller.applyPaper(result);
      case EditorMenuAction.importPdf:
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final progress = ValueNotifier<String>(l10n.importPdf);
        final dialog = showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: ValueListenableBuilder<String>(
              valueListenable: progress,
              builder: (_, label, _) => AlertDialog(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(label)),
                  ],
                ),
              ),
            ),
          ),
        );
        try {
          await controller.importPdfWithProgress((d, t) {
            progress.value = l10n.pdfImportProgress(d, t);
          });
        } finally {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          await dialog;
          progress.dispose();
        }
      case EditorMenuAction.scanPages:
        if (!context.mounted) return;
        await _scanAndInsert(controller);
      case EditorMenuAction.deletePage:
        if (!context.mounted) return;
        await _deleteCurrentPage(context, controller, l10n);
      case EditorMenuAction.importHtml:
        if (!context.mounted) return;
        await _importHtml(context, controller, l10n);
      case EditorMenuAction.settings:
        if (context.mounted) context.push('/settings');
      case EditorMenuAction.collaborate:
        if (context.mounted) {
          context.push('/collaboration/${widget.notebookId}');
        }
      case EditorMenuAction.nearbySync:
        if (context.mounted) {
          context.push('/nearby-sync/${widget.notebookId}');
        }
      case EditorMenuAction.scrollDirection:
        final current = ref.read(settingsProvider).pageBrowseMode;
        ref
            .read(settingsProvider.notifier)
            .setPageBrowseMode(
              current == PageBrowseMode.swipeHorizontal
                  ? PageBrowseMode.scrollVertical
                  : PageBrowseMode.swipeHorizontal,
            );
      case EditorMenuAction.studyMode:
        controller.toggleStudyMode();
      case EditorMenuAction.presentView:
        controller.togglePresentationMode();
      case EditorMenuAction.makeFlashcard:
        final front = controller.selectedTextId != null
            ? controller.textBlocks
                  .where((b) => b.id == controller.selectedTextId)
                  .map((b) => b.plainText)
                  .firstOrNull
            : controller.textBlocks
                  .map((b) => b.plainText)
                  .where((t) => t.trim().isNotEmpty)
                  .take(1)
                  .firstOrNull;
        await createFlashcardFromEditorSelection(
          context: context,
          ref: ref,
          frontHint: (front ?? '').trim(),
        );
      case EditorMenuAction.importAnyFile:
        if (context.mounted) context.push('/import');
      case EditorMenuAction.saveSnapshot:
        await controller.saveCurrentSnapshot();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.snapshotSaved)));
        }
      case EditorMenuAction.restoreSnapshot:
        final page = controller.currentPage;
        if (page == null) return;
        final selected = await showPageSnapshotsSheet(
          context,
          repository: controller.repository,
          pageId: page.id,
        );
        if (selected == null || !context.mounted) return;
        await controller.restoreSnapshot(selected);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.snapshotRestored)));
        }
      case EditorMenuAction.addTag:
        await _promptAddTag(context, controller);
      case EditorMenuAction.templateBlank:
        await controller.setTemplate(PageTemplate.blank);
      case EditorMenuAction.templateLined:
        await controller.setTemplate(PageTemplate.lined);
      case EditorMenuAction.templateGrid:
        await controller.setTemplate(PageTemplate.grid);
      case EditorMenuAction.paperA4:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.a4);
      case EditorMenuAction.paperA2:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.a2);
      case EditorMenuAction.paperA3:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.a3);
      case EditorMenuAction.paperA5:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.a5);
      case EditorMenuAction.paperA6:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.a6);
      case EditorMenuAction.paperLetter:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.letter);
      case EditorMenuAction.paperLegal:
        await controller.updateNewPageDefaults(paperFormat: PaperFormat.legal);
      case EditorMenuAction.paperTabloid:
        await controller.updateNewPageDefaults(
          paperFormat: PaperFormat.tabloid,
        );
      case EditorMenuAction.orientationPortrait:
        await controller.updateNewPageDefaults(
          orientation: PageOrientation.portrait,
        );
      case EditorMenuAction.orientationLandscape:
        await controller.updateNewPageDefaults(
          orientation: PageOrientation.landscape,
        );
    }
  }

  Future<void> _promptAddTag(
    BuildContext context,
    EditorController controller,
  ) async {
    final field = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.addTag),
          content: TextField(controller: field, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
    if (ok == true && field.text.trim().isNotEmpty) {
      await controller.addTag(field.text.trim());
    }
  }

  Future<void> _openOutline(
    BuildContext context,
    EditorController controller,
    AppLocalizations l10n,
  ) async {
    final importable = await controller.loadPreviousClassChapters();
    if (!context.mounted) return;
    final previousClass = controller.notebook?.schoolClass == null
        ? null
        : l10n.importFromClass(controller.notebook!.schoolClass! - 1);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            top: 48,
            bottom: MediaQuery.paddingOf(ctx).bottom + 12,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return OutlineSidebar(
                  nodes: controller.outline,
                  importable: importable,
                  previousClassLabel: previousClass,
                  onAdd: (title) => controller.addOutlineNode(title: title),
                  onAddSubchapter: (parent, title) => controller.addOutlineNode(
                    parentId: parent.id,
                    title: title,
                  ),
                  onImport: (chapter) =>
                      controller.importOutlineTitle(chapter.title),
                  onRename: (node) async {
                    final c = TextEditingController(text: node.title);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        final dialogL10n = AppLocalizations.of(context)!;
                        return AlertDialog(
                          title: Text(dialogL10n.renameSection),
                          content: TextField(
                            controller: c,
                            autofocus: true,
                            onSubmitted: (_) => Navigator.pop(context, true),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(dialogL10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(dialogL10n.save),
                            ),
                          ],
                        );
                      },
                    );
                    if (ok == true && c.text.trim().isNotEmpty) {
                      await controller.renameOutline(node, c.text.trim());
                    }
                  },
                  onDelete: controller.deleteOutline,
                  onTap: (node) async {
                    await controller.jumpToOutline(node);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  onIndent: controller.indentOutline,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LassoObjectHighlightPainter extends CustomPainter {
  const _LassoObjectHighlightPainter({
    required this.shapes,
    required this.images,
    required this.texts,
    this.stickers = const [],
  });

  final List<Rect> shapes;
  final List<Rect> images;
  final List<Rect> texts;
  final List<Rect> stickers;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F6FED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rect in [...shapes, ...images, ...texts, ...stickers]) {
      canvas.drawRect(rect.inflate(3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LassoObjectHighlightPainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
        oldDelegate.images != images ||
        oldDelegate.texts != texts ||
        oldDelegate.stickers != stickers;
  }
}
