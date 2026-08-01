import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared framing for live [InkCanvas] and [PageSnapshot] so fit-zoom and
/// neighbor previews match GoodNotes-style margins (page centered in workspace).
class PageViewportFit {
  PageViewportFit._();

  /// Invisible interaction gutter around the paper (32px per side).
  static const double gutter = 64;

  static Size childSize(Size pageSize) =>
      Size(pageSize.width + gutter, pageSize.height + gutter);

  /// Breathing room between page and viewport edges — larger than a thin
  /// hairline so the paper clearly floats on the workspace background.
  static EdgeInsets paddingFor(Size viewport) {
    return EdgeInsets.symmetric(
      horizontal: math.max(48.0, viewport.width * 0.1),
      vertical: math.max(40.0, viewport.height * 0.08),
    );
  }

  static double fitScale(Size viewport, Size pageSize) {
    final pad = paddingFor(viewport);
    final child = childSize(pageSize);
    final availW =
        (viewport.width - pad.horizontal).clamp(1.0, double.infinity);
    final availH =
        (viewport.height - pad.vertical).clamp(1.0, double.infinity);
    return math.min(availW / child.width, availH / child.height);
  }
}
