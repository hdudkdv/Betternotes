import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_units.dart';
import '../../domain/drawing_aids.dart';
import '../editor_chrome.dart';
import 'stylus_pan.dart';

/// Compass overlay: place center → set radius via wheel → draw on the arc.
class CompassOverlay extends StatelessWidget {
  const CompassOverlay({
    super.key,
    required this.aid,
    required this.pageSize,
    required this.onChanged,
    required this.onToggleFixed,
    this.readOnly = false,
  });

  final CompassAid aid;
  final Size pageSize;
  final ValueChanged<CompassAid> onChanged;
  final VoidCallback onToggleFixed;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final center = aid.center;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _CompassPainter(aid: aid, pageSize: pageSize),
          ),
        ),
        if (!readOnly && aid.phase == CompassPhase.placingCenter)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (d) {
                onChanged(
                  aid.copyWith(
                    center: d.localPosition,
                    phase: CompassPhase.adjusting,
                  ),
                );
              },
              child: Center(
                child: Material(
                  color: EditorChrome.floating.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      l10n.compassSetCenter,
                      style: TextStyle(
                        color: EditorChrome.onDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (center != null) ...[
          // Pivot
          Positioned(
            left: center.dx - 10,
            top: center.dy - 10,
            child: IgnorePointer(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EditorChrome.selected,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
          if (!readOnly && aid.phase != CompassPhase.placingCenter)
            Positioned(
              left: (aid.armTip?.dx ?? center.dx) - 14,
              top: (aid.armTip?.dy ?? center.dy) - 14,
              child: StylusPan(
                onPanUpdate: (delta) {
                  final tip = (aid.armTip ?? center) + delta;
                  final angle = math.atan2(
                    tip.dy - center.dy,
                    tip.dx - center.dx,
                  );
                  final radiusMm = PageUnits.ptToMm(
                    (tip - center).distance,
                  ).clamp(5.0, 200.0);
                  onChanged(
                    aid.copyWith(
                      armAngle: angle,
                      radiusMm: radiusMm,
                      phase: CompassPhase.ready,
                    ),
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: EditorChrome.selected,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          // Radius wheel (left side of page).
          if (!readOnly && aid.phase != CompassPhase.placingCenter)
            Positioned(
              left: 8,
              top: pageSize.height * 0.22,
              child: _RadiusWheel(
                radiusMm: aid.radiusMm,
                onChanged: (mm) => onChanged(
                  aid.copyWith(radiusMm: mm, phase: CompassPhase.ready),
                ),
              ),
            ),
          Positioned(
            left: (center.dx - 70).clamp(8, pageSize.width - 150),
            top: (center.dy - 56).clamp(8, pageSize.height - 48),
            child: Material(
              color: EditorChrome.floating.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${aid.radiusMm.toStringAsFixed(0)} mm',
                      style: TextStyle(
                        color: EditorChrome.onDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: aid.fixed
                            ? EditorChrome.selected
                            : EditorChrome.onDarkMuted,
                      ),
                      onPressed: onToggleFixed,
                      child: Text(
                        aid.fixed ? l10n.guideFixed : l10n.fixGuide,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RadiusWheel extends StatefulWidget {
  const _RadiusWheel({required this.radiusMm, required this.onChanged});

  final double radiusMm;
  final ValueChanged<double> onChanged;

  @override
  State<_RadiusWheel> createState() => _RadiusWheelState();
}

class _RadiusWheelState extends State<_RadiusWheel> {
  late final FixedExtentScrollController _controller;
  double _dragAccum = 0;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: (widget.radiusMm.round() - 5).clamp(0, 195),
    );
  }

  @override
  void didUpdateWidget(covariant _RadiusWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final item = (widget.radiusMm.round() - 5).clamp(0, 195);
    if (_controller.hasClients && _controller.selectedItem != item) {
      _controller.jumpToItem(item);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nudgeBy(double dy) {
    _dragAccum += dy;
    const step = 18.0;
    if (_dragAccum.abs() < step) return;
    final dir = _dragAccum > 0 ? 1 : -1;
    _dragAccum = 0;
    if (!_controller.hasClients) return;
    final next = (_controller.selectedItem + dir).clamp(0, 195);
    _controller.jumpToItem(next);
    widget.onChanged((next + 5).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cm = widget.radiusMm / 10;
    return Material(
      color: EditorChrome.floating.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: SizedBox(
        width: 72,
        height: 210,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.compassRadius,
              style: TextStyle(
                color: EditorChrome.onDarkMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${cm.toStringAsFixed(1)} cm',
              style: TextStyle(
                color: EditorChrome.onDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${widget.radiusMm.round()} mm',
              style: TextStyle(
                color: EditorChrome.onDarkMuted,
                fontSize: 11,
              ),
            ),
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerMove: (event) {
                  if (!event.down || event.delta.dy.abs() < 0.4) return;
                  _nudgeBy(event.delta.dy);
                },
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 28,
                  perspective: 0.003,
                  diameterRatio: 1.1,
                  physics: const FixedExtentScrollPhysics(),
                  controller: _controller,
                  onSelectedItemChanged: (i) {
                    widget.onChanged((i + 5).toDouble());
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 196,
                    builder: (context, index) {
                      final mm = index + 5;
                      final selected = mm == widget.radiusMm.round();
                      return Center(
                        child: Text(
                          '$mm',
                          style: TextStyle(
                            color: selected
                                ? EditorChrome.selected
                                : EditorChrome.onDarkMuted,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: selected ? 16 : 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.aid, required this.pageSize});

  final CompassAid aid;
  final Size pageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final c = aid.center;
    if (c == null) return;
    final r = aid.radiusPt;

    // Ghost circle — guide only; ink is drawn by the user.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0x552F6FED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    final tip = aid.armTip;
    if (tip != null) {
      canvas.drawLine(
        c,
        tip,
        Paint()
          ..color = const Color(0xFF2F6FED)
          ..strokeWidth = 1.8,
      );
    }

    // Subtle mm ticks on the rim every cm.
    for (var mm = 0; mm < aid.radiusMm.round(); mm += 10) {
      final rr = PageUnits.mmToPt(mm.toDouble());
      if (rr <= 0 || rr >= r) continue;
      canvas.drawCircle(
        c,
        rr,
        Paint()
          ..color = const Color(0x332F6FED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.aid.center != aid.center ||
      oldDelegate.aid.radiusMm != aid.radiusMm ||
      oldDelegate.aid.armAngle != aid.armAngle ||
      oldDelegate.aid.phase != aid.phase;
}
