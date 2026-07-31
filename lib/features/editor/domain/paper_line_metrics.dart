import 'dart:math' as math;
import 'dart:ui';

import '../../../../data/models/content_models.dart';
import '../../../../shared/utils/page_size.dart';
import 'ink_models.dart';

/// Geometry of the ruled paper, used to place line-bound text on the rules.
///
/// [lineOrigin] mirrors where [PageBackgroundPainter] starts drawing rules so
/// snapping and painting can never drift apart.
class PaperLineMetrics {
  const PaperLineMetrics({
    required this.lineSpacing,
    required this.marginLeft,
    required this.marginTop,
    required this.lineOrigin,
    required this.pageWidth,
    required this.pageHeight,
    this.explicitLines,
  });

  final double lineSpacing;
  final double marginLeft;
  final double marginTop;

  /// Y position of the first painted rule.
  final double lineOrigin;
  final double pageWidth;
  final double pageHeight;

  /// Rules of a hand-made paper template, if any.
  final List<double>? explicitLines;

  double get contentWidth => math.max(120, pageWidth - marginLeft - 36);
  double get rightEdge => pageWidth - 36;

  factory PaperLineMetrics.from({
    PaperTemplate? paper,
    PageTemplate template = PageTemplate.lined,
    Size? pageSize,
  }) {
    final size = pageSize ?? NotePageSize.defaultSize;
    if (paper != null) {
      final grid = paper.style == 'grid';
      var spacing = grid ? paper.gridSize : paper.lineSpacing;
      var marginTop = paper.marginTop;
      var marginLeft = paper.marginLeft;
      // Grid papers are painted from the page edge, ruled papers from the top
      // margin.
      var origin = grid ? 0.0 : paper.marginTop;
      List<double>? lines;

      if (paper.style == 'custom') {
        final horizontal = paper.horizontalLines;
        if (horizontal != null && horizontal.isNotEmpty) {
          lines = [...horizontal]..sort();
          origin = lines.first;
          marginTop = lines.first;
          if (lines.length >= 2) {
            spacing = (lines[1] - lines[0]).abs().clamp(12.0, 64.0);
          }
        }
        final vertical = paper.verticalLines;
        if (vertical != null && vertical.isNotEmpty) {
          marginLeft = vertical.first;
        }
      }

      return PaperLineMetrics(
        lineSpacing: spacing,
        marginLeft: marginLeft,
        marginTop: marginTop,
        lineOrigin: origin,
        pageWidth: size.width,
        pageHeight: size.height,
        explicitLines: lines,
      );
    }

    switch (template) {
      case PageTemplate.grid:
        return PaperLineMetrics(
          lineSpacing: 24,
          marginLeft: 48,
          marginTop: 48,
          lineOrigin: 0,
          pageWidth: size.width,
          pageHeight: size.height,
        );
      case PageTemplate.blank:
      case PageTemplate.lined:
        return PaperLineMetrics(
          lineSpacing: 28,
          marginLeft: 72,
          marginTop: 48,
          lineOrigin: 48,
          pageWidth: size.width,
          pageHeight: size.height,
        );
    }
  }

  /// Y of the ruled line nearest to [y]; text baselines sit exactly here.
  double snapToLine(double y) {
    final lines = explicitLines;
    if (lines != null && lines.isNotEmpty) {
      var best = lines.first;
      var bestDistance = (y - best).abs();
      for (final line in lines) {
        final distance = (y - line).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = line;
        }
      }
      return best;
    }
    final first = math.max(lineOrigin, marginTop);
    final maxIndex = ((pageHeight - 24 - first) / lineSpacing).floor().clamp(
      0,
      400,
    );
    final index = ((y - first) / lineSpacing).round().clamp(0, maxIndex);
    return first + index * lineSpacing;
  }

  double fontSizeForLines() => math.min(lineSpacing * 0.68, 18.0);

  double heightFactorForLines(double fontSize) => lineSpacing / fontSize;
}
