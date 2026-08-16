import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/ink_engine.dart';
import '../../domain/ink_models.dart';
import 'ink_painter.dart';
import 'cached_page_background.dart';
import 'page_background_painter.dart';
import 'page_viewport_fit.dart';

/// Large but finite board for "infinite" documents.
/// Viewport culling keeps paint cost proportional to what's on screen.
const Size kInfiniteCanvasSize = Size(32000, 32000);

class InkCanvas extends StatefulWidget {
  const InkCanvas({
    super.key,
    required this.engine,
    required this.template,
    required this.pageSize,
    this.pageId,
    required this.fingerPanZoom,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    this.backgroundImage,
    this.paper,
    this.canvasMode = CanvasMode.page,
    this.overlay,
    this.readOnly = false,
    this.hideInk = false,
    this.browseMode = PageBrowseMode.swipeHorizontal,
    this.onBrowsePan,
    this.onBrowsePanEnd,
    this.onScrollLockChanged,
    this.onZoomedChanged,
    this.onTwoFingerTap,
    this.onThreeFingerSwipe,
    this.onDoubleTap,
  });

  final InkEngine engine;
  final PageTemplate template;
  final Size pageSize;

  /// When this changes the view snaps back to fit so the reveal after a
  /// page flip matches the snapshot underneath.
  final String? pageId;
  final ui.Image? backgroundImage;
  final PaperTemplate? paper;
  final CanvasMode canvasMode;
  final bool fingerPanZoom;
  final bool readOnly;
  final bool hideInk;
  final Widget? overlay;
  final PageBrowseMode browseMode;

  /// Finger pan for page browse (fit zoom, or zoomed + edge overscroll).
  /// Return true if the parent consumed the gesture (skip canvas pan).
  final bool Function(Offset globalDelta)? onBrowsePan;
  final VoidCallback? onBrowsePanEnd;

  /// Lock PageView/ListView while drawing or pinching (not merely zoomed —
  /// zoomed edge-swipes still drive the page strip).
  final ValueChanged<bool>? onScrollLockChanged;

  /// Fit vs zoomed — the page strip hides the live canvas only at fit zoom.
  final ValueChanged<bool>? onZoomedChanged;

  /// Two-finger tap (little movement) for configurable shortcuts.
  final VoidCallback? onTwoFingerTap;

  /// Three-finger horizontal swipe: `-1` left, `+1` right.
  final ValueChanged<int>? onThreeFingerSwipe;
  final VoidCallback? onDoubleTap;

  final void Function(
    Offset pagePoint, {
    required bool isStylus,
    double pressure,
  })
  onPointerDown;
  final void Function(Offset pagePoint, {double pressure}) onPointerMove;
  final VoidCallback onPointerUp;

  @override
  State<InkCanvas> createState() => InkCanvasState();
}

class InkCanvasState extends State<InkCanvas>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  final Map<int, Offset> _pointerGlobal = {};
  int? _drawPointer;
  bool _drawing = false;
  bool _drawIsStylus = false;
  Offset? _panLastFocal;
  Size _viewportSize = Size.zero;
  double _fitScale = 1;
  Size? _fittedViewport;
  Size? _fittedPageSize;
  AnimationController? _viewAnim;
  bool _keyboardOpen = false;
  bool _scrollLockSent = false;
  bool _zoomedSent = false;
  double? _pinchBaseDistance;
  double? _pinchBaseScale;
  Offset? _pinchFocalGlobal;
  double _multiTravel = 0;
  int _multiMaxPointers = 0;
  Offset? _threeFingerStart;
  bool _browseActive = false;
  bool _drawPending = false;
  int? _pendingPointer;
  Offset? _pendingGlobal;
  Offset? _pendingLocal;
  double _pendingPressure = 0.5;

  /// Set once the fit matrix has been written to [_transform]. Until then the
  /// controller is still identity (scale=1), which must NOT count as zoomed —
  /// otherwise page-swipe is locked and the page pans at the wrong size.
  bool _fitReady = false;

  /// Current zoom relative to the scale at which the page fits the viewport.
  double get relativeZoom =>
      _transform.value.getMaxScaleOnAxis() / (_fitScale == 0 ? 1 : _fitScale);

  /// True only when clearly zoomed in past fit. Unfitted identity ≠ zoomed.
  bool get _isZoomed {
    if (!_fitReady || _fitScale <= 0) return false;
    final scale = _transform.value.getMaxScaleOnAxis();
    // InteractiveViewer can briefly sit on identity (scale=1) before the fit
    // matrix sticks. That must not lock page-swipe as "zoomed in".
    if ((scale - 1.0).abs() < 0.02 && (_fitScale - 1.0).abs() > 0.08) {
      return false;
    }
    return scale > _fitScale * 1.12;
  }

  double get _minScale =>
      widget.canvasMode == CanvasMode.infinite ? 0.012 : _fitScale;

  double get _maxScale =>
      widget.canvasMode == CanvasMode.infinite ? 80.0 : _fitScale * 8.0;

  /// Scales around the viewport center, used by the zoom controls.
  void zoomBy(double factor) {
    final size = _viewportSize;
    if (size == Size.zero) return;
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minScale, _maxScale);
    final applied = target / current;
    if ((applied - 1).abs() < 0.001) return;
    final center = Offset(size.width / 2, size.height / 2);
    final zoom = Matrix4.identity()
      ..setEntry(0, 0, applied)
      ..setEntry(1, 1, applied)
      ..setEntry(0, 3, center.dx * (1 - applied))
      ..setEntry(1, 3, center.dy * (1 - applied));
    setState(() {
      _transform.value = zoom * _transform.value;
      _clampView();
    });
  }

  /// Resets the view so the whole page is visible again.
  void fitToViewport() {
    final size = _viewportSize;
    if (size == Size.zero) return;
    setState(() {
      _transform.value = _fitMatrix(size);
      _fitReady = true;
    });
    _forceScrollUnlock();
  }

  Size get _childSize {
    final infinite = widget.canvasMode == CanvasMode.infinite;
    final pageSize = infinite ? kInfiniteCanvasSize : widget.pageSize;
    return infinite ? pageSize : PageViewportFit.childSize(pageSize);
  }

  double _computeFitScale(Size viewport) {
    if (widget.canvasMode == CanvasMode.infinite) {
      final child = _childSize;
      return math.min(
        viewport.width / child.width,
        viewport.height / child.height,
      );
    }
    // GoodNotes-style: page floats centered with a clear workspace margin.
    return PageViewportFit.fitScale(viewport, widget.pageSize);
  }

  Matrix4 _fitMatrix(Size viewport) {
    _fitScale = _computeFitScale(viewport);
    if (widget.canvasMode == CanvasMode.infinite) {
      return _matrixForScale(_fitScale, viewport);
    }
    return PageViewportFit.fitMatrix(viewport, widget.pageSize);
  }

  /// Centers [scale] in the viewport (no free translation).
  Matrix4 _matrixForScale(double scale, Size viewport) {
    final child = _childSize;
    final dx = (viewport.width - child.width * scale) / 2;
    final dy = (viewport.height - child.height * scale) / 2;
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  /// Keep the same page point under the viewport center when the keyboard
  /// (or any inset) changes the available size — never jump back to fit-zoom.
  void _retainViewOnViewportChange(Size oldViewport, Size newViewport) {
    if (oldViewport == Size.zero || newViewport == Size.zero) return;
    final current = _transform.value;
    final scale = current.getMaxScaleOnAxis();
    final inv = Matrix4.inverted(current);
    final pageFocus = MatrixUtils.transformPoint(
      inv,
      Offset(oldViewport.width / 2, oldViewport.height / 2),
    );
    _fitScale = _computeFitScale(newViewport);
    final clamped = scale.clamp(_minScale, _maxScale);
    final newCenter = Offset(newViewport.width / 2, newViewport.height / 2);
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, clamped)
      ..setEntry(1, 1, clamped)
      ..setEntry(0, 3, newCenter.dx - pageFocus.dx * clamped)
      ..setEntry(1, 3, newCenter.dy - pageFocus.dy * clamped);
    _clampView();
  }

  /// Pan translation limits for the current scale (scene → viewport).
  ({double minDx, double maxDx, double minDy, double maxDy})
  _translationBounds([double? scaleOverride]) {
    final scale = (scaleOverride ?? _transform.value.getMaxScaleOnAxis()).clamp(
      _minScale,
      _maxScale,
    );
    final child = _childSize;
    final scaledW = child.width * scale;
    final scaledH = child.height * scale;
    final vp = _viewportSize;

    late double minDx, maxDx, minDy, maxDy;
    if (scaledW <= vp.width + 0.5) {
      minDx = maxDx = (vp.width - scaledW) / 2;
    } else {
      minDx = vp.width - scaledW;
      maxDx = 0;
    }
    if (scaledH <= vp.height + 0.5) {
      minDy = maxDy = (vp.height - scaledH) / 2;
    } else {
      minDy = vp.height - scaledH;
      maxDy = 0;
    }
    return (minDx: minDx, maxDx: maxDx, minDy: minDy, maxDy: maxDy);
  }

  /// Keep scale ≥ fit and translation so the page never leaves the viewport.
  void _clampView() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (_viewportSize == Size.zero || _fitScale <= 0) return;

    final current = _transform.value;
    final scale = current.getMaxScaleOnAxis().clamp(_minScale, _maxScale);
    final b = _translationBounds(scale);
    final dx = current.storage[12].clamp(b.minDx, b.maxDx);
    final dy = current.storage[13].clamp(b.minDy, b.maxDy);
    final scaleChanged = (current.getMaxScaleOnAxis() - scale).abs() > 0.0001;
    final posChanged =
        (current.storage[12] - dx).abs() > 0.5 ||
        (current.storage[13] - dy).abs() > 0.5;
    if (!scaleChanged && !posChanged) return;

    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  void _snapToFitIfNeeded() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (_viewportSize == Size.zero) return;
    final scale = _transform.value.getMaxScaleOnAxis();
    // Keep intentional zoom. Only settle back to fit when the user has
    // pinched almost all the way out — snapping at 12% made zoom feel stuck.
    if (_fitReady && scale > _fitScale * 1.03) {
      _clampView();
      _updateScrollLock();
      return;
    }
    final fitted = _fitMatrix(_viewportSize);
    if (_transform.value != fitted) {
      _transform.value = fitted;
    }
    _fitReady = true;
    _forceScrollUnlock();
  }

  /// Smoothly pans so [pagePoint] sits near the top of the visible area
  /// (above the keyboard when open).
  void ensurePagePointVisible(Offset pagePoint, {double topFraction = 0.2}) {
    if (_viewportSize == Size.zero) return;
    final matrix = _transform.value;
    final scale = matrix.getMaxScaleOnAxis();
    final viewPoint = MatrixUtils.transformPoint(matrix, pagePoint);
    final insetBottom = _keyboardOpen
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final visibleTop = 24.0;
    final visibleBottom = _viewportSize.height - insetBottom - 24.0;
    if (visibleBottom <= visibleTop) return;

    // Already comfortably in the upper half of the visible band — stay put.
    final comfortBottom = visibleTop + (visibleBottom - visibleTop) * 0.55;
    final visibleLeft = 16.0;
    final visibleRight = _viewportSize.width - 16.0;
    final inY = viewPoint.dy >= visibleTop && viewPoint.dy <= comfortBottom;
    final inX = viewPoint.dx >= visibleLeft && viewPoint.dx <= visibleRight;
    if (inY && inX) return;

    final targetY =
        visibleTop + (_viewportSize.height - insetBottom) * topFraction;
    final targetX = viewPoint.dx.clamp(visibleLeft + 40, visibleRight - 40);
    // view = page * scale + translation
    final newDx = matrix.storage[12] + (targetX - viewPoint.dx);
    final newDy = targetY - pagePoint.dy * scale;
    final end = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, newDx)
      ..setEntry(1, 3, newDy);
    _animateTransformTo(end);
  }

  void _animateTransformTo(Matrix4 end) {
    _viewAnim?.stop();
    _viewAnim?.dispose();
    final start = Matrix4.copy(_transform.value);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final animation = Matrix4Tween(
      begin: start,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
    void tick() => _transform.value = animation.value;
    animation.addListener(tick);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeListener(tick);
        controller.dispose();
        if (identical(_viewAnim, controller)) {
          _viewAnim = null;
        }
      }
    });
    _viewAnim = controller;
    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(covariant InkCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId &&
        widget.pageId != null &&
        widget.canvasMode != CanvasMode.infinite) {
      _fittedViewport = null;
      _fittedPageSize = null;
      _fitReady = false;
      _zoomedSent = true; // force a false emit after the new fit lands
      // Unlock immediately so a mid-fit identity matrix cannot freeze swipe.
      widget.onZoomedChanged?.call(false);
      widget.onScrollLockChanged?.call(false);
      _scrollLockSent = false;
    }
  }

  @override
  void dispose() {
    _viewAnim?.dispose();
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    _updateScrollLock();
    if (widget.canvasMode == CanvasMode.infinite) {
      setState(() {});
    }
  }

  void _updateScrollLock() {
    // Lock native list physics while drawing or pinching. Zoomed-in single
    // finger must stay free so edge-overscroll can flip pages (GoodNotes).
    final lock = _drawing || _pointerGlobal.length >= 2;
    if (lock != _scrollLockSent) {
      _scrollLockSent = lock;
      widget.onScrollLockChanged?.call(lock);
    }
    final zoomed = _isZoomed;
    if (zoomed != _zoomedSent) {
      _zoomedSent = zoomed;
      widget.onZoomedChanged?.call(zoomed);
    }
  }

  void _forceScrollUnlock() {
    _scrollLockSent = false;
    widget.onScrollLockChanged?.call(false);
    final zoomed = _isZoomed;
    _zoomedSent = zoomed;
    widget.onZoomedChanged?.call(zoomed);
  }

  void _resetPinch() {
    _pinchBaseDistance = null;
    _pinchBaseScale = null;
    _pinchFocalGlobal = null;
  }

  void _applyPinchScale() {
    if (_viewportSize == Size.zero) return;
    final points = _pointerGlobal.values.toList();
    if (points.length < 2) return;
    final dist = (points[0] - points[1]).distance;
    if (dist < 12) return;
    final focal = _focalGlobal();
    if (_pinchBaseDistance == null || _pinchBaseScale == null) {
      _pinchBaseDistance = dist;
      _pinchBaseScale = _transform.value.getMaxScaleOnAxis();
      _pinchFocalGlobal = focal;
      return;
    }
    final factor = dist / _pinchBaseDistance!;
    final newScale = (_pinchBaseScale! * factor).clamp(_minScale, _maxScale);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final focalLocal = box.globalToLocal(_pinchFocalGlobal ?? focal);
    final current = _transform.value;
    final currentScale = current.getMaxScaleOnAxis().clamp(0.01, 100.0);
    final applied = newScale / currentScale;
    if ((applied - 1).abs() < 0.001) {
      _clampView();
      return;
    }
    final zoom = Matrix4.identity()
      ..setEntry(0, 0, applied)
      ..setEntry(1, 1, applied)
      ..setEntry(0, 3, focalLocal.dx * (1 - applied))
      ..setEntry(1, 3, focalLocal.dy * (1 - applied));
    _transform.value = zoom * current;
    // Clamp on finger-up; doing it every pinch tick fights the gesture.
  }

  bool _isTouch(PointerEvent event) => event.kind == PointerDeviceKind.touch;

  /// [Listener] wraps the gutter box; ink APIs expect page-local coords.
  Offset _toPageLocal(Offset local) {
    if (widget.canvasMode == CanvasMode.infinite) return local;
    return local -
        const Offset(PageViewportFit.gutter / 2, PageViewportFit.gutter / 2);
  }

  bool _isActiveStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus ||
      // Cheap pens and some Windows/Android stacks report a stylus as touch
      // but still expose a pressure range or a tiny contact patch.
      (event.kind == PointerDeviceKind.touch &&
          (event.pressureMax > 1.0 || (event.size > 0 && event.size < 0.08)));

  /// Whether this pointer should ink (vs. pan / page-browse).
  bool _canDrawWith(PointerEvent event) {
    if (widget.readOnly) return false;
    if (widget.engine.tool == InkTool.none) return false;
    if (widget.engine.tool == InkTool.image) return false;
    if (widget.engine.tool == InkTool.text) {
      return true; // tap to place text
    }
    if (_isActiveStylus(event)) return true;
    // Stylus-only mode (normal notebook pages): fingers navigate.
    if (widget.fingerPanZoom) return false;
    return _isTouch(event) || event.kind == PointerDeviceKind.mouse;
  }

  bool _canBrowseWith(PointerEvent event) {
    if (widget.canvasMode == CanvasMode.infinite) return false;
    // Anything that is not inking (finger-nav mode, hand tool, read-only)
    // drives page browse. Viewport keeps owning the gesture after the live
    // canvas hides mid-swipe.
    return !_canDrawWith(event);
  }

  Offset _focalGlobal() {
    final points = _pointerGlobal.values.toList();
    if (points.isEmpty) return Offset.zero;
    var sum = Offset.zero;
    for (final p in points) {
      sum += p;
    }
    return sum / points.length.toDouble();
  }

  void _applyPanDelta(Offset globalDelta) {
    // Page mode at fit zoom: no free pan — finger swipe changes pages instead.
    if (widget.canvasMode != CanvasMode.infinite && !_isZoomed) return;
    final matrix = Matrix4.copy(_transform.value);
    final scale = matrix.getMaxScaleOnAxis().clamp(0.01, 100.0);
    // InteractiveViewer / Matrix4 translate is in pre-scale (scene) units.
    matrix.translateByDouble(
      globalDelta.dx / scale,
      globalDelta.dy / scale,
      0,
      1,
    );
    _transform.value = matrix;
    _clampView();
  }

  bool _tryBrowsePan(Offset globalDelta) {
    final cb = widget.onBrowsePan;
    if (cb == null || widget.canvasMode == CanvasMode.infinite) return false;
    final consumed = cb(globalDelta);
    if (consumed) _browseActive = true;
    return consumed;
  }

  /// GoodNotes-style navigation:
  /// - Fit zoom: horizontal/vertical swipe flips pages.
  /// - Zoomed in: pan freely; once the page edge is hit, further swipe in that
  ///   direction overscrolls into the page strip (next/previous page).
  void _handleNavPan(Offset delta) {
    if (widget.canvasMode == CanvasMode.infinite) {
      _applyPanDelta(delta);
      return;
    }

    final horizontal = widget.browseMode == PageBrowseMode.swipeHorizontal;
    final bounds = _translationBounds();
    final dx = _transform.value.storage[12];
    final dy = _transform.value.storage[13];

    if (horizontal) {
      // Mostly vertical movement while zoomed → just pan.
      if (_isZoomed && delta.dx.abs() < delta.dy.abs() * 0.85) {
        _applyPanDelta(delta);
        return;
      }
      final atLeft = dx >= bounds.maxDx - 1.0;
      final atRight = dx <= bounds.minDx + 1.0;
      // Finger right → content right → previous page; finger left → next.
      final toPrev = delta.dx > 0;
      final toNext = delta.dx < 0;
      if ((atLeft && toPrev) || (atRight && toNext)) {
        _tryBrowsePan(Offset(delta.dx, 0));
        // Keep orthogonal pan when zoomed.
        if (_isZoomed && delta.dy.abs() > 0.01) {
          _applyPanDelta(Offset(0, delta.dy));
        }
        return;
      }
      if (_isZoomed) {
        _applyPanDelta(delta);
        return;
      }
      _tryBrowsePan(Offset(delta.dx, 0));
      return;
    }

    // Vertical continuous browse.
    if (_isZoomed && delta.dy.abs() < delta.dx.abs() * 0.85) {
      _applyPanDelta(delta);
      return;
    }
    final atTop = dy >= bounds.maxDy - 1.0;
    final atBottom = dy <= bounds.minDy + 1.0;
    final toPrev = delta.dy > 0;
    final toNext = delta.dy < 0;
    if ((atTop && toPrev) || (atBottom && toNext)) {
      _tryBrowsePan(Offset(0, delta.dy));
      if (_isZoomed && delta.dx.abs() > 0.01) {
        _applyPanDelta(Offset(delta.dx, 0));
      }
      return;
    }
    if (_isZoomed) {
      _applyPanDelta(delta);
    } else {
      _tryBrowsePan(delta);
    }
  }

  /// Visible board rect in page/local coordinates.
  Rect _visibleWorldRect(Size pageSize) {
    if (_viewportSize == Size.zero) {
      return Offset.zero & pageSize;
    }
    final inv = Matrix4.inverted(_transform.value);
    final tl = MatrixUtils.transformPoint(inv, Offset.zero);
    final br = MatrixUtils.transformPoint(
      inv,
      Offset(_viewportSize.width, _viewportSize.height),
    );
    return Rect.fromPoints(tl, br).intersect(Offset.zero & pageSize);
  }

  void _clearDrawPending() {
    _drawPending = false;
    _pendingPointer = null;
    _pendingGlobal = null;
    _pendingLocal = null;
    _pendingPressure = 0.5;
  }

  bool _shouldDeferDraw(PointerEvent event) {
    if (widget.canvasMode == CanvasMode.infinite) return false;
    if (widget.fingerPanZoom) return false;
    if (_isZoomed) return false;
    if (_isActiveStylus(event)) return false;
    if (widget.engine.tool == InkTool.text ||
        widget.engine.tool == InkTool.lasso) {
      return false;
    }
    return _isTouch(event) || event.kind == PointerDeviceKind.mouse;
  }

  bool _isPageSwipeAxis(Offset slop) {
    if (widget.canvasMode == CanvasMode.infinite || _isZoomed) return false;
    if (widget.browseMode == PageBrowseMode.swipeHorizontal) {
      return slop.dx.abs() > slop.dy.abs() * 1.15;
    }
    return slop.dy.abs() > slop.dx.abs() * 1.15;
  }

  bool _isPageSwipeSlop(Offset slop) {
    return slop.distance >= 36 && _isPageSwipeAxis(slop);
  }

  void _beginStroke(
    int pointer,
    Offset local, {
    required bool isStylus,
    required double pressure,
  }) {
    _drawPointer = pointer;
    _drawing = true;
    _drawIsStylus = isStylus;
    _clearDrawPending();
    _updateScrollLock();
    widget.onPointerDown(
      _toPageLocal(local),
      isStylus: isStylus,
      pressure: pressure,
    );
  }

  void _stopDrawing({required bool commit}) {
    if (!_drawing) return;
    if (commit) {
      widget.onPointerUp();
    } else {
      widget.engine.cancelStroke();
    }
    _drawing = false;
    _drawPointer = null;
    _drawIsStylus = false;
    _updateScrollLock();
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Palm rejection: ignore touch while a stylus stroke is active.
    if (_drawing && _drawIsStylus && _isTouch(event)) {
      return;
    }

    _pointerGlobal[event.pointer] = event.position;
    _multiMaxPointers = _multiMaxPointers < _pointerGlobal.length
        ? _pointerGlobal.length
        : _multiMaxPointers;
    _updateScrollLock();

    // A second finger cancels ink and starts pinch-zoom — unless the
    // active stroke is from a stylus (then the extra touch is treated as palm).
    if (_pointerGlobal.length >= 2) {
      if (_drawing && _drawIsStylus) {
        _pointerGlobal.remove(event.pointer);
        _updateScrollLock();
        return;
      }
      if (_drawing) {
        _stopDrawing(commit: false);
      }
      _clearDrawPending();
      _resetPinch();
      _panLastFocal = _focalGlobal();
      if (_pointerGlobal.length >= 3) {
        _threeFingerStart ??= _focalGlobal();
      }
      setState(() {});
      return;
    }

    // Single pointer.
    _multiMaxPointers = 1;
    _multiTravel = 0;
    _threeFingerStart = null;
    if (_canDrawWith(event)) {
      if (_shouldDeferDraw(event)) {
        _drawPending = true;
        _pendingPointer = event.pointer;
        _pendingGlobal = event.position;
        _pendingLocal = event.localPosition;
        _pendingPressure = event.pressure == 0 ? 0.5 : event.pressure;
        _panLastFocal = event.position;
        return;
      }
      setState(() {});
      _beginStroke(
        event.pointer,
        event.localPosition,
        isStylus: _isActiveStylus(event),
        pressure: event.pressure == 0 ? 0.5 : event.pressure,
      );
      return;
    }

    // Navigation pointer: browse pages at fit zoom / pan when zoomed in.
    if (_canBrowseWith(event)) {
      _panLastFocal = event.position;
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointerGlobal.containsKey(event.pointer)) return;
    _pointerGlobal[event.pointer] = event.position;

    if (_pointerGlobal.length >= 2) {
      _clearDrawPending();
      final focal = _focalGlobal();
      if (_keyboardOpen) {
        _panLastFocal = focal;
        return;
      }
      if (_panLastFocal != null) {
        final delta = focal - _panLastFocal!;
        _multiTravel += delta.distance;
        // Pinch-zoom only; pan only while zoomed-in. Never free-drag at fit.
        _applyPinchScale();
        if (_isZoomed || widget.canvasMode == CanvasMode.infinite) {
          _applyPanDelta(delta);
        } else {
          _clampView();
        }
        if (_pointerGlobal.length >= 3 && _threeFingerStart != null) {
          final swipe = focal - _threeFingerStart!;
          if (swipe.dx.abs() > 64 && swipe.dx.abs() > swipe.dy.abs() * 1.4) {
            widget.onThreeFingerSwipe?.call(swipe.dx < 0 ? -1 : 1);
            _threeFingerStart = null;
          }
        }
      }
      _panLastFocal = focal;
      return;
    }

    if (_drawing && event.pointer == _drawPointer) {
      widget.onPointerMove(
        _toPageLocal(event.localPosition),
        pressure: event.pressure == 0 ? 0.5 : event.pressure,
      );
      return;
    }

    if (_drawPending && event.pointer == _pendingPointer) {
      final slop = event.position - (_pendingGlobal ?? event.position);
      if (_isPageSwipeSlop(slop)) {
        // Finger/mouse swipe on the page. Lock the viewport so both
        // listeners do not double-drive the PageView.
        _clearDrawPending();
        _scrollLockSent = true;
        widget.onScrollLockChanged?.call(true);
        _handleNavPan(event.position - (_panLastFocal ?? event.position));
        _panLastFocal = event.position;
        return;
      }
      if (_isPageSwipeAxis(slop)) {
        // Still looks like a page turn; wait for the 36px commit.
        return;
      }
      if (slop.distance >= 10) {
        final local = _pendingLocal ?? event.localPosition;
        setState(() {});
        _beginStroke(
          event.pointer,
          local,
          isStylus: false,
          pressure: _pendingPressure,
        );
        widget.onPointerMove(
          _toPageLocal(event.localPosition),
          pressure: event.pressure == 0 ? 0.5 : event.pressure,
        );
        return;
      }
      return;
    }

    // Fit zoom → page flip. Zoomed → pan, then edge-overscroll → page flip.
    if (!_keyboardOpen && !_drawing && _panLastFocal != null) {
      final delta = event.position - _panLastFocal!;
      _handleNavPan(delta);
      _panLastFocal = event.position;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMulti = _pointerGlobal.length >= 2;
    final maxPointers = _multiMaxPointers;
    final travel = _multiTravel;
    final wasBrowse = _browseActive;
    _pointerGlobal.remove(event.pointer);

    if (_drawPending && event.pointer == _pendingPointer) {
      final startGlobal = _pendingGlobal ?? event.position;
      final slop = event.position - startGlobal;
      if (_isPageSwipeSlop(slop) ||
          (slop.distance >= 24 && _isPageSwipeAxis(slop))) {
        _clearDrawPending();
      } else {
        final local = _pendingLocal ?? event.localPosition;
        _beginStroke(
          event.pointer,
          local,
          isStylus: false,
          pressure: _pendingPressure,
        );
        if (slop.distance > 2) {
          widget.onPointerMove(
            _toPageLocal(event.localPosition),
            pressure: event.pressure == 0 ? 0.5 : event.pressure,
          );
        }
        _stopDrawing(commit: true);
        setState(() {});
      }
    }

    if (event.pointer == _drawPointer) {
      _stopDrawing(commit: true);
      setState(() {});
    }

    if (wasMulti && _pointerGlobal.length < 2) {
      if (maxPointers == 2 && travel < 18) {
        widget.onTwoFingerTap?.call();
      }
      _resetPinch();
      _threeFingerStart = null;
      _multiTravel = 0;
      _multiMaxPointers = _pointerGlobal.length;
      _snapToFitIfNeeded();
    }

    if (_pointerGlobal.isEmpty) {
      if (wasBrowse) {
        widget.onBrowsePanEnd?.call();
        _browseActive = false;
      }
      _panLastFocal = null;
      _multiMaxPointers = 0;
      _multiTravel = 0;
      _snapToFitIfNeeded();
    } else if (_pointerGlobal.length >= 2) {
      _panLastFocal = _focalGlobal();
      _resetPinch();
    } else {
      _panLastFocal = _pointerGlobal.values.first;
      _resetPinch();
    }
    _updateScrollLock();
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerGlobal.remove(event.pointer);
    if (event.pointer == _pendingPointer) {
      _clearDrawPending();
    }
    if (event.pointer == _drawPointer) {
      _stopDrawing(commit: false);
    }
    _resetPinch();
    _panLastFocal = _pointerGlobal.isEmpty ? null : _focalGlobal();
    if (_pointerGlobal.isEmpty) {
      if (_browseActive) {
        widget.onBrowsePanEnd?.call();
        _browseActive = false;
      }
      _multiMaxPointers = 0;
      _multiTravel = 0;
      _snapToFitIfNeeded();
    }
    _updateScrollLock();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final infinite = widget.canvasMode == CanvasMode.infinite;
    final pageSize = infinite ? kInfiniteCanvasSize : widget.pageSize;
    final margin = infinite ? 2000.0 : 120.0;

    // InteractiveViewer only for pinch-zoom; pan is handled manually
    // so one-finger drawing is never stolen by the viewer.
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _viewportSize = viewport;
        _keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        if (!infinite && viewport.width > 0) {
          final pageChanged = _fittedPageSize != widget.pageSize;
          final viewportChanged = _fittedViewport != viewport;
          if (_fittedViewport == null || pageChanged) {
            final firstFit = _fittedViewport == null;
            _fittedPageSize = widget.pageSize;
            _fittedViewport = viewport;
            final matrix = _fitMatrix(viewport);
            if (firstFit) {
              // InteractiveViewer is not listening yet this build — safe to
              // write the fit matrix synchronously so the first paint is correct
              // and page-swipe is not locked by identity scale=1.
              _transform.value = matrix;
              _fitReady = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _forceScrollUnlock();
              });
            } else {
              _fitReady = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _transform.value = matrix;
                _fitReady = true;
                _forceScrollUnlock();
              });
            }
          } else if (viewportChanged) {
            final oldViewport = _fittedViewport!;
            _fittedViewport = viewport;
            // Keyboard / safe-area changes must not throw the user back to
            // fit-zoom while they are typing.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _retainViewOnViewportChange(oldViewport, viewport);
                _fitReady = true;
              }
            });
          }
        }
        final visible = _visibleWorldRect(pageSize);
        final minScale = _minScale <= 0 ? 0.01 : _minScale;
        final maxScale = _maxScale;

        return InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          // Page mode: no slack margin — otherwise the page can drift.
          boundaryMargin: EdgeInsets.all(infinite ? margin : 0),
          minScale: minScale,
          maxScale: maxScale,
          // Pinch/pan are handled in [Listener] so they never race PageView.
          panEnabled: _keyboardOpen && !_drawing,
          scaleEnabled: false,
          onInteractionEnd: infinite
              ? null
              : (_) {
                  _snapToFitIfNeeded();
                },
          // Listener fills the gutter too so left/right swipes starting on the
          // margin still drive page browse. Drawing coords are shifted back
          // into page space below.
          child: SizedBox(
            width: pageSize.width + (infinite ? 0 : 64),
            height: pageSize.height + (infinite ? 0 : 64),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Drawing / browse listener sits under overlays so a stylus
                // on a wheel, handle or button never starts an ink stroke.
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: Center(
                      child: GestureDetector(
                        onDoubleTap: widget.onDoubleTap,
                        child: Container(
                          width: pageSize.width,
                          height: pageSize.height,
                          decoration: BoxDecoration(
                            boxShadow: infinite
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 32,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                          ),
                          child: RepaintBoundary(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (infinite)
                                  CustomPaint(
                                    size: pageSize,
                                    isComplex: true,
                                    willChange: true,
                                    painter: PageBackgroundPainter(
                                      template: widget.template,
                                      pdfImage: widget.backgroundImage,
                                      paper: widget.paper,
                                      visibleWorldRect: visible,
                                      infinite: true,
                                    ),
                                  )
                                else
                                  CachedPageBackground(
                                    pageSize: pageSize,
                                    template: widget.template,
                                    paper: widget.paper,
                                    pdfImage: widget.backgroundImage,
                                  ),
                                if (!widget.hideInk)
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      widget.engine,
                                      InkPainter.settledCacheTick,
                                    ]),
                                    builder: (context, _) {
                                      final erasing =
                                          widget.engine.tool == InkTool.eraser;
                                      return CustomPaint(
                                        size: pageSize,
                                        isComplex: true,
                                        willChange:
                                            widget.engine.activeStroke != null,
                                        painter: InkPainter(
                                          strokes: widget.engine.strokes,
                                          activeStroke:
                                              widget.engine.activeStroke,
                                          lassoPoints:
                                              widget.engine.lassoPoints,
                                          selectedIds:
                                              widget.engine.selectedIds,
                                          visibleWorldRect: infinite
                                              ? visible
                                              : null,
                                          eraserCursor: erasing
                                              ? widget.engine.eraserCursor
                                              : null,
                                          eraserRadius: erasing
                                              ? widget.engine.width / 2
                                              : null,
                                          paintEpoch: widget.engine.paintEpoch,
                                          cacheSettled: true,
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.overlay != null)
                  SizedBox(
                    width: pageSize.width,
                    height: pageSize.height,
                    child: widget.overlay,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
