import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/providers/library_providers.dart';
import '../domain/ink_models.dart';

class ToolPresets extends ChangeNotifier {
  ToolPresets(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  List<double> penWidths = [1.5, 2.5, 5.0];
  List<double> markerWidths = [6.0, 12.0, 20.0];
  List<double> eraserWidths = [8.0, 16.0, 28.0];
  List<int> colors = [
    0xFF1A1A1A,
    0xFF4A4A4A,
    0xFF1D4E89,
    0xFFB42318,
    0xFFD4A017,
  ];
  EraserMode eraserMode = EraserMode.stroke;
  Set<ContentKind> eraseTargets = {...kDefaultContentTargets};
  Set<ContentKind> lassoTargets = {...kDefaultContentTargets};
  int penWidthIndex = 1;
  int markerWidthIndex = 1;
  int eraserWidthIndex = 1;

  double widthFor(InkTool tool) {
    switch (tool) {
      case InkTool.marker:
        return markerWidths[markerWidthIndex.clamp(0, markerWidths.length - 1)];
      case InkTool.eraser:
        return eraserWidths[eraserWidthIndex.clamp(0, eraserWidths.length - 1)];
      default:
        return penWidths[penWidthIndex.clamp(0, penWidths.length - 1)];
    }
  }

  List<double> widthsFor(InkTool tool) {
    switch (tool) {
      case InkTool.marker:
        return markerWidths;
      case InkTool.eraser:
        return eraserWidths;
      default:
        return penWidths;
    }
  }

  int widthIndexFor(InkTool tool) {
    switch (tool) {
      case InkTool.marker:
        return markerWidthIndex;
      case InkTool.eraser:
        return eraserWidthIndex;
      default:
        return penWidthIndex;
    }
  }

  void selectWidthIndex(InkTool tool, int index) {
    switch (tool) {
      case InkTool.marker:
        markerWidthIndex = index.clamp(0, markerWidths.length - 1);
        break;
      case InkTool.eraser:
        eraserWidthIndex = index.clamp(0, eraserWidths.length - 1);
        break;
      default:
        penWidthIndex = index.clamp(0, penWidths.length - 1);
        break;
    }
    notifyListeners();
    _save();
  }

  void setWidthSlot(InkTool tool, int index, double value) {
    final v = value.clamp(0.5, 64.0);
    switch (tool) {
      case InkTool.marker:
        markerWidths = [...markerWidths]..[index] = v;
        break;
      case InkTool.eraser:
        eraserWidths = [...eraserWidths]..[index] = v;
        break;
      default:
        penWidths = [...penWidths]..[index] = v;
        break;
    }
    notifyListeners();
    _save();
  }

  void setEraserMode(EraserMode mode) {
    eraserMode = mode;
    notifyListeners();
    _save();
  }

  void setEraseTargets(Set<ContentKind> value) {
    eraseTargets = Set<ContentKind>.of(value);
    notifyListeners();
    _save();
  }

  void setLassoTargets(Set<ContentKind> value) {
    lassoTargets = Set<ContentKind>.of(value);
    notifyListeners();
    _save();
  }

  void addColor(int value) {
    if (colors.contains(value)) return;
    colors = [...colors, value];
    notifyListeners();
    _save();
  }

  /// Swaps a swatch in place so the row keeps its order.
  void replaceColor(int oldValue, int newValue) {
    final index = colors.indexOf(oldValue);
    if (index < 0) return;
    if (colors.contains(newValue)) {
      colors = colors.where((c) => c != oldValue).toList();
    } else {
      colors = [...colors]..[index] = newValue;
    }
    notifyListeners();
    _save();
  }

  void removeColor(int value) {
    if (colors.length <= 1) return;
    colors = colors.where((c) => c != value).toList();
    notifyListeners();
    _save();
  }

  void _load() {
    try {
      final raw = _prefs.getString('toolPresetsV1');
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      penWidths = _doubles(map['penWidths'], penWidths);
      markerWidths = _doubles(map['markerWidths'], markerWidths);
      eraserWidths = _doubles(map['eraserWidths'], eraserWidths);
      colors = [
        for (final c in (map['colors'] as List? ?? colors)) (c as num).toInt(),
      ];
      if (colors.isEmpty) {
        colors = [0xFF1A1A1A];
      }
      eraserMode = EraserMode.values.firstWhere(
        (m) => m.name == map['eraserMode'],
        orElse: () => EraserMode.stroke,
      );
      eraseTargets = _kinds(map['eraseTargets'], eraseTargets);
      lassoTargets = _kinds(map['lassoTargets'], lassoTargets);
      penWidthIndex = (map['penWidthIndex'] as num?)?.toInt() ?? 1;
      markerWidthIndex = (map['markerWidthIndex'] as num?)?.toInt() ?? 1;
      eraserWidthIndex = (map['eraserWidthIndex'] as num?)?.toInt() ?? 1;
    } catch (_) {}
  }

  List<double> _doubles(dynamic raw, List<double> fallback) {
    if (raw is! List || raw.length != 3) return fallback;
    return [for (final v in raw) (v as num).toDouble()];
  }

  Set<ContentKind> _kinds(dynamic raw, Set<ContentKind> fallback) {
    if (raw is! List || raw.isEmpty) return fallback;
    final parsed = <ContentKind>{};
    for (final item in raw) {
      final name = item.toString();
      for (final kind in ContentKind.values) {
        if (kind.name == name) parsed.add(kind);
      }
    }
    return parsed.isEmpty ? fallback : parsed;
  }

  Future<void> _save() async {
    await _prefs.setString(
      'toolPresetsV1',
      jsonEncode({
        'penWidths': penWidths,
        'markerWidths': markerWidths,
        'eraserWidths': eraserWidths,
        'colors': colors,
        'eraserMode': eraserMode.name,
        'eraseTargets': eraseTargets.map((k) => k.name).toList(),
        'lassoTargets': lassoTargets.map((k) => k.name).toList(),
        'penWidthIndex': penWidthIndex,
        'markerWidthIndex': markerWidthIndex,
        'eraserWidthIndex': eraserWidthIndex,
      }),
    );
  }
}

final toolPresetsProvider = ChangeNotifierProvider<ToolPresets>((ref) {
  return ToolPresets(ref.watch(sharedPreferencesProvider));
});
