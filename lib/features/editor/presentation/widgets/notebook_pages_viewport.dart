import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../data/models/content_models.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../../domain/pointer_routing.dart';
import '../editor_chrome.dart';
import '../page_preview_cache.dart';
import 'ink_painter.dart';
import 'page_background_painter.dart';
import 'page_viewport_fit.dart';
import 'shape_painter.dart';

/// Static (non-interactive) snapshot of a page for multi-page browsing.
/// Prefers a warm [PagePreviewCache] bitmap when available.
class PageSnapshot extends StatelessWidget {
  const PageSnapshot({
    super.key,
    required this.page,
    this.width,
    this.matchLiveFit = false,
  });

  final NotePage page;
  final double? width;

  /// When true, apply the same transform matrix as [InkCanvas] at fit-zoom.
  final bool matchLiveFit;

  @override
  Widget build(BuildContext context) {
    final pageSize = NotePageSize.resolve(page.paperFormat, page.orientation);
    final canvasSize = PageViewportFit.childSize(pageSize);
    final paper = ValueListenableBuilder<ui.Image?>(
      valueListenable: PagePreviewCache.instance.listenableFor(page.id),
      builder: (context, cached, _) {
        final image = cached ?? PagePreviewCache.instance.get(page);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: EditorChrome.divider),
          ),
          child: image != null
              ? _CachedPageImage(image: image, pageSize: pageSize)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      size: pageSize,
                      painter: PageBackgroundPainter(
                        template: page.template,
                        paper: page.customPaper,
                      ),
                    ),
                    CustomPaint(
                      size: pageSize,
                      painter: InkPainter(strokes: page.strokes),
                    ),
                    CustomPaint(
                      size: pageSize,
                      painter: ShapePainter(shapes: page.shapes),
                    ),
                  ],
                ),
        );
      },
    );

    final aspect = canvasSize.width / canvasSize.height;
    if (width != null) {
      return SizedBox(
        width: width,
        height: width! / aspect,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return PageViewportFit.framed(
              viewport: Size(constraints.maxWidth, constraints.maxHeight),
              pageSize: pageSize,
              paper: paper,
            );
          },
        ),
      );
    }
    if (matchLiveFit) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return PageViewportFit.framed(
            viewport: Size(constraints.maxWidth, constraints.maxHeight),
            pageSize: pageSize,
            paper: paper,
          );
        },
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return PageViewportFit.framed(
              viewport: Size(constraints.maxWidth, constraints.maxHeight),
              pageSize: pageSize,
              paper: paper,
            );
          },
        ),
      ),
    );
  }
}

class _CachedPageImage extends StatelessWidget {
  const _CachedPageImage({required this.image, required this.pageSize});

  final ui.Image image;
  final Size pageSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: pageSize,
      painter: _ImagePainter(image),
    );
  }
}

class _ImagePainter extends CustomPainter {
  _ImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) =>
      oldDelegate.image != image;

  @override
  bool hitTest(Offset position) => false;
}

/// Placeholder shown past the last page to create a new one.
class AddPageAffordance extends StatelessWidget {
  const AddPageAffordance({super.key, required this.axis, required this.onTap});

  final Axis axis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (axis == Axis.vertical)
              Icon(
                Icons.arrow_upward_rounded,
                color: EditorChrome.selected,
                size: 22,
              ),
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: EditorChrome.selected, width: 2),
              ),
              child: Icon(
                Icons.note_add_outlined,
                color: EditorChrome.selected,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 130,
              child: Text(
                l10n.dragToAddPage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.onDarkMuted,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Touch / trackpad may scroll pages. Stylus and mouse write ink and must
/// never drive [PageView] / [ListView] scrolling. Right-click browse is
/// handled in [InkCanvas] / the viewport listener, not by scroll physics.
class _TouchOnlyScrollBehavior extends MaterialScrollBehavior {
  const _TouchOnlyScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
  };
}

/// GoodNotes-like multi-page browser: horizontal swipe or vertical scroll.
class NotebookPagesViewport extends StatefulWidget {
  const NotebookPagesViewport({
    super.key,
    required this.pages,
    required this.pageIndex,
    required this.browseMode,
    required this.canvasMode,
    required this.onPageChanged,
    required this.activePageBuilder,
    this.onReachEnd,
    this.onFlipStart,
    this.readOnly = false,
    this.navigationLocked = false,
  });

  final List<NotePage> pages;
  final int pageIndex;
  final PageBrowseMode browseMode;
  final CanvasMode canvasMode;
  final ValueChanged<int> onPageChanged;
  final Widget Function(BuildContext context, int index) activePageBuilder;
  final Future<void> Function()? onReachEnd;

  /// Sync the leaving page into [pages] before the live canvas is hidden.
  final VoidCallback? onFlipStart;
  final bool readOnly;

  /// Page lock (Schloss): stay on this page — no swipe / scroll / adjacent.
  final bool navigationLocked;

  @override
  State<NotebookPagesViewport> createState() => NotebookPagesViewportState();
}

class NotebookPagesViewportState extends State<NotebookPagesViewport> {
  static const _itemGap = 28.0;
  static const _listPadding = EdgeInsets.symmetric(
    vertical: 20,
    horizontal: 12,
  );

  PageController? _pageController;
  ScrollController? _scrollController;
  final Map<int, GlobalKey> _keys = {};
  bool _ignorePageSync = false;
  bool _selecting = false;
  bool _creatingPage = false;

  /// Set while jumping to a page, so the jump cannot select another page.
  bool _restoring = false;
  double _swipeAccum = 0;

  /// Locks PageView / ListView while drawing or pinching.
  bool _scrollLock = false;

  /// Live canvas is hidden; PageView only slides cached snapshots.
  bool _flipping = false;
  int _flipToken = 0;

  /// When zoomed, fit-zoom parent browse stays off (canvas pans / edge-flips).
  bool _zoomed = false;

  /// Viewport-owned fit-zoom swipe (survives hiding the live canvas).
  int? _browsePointer;
  Offset? _browseDown;
  Offset? _browseLastGlobal;
  bool _committing = false;

  /// Swipe velocity (px/s, screen space) for natural page commits.
  double _swipeVelocity = 0;
  int _lastPanMicros = 0;

  ScrollController? get scrollController => _scrollController;

  /// Called from [InkCanvas] so ink / pinch / zoom cannot pan the page list.
  void setScrollLock(bool locked) {
    if (_scrollLock == locked) return;
    final pc = _pageController;
    if (locked && pc != null && pc.hasClients && pc.page != null) {
      // Cancel a half-finished swipe the moment a pinch starts so the page
      // cannot stick between slots.
      final settled = pc.page!.round().clamp(0, widget.pages.length - 1);
      if ((pc.page! - settled).abs() > 0.01) {
        pc.jumpToPage(settled);
      }
    }
    setState(() => _scrollLock = locked);
    if (locked) {
      _swipeAccum = 0;
      _browsePointer = null;
      _browseDown = null;
      _browseLastGlobal = null;
      PagePreviewCache.instance.setPaused(true);
    } else if (!_flipping) {
      PagePreviewCache.instance.setPaused(false);
      _scheduleNeighborPreviews();
    }
  }

  void setZoomed(bool zoomed) {
    if (_zoomed == zoomed) return;
    _zoomed = zoomed;
  }

  void _scheduleNeighborPreviews() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    PagePreviewCache.instance.scheduleNeighbors(
      widget.pages,
      widget.pageIndex,
    );
  }

  void _enterFlip() {
    if (_flipping) return;
    widget.onFlipStart?.call();
    PagePreviewCache.instance.setPaused(true);
    setState(() => _flipping = true);
  }

  int _viewportPointers = 0;

  bool _isBrowseKind(PointerEvent event) {
    return PointerRouting.browsesLikeFinger(event);
  }

  void _onViewportPointerDown(PointerDownEvent event) {
    _viewportPointers++;
    if (_viewportPointers >= 2) {
      _browsePointer = null;
      _browseDown = null;
      _browseLastGlobal = null;
      return;
    }
    if (_scrollLock || _zoomed || widget.navigationLocked) return;
    if (!_isBrowseKind(event)) return;
    _browsePointer = event.pointer;
    _browseDown = event.position;
    _browseLastGlobal = event.position;
  }

  void _onViewportPointerMove(PointerMoveEvent event) {
    if (_viewportPointers >= 2) return;
    if (_scrollLock || _zoomed || widget.navigationLocked) return;
    if (_browsePointer != null && event.pointer != _browsePointer) return;
    if (_browsePointer == null && !_isBrowseKind(event)) return;

    if (_browsePointer == null) {
      _browsePointer = event.pointer;
      _browseDown = event.position;
      _browseLastGlobal = event.position;
      return;
    }

    final last = _browseLastGlobal ?? event.position;
    _browseLastGlobal = event.position;
    final delta = event.position - last;

    if (!_flipping) {
      final slop = event.position - (_browseDown ?? event.position);
      // Keep the live canvas interactive until this is clearly a page swipe.
      if (slop.distance < 36) return;
      if (slop.dx.abs() < slop.dy.abs() * 1.15) return;
    }

    handleBrowsePan(delta);
  }

  void _onViewportPointerUp(PointerUpEvent event) {
    _finishViewportBrowse(event.pointer);
  }

  void _onViewportPointerCancel(PointerCancelEvent event) {
    _finishViewportBrowse(event.pointer);
  }

  void _finishViewportBrowse(int pointer) {
    _viewportPointers = (_viewportPointers - 1).clamp(0, 8);
    if (_browsePointer != pointer) {
      if (_viewportPointers == 0 && _flipping && !_committing) {
        handleBrowsePanEnd();
      }
      return;
    }
    final shouldCommit = _flipping || _swipeAccum.abs() > 1;
    _browsePointer = null;
    _browseDown = null;
    _browseLastGlobal = null;
    // Zoomed edge-flips are ended by InkCanvas so we do not double-commit.
    if (shouldCommit && !_zoomed) {
      handleBrowsePanEnd();
    }
  }

  void _exitFlipSoon() {
    final token = ++_flipToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _flipToken) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || token != _flipToken) return;
        setState(() => _flipping = false);
        PagePreviewCache.instance.setPaused(false);
        _scheduleNeighborPreviews();
      });
    });
  }

  @Deprecated('Use setScrollLock')
  void setDrawingLock(bool locked) => setScrollLock(locked);

  ScrollPhysics get _scrollPhysics {
    // Page flips are driven by InkCanvas finger-browse / goToAdjacent /
    // sidebar — not by PageView's own drag (that fought the canvas and
    // often ended up permanently locked).
    return const NeverScrollableScrollPhysics();
  }

  ScrollPhysics get _listPhysics {
    if (_scrollLock || widget.navigationLocked) {
      return const NeverScrollableScrollPhysics();
    }
    return const ClampingScrollPhysics();
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleNeighborPreviews();
    });
  }

  void _initControllers() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      _pageController = PageController(
        initialPage: widget.pageIndex,
        viewportFraction: 1.0,
      );
      _scrollController?.dispose();
      _scrollController = null;
    } else {
      _scrollController = ScrollController();
      _pageController?.dispose();
      _pageController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(widget.pageIndex, animate: false);
      });
    }
  }

  @override
  void didUpdateWidget(covariant NotebookPagesViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages.length > oldWidget.pages.length) {
      _creatingPage = false;
    }
    if (oldWidget.browseMode != widget.browseMode ||
        oldWidget.canvasMode != widget.canvasMode) {
      _pageController?.dispose();
      _scrollController?.dispose();
      _pageController = null;
      _scrollController = null;
      _initControllers();
      setState(() {});
      return;
    }
    if (oldWidget.pageIndex != widget.pageIndex) {
      _scheduleNeighborPreviews();
      if (_ignorePageSync) return;
      if (_pageController != null && _pageController!.hasClients) {
        final current = _pageController!.page?.round() ?? widget.pageIndex;
        if (current != widget.pageIndex) {
          _pageController!.animateToPage(
            widget.pageIndex,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      } else if (_scrollController != null) {
        _scrollToIndex(widget.pageIndex, animate: true);
      }
    } else if (!identical(oldWidget.pages, widget.pages)) {
      _scheduleNeighborPreviews();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  void _emitPage(int index) {
    if (_selecting || index == widget.pageIndex) return;
    if (index < 0 || index >= widget.pages.length) return;
    _selecting = true;
    _ignorePageSync = true;
    widget.onPageChanged(index);
    _selecting = false;
    // The controller persists the previous page asynchronously. Keep the
    // viewport's gesture responsive and only suppress the matching rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ignorePageSync = false;
    });
  }

  void goToAdjacent(int delta) {
    if (widget.navigationLocked) return;
    final target = widget.pageIndex + delta;
    if (target >= widget.pages.length && delta > 0 && !widget.readOnly) {
      _requestAddPage();
      return;
    }
    if (target < 0 || target >= widget.pages.length) return;
    unawaited(_commitPage(target, animate: true));
  }

  /// Animates (optional) then always commits [selectPage]. Relying only on
  /// ScrollEnd + pending index was flaky with jumpTo-driven browse pans.
  Future<void> _commitPage(int target, {required bool animate}) async {
    final showAdd = !widget.readOnly && widget.onReachEnd != null;
    final maxIndex = widget.pages.length - 1 + (showAdd ? 1 : 0);
    if (maxIndex < 0) return;
    final clamped = target.clamp(0, maxIndex);

    if (clamped >= widget.pages.length) {
      await _requestAddPage();
      if (_pageController?.hasClients ?? false) {
        _pageController!.jumpToPage(widget.pages.length - 1);
      }
      return;
    }

    if (_committing) return;
    _committing = true;
    _enterFlip();
    try {
      final pc = _pageController;
      if (pc != null && pc.hasClients) {
        final page = pc.page;
        final needsMove = page == null || (page - clamped).abs() > 0.001;
        if (needsMove) {
          if (animate) {
            await pc.animateToPage(
              clamped,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          } else {
            pc.jumpToPage(clamped);
          }
        }
      }
      if (!mounted) return;
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      _emitPage(clamped);
      _exitFlipSoon();
    } finally {
      _committing = false;
    }
  }

  Future<void> _requestAddPage() async {
    if (_creatingPage || widget.readOnly || widget.onReachEnd == null) return;
    _creatingPage = true;
    try {
      await widget.onReachEnd!.call();
    } finally {
      if (mounted) _creatingPage = false;
    }
  }

  /// Consume browse pan from [InkCanvas]. Returns true if handled.
  bool handleBrowsePan(Offset delta) {
    if (widget.navigationLocked) return true;
    if (widget.canvasMode == CanvasMode.infinite) return false;

    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      // Absorb vertical movement at fit zoom so the page cannot drift.
      if (delta.dx.abs() < delta.dy.abs() * 0.85) return true;
      _swipeAccum += delta.dx;
      // Hide the live canvas only after a real page-turn swipe, otherwise
      // writing / pinch-zoom die because the canvas goes Offstage.
      if (!_flipping && _swipeAccum.abs() < 36) {
        return true;
      }
      _enterFlip();
      PagePreviewCache.instance.setPaused(true);

      final now = DateTime.now().microsecondsSinceEpoch;
      if (_lastPanMicros > 0) {
        final dt = (now - _lastPanMicros) / 1e6;
        if (dt > 0 && dt < 0.08) {
          final v = delta.dx / dt;
          _swipeVelocity = _swipeVelocity * 0.65 + v * 0.35;
        }
      }
      _lastPanMicros = now;

      final pc = _pageController;
      if (pc != null && pc.hasClients) {
        final next = (pc.position.pixels - delta.dx).clamp(
          pc.position.minScrollExtent,
          pc.position.maxScrollExtent,
        );
        pc.jumpTo(next);
      }
      return true;
    }

    // Vertical continuous: scroll the page list.
    final sc = _scrollController;
    if (sc == null || !sc.hasClients) return false;
    if (delta.dy.abs() < delta.dx.abs() * 0.85 && !widget.readOnly) {
      return false;
    }
    PagePreviewCache.instance.setPaused(true);
    final next = (sc.offset - delta.dy).clamp(0.0, sc.position.maxScrollExtent);
    sc.jumpTo(next);
    return true;
  }

  void handleBrowsePanEnd() {
    if (widget.navigationLocked) {
      _swipeAccum = 0;
      _swipeVelocity = 0;
      _lastPanMicros = 0;
      return;
    }
    if (widget.browseMode != PageBrowseMode.swipeHorizontal) {
      _swipeAccum = 0;
      _swipeVelocity = 0;
      _lastPanMicros = 0;
      return;
    }
    const distanceThreshold = 56.0;
    const velocityThreshold = 700.0;
    int target;
    if (_swipeAccum <= -distanceThreshold ||
        _swipeVelocity <= -velocityThreshold) {
      target = widget.pageIndex + 1;
    } else if (_swipeAccum >= distanceThreshold ||
        _swipeVelocity >= velocityThreshold) {
      target = widget.pageIndex - 1;
    } else {
      final pc = _pageController;
      target = (pc != null && pc.hasClients && pc.page != null)
          ? pc.page!.round()
          : widget.pageIndex;
    }
    _swipeAccum = 0;
    _swipeVelocity = 0;
    _lastPanMicros = 0;
    unawaited(_commitPage(target, animate: true));
  }

  bool _onPageScroll(ScrollNotification n) {
    if (widget.browseMode != PageBrowseMode.swipeHorizontal) return false;
    if (_scrollLock || widget.navigationLocked) return false;
    if (n is! ScrollEndNotification) return false;

    final pc = _pageController;
    if (pc == null || !pc.hasClients || pc.page == null) return false;
    final showAdd = !widget.readOnly && widget.onReachEnd != null;
    final maxIndex = widget.pages.length - 1 + (showAdd ? 1 : 0);
    final rounded = pc.page!.round().clamp(0, maxIndex < 0 ? 0 : maxIndex);
    // Always land on a whole page — fixes pages stuck halfway at the edge.
    if ((pc.page! - rounded).abs() > 0.001) {
      pc.jumpToPage(rounded);
    }
    // Page commits happen in [_commitPage] after browse/adjacent gestures.
    // Avoid selecting mid-settle here — that was a major source of hitching.
    return false;
  }

  /// Height a page occupies in the vertical list, including the gap below it.
  double _estimatedExtent(int index, double viewportWidth) {
    if (index >= widget.pages.length) return 240;
    final page = widget.pages[index];
    final size = NotePageSize.resolve(page.paperFormat, page.orientation);
    final aspect =
        (size.height + PageViewportFit.gutter) /
        (size.width + PageViewportFit.gutter);
    return viewportWidth * 0.92 * aspect + _itemGap;
  }

  double _estimatedOffset(int index, double viewportWidth) {
    var offset = _listPadding.top;
    for (var i = 0; i < index; i++) {
      offset += _estimatedExtent(i, viewportWidth);
    }
    return offset;
  }

  void _scrollToIndex(int index, {required bool animate}) {
    _restoring = true;
    _scrollStep(index, animate: animate, attempt: 0);
  }

  /// Pages outside the built range have no context yet, so approximate the
  /// offset first and let the next frame land on the exact position.
  void _scrollStep(int index, {required bool animate, required int attempt}) {
    final sc = _scrollController;
    if (sc == null || !sc.hasClients) {
      _endRestore();
      return;
    }
    final ctx = _keyFor(index).currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.08,
        duration: animate ? const Duration(milliseconds: 240) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
      _endRestore();
      return;
    }
    if (attempt >= 4) {
      _endRestore();
      return;
    }
    // Build-time callbacks can run before this state has a laid-out RenderBox.
    // BuildContext.size asserts in that phase, so only read a verified box.
    final box = context.findRenderObject() as RenderBox?;
    final width = box != null && box.hasSize
        ? box.size.width
        : MediaQuery.sizeOf(context).width;
    sc.jumpTo(
      _estimatedOffset(index, width).clamp(0.0, sc.position.maxScrollExtent),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollStep(index, animate: false, attempt: attempt + 1);
      }
    });
  }

  void _endRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoring = false;
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (widget.browseMode != PageBrowseMode.scrollVertical) return false;
    if (_scrollLock || widget.navigationLocked) return false;
    if (n is OverscrollNotification &&
        n.overscroll > 8 &&
        n.metrics.extentAfter <= 0) {
      _requestAddPage();
      return false;
    }
    if (_restoring) return false;
    if (n is! ScrollEndNotification) return false;
    final scrollBox = context.findRenderObject() as RenderBox?;
    if (scrollBox == null) return false;
    final origin = scrollBox.localToGlobal(Offset.zero);
    final targetY = origin.dy + scrollBox.size.height * 0.32;

    var best = widget.pageIndex;
    var bestDist = double.infinity;
    for (var i = 0; i < widget.pages.length; i++) {
      final ctx = _keyFor(i).currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      final dist = (y - targetY).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best != widget.pageIndex) {
      _emitPage(best);
    }
    return false;
  }

  Widget _constrainedActive(BuildContext context, int index, double maxWidth) {
    final page = widget.pages[index];
    final size = NotePageSize.resolve(page.paperFormat, page.orientation);
    final width = maxWidth * 0.92;
    final aspect =
        (size.height + PageViewportFit.gutter) /
        (size.width + PageViewportFit.gutter);
    final h = width * aspect;
    return Center(
      child: SizedBox(
        height: h,
        width: width,
        child: widget.activePageBuilder(context, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canvasMode == CanvasMode.infinite) {
      return widget.activePageBuilder(context, widget.pageIndex);
    }

    final showAddSlot = !widget.readOnly && widget.onReachEnd != null;

    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onViewportPointerDown,
        onPointerMove: _onViewportPointerMove,
        onPointerUp: _onViewportPointerUp,
        onPointerCancel: _onViewportPointerCancel,
        child: ScrollConfiguration(
          behavior: const _TouchOnlyScrollBehavior(),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onPageScroll,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: !_flipping,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _scrollPhysics,
                    allowImplicitScrolling: true,
                    itemCount: widget.pages.length + (showAddSlot ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.pages.length) {
                        return Center(
                          child: AddPageAffordance(
                            axis: Axis.horizontal,
                            onTap: () => _requestAddPage(),
                          ),
                        );
                      }
                      return RepaintBoundary(
                        child: PageSnapshot(
                          page: widget.pages[index],
                          matchLiveFit: true,
                        ),
                      );
                    },
                  ),
                ),
                if (widget.pageIndex < widget.pages.length)
                  Positioned.fill(
                    child: Offstage(
                      offstage: _flipping,
                      child: IgnorePointer(
                        ignoring: _flipping,
                        child: widget.activePageBuilder(
                          context,
                          widget.pageIndex,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Vertical continuous scroll through all pages.
    return ScrollConfiguration(
      behavior: const _TouchOnlyScrollBehavior(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView.builder(
              controller: _scrollController,
              physics: _listPhysics,
              padding: _listPadding,
              itemCount: widget.pages.length + (showAddSlot ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= widget.pages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    child: Center(
                      child: AddPageAffordance(
                        axis: Axis.vertical,
                        onTap: () => _requestAddPage(),
                      ),
                    ),
                  );
                }
                return KeyedSubtree(
                  key: _keyFor(index),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _itemGap),
                    child: Center(
                      child: index == widget.pageIndex
                          ? _constrainedActive(
                              context,
                              index,
                              constraints.maxWidth,
                            )
                          : RepaintBoundary(
                              child: GestureDetector(
                                onTap: widget.navigationLocked
                                    ? null
                                    : () => _emitPage(index),
                                child: PageSnapshot(
                                  page: widget.pages[index],
                                  width: constraints.maxWidth * 0.92,
                                  matchLiveFit: true,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
