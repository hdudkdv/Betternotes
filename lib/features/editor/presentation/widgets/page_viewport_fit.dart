import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared framing for live [InkCanvas] and [PageSnapshot] so fit-zoom and
/// neighbor previews match GoodNotes-style margins (page centered in workspace).
class PageViewportFit {
  PageViewportFit._();

  /// Invisible interaction gutter around the paper (32px per side).
  /// Not part of the fit-scale math — only hit-testing / chrome.
  static const double gutter = 64;

  static Size childSize(Size pageSize) =>
      Size(pageSize.width + gutter, pageSize.height + gutter);

  /// Workspace margin around the paper (GoodNotes-like floating page).
  static EdgeInsets paddingFor(Size viewport) {
    return EdgeInsets.symmetric(
      horizontal: math.max(36.0, viewport.width * 0.07),
      vertical: math.max(28.0, viewport.height * 0.055),
    );
  }

  /// Scale so the **paper** (not the gutter) fits inside the padded viewport.
  static double fitScale(Size viewport, Size pageSize) {
    final pad = paddingFor(viewport);
    final availW = (viewport.width - pad.horizontal).clamp(
      1.0,
      double.infinity,
    );
    final availH = (viewport.height - pad.vertical).clamp(1.0, double.infinity);
    return math.min(availW / pageSize.width, availH / pageSize.height);
  }

  /// Same matrix [InkCanvas] uses at fit-zoom — keep snapshots pixel-aligned.
  static Matrix4 fitMatrix(Size viewport, Size pageSize) {
    final scale = fitScale(viewport, pageSize);
    final child = childSize(pageSize);
    // Centering the gutter-box keeps the paper itself centered in the viewport.
    final dx = (viewport.width - child.width * scale) / 2;
    final dy = (viewport.height - child.height * scale) / 2;
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  /// Frames [paper] (page-sized) exactly like the live canvas at fit zoom.
  static Widget framed({
    required Size viewport,
    required Size pageSize,
    required Widget paper,
  }) {
    final child = childSize(pageSize);
    return ClipRect(
      child: transformedChild(
        transform: fitMatrix(viewport, pageSize),
        childSize: child,
        child: SizedBox(
          width: child.width,
          height: child.height,
          child: Center(
            child: SizedBox(
              width: pageSize.width,
              height: pageSize.height,
              child: paper,
            ),
          ),
        ),
      ),
    );
  }

  /// Keeps a page-sized child at its intrinsic size under tight parent
  /// constraints, then paints [transform] from the top-left.
  ///
  /// Same idea as [InteractiveViewer] with `constrained: false`. Without this,
  /// a tight landscape viewport stretches the paper to the screen size *and*
  /// then scales it — the page ends up in a corner and Fit cannot recover.
  static Widget transformedChild({
    required Matrix4 transform,
    required Size childSize,
    required Widget child,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: childSize.width,
      minHeight: childSize.height,
      maxWidth: childSize.width,
      maxHeight: childSize.height,
      child: Transform(
        transform: transform,
        alignment: Alignment.topLeft,
        filterQuality: filterQuality,
        child: child,
      ),
    );
  }
}
