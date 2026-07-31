import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../../../data/models/notebook.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_size.dart';
import '../editor_chrome.dart';
import 'ink_painter.dart';
import 'page_background_painter.dart';
import 'shape_painter.dart';

/// Static (non-interactive) snapshot of a page for multi-page browsing.
class PageSnapshot extends StatelessWidget {
  const PageSnapshot({super.key, required this.page, this.width});

  final NotePage page;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final pageSize = NotePageSize.resolve(page.paperFormat, page.orientation);
    // Match InkCanvas' 32px interaction gutter on every side. Without this,
    // a static page and its interactive replacement have different fitted
    // sizes, producing a visible jump when scrolling settles.
    final canvasSize = Size(pageSize.width + 64, pageSize.height + 64);
    final content = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: Center(
          child: SizedBox(
            width: pageSize.width,
            height: pageSize.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
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
            ),
          ),
        ),
      ),
    );

    final aspect = canvasSize.width / canvasSize.height;
    if (width != null) {
      return SizedBox(width: width, height: width! / aspect, child: content);
    }
    return Center(
      child: AspectRatio(aspectRatio: aspect, child: content),
    );
  }
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
    this.readOnly = false,
  });

  final List<NotePage> pages;
  final int pageIndex;
  final PageBrowseMode browseMode;
  final CanvasMode canvasMode;
  final ValueChanged<int> onPageChanged;
  final Widget Function(BuildContext context, int index) activePageBuilder;
  final Future<void> Function()? onReachEnd;
  final bool readOnly;

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
  int? _deferredActivationIndex;
  bool _creatingPage = false;

  /// Set while jumping to a page, so the jump cannot select another page.
  bool _restoring = false;
  double _swipeAccum = 0;

  ScrollController? get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      _pageController = PageController(
        initialPage: widget.pageIndex,
        viewportFraction: 0.88,
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
      // Keep the scroll-settling frame cheap. The static page snapshot gives
      // immediate visual feedback; the interactive canvas is attached on the
      // following frame, after the list has settled.
      _deferredActivationIndex = widget.pageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _deferredActivationIndex == widget.pageIndex) {
          setState(() => _deferredActivationIndex = null);
        }
      });
      if (_ignorePageSync) return;
      if (_pageController != null && _pageController!.hasClients) {
        final current = _pageController!.page?.round() ?? widget.pageIndex;
        if (current != widget.pageIndex) {
          _pageController!.animateToPage(
            widget.pageIndex,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
      } else if (_scrollController != null) {
        _scrollToIndex(widget.pageIndex, animate: true);
      }
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
    final target = widget.pageIndex + delta;
    if (target >= widget.pages.length && delta > 0 && !widget.readOnly) {
      _requestAddPage();
      return;
    }
    if (target < 0 || target >= widget.pages.length) return;
    if (_pageController?.hasClients ?? false) {
      _pageController!.animateToPage(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _emitPage(target);
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

  /// Consume two-finger browse pan from [InkCanvas]. Returns true if handled.
  bool handleBrowsePan(Offset delta) {
    if (widget.canvasMode == CanvasMode.infinite) return false;

    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      // Absorb vertical movement at fit zoom so the page cannot drift.
      if (delta.dx.abs() < delta.dy.abs() * 0.85) return true;
      final pc = _pageController;
      if (pc != null && pc.hasClients) {
        final next = (pc.position.pixels - delta.dx).clamp(
          pc.position.minScrollExtent,
          pc.position.maxScrollExtent,
        );
        pc.jumpTo(next);
      }
      _swipeAccum += delta.dx;
      return true;
    }

    // Vertical continuous: scroll the page list.
    final sc = _scrollController;
    if (sc == null || !sc.hasClients) return false;
    if (delta.dy.abs() < delta.dx.abs() * 0.85 && !widget.readOnly) {
      return false;
    }
    final next = (sc.offset - delta.dy).clamp(0.0, sc.position.maxScrollExtent);
    sc.jumpTo(next);
    return true;
  }

  void handleBrowsePanEnd() {
    if (widget.browseMode != PageBrowseMode.swipeHorizontal) {
      _swipeAccum = 0;
      return;
    }
    const threshold = 72.0;
    if (_swipeAccum <= -threshold) {
      goToAdjacent(1);
    } else if (_swipeAccum >= threshold) {
      goToAdjacent(-1);
    } else {
      _snapPageToIndex(widget.pageIndex);
    }
    _swipeAccum = 0;
  }

  void _snapPageToIndex(int index) {
    final pc = _pageController;
    if (pc == null || !pc.hasClients) return;
    final showAdd = !widget.readOnly && widget.onReachEnd != null;
    final maxIndex = widget.pages.length - 1 + (showAdd ? 1 : 0);
    if (maxIndex < 0) return;
    final target = index.clamp(0, maxIndex);
    pc.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  bool _onPageScroll(ScrollNotification n) {
    if (widget.browseMode != PageBrowseMode.swipeHorizontal) return false;
    if (n is! ScrollEndNotification) return false;
    final pc = _pageController;
    if (pc == null || !pc.hasClients || pc.page == null) return false;
    final page = pc.page!;
    final showAdd = !widget.readOnly && widget.onReachEnd != null;
    final maxIndex = widget.pages.length - 1 + (showAdd ? 1 : 0);
    if (maxIndex < 0) return false;
    final rounded = page.round().clamp(0, maxIndex);
    // Incomplete swipe: spring back to the nearest settled page.
    if ((page - rounded).abs() > 0.01) {
      _snapPageToIndex(rounded);
    }
    return false;
  }

  /// Height a page occupies in the vertical list, including the gap below it.
  double _estimatedExtent(int index, double viewportWidth) {
    if (index >= widget.pages.length) return 240;
    final page = widget.pages[index];
    final size = NotePageSize.resolve(page.paperFormat, page.orientation);
    final aspect = (size.height + 64) / (size.width + 64);
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
        duration: animate ? const Duration(milliseconds: 280) : Duration.zero,
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
    final aspect = (size.height + 64) / (size.width + 64);
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
      return NotificationListener<ScrollNotification>(
        onNotification: _onPageScroll,
        child: PageView.builder(
          controller: _pageController,
          physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
          onPageChanged: (index) {
            if (index < widget.pages.length) {
              _emitPage(index);
            } else {
              _requestAddPage();
            }
          },
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
            if (index == widget.pageIndex &&
                _deferredActivationIndex != widget.pageIndex) {
              return widget.activePageBuilder(context, index);
            }
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: PageSnapshot(page: widget.pages[index]),
              ),
            );
          },
        ),
      );
    }

    // Vertical continuous scroll through all pages.
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
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
                    child:
                        index == widget.pageIndex &&
                            _deferredActivationIndex != widget.pageIndex
                        ? _constrainedActive(
                            context,
                            index,
                            constraints.maxWidth,
                          )
                        : RepaintBoundary(
                            child: GestureDetector(
                              onTap: () => _emitPage(index),
                              child: PageSnapshot(
                                page: widget.pages[index],
                                width: constraints.maxWidth * 0.92,
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
    );
  }
}
