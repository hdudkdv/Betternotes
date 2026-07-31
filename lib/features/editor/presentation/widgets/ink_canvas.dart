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
  Offset? _panLastFocal;
  Size _viewportSize = Size.zero;
  bool _browseActive = false;
  double _fitScale = 1;
  Size? _fittedViewport;
  Size? _fittedPageSize;
  AnimationController? _viewAnim;
  bool _keyboardOpen = false;

  /// Current zoom relative to the scale at which the page fits the viewport.
  double get relativeZoom =>
      _transform.value.getMaxScaleOnAxis() / (_fitScale == 0 ? 1 : _fitScale);

  bool get _isZoomed => relativeZoom > 1.05;

  /// Scales around the viewport center, used by the zoom controls.
  void zoomBy(double factor) {
    final size = _viewportSize;
    if (size == Size.zero) return;
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_fitScale * 0.4, _fitScale * 8.0);
    final applied = target / current;
    if ((applied - 1).abs() < 0.001) return;
    final center = Offset(size.width / 2, size.height / 2);
    final zoom = Matrix4.identity()
      ..setEntry(0, 0, applied)
      ..setEntry(1, 1, applied)
      ..setEntry(0, 3, center.dx * (1 - applied))
      ..setEntry(1, 3, center.dy * (1 - applied));
    setState(() => _transform.value = zoom * _transform.value);
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
    return (viewport.width / child.width) < (viewport.height / child.height)
        ? viewport.width / child.width
        : viewport.height / child.height;
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
    final clamped = scale.clamp(_fitScale * 0.4, _fitScale * 8.0);
    final newCenter = Offset(newViewport.width / 2, newViewport.height / 2);
    _transform.value = Matrix4.identity()
      ..setEntry(0, 0, clamped)
      ..setEntry(1, 1, clamped)
      ..setEntry(0, 3, newCenter.dx - pageFocus.dx * clamped)
      ..setEntry(1, 3, newCenter.dy - pageFocus.dy * clamped);
  }

  /// At fit zoom, keep the page centered — InteractiveViewer two-finger
  /// gestures would otherwise translate freely (including vertically).
  void _clampFitTranslation() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (_viewportSize == Size.zero) return;
    final scale = _transform.value.getMaxScaleOnAxis();
    if (scale > _fitScale * 1.05) return;
    final target = scale < _fitScale * 0.98
        ? _fitMatrix(_viewportSize)
        : _matrixForScale(
            scale.clamp(_fitScale, _fitScale * 1.05),
            _viewportSize,
          );
    final current = _transform.value;
    if ((current.storage[12] - target.storage[12]).abs() > 0.5 ||
        (current.storage[13] - target.storage[13]).abs() > 0.5 ||
        (current.getMaxScaleOnAxis() - target.getMaxScaleOnAxis()).abs() >
            0.001) {
      _transform.value = target;
    }
  }

  void _snapToFitIfNeeded() {
    if (widget.canvasMode == CanvasMode.infinite) return;
    if (_viewportSize == Size.zero) return;
    if (_transform.value.getMaxScaleOnAxis() > _fitScale * 1.05) return;
    final fitted = _fitMatrix(_viewportSize);
    if (_transform.value != fitted) {
      _transform.value = fitted;
    }
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
    if (widget.canvasMode == CanvasMode.infinite) {
      setState(() {});
    }
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
    // Page mode at fit zoom is axis-locked to page browsing — no free pan.
    if (widget.canvasMode != CanvasMode.infinite && !_isZoomed) return;
    final matrix = Matrix4.copy(_transform.value);
    final scale = matrix.getMaxScaleOnAxis().clamp(0.01, 100.0);
    matrix.translateByDouble(
      globalDelta.dx / scale,
      globalDelta.dy / scale,
      0,
      1,
    );
    _transform.value = matrix;
  }

  bool _tryBrowsePan(Offset globalDelta) {
    final cb = widget.onBrowsePan;
    if (cb == null || widget.canvasMode == CanvasMode.infinite) return false;
    // Only browse when roughly fit-to-view (not deep-zoomed).
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
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerGlobal[event.pointer] = event.position;

    // A second finger always cancels ink and starts pan / browse.
    if (_pointerGlobal.length >= 2) {
      if (_drawing) {
        _stopDrawing(commit: false);
      }
      _panLastFocal = _focalGlobal();
      _browseActive = false;
      setState(() {});
      return;
    }

    // Single pointer.
    if (_canDrawWith(event)) {
      _drawPointer = event.pointer;
      _drawing = true;
      setState(() {});
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
      // While the keyboard is open, InteractiveViewer owns pan/zoom gestures.
      if (_keyboardOpen) {
        _panLastFocal = focal;
        return;
      }
      if (_panLastFocal != null) {
        final delta = focal - _panLastFocal!;
        final atFitBrowse =
            widget.canvasMode != CanvasMode.infinite &&
            !_isZoomed &&
            widget.onBrowsePan != null;
        if (atFitBrowse) {
          // At fit zoom the parent owns navigation. In particular, do not
          // turn an off-axis drag into a vertical/horizontal canvas pan.
          _tryBrowsePan(delta);
          _clampFitTranslation();
        } else if (!_tryBrowsePan(delta)) {
          _applyPanDelta(delta);
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

    // At fit zoom, PageView/ListView owns one-finger navigation across the
    // whole workspace. A zoomed canvas stays pannable with one finger.
    // With the keyboard open, InteractiveViewer handles pan instead.
    if (!_keyboardOpen &&
        !_drawing &&
        _panLastFocal != null &&
        (widget.readOnly || widget.fingerPanZoom)) {
      final delta = event.position - _panLastFocal!;
      if (_isZoomed) {
        _applyPanDelta(delta);
      }
      _panLastFocal = event.position;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasMulti = _pointerGlobal.length >= 2;
    _pointerGlobal.remove(event.pointer);

    if (event.pointer == _drawPointer) {
      _stopDrawing(commit: true);
      setState(() {});
    }

    if ((wasMulti || _browseActive) && _pointerGlobal.length < 2) {
      if (_browseActive) {
        widget.onBrowsePanEnd?.call();
      }
      _browseActive = false;
      _snapToFitIfNeeded();
    }

    if (_pointerGlobal.length >= 2) {
      _panLastFocal = _focalGlobal();
    } else if (_pointerGlobal.length == 1) {
      _panLastFocal = _pointerGlobal.values.first;
    } else {
      _panLastFocal = null;
      _snapToFitIfNeeded();
    }
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    final wasBrowse = _browseActive;
    _pointerGlobal.remove(event.pointer);
    if (event.pointer == _drawPointer) {
      _stopDrawing(commit: false);
    }
    if (wasBrowse && _pointerGlobal.length < 2) {
      widget.onBrowsePanEnd?.call();
      _browseActive = false;
    }
    _panLastFocal = _pointerGlobal.isEmpty ? null : _focalGlobal();
    if (_pointerGlobal.isEmpty) {
      _snapToFitIfNeeded();
    }
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
              if (mounted) _transform.value = matrix;
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
        final minScale = infinite ? 0.012 : _fitScale * 0.4;
        final maxScale = infinite ? 80.0 : _fitScale * 8.0;

        return InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          boundaryMargin: EdgeInsets.all(margin),
          minScale: minScale,
          maxScale: maxScale,
          // Keyboard up: allow finger-panning the page while typing.
          panEnabled: _keyboardOpen,
          scaleEnabled: true,
          onInteractionUpdate: infinite
              ? null
              : (_) {
                  _clampFitTranslation();
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
