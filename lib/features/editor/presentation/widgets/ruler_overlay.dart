import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_units.dart';
import '../../domain/drawing_aids.dart';
import '../editor_chrome.dart';
import 'stylus_pan.dart';

/// Visual ruler in page coordinates — always spans page edge → edge.
class RulerOverlay extends StatelessWidget {
  const RulerOverlay({
    super.key,
    required this.aid,
    required this.onChanged,
    required this.onToggleFixed,
    this.readOnly = false,
  });

  final RulerAid aid;
  final ValueChanged<RulerAid> onChanged;
  final VoidCallback onToggleFixed;
  final bool readOnly;

  void _moveBy(Offset delta) {
    final next = aid.center + delta;
    onChanged(
      aid.copyWith(
        center: Offset(
          next.dx.clamp(0, aid.pageSize.width),
          next.dy.clamp(0, aid.pageSize.height),
        ),
      ),
    );
  }

  void _rotateFrom(Offset tip, {required bool fromStart}) {
    final angle = fromStart
        ? math.atan2(aid.center.dy - tip.dy, aid.center.dx - tip.dx)
        : math.atan2(tip.dy - aid.center.dy, tip.dx - aid.center.dx);
    onChanged(aid.copyWith(angle: angle));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mid = Offset(
      (aid.start.dx + aid.end.dx) / 2,
      (aid.start.dy + aid.end.dy) / 2,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            size: aid.pageSize,
            painter: _RulerPainter(aid: aid),
          ),
        ),
        if (!readOnly && !aid.fixed) ...[
          // Small center grip only — the body must not steal ink.
          Positioned(
            left: mid.dx - 40,
            top: mid.dy - 20,
            width: 80,
            height: 40,
            child: Transform.rotate(
              angle: aid.angle,
              child: StylusPan(
                onPanUpdate: _moveBy,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: EditorChrome.selected.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white70, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          _Handle(
            at: aid.end,
            onDrag: (delta) => _rotateFrom(aid.end + delta, fromStart: false),
          ),
          _Handle(
            at: aid.start,
            onDrag: (delta) => _rotateFrom(aid.start + delta, fromStart: true),
          ),
        ],
        Positioned(
          left: (mid.dx - 88).clamp(8, aid.pageSize.width - 176),
          top: (mid.dy + 22).clamp(8, aid.pageSize.height - 52),
          child: Material(
            color: EditorChrome.floating.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 4, 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${aid.inclinationDeg.abs().toStringAsFixed(0)}°',
                    style: TextStyle(
                      color: EditorChrome.onDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    tooltip: aid.fixed ? l10n.guideFixed : l10n.fixGuide,
                    visualDensity: VisualDensity.compact,
                    onPressed: readOnly ? null : onToggleFixed,
                    icon: Icon(
                      aid.fixed
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: aid.fixed
                          ? EditorChrome.selected
                          : EditorChrome.onDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.at, required this.onDrag});

  final Offset at;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 22,
      top: at.dy - 22,
      child: StylusPan(
        onPanUpdate: onDrag,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: EditorChrome.selected,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.aid});

  final RulerAid aid;

  @override
  void paint(Canvas canvas, Size size) {
    final start = aid.start;
    final end = aid.end;
    final dir = aid.direction;
    final normal = aid.normal;
    const half = RulerAid.edgeOffset;

    final bodyPath = Path()
      ..moveTo((start + normal * half).dx, (start + normal * half).dy)
      ..lineTo((end + normal * half).dx, (end + normal * half).dy)
      ..lineTo((end - normal * half).dx, (end - normal * half).dy)
      ..lineTo((start - normal * half).dx, (start - normal * half).dy)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = const Color(0xE8F4E8C8));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF5C5346)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawLine(
      start - normal * half,
      end - normal * half,
      Paint()
        ..color = const Color(0xFF2F6FED)
        ..strokeWidth = 1.6,
    );

    final mm = PageUnits.pointsPerMm;
    final length = aid.lengthPt;
    var x = 0.0;
    var index = 0;
    while (x <= length + 0.5) {
      final along = start + dir * x;
      final isCm = index % 10 == 0;
      final isHalf = index % 5 == 0;
      final tick = isCm ? 11.0 : (isHalf ? 7.0 : 4.0);
      final edge = along - normal * half;
      final tip = along - normal * (half - tick);
      canvas.drawLine(
        edge,
        tip,
        Paint()
          ..color = const Color(0xFF2A241C)
          ..strokeWidth = isCm ? 1.3 : 0.9,
      );
      if (isCm) {
        final label = (index ~/ 10).toString();
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF2A241C),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final anchor = along - normal * (half + 3);
        canvas.save();
        canvas.translate(anchor.dx, anchor.dy);
        canvas.rotate(aid.angle);
        tp.paint(canvas, Offset(-tp.width / 2, 1));
        canvas.restore();
      }
      x += mm;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.aid.center != aid.center ||
      oldDelegate.aid.angle != aid.angle ||
      oldDelegate.aid.pageSize != aid.pageSize ||
      oldDelegate.aid.fixed != aid.fixed;
}
