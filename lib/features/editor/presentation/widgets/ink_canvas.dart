import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/content_models.dart';
import '../../domain/ink_engine.dart';
import '../../domain/ink_models.dart';
import 'ink_painter.dart';
import 'cached_page_background.dart';
import 'page_background_painter.dart';

/// Large but finite board for "infinite" documents.
/// Viewport culling keeps paint cost proportional to what's on screen.
const Size kInfiniteCanvasSize = Size(32000, 32000);

class InkCanvas extends StatefulWidget {
  const InkCanvas({
    super.key,
    required this.engine,
    required this.template,
    required this.pageSize,
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
    this.onTwoFingerTap,
    this.onThreeFingerSwipe,
    this.onDoubleTap,
  });

  final InkEngine engine;
  final PageTemplate template;
  final Size pageSize;
  final ui.Image? backgroundImage;
  final PaperTemplate? paper;
  final CanvasMode canvasMode;
  final bool fingerPanZoom;
  final bool readOnly;
  final bool hideInk;
  final Widget? overlay;
  final PageBrowseMode browseMode;

  /// Finger pan at fit-zoom: used for page browse (swipe/scroll).
  /// Return true if the parent consumed the gesture (skip canvas pan).
  final bool Function(Offset globalDelta)? onBrowsePan;
  final VoidCallback? onBrowsePanEnd;

  /// Lock PageView/ListView while drawing, pinching, or zoomed in.
  final ValueChanged<bool>? onScrollLockChanged;

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
  double? _pinchBaseDistance;
  double? _pinchBaseScale;
  Offset? _pinchFocalGlobal;
  double _multiTravel = 0;
  int _multiMaxPointers = 0;
  Offset? _threeFingerStart;
  bool _browseActive = false;

  /// Current zoom relative to the scale at which the page fits the viewport.
  double get relativeZoom =>
      _transform.value.getMaxScaleOnAxis() / (_fitScale == 0 ? 1 : _fitScale);

  /// True only when clearly zoomed in — tiny float noise must not block swipes.
  bool get _isZoomed =>
      _fitScale > 0 &&
      _transform.value.getMaxScaleOnAxis() > _fitScale * 1.12;

  /// Inset so the fitted page keeps a small gap to the viewport edges.
  static const double _fitPadding = 22;

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
    setState(() => _transform.value = _fitMatrix(size));
  }

  Size get _childSize {
    final infinite = widget.canvasMode == CanvasMode.infinite;
    final pageSize = infinite ? kInfiniteCanvasSize : widget.pageSize;
    return infinite
        ? pageSize
        : Size(pageSize.width + 64, pageSize.height + 64);
  }

  double _computeFitScale(Size viewport) {
    final child = _childSize;
    // Leave a little breathing room so the page never sits flush to the edges.
    final availW = (viewport.width - 2 * _fitPadding).clamp(1.0, double.infinity);
    final availH = (viewport.height - 2 * _fitPadding).clamp(1.0, double.infinity);
    final scaleW = availW / child.width;
    final scaleH = availH / child.height;
    return scaleW < scaleH ? scaleW : scaleH;
  }

  Matrix4 _fitMatrix(Size viewport) {
    _fitScale = _computeFitScale(viewport);
    return _matrixForScale(_fitScale, viewport);
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

  /// Keep scale ≥ fit and translation so the page never leaves the viewport.
  void _clampView() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (_viewportSize == Size.zero || _fitScale <= 0) return;

    final current = _transform.value;
    final scale = current.getMaxScaleOnAxis().clamp(_minScale, _maxScale);
    final child = _childSize;
    final scaledW = child.width * scale;
    final scaledH = child.height * scale;
    final vp = _viewportSize;

    double minDx;
    double maxDx;
    double minDy;
    double maxDy;
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

    final dx = current.storage[12].clamp(minDx, maxDx);
    final dy = current.storage[13].clamp(minDy, maxDy);
    final scaleChanged =
        (current.getMaxScaleOnAxis() - scale).abs() > 0.0001;
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
    // Anything at/near fit zoom snaps back to a perfectly centered page.
    if (_transform.value.getMaxScaleOnAxis() > _fitScale * 1.12) {
      _clampView();
      _updateScrollLock();
      return;
    }
    final fitted = _fitMatrix(_viewportSize);
    if (_transform.value != fitted) {
      _transform.value = fitted;
    }
    _forceScrollUnlock();
  }

  /// Smoothly pans so [pagePoint] sits near the top of the visible area
  /// (above the keyboard when open).
  void ensurePagePointVisible(
    Offset pagePoint, {
    double topFraction = 0.2,
  }) {
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

    final targetY = visibleTop + (_viewportSize.height - insetBottom) * topFraction;
    final targetX = viewPoint.dx.clamp(
      visibleLeft + 40,
      visibleRight - 40,
    );
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
    final animation = Matrix4Tween(begin: start, end: end).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
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
    // Lock page browsing only while drawing, pinching, or actually zoomed-in.
    // Never lock for the keyboard — that permanently blocked page swipes.
    final lock = _drawing || _pointerGlobal.length >= 2 || _isZoomed;
    if (lock == _scrollLockSent) return;
    _scrollLockSent = lock;
    widget.onScrollLockChanged?.call(lock);
  }

  void _forceScrollUnlock() {
    _scrollLockSent = true; // ensure the false below is emitted
    _scrollLockSent = false;
    widget.onScrollLockChanged?.call(false);
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
    _clampView();
  }

  bool _isStylusOrMouse(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus ||
        event.kind == PointerDeviceKind.mouse;
  }

  bool _isTouch(PointerEvent event) => event.kind == PointerDeviceKind.touch;

  /// One finger draws (unless stylus-only mode). Stylus/mouse always draw.
  bool _canDrawWith(PointerEvent event) {
    if (widget.readOnly) return false;
    if (widget.engine.tool == InkTool.none) return false;
    if (widget.engine.tool == InkTool.image) return false;
    if (widget.engine.tool == InkTool.text) {
      return true; // tap to place text
    }
    if (_isStylusOrMouse(event)) return true;
    if (_isTouch(event)) {
      // Stylus-only navigation mode: finger does not draw.
      if (widget.fingerPanZoom) return false;
      return true;
    }
    return true;
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
    if (_isZoomed) return false;
    final consumed = cb(globalDelta);
    if (consumed) _browseActive = true;
    return consumed;
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
      _drawPointer = event.pointer;
      _drawing = true;
      _drawIsStylus = _isStylusOrMouse(event);
      setState(() {});
      _updateScrollLock();
      widget.onPointerDown(
        event.localPosition,
        isStylus:
            event.kind == PointerDeviceKind.stylus ||
            event.kind == PointerDeviceKind.invertedStylus,
        pressure: event.pressure == 0 ? 0.5 : event.pressure,
      );
      return;
    }

    // Finger navigation: stylus/mouse writes, a finger browses or pans.
    if ((widget.fingerPanZoom || widget.readOnly) && _isTouch(event)) {
      _panLastFocal = event.position;
      setState(() {});
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_pointerGlobal.containsKey(event.pointer)) return;
    _pointerGlobal[event.pointer] = event.position;

    if (_pointerGlobal.length >= 2) {
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
        event.localPosition,
        pressure: event.pressure == 0 ? 0.5 : event.pressure,
      );
      return;
    }

    // At fit zoom, drive page browsing from the canvas (PageView alone is
    // unreliable under InteractiveViewer). When zoomed, pan the page instead.
    if (!_keyboardOpen &&
        !_drawing &&
        _panLastFocal != null &&
        (widget.readOnly || widget.fingerPanZoom)) {
      final delta = event.position - _panLastFocal!;
      if (_isZoomed) {
        _applyPanDelta(delta);
      } else {
        _tryBrowsePan(delta);
      }
      _panLastFocal = event.position;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMulti = _pointerGlobal.length >= 2;
    final maxPointers = _multiMaxPointers;
    final travel = _multiTravel;
    final wasBrowse = _browseActive;
    _pointerGlobal.remove(event.pointer);

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
    if (event.pointer == _drawPointer) {
      _stopDrawing(commit: false);
    }
    _resetPinch();
    _panLastFocal = _pointerGlobal.isEmpty ? null : _focalGlobal();
    if (_pointerGlobal.isEmpty) {
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
            _fittedPageSize = widget.pageSize;
            _fittedViewport = viewport;
            final matrix = _fitMatrix(viewport);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _transform.value = matrix;
              _forceScrollUnlock();
            });
          } else if (viewportChanged) {
            final oldViewport = _fittedViewport!;
            _fittedViewport = viewport;
            // Keyboard / safe-area changes must not throw the user back to
            // fit-zoom while they are typing.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _retainViewOnViewportChange(oldViewport, viewport);
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
          onInteractionUpdate: infinite
              ? null
              : (_) {
                  _clampView();
                },
          onInteractionEnd: infinite
              ? null
              : (_) {
                  _snapToFitIfNeeded();
                },
          child: SizedBox(
            width: pageSize.width + (infinite ? 0 : 64),
            height: pageSize.height + (infinite ? 0 : 64),
            child: Center(
              child: GestureDetector(
                onDoubleTap: widget.onDoubleTap,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: _handlePointerUp,
                  onPointerCancel: _handlePointerCancel,
                  child: Container(
                    width: pageSize.width,
                    height: pageSize.height,
                    decoration: BoxDecoration(
                      boxShadow: infinite
                          ? null
                          : [
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
                        // Rebuild only ink while drawing — keep paper static.
                        if (!widget.hideInk)
                          AnimatedBuilder(
                            animation: widget.engine,
                            builder: (context, _) {
                              final erasing =
                                  widget.engine.tool == InkTool.eraser;
                              return CustomPaint(
                                size: pageSize,
                                isComplex: true,
                                willChange: true,
                                painter: InkPainter(
                                  strokes: widget.engine.strokes,
                                  activeStroke: widget.engine.activeStroke,
                                  lassoPoints: widget.engine.lassoPoints,
                                  selectedIds: widget.engine.selectedIds,
                                  visibleWorldRect: infinite ? visible : null,
                                  eraserCursor: erasing
                                      ? widget.engine.eraserCursor
                                      : null,
                                  eraserRadius: erasing
                                      ? widget.engine.width / 2
                                      : null,
                                  paintEpoch: widget.engine.paintEpoch,
                                ),
                              );
                            },
                          ),
                        if (widget.overlay != null) widget.overlay!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
