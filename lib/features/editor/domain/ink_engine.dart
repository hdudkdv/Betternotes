import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';

import 'ink_models.dart';
import 'geometry_guides.dart';

/// Captures strokes, manages undo/redo, eraser and lasso operations.
class InkEngine extends ChangeNotifier {
  InkEngine({List<InkStroke>? initial}) {
    if (initial != null) {
      _strokes = List.of(initial);
    }
  }

  static const _uuid = Uuid();

  List<InkStroke> _strokes = [];
  InkStroke? _activeStroke;
  final List<_HistoryEntry> _undo = [];
  final List<_HistoryEntry> _redo = [];
  List<InkStroke>? _eraserBefore;
  bool _paintScheduled = false;
  int _paintEpoch = 0;

  InkTool tool = InkTool.pen;
  int colorValue = 0xFF1A1A1A;
  double width = 2.5;
  StrokeStyle strokeStyle = StrokeStyle.solid;
  EraserMode eraserMode = EraserMode.stroke;
  Offset? eraserCursor;
  Set<ContentKind> eraseTargets = {...kDefaultContentTargets};
  Set<ContentKind> lassoTargets = {...kDefaultContentTargets};

  /// 0 = ignore stylus pressure, 1 = full pressure response.
  double pressureSensitivity = 0.0;

  /// Optional ruler/compass constraint used with freehand tools.
  DrawingGuide guide = DrawingGuide.none;

  /// When set (ruler/compass overlays), freehand samples snap onto the aid.
  Offset Function(Offset point)? pointConstraint;

  List<Offset> _lassoPoints = [];
  List<Offset> _closedLasso = [];
  Set<String> selectedIds = {};
  Offset? _guideOrigin;

  List<InkStroke> get strokes => List.unmodifiable(_strokes);
  InkStroke? get activeStroke => _activeStroke;
  List<Offset> get lassoPoints => List.unmodifiable(_lassoPoints);
  List<Offset> get lastClosedLasso => List.unmodifiable(_closedLasso);

  /// Visual / hit radius of the eraser tip. Precise mode uses a much smaller
  /// contact than stroke/section so "Genau" only lifts a narrow band of ink.
  double get eraseRadius {
    if (eraserMode == EraserMode.precise) {
      return (width * 0.22).clamp(0.6, width * 0.35);
    }
    return width / 2;
  }

  /// Bumps whenever the active stroke geometry changes in place.
  int get paintEpoch => _paintEpoch;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void _notifyNow() {
    _paintScheduled = false;
    _paintEpoch++;
    notifyListeners();
  }

  /// Coalesce high-frequency pointer moves to one rebuild per frame.
  void _notifyPaint() {
    if (_paintScheduled) return;
    _paintScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!_paintScheduled) return;
      _notifyNow();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void setTool(InkTool value) {
    // Legacy exclusive guide tools become overlays on the pen.
    if (value == InkTool.ruler) {
      tool = tool.isFreehand ? tool : InkTool.pen;
      guide = guide == DrawingGuide.ruler ? DrawingGuide.none : DrawingGuide.ruler;
      selectedIds = {};
      _lassoPoints = [];
      eraserCursor = null;
      notifyListeners();
      return;
    }
    if (value == InkTool.compass) {
      tool = tool.isFreehand ? tool : InkTool.pen;
      guide = guide == DrawingGuide.compass
          ? DrawingGuide.none
          : DrawingGuide.compass;
      selectedIds = {};
      _lassoPoints = [];
      eraserCursor = null;
      notifyListeners();
      return;
    }

    tool = value;
    selectedIds = {};
    _lassoPoints = [];
    eraserCursor = null;
    if (!value.isFreehand) {
      guide = DrawingGuide.none;
    }
    // Sensible pressure defaults per tool.
    if (value == InkTool.fountain || value == InkTool.pencil) {
      if (pressureSensitivity < 0.05) pressureSensitivity = 0.85;
    } else if (value == InkTool.pen) {
      if (pressureSensitivity > 0.95) pressureSensitivity = 0.0;
    }
    notifyListeners();
  }

  void setGuide(DrawingGuide value) {
    guide = guide == value ? DrawingGuide.none : value;
    notifyListeners();
  }

  void setStrokeStyle(StrokeStyle value) {
    strokeStyle = value;
    notifyListeners();
  }

  Offset _constrained(Offset point) {
    final c = pointConstraint;
    if (c != null) return c(point);
    return point;
  }

  void setPressureSensitivity(double value) {
    pressureSensitivity = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Ballpoint vs fountain under the shared "Pen" toolbar button.
  void setPenSubtype({required bool fountain}) {
    tool = fountain ? InkTool.fountain : InkTool.pen;
    if (fountain && pressureSensitivity < 0.05) {
      pressureSensitivity = 0.85;
    }
    if (!fountain && pressureSensitivity > 0.95) {
      pressureSensitivity = 0.0;
    }
    notifyListeners();
  }

  double _effectivePressure(double raw) {
    final s = pressureSensitivity.clamp(0.0, 1.0);
    return (0.5 + (raw.clamp(0.0, 1.0) - 0.5) * s).clamp(0.05, 1.0);
  }

  void setColor(int value) {
    colorValue = value;
    notifyListeners();
  }

  void setWidth(double value) {
    width = value;
    notifyListeners();
  }

  void setEraserMode(EraserMode mode) {
    eraserMode = mode;
    notifyListeners();
  }

  void setEraseTargets(Set<ContentKind> value) {
    eraseTargets = Set<ContentKind>.of(value);
    notifyListeners();
  }

  void setLassoTargets(Set<ContentKind> value) {
    lassoTargets = Set<ContentKind>.of(value);
    notifyListeners();
  }

  void clearSelection() {
    if (selectedIds.isEmpty && _lassoPoints.isEmpty && _closedLasso.isEmpty) {
      return;
    }
    selectedIds = {};
    _lassoPoints = [];
    _closedLasso = [];
    notifyListeners();
  }

  bool selectionHits(Offset point, {double tolerance = 14}) {
    if (selectedIds.isEmpty) return false;
    for (final s in _strokes) {
      if (!selectedIds.contains(s.id)) continue;
      if (s.hitsPoint(point, tolerance: tolerance)) return true;
    }
    return false;
  }

  void replaceStrokes(
    List<InkStroke> strokes, {
    bool recordHistory = false,
    bool quiet = false,
  }) {
    if (recordHistory) {
      _pushUndo(_HistoryEntry.replace(List.of(_strokes)));
    } else {
      _undo.clear();
      _redo.clear();
    }
    _strokes = List.of(strokes);
    _activeStroke = null;
    _lassoPoints = [];
    selectedIds = {};
    eraserCursor = null;
    _paintEpoch++;
    if (!quiet) {
      notifyListeners();
    }
  }

  void beginStroke(Offset point, {double pressure = 0.5, int t = 0}) {
    if (tool == InkTool.none ||
        tool == InkTool.text ||
        tool == InkTool.shape ||
        tool == InkTool.image) {
      return;
    }

    if (tool == InkTool.lasso) {
      _lassoPoints = [point];
      selectedIds = {};
      _notifyNow();
      return;
    }

    if (tool == InkTool.eraser) {
      _eraserBefore = List.of(_strokes);
      eraserCursor = point;
      _eraseAt(point);
      return;
    }

    final p = _effectivePressure(pressure);
    final start = _constrained(point);
    _guideOrigin = start;
    _activeStroke = InkStroke(
      id: _uuid.v4(),
      tool: tool,
      colorValue: colorValue,
      width: width,
      style: tool.isFreehand ? strokeStyle : StrokeStyle.solid,
      points: <StrokePoint>[
        StrokePoint(x: start.dx, y: start.dy, pressure: p, t: t),
      ],
    );
    _notifyNow();
  }

  void appendStroke(Offset point, {double pressure = 0.5, int t = 0}) {
    if (tool == InkTool.none ||
        tool == InkTool.text ||
        tool == InkTool.shape ||
        tool == InkTool.image) {
      return;
    }

    if (tool == InkTool.lasso) {
      if (_lassoPoints.isEmpty) return;
      _lassoPoints = [..._lassoPoints, point];
      _notifyPaint();
      return;
    }

    if (tool == InkTool.eraser) {
      eraserCursor = point;
      _eraseAt(point);
      return;
    }

    final active = _activeStroke;
    if (active == null) return;
    final p = _effectivePressure(pressure);
    final origin = _guideOrigin ?? active.points.first.offset;

    // Overlay aids (ruler/compass) snap samples onto the guide geometry —
    // the user chooses where ink is laid, rather than auto-drawing a circle.
    if (pointConstraint != null) {
      final snapped = _constrained(point);
      final last = active.points.last;
      final dx = snapped.dx - last.x;
      final dy = snapped.dy - last.y;
      if (dx * dx + dy * dy < 0.09) return;
      active.points.add(
        StrokePoint(x: snapped.dx, y: snapped.dy, pressure: p, t: t),
      );
      _notifyPaint();
      return;
    }

    // Legacy angle-snap ruler (no overlay).
    if (guide == DrawingGuide.ruler) {
      final end = snapRulerEndpoint(origin, point);
      active.points
        ..clear()
        ..add(StrokePoint(x: origin.dx, y: origin.dy, pressure: p, t: t))
        ..add(StrokePoint(x: end.dx, y: end.dy, pressure: p, t: t));
      _notifyPaint();
      return;
    }

    final last = active.points.last;
    final dx = point.dx - last.x;
    final dy = point.dy - last.y;
    // Pencil keeps a slightly coarser sample than pen so grain stays cheap.
    final minDist2 = tool == InkTool.pencil ? 0.36 : 0.16;
    if (dx * dx + dy * dy < minDist2) return;

    active.points.add(
      StrokePoint(x: point.dx, y: point.dy, pressure: p, t: t),
    );
    _notifyPaint();
  }

  void cancelStroke() {
    if (tool == InkTool.eraser) {
      if (_eraserBefore != null) {
        _strokes = List.of(_eraserBefore!);
        _eraserBefore = null;
      }
      eraserCursor = null;
      notifyListeners();
      return;
    }
    if (_activeStroke == null && _lassoPoints.isEmpty) return;
    _activeStroke = null;
    _guideOrigin = null;
    _lassoPoints = [];
    notifyListeners();
  }

  void endStroke() {
    if (tool == InkTool.none ||
        tool == InkTool.text ||
        tool == InkTool.shape ||
        tool == InkTool.image) {
      return;
    }

    if (tool == InkTool.lasso) {
      _closedLasso = _lassoPoints.length >= 3 ? List.of(_lassoPoints) : [];
      if (_closedLasso.length >= 3) {
        final hit = <String>{};
        for (final s in _strokes) {
          if (!matchesContentFilter(s, lassoTargets)) continue;
          if (s.intersectsPolygon(_closedLasso)) hit.add(s.id);
        }
        selectedIds = hit;
      }
      _lassoPoints = [];
      _notifyNow();
      return;
    }

    if (tool == InkTool.eraser) {
      final before = _eraserBefore;
      if (before != null && !listEquals(before, _strokes)) {
        _pushUndo(_HistoryEntry.replace(before));
        _redo.clear();
      }
      _eraserBefore = null;
      eraserCursor = null;
      _notifyNow();
      return;
    }

    final active = _activeStroke;
    if (active == null || active.points.isEmpty) {
      _activeStroke = null;
      _guideOrigin = null;
      _notifyNow();
      return;
    }

    // Snapshot points so later in-place drawing cannot mutate history.
    final committed = InkStroke(
      id: active.id,
      tool: active.tool,
      colorValue: active.colorValue,
      width: active.width,
      style: active.style,
      points: List<StrokePoint>.of(active.points),
    );
    _pushUndo(_HistoryEntry.add(committed));
    _strokes = [..._strokes, committed];
    _activeStroke = null;
    _guideOrigin = null;
    _redo.clear();
    _notifyNow();
  }

  void deleteSelected() {
    if (selectedIds.isEmpty) return;
    final removed = _strokes.where((s) => selectedIds.contains(s.id)).toList();
    _pushUndo(_HistoryEntry.remove(removed));
    _strokes = _strokes.where((s) => !selectedIds.contains(s.id)).toList();
    selectedIds = {};
    _redo.clear();
    notifyListeners();
  }

  void moveSelected(Offset delta, {bool recordHistory = false}) {
    if (selectedIds.isEmpty || delta == Offset.zero) return;
    if (recordHistory) {
      _pushUndo(_HistoryEntry.replace(List.of(_strokes)));
      _redo.clear();
    }
    _strokes = [
      for (final s in _strokes)
        if (selectedIds.contains(s.id)) s.translated(delta) else s,
    ];
    notifyListeners();
  }

  void commitSelectionMove(List<InkStroke> beforeMove) {
    _pushUndo(_HistoryEntry.replace(beforeMove));
    _redo.clear();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final entry = _undo.removeLast();
    _redo.add(_snapshot());
    _apply(entry);
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final entry = _redo.removeLast();
    _undo.add(_snapshot());
    _apply(entry);
    notifyListeners();
  }

  void clearPage() {
    if (_strokes.isEmpty) return;
    _pushUndo(_HistoryEntry.replace(List.of(_strokes)));
    _strokes = [];
    selectedIds = {};
    _redo.clear();
    notifyListeners();
  }

  void _eraseAt(Offset point) {
    final radius = eraseRadius;
    final precise = eraserMode == EraserMode.precise;
    switch (eraserMode) {
      case EraserMode.stroke:
        final hit = _strokes
            .where(
              (s) =>
                  matchesContentFilter(s, eraseTargets) &&
                  s.hitsPoint(point, tolerance: radius),
            )
            .toList();
        if (hit.isEmpty) {
          notifyListeners();
          return;
        }
        final ids = hit.map((s) => s.id).toSet();
        _strokes = _strokes.where((s) => !ids.contains(s.id)).toList();
        break;
      case EraserMode.section:
        final next = <InkStroke>[];
        var changed = false;
        for (final s in _strokes) {
          if (!matchesContentFilter(s, eraseTargets) ||
              !s.hitsPoint(point, tolerance: radius)) {
            next.add(s);
            continue;
          }
          final parts = s.eraseSection(point, radius: radius, newId: _uuid.v4);
          if (parts.length != 1 || parts.first.id != s.id) {
            changed = true;
          }
          next.addAll(parts);
        }
        if (!changed) {
          notifyListeners();
          return;
        }
        _strokes = next;
        break;
      case EraserMode.precise:
        final next = <InkStroke>[];
        var changed = false;
        for (final s in _strokes) {
          if (!matchesContentFilter(s, eraseTargets) ||
              !s.hitsPoint(
                point,
                tolerance: radius,
                includeStrokeWidth: !precise,
              )) {
            next.add(s);
            continue;
          }
          final parts = s.erasePrecise(point, radius, newId: _uuid.v4);
          if (parts.length != 1 ||
              parts.isEmpty ||
              parts.first.points.length != s.points.length) {
            changed = true;
          }
          next.addAll(parts);
        }
        if (!changed) {
          notifyListeners();
          return;
        }
        _strokes = next;
        break;
    }
    notifyListeners();
  }

  void _pushUndo(_HistoryEntry entry) {
    _undo.add(entry);
    if (_undo.length > 100) {
      _undo.removeAt(0);
    }
  }

  _HistoryEntry _snapshot() => _HistoryEntry.replace(List.of(_strokes));

  void _apply(_HistoryEntry entry) {
    switch (entry.type) {
      case _HistoryType.add:
        _strokes = _strokes
            .where((s) => s.id != entry.strokes.first.id)
            .toList();
        break;
      case _HistoryType.remove:
        _strokes = [..._strokes, ...entry.strokes];
        break;
      case _HistoryType.replace:
        _strokes = List.of(entry.strokes);
        break;
    }
    selectedIds = {};
    _activeStroke = null;
    eraserCursor = null;
  }
}

enum _HistoryType { add, remove, replace }

class _HistoryEntry {
  _HistoryEntry._(this.type, this.strokes);

  factory _HistoryEntry.add(InkStroke stroke) =>
      _HistoryEntry._(_HistoryType.add, [stroke]);

  factory _HistoryEntry.remove(List<InkStroke> strokes) =>
      _HistoryEntry._(_HistoryType.remove, strokes);

  factory _HistoryEntry.replace(List<InkStroke> strokes) =>
      _HistoryEntry._(_HistoryType.replace, strokes);

  final _HistoryType type;
  final List<InkStroke> strokes;
}
