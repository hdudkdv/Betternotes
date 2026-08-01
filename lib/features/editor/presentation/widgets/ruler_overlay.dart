import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/page_units.dart';
import '../../domain/drawing_aids.dart';
import '../editor_chrome.dart';

/// Visual ruler in page coordinates with cm/mm ticks and inclination.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bodyCenter = aid.center;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(child: CustomPaint(painter: _RulerPainter(aid: aid))),
        if (!readOnly) ...[
          // Movable strip — only the ruler body captures drags.
          Positioned(
            left: bodyCenter.dx - 36,
            top: bodyCenter.dy - 36,
            width: 72,
            height: 72,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                onChanged(aid.copyWith(center: aid.center + d.delta));
              },
              child: const SizedBox.expand(),
            ),
          ),
          _Handle(
            at: aid.end,
            onDrag: (delta) {
              final tip = aid.end + delta;
              final angle = math.atan2(
                tip.dy - aid.center.dy,
                tip.dx - aid.center.dx,
              );
              onChanged(aid.copyWith(angle: angle));
            },
          ),
          _Handle(
            at: aid.start,
            onDrag: (delta) {
              final tip = aid.start + delta;
              final angle = math.atan2(
                aid.center.dy - tip.dy,
                aid.center.dx - tip.dx,
              );
              onChanged(aid.copyWith(angle: angle));
            },
          ),
        ],
        Positioned(
          left: (aid.center.dx - 78).clamp(8, double.infinity),
          top: (aid.center.dy - 52).clamp(8, double.infinity),
          child: Material(
            color: EditorChrome.floating.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      left: at.dx - 14,
      top: at.dy - 14,
      child: GestureDetector(
        onPanUpdate: (d) => onDrag(d.delta),
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
    final normal = Offset(-dir.dy, dir.dx);

    final bodyPath = Path()
      ..moveTo((start + normal * 14).dx, (start + normal * 14).dy)
      ..lineTo((end + normal * 14).dx, (end + normal * 14).dy)
      ..lineTo((end - normal * 14).dx, (end - normal * 14).dy)
      ..lineTo((start - normal * 14).dx, (start - normal * 14).dy)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = const Color(0xE8F4E8C8));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF5C5346)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Drawing edge (ink snaps here).
    canvas.drawLine(
      start - normal * 14,
      end - normal * 14,
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
      final a = along - normal * 14;
      final b = along - normal * (14 - tick);
      canvas.drawLine(
        a,
        b,
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
        final anchor = along - normal * 1;
        canvas.save();
        canvas.translate(anchor.dx, anchor.dy);
        canvas.rotate(aid.angle);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height - 1));
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
      oldDelegate.aid.lengthPt != aid.lengthPt ||
      oldDelegate.aid.fixed != aid.fixed;
}
