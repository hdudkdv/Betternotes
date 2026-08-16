import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

enum ChartKind {
  pie,
  bar,
  line,
  mindmap,
  gantt,
  area,
  er,
  usecase,
  flow,
  venn,
  sequence,
  axes,
  numberline,
  cornell,
  vocab,
}

class ChartSeriesRow {
  ChartSeriesRow({
    this.label = '',
    this.value = '',
    this.start = '',
    this.end = '',
  });

  String label;
  String value;
  String start;
  String end;
}

Future<Uint8List?> showChartBuilderSheet(
  BuildContext context, {
  bool chartPack = false,
  bool helperPack = false,
}) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChartBuilderSheet(
      chartPack: chartPack,
      helperPack: helperPack,
    ),
  );
}

class _ChartBuilderSheet extends StatefulWidget {
  const _ChartBuilderSheet({
    required this.chartPack,
    required this.helperPack,
  });

  final bool chartPack;
  final bool helperPack;

  @override
  State<_ChartBuilderSheet> createState() => _ChartBuilderSheetState();
}

class _ChartBuilderSheetState extends State<_ChartBuilderSheet> {
  ChartKind _kind = ChartKind.bar;
  final _title = TextEditingController();
  final _rows = <ChartSeriesRow>[
    ChartSeriesRow(label: 'A', value: '4', start: '0', end: '3'),
    ChartSeriesRow(label: 'B', value: '7', start: '2', end: '6'),
    ChartSeriesRow(label: 'C', value: '3', start: '5', end: '8'),
  ];
  bool _busy = false;

  bool get _gantt => _kind == ChartKind.gantt;
  bool get _needsPack => const {
        ChartKind.gantt,
        ChartKind.area,
        ChartKind.er,
        ChartKind.usecase,
        ChartKind.flow,
        ChartKind.venn,
        ChartKind.sequence,
      }.contains(_kind);
  bool get _needsHelper => const {
        ChartKind.axes,
        ChartKind.numberline,
        ChartKind.cornell,
        ChartKind.vocab,
      }.contains(_kind);
  bool get _textOnly => const {
        ChartKind.mindmap,
        ChartKind.er,
        ChartKind.usecase,
        ChartKind.flow,
        ChartKind.venn,
        ChartKind.sequence,
      }.contains(_kind);
  bool get _noRows => const {
        ChartKind.axes,
        ChartKind.numberline,
        ChartKind.cornell,
      }.contains(_kind);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _insert() async {
    if (_needsPack && !widget.chartPack) {
      context.push('/marketplace');
      return;
    }
    if (_needsHelper && !widget.helperPack) {
      context.push('/marketplace');
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await ChartRenderer.renderPng(
        kind: _kind,
        title: _title.text.trim(),
        rows: _rows,
      );
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<(ChartKind, String)> _chips(AppLocalizations l10n) => [
        (ChartKind.pie, l10n.chartPie),
        (ChartKind.bar, l10n.chartBar),
        (ChartKind.line, l10n.chartLine),
        (ChartKind.mindmap, l10n.chartMindmap),
        (ChartKind.gantt, l10n.chartGantt),
        (ChartKind.area, l10n.chartArea),
        (ChartKind.er, l10n.chartEr),
        (ChartKind.usecase, l10n.chartUsecase),
        (ChartKind.flow, l10n.chartFlow),
        (ChartKind.venn, l10n.chartVenn),
        (ChartKind.sequence, l10n.chartSequence),
        (ChartKind.axes, l10n.chartAxes),
        (ChartKind.numberline, l10n.chartNumberline),
        (ChartKind.cornell, l10n.chartCornell),
        (ChartKind.vocab, l10n.chartVocab),
      ];

  bool _locked(ChartKind kind) {
    const pack = {
      ChartKind.gantt,
      ChartKind.area,
      ChartKind.er,
      ChartKind.usecase,
      ChartKind.flow,
      ChartKind.venn,
      ChartKind.sequence,
    };
    const helper = {
      ChartKind.axes,
      ChartKind.numberline,
      ChartKind.cornell,
      ChartKind.vocab,
    };
    if (pack.contains(kind)) return !widget.chartPack;
    if (helper.contains(kind)) return !widget.helperPack;
    return false;
  }

  (String, String, String?) _rowLabels(AppLocalizations l10n) {
    return switch (_kind) {
      ChartKind.er => (l10n.chartEntity, l10n.chartAttributes, l10n.chartRelation),
      ChartKind.usecase => (l10n.chartActor, l10n.chartUsecase, null),
      ChartKind.sequence => (l10n.chartFrom, l10n.chartTo, l10n.chartMessage),
      ChartKind.venn => (l10n.chartSet, l10n.chartItems, null),
      ChartKind.mindmap || ChartKind.flow => (l10n.chartLabel, '', null),
      _ => (l10n.chartLabel, l10n.chartValue, null),
    };
  }

  Widget _rowEditor(AppLocalizations l10n, int i) {
    final labels = _rowLabels(l10n);
    final numeric = !_textOnly && !_gantt;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: _rows[i].label,
            decoration: InputDecoration(
              labelText: labels.$1,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _rows[i].label = v,
          ),
        ),
        if (_gantt) ...[
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: _rows[i].start,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.chartStart,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _rows[i].start = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: _rows[i].end,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.chartEnd,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _rows[i].end = v,
            ),
          ),
        ] else if (labels.$2.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: _rows[i].value,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: labels.$2,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _rows[i].value = v,
            ),
          ),
        ],
        if (labels.$3 != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: _kind == ChartKind.sequence
                  ? _rows[i].start
                  : _rows[i].end,
              decoration: InputDecoration(
                labelText: labels.$3,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                if (_kind == ChartKind.sequence) {
                  _rows[i].start = v;
                } else {
                  _rows[i].end = v;
                }
              },
            ),
          ),
        ],
        IconButton(
          onPressed: _rows.length <= 1
              ? null
              : () => setState(() => _rows.removeAt(i)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppTheme.palette;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(palette.radius + 8),
            border: Border.all(color: palette.outline),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.diagrams,
                  style: AppTheme.headline(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in _chips(l10n))
                      FilterChip(
                        label: Text(item.$2),
                        selected: _kind == item.$1,
                        avatar: _locked(item.$1)
                            ? const Icon(Icons.lock_outline, size: 16)
                            : null,
                        onSelected: (_) {
                          if (_locked(item.$1)) {
                            context.push('/marketplace');
                            return;
                          }
                          setState(() => _kind = item.$1);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: l10n.chartTitle,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (!_noRows) ...[
                  for (var i = 0; i < _rows.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _rowEditor(l10n, i),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _rows.add(ChartSeriesRow()),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.chartAddRow),
                  ),
                ],
                const SizedBox(height: 6),
                FilledButton(
                  onPressed: _busy ? null : _insert,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.chartInsert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class ChartRenderer {
  static const _colors = <Color>[
    Color(0xFF1D4E89),
    Color(0xFF0F766E),
    Color(0xFFD4A017),
    Color(0xFFB42318),
    Color(0xFF7C3AED),
    Color(0xFF0A84FF),
    Color(0xFFD6336C),
    Color(0xFF157347),
  ];

  static Future<Uint8List?> renderPng({
    required ChartKind kind,
    required String title,
    required List<ChartSeriesRow> rows,
    int width = 720,
    int height = 520,
  }) async {
    final values = <({String label, double value, double start, double end})>[];
    for (final row in rows) {
      final label = row.label.trim().isEmpty
          ? '${values.length + 1}'
          : row.label.trim();
      if (kind == ChartKind.gantt) {
        final start = double.tryParse(row.start.replaceAll(',', '.'));
        final end = double.tryParse(row.end.replaceAll(',', '.'));
        if (start == null || end == null || end <= start) continue;
        values.add((label: label, value: end - start, start: start, end: end));
      } else {
        final v = double.tryParse(row.value.replaceAll(',', '.')) ?? 0;
        values.add((label: label, value: v, start: 0, end: v));
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFCF7),
    );

    if (title.isNotEmpty &&
        kind != ChartKind.mindmap &&
        kind != ChartKind.cornell) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 20, fontWeight: FontWeight.w700),
      )..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
        ..addText(title);
      final p = builder.build()
        ..layout(ui.ParagraphConstraints(width: width - 48.0));
      canvas.drawParagraph(p, const Offset(24, 16));
    }

    final plot = Rect.fromLTWH(
      36,
      title.isEmpty || kind == ChartKind.mindmap || kind == ChartKind.cornell
          ? 24
          : 52,
      width - 60.0,
      height - (title.isEmpty ? 56.0 : 80.0),
    );

    switch (kind) {
      case ChartKind.pie:
        _pie(canvas, plot, values);
        _legend(canvas, Offset(24, height - 36.0), values);
      case ChartKind.bar:
        _bar(canvas, plot, values);
        _legend(canvas, Offset(24, height - 36.0), values);
      case ChartKind.line:
        _line(canvas, plot, values);
        _legend(canvas, Offset(24, height - 36.0), values);
      case ChartKind.area:
        _area(canvas, plot, values);
        _legend(canvas, Offset(24, height - 36.0), values);
      case ChartKind.gantt:
        _gantt(canvas, plot, values);
      case ChartKind.mindmap:
        _mindmap(canvas, plot, title, rows);
      case ChartKind.er:
        _er(canvas, plot, rows);
      case ChartKind.usecase:
        _usecase(canvas, plot, rows);
      case ChartKind.flow:
        _flow(canvas, plot, rows);
      case ChartKind.venn:
        _venn(canvas, plot, rows);
      case ChartKind.sequence:
        _sequence(canvas, plot, rows);
      case ChartKind.axes:
        _axes(canvas, plot);
      case ChartKind.numberline:
        _numberline(canvas, plot);
      case ChartKind.cornell:
        _cornell(canvas, plot, title);
      case ChartKind.vocab:
        _vocab(canvas, plot, title, rows);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return bytes?.buffer.asUint8List();
  }

  static void _pie(
    Canvas canvas,
    Rect plot,
    List<({String label, double value, double start, double end})> values,
  ) {
    final total = values.fold<double>(0, (s, v) => s + v.value.abs());
    if (total <= 0) return;
    final side = math.min(plot.width, plot.height);
    final box = Rect.fromCenter(center: plot.center, width: side, height: side);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i].value.abs() / total) * math.pi * 2;
      canvas.drawArc(
        box,
        start,
        sweep,
        true,
        Paint()..color = _colors[i % _colors.length],
      );
      start += sweep;
    }
  }

  static void _bar(
    Canvas canvas,
    Rect plot,
    List<({String label, double value, double start, double end})> values,
  ) {
    final maxV = values.fold<double>(0, (s, v) => math.max(s, v.value.abs()));
    if (maxV <= 0) return;
    final gap = 12.0;
    final barW = (plot.width - gap * (values.length + 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = (values[i].value.abs() / maxV) * plot.height;
      final x = plot.left + gap + i * (barW + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, plot.bottom - h, barW, h),
          const Radius.circular(6),
        ),
        Paint()..color = _colors[i % _colors.length],
      );
    }
  }

  static void _line(
    Canvas canvas,
    Rect plot,
    List<({String label, double value, double start, double end})> values,
  ) {
    if (values.length < 2) return;
    final maxV = values.fold<double>(0, (s, v) => math.max(s, v.value.abs()));
    if (maxV <= 0) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = plot.left + plot.width * (i / (values.length - 1));
      final y = plot.bottom - (values[i].value.abs() / maxV) * plot.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = _colors[i % _colors.length],
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1D4E89)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _area(
    Canvas canvas,
    Rect plot,
    List<({String label, double value, double start, double end})> values,
  ) {
    if (values.length < 2) return;
    final maxV = values.fold<double>(0, (s, v) => math.max(s, v.value.abs()));
    if (maxV <= 0) return;
    final path = Path()..moveTo(plot.left, plot.bottom);
    for (var i = 0; i < values.length; i++) {
      final x = plot.left + plot.width * (i / (values.length - 1));
      final y = plot.bottom - (values[i].value.abs() / maxV) * plot.height;
      path.lineTo(x, y);
    }
    path
      ..lineTo(plot.right, plot.bottom)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF1D4E89).withValues(alpha: 0.22),
    );
    _line(canvas, plot, values);
  }

  static void _gantt(
    Canvas canvas,
    Rect plot,
    List<({String label, double value, double start, double end})> values,
  ) {
    if (values.isEmpty) return;
    var minX = values.first.start;
    var maxX = values.first.end;
    for (final row in values) {
      minX = math.min(minX, row.start);
      maxX = math.max(maxX, row.end);
    }
    final span = maxX - minX;
    if (span <= 0) return;
    final rowH = plot.height / values.length;
    for (var i = 0; i < values.length; i++) {
      final row = values[i];
      final y = plot.top + i * rowH + 6;
      final h = math.max(14.0, rowH - 12);
      final x = plot.left + 72 + ((row.start - minX) / span) * (plot.width - 72);
      final w = ((row.end - row.start) / span) * (plot.width - 72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, math.max(8, w), h),
          const Radius.circular(5),
        ),
        Paint()..color = _colors[i % _colors.length],
      );
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 12, fontWeight: FontWeight.w600),
      )..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
        ..addText(row.label);
      final p = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 68));
      canvas.drawParagraph(p, Offset(plot.left, y + 2));
    }
  }

  static void _legend(
    Canvas canvas,
    Offset origin,
    List<({String label, double value, double start, double end})> values,
  ) {
    var x = origin.dx;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(
        Offset(x + 5, origin.dy + 6),
        5,
        Paint()..color = _colors[i % _colors.length],
      );
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontSize: 12, fontWeight: FontWeight.w600),
      )..pushStyle(ui.TextStyle(color: const Color(0xFF1A1A1A)))
        ..addText(values[i].label);
      final p = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 80));
      canvas.drawParagraph(p, Offset(x + 14, origin.dy));
      x += 96;
    }
  }

  static void _text(
    Canvas canvas,
    Offset at,
    String text, {
    double size = 13,
    FontWeight weight = FontWeight.w600,
    double maxWidth = 160,
    Color color = const Color(0xFF1A1A1A),
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: size, fontWeight: weight),
    )..pushStyle(ui.TextStyle(color: color))
      ..addText(text);
    final p = builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(p, at);
  }

  static void _box(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  static void _arrow(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = 1.6,
    );
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    final path = Path()
      ..moveTo(b.dx, b.dy)
      ..lineTo(
        b.dx - 8 * math.cos(angle - 0.4),
        b.dy - 8 * math.sin(angle - 0.4),
      )
      ..lineTo(
        b.dx - 8 * math.cos(angle + 0.4),
        b.dy - 8 * math.sin(angle + 0.4),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static void _mindmap(
    Canvas canvas,
    Rect plot,
    String title,
    List<ChartSeriesRow> rows,
  ) {
    final nodes = [
      for (final row in rows)
        if (row.label.trim().isNotEmpty) row.label.trim(),
    ];
    if (nodes.isEmpty) return;
    final center = plot.center;
    canvas.drawCircle(center, 46, Paint()..color = const Color(0xFF1D4E89));
    _text(
      canvas,
      Offset(center.dx - 40, center.dy - 12),
      title.isEmpty ? 'Thema' : title,
      size: 14,
      weight: FontWeight.w800,
      maxWidth: 80,
      color: const Color(0xFFFFFFFF),
    );
    for (var i = 0; i < nodes.length; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / nodes.length);
      final tip = Offset(
        center.dx + math.cos(angle) * 150,
        center.dy + math.sin(angle) * 110,
      );
      canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = _colors[i % _colors.length]
          ..strokeWidth = 2,
      );
      _box(
        canvas,
        Rect.fromCenter(center: tip, width: 108, height: 36),
        _colors[i % _colors.length],
      );
      _text(
        canvas,
        Offset(tip.dx - 48, tip.dy - 8),
        nodes[i],
        maxWidth: 96,
      );
    }
  }

  static void _er(Canvas canvas, Rect plot, List<ChartSeriesRow> rows) {
    final items = [
      for (final row in rows)
        if (row.label.trim().isNotEmpty) row,
    ];
    if (items.isEmpty) return;
    final cols = items.length <= 2 ? items.length : 2;
    final w = (plot.width - 20) / cols;
    final h = 110.0;
    final centers = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      final col = i % cols;
      final r = i ~/ cols;
      final rect = Rect.fromLTWH(
        plot.left + col * (w + 10),
        plot.top + r * (h + 24),
        w - 10,
        h,
      );
      centers.add(rect.center);
      _box(canvas, rect, _colors[i % _colors.length]);
      _text(
        canvas,
        Offset(rect.left + 10, rect.top + 8),
        items[i].label.trim(),
        weight: FontWeight.w800,
        maxWidth: rect.width - 20,
      );
      canvas.drawLine(
        Offset(rect.left + 8, rect.top + 30),
        Offset(rect.right - 8, rect.top + 30),
        Paint()..color = const Color(0xFF888888),
      );
      _text(
        canvas,
        Offset(rect.left + 10, rect.top + 36),
        items[i].value.trim().isEmpty ? ' ' : items[i].value.trim(),
        size: 12,
        maxWidth: rect.width - 20,
      );
    }
    for (var i = 0; i < items.length - 1; i++) {
      final rel = items[i].end.trim();
      _arrow(
        canvas,
        centers[i],
        centers[i + 1],
        const Color(0xFF444444),
      );
      if (rel.isNotEmpty) {
        final mid = Offset.lerp(centers[i], centers[i + 1], 0.5)!;
        _text(canvas, Offset(mid.dx - 30, mid.dy - 16), rel, size: 11);
      }
    }
  }

  static void _usecase(Canvas canvas, Rect plot, List<ChartSeriesRow> rows) {
    final actors = <String>{};
    final cases = <(String, String)>[];
    for (final row in rows) {
      final actor = row.label.trim();
      final name = row.value.trim();
      if (actor.isEmpty && name.isEmpty) continue;
      if (actor.isNotEmpty) actors.add(actor);
      if (name.isNotEmpty) {
        cases.add((actor.isEmpty ? 'Akteur' : actor, name));
      }
    }
    final actorList = actors.toList();
    for (var i = 0; i < actorList.length; i++) {
      final x = plot.left + 28;
      final y = plot.top + 36 + i * 90;
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()..color = const Color(0xFF1A1A1A),
      );
      canvas.drawLine(
        Offset(x, y + 10),
        Offset(x, y + 36),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(x - 14, y + 20),
        Offset(x + 14, y + 20),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(x, y + 36),
        Offset(x - 12, y + 54),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(x, y + 36),
        Offset(x + 12, y + 54),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 2,
      );
      _text(canvas, Offset(x - 24, y + 58), actorList[i], size: 11, maxWidth: 70);
    }
    final system = Rect.fromLTWH(
      plot.left + 110,
      plot.top,
      plot.width - 120,
      plot.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(system, const Radius.circular(10)),
      Paint()
        ..color = const Color(0xFF1D4E89)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (var i = 0; i < cases.length; i++) {
      final oval = Rect.fromLTWH(
        system.left + 24,
        system.top + 20 + i * 70,
        system.width - 48,
        48,
      );
      canvas.drawOval(
        oval,
        Paint()..color = const Color(0xFF1D4E89).withValues(alpha: 0.12),
      );
      canvas.drawOval(
        oval,
        Paint()
          ..color = const Color(0xFF1D4E89)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _text(
        canvas,
        Offset(oval.left + 12, oval.center.dy - 8),
        cases[i].$2,
        maxWidth: oval.width - 24,
      );
    }
  }

  static void _flow(Canvas canvas, Rect plot, List<ChartSeriesRow> rows) {
    final steps = [
      for (final row in rows)
        if (row.label.trim().isNotEmpty) row.label.trim(),
    ];
    if (steps.isEmpty) return;
    final h = math.min(48.0, (plot.height - 16) / steps.length - 16);
    for (var i = 0; i < steps.length; i++) {
      final y = plot.top + i * (h + 22);
      final rect = Rect.fromLTWH(plot.left + 80, y, plot.width - 160, h);
      _box(canvas, rect, _colors[i % _colors.length]);
      _text(
        canvas,
        Offset(rect.left + 12, rect.center.dy - 8),
        steps[i],
        maxWidth: rect.width - 24,
      );
      if (i < steps.length - 1) {
        _arrow(
          canvas,
          Offset(rect.center.dx, rect.bottom),
          Offset(rect.center.dx, rect.bottom + 18),
          const Color(0xFF444444),
        );
      }
    }
  }

  static void _venn(Canvas canvas, Rect plot, List<ChartSeriesRow> rows) {
    final sets = [
      for (final row in rows)
        if (row.label.trim().isNotEmpty) row,
    ].take(3).toList();
    if (sets.isEmpty) return;
    final r = math.min(plot.width, plot.height) * 0.28;
    final centers = sets.length == 1
        ? [plot.center]
        : sets.length == 2
            ? [
                plot.center.translate(-r * 0.55, 0),
                plot.center.translate(r * 0.55, 0),
              ]
            : [
                plot.center.translate(-r * 0.55, -r * 0.2),
                plot.center.translate(r * 0.55, -r * 0.2),
                plot.center.translate(0, r * 0.55),
              ];
    for (var i = 0; i < sets.length; i++) {
      canvas.drawCircle(
        centers[i],
        r,
        Paint()..color = _colors[i % _colors.length].withValues(alpha: 0.22),
      );
      canvas.drawCircle(
        centers[i],
        r,
        Paint()
          ..color = _colors[i % _colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      _text(
        canvas,
        Offset(centers[i].dx - 40, centers[i].dy - r - 4),
        sets[i].label.trim(),
        maxWidth: 80,
      );
    }
  }

  static void _sequence(Canvas canvas, Rect plot, List<ChartSeriesRow> rows) {
    final names = <String>[];
    void add(String name) {
      final n = name.trim();
      if (n.isNotEmpty && !names.contains(n)) names.add(n);
    }

    for (final row in rows) {
      add(row.label);
      add(row.value);
    }
    if (names.isEmpty) return;
    final gap = plot.width / names.length;
    final tops = <String, Offset>{};
    for (var i = 0; i < names.length; i++) {
      final x = plot.left + gap * i + gap / 2;
      final box = Rect.fromCenter(
        center: Offset(x, plot.top + 18),
        width: math.min(100, gap - 8),
        height: 28,
      );
      _box(canvas, box, _colors[i % _colors.length]);
      _text(
        canvas,
        Offset(box.left + 6, box.top + 6),
        names[i],
        size: 12,
        maxWidth: box.width - 12,
      );
      canvas.drawLine(
        Offset(x, box.bottom),
        Offset(x, plot.bottom),
        Paint()
          ..color = const Color(0xFFBBBBBB)
          ..strokeWidth = 1.2,
      );
      tops[names[i]] = Offset(x, box.bottom);
    }
    var y = plot.top + 56;
    for (final row in rows) {
      final from = tops[row.label.trim()];
      final to = tops[row.value.trim()];
      if (from == null || to == null) continue;
      final a = Offset(from.dx, y);
      final b = Offset(to.dx, y);
      _arrow(canvas, a, b, const Color(0xFF1D4E89));
      if (row.start.trim().isNotEmpty) {
        _text(
          canvas,
          Offset(math.min(a.dx, b.dx) + 8, y - 16),
          row.start.trim(),
          size: 11,
          maxWidth: (a.dx - b.dx).abs() + 40,
        );
      }
      y += 36;
    }
  }

  static void _axes(Canvas canvas, Rect plot) {
    final origin = Offset(plot.left + 36, plot.bottom - 28);
    _arrow(
      canvas,
      Offset(origin.dx, plot.bottom),
      Offset(origin.dx, plot.top),
      const Color(0xFF1A1A1A),
    );
    _arrow(
      canvas,
      Offset(plot.left, origin.dy),
      Offset(plot.right, origin.dy),
      const Color(0xFF1A1A1A),
    );
    _text(canvas, Offset(plot.right - 18, origin.dy + 6), 'x', size: 14);
    _text(canvas, Offset(origin.dx + 8, plot.top), 'y', size: 14);
    for (var i = 1; i <= 8; i++) {
      final x = origin.dx + i * ((plot.width - 50) / 9);
      canvas.drawLine(
        Offset(x, origin.dy - 4),
        Offset(x, origin.dy + 4),
        Paint()..color = const Color(0xFF1A1A1A),
      );
      final y = origin.dy - i * ((plot.height - 40) / 9);
      canvas.drawLine(
        Offset(origin.dx - 4, y),
        Offset(origin.dx + 4, y),
        Paint()..color = const Color(0xFF1A1A1A),
      );
    }
  }

  static void _numberline(Canvas canvas, Rect plot) {
    final y = plot.center.dy;
    _arrow(
      canvas,
      Offset(plot.left, y),
      Offset(plot.right, y),
      const Color(0xFF1A1A1A),
    );
    for (var n = -5; n <= 5; n++) {
      final x = plot.left + ((n + 5) / 10) * plot.width;
      canvas.drawLine(
        Offset(x, y - 8),
        Offset(x, y + 8),
        Paint()
          ..color = const Color(0xFF1A1A1A)
          ..strokeWidth = 1.4,
      );
      _text(canvas, Offset(x - 8, y + 12), '$n', size: 12, maxWidth: 24);
    }
  }

  static void _cornell(Canvas canvas, Rect plot, String title) {
    _box(canvas, plot, const Color(0xFF1D4E89));
    _text(
      canvas,
      Offset(plot.left + 12, plot.top + 8),
      title.isEmpty ? 'Cornell' : title,
      weight: FontWeight.w800,
      maxWidth: plot.width - 24,
    );
    final cue = Rect.fromLTWH(
      plot.left + 8,
      plot.top + 36,
      plot.width * 0.32,
      plot.height - 100,
    );
    final notes = Rect.fromLTWH(
      cue.right + 8,
      cue.top,
      plot.right - cue.right - 16,
      cue.height,
    );
    final sum = Rect.fromLTWH(
      plot.left + 8,
      cue.bottom + 8,
      plot.width - 16,
      plot.bottom - cue.bottom - 16,
    );
    _box(canvas, cue, const Color(0xFF0F766E));
    _box(canvas, notes, const Color(0xFF1D4E89));
    _box(canvas, sum, const Color(0xFFD4A017));
    _text(canvas, Offset(cue.left + 8, cue.top + 8), 'Stichworte', size: 12);
    _text(canvas, Offset(notes.left + 8, notes.top + 8), 'Notizen', size: 12);
    _text(canvas, Offset(sum.left + 8, sum.top + 8), 'Zusammenfassung', size: 12);
  }

  static void _vocab(
    Canvas canvas,
    Rect plot,
    String title,
    List<ChartSeriesRow> rows,
  ) {
    _text(
      canvas,
      Offset(plot.left, plot.top),
      title.isEmpty ? 'Vokabeln' : title,
      weight: FontWeight.w800,
      maxWidth: plot.width,
    );
    final top = plot.top + 28;
    final rowH = (plot.height - 36) / 8;
    final mid = plot.left + plot.width / 2;
    canvas.drawRect(
      Rect.fromLTWH(plot.left, top, plot.width, rowH),
      Paint()..color = const Color(0xFF1D4E89).withValues(alpha: 0.12),
    );
    _text(canvas, Offset(plot.left + 8, top + 8), 'Wort', size: 13);
    _text(canvas, Offset(mid + 8, top + 8), 'Bedeutung', size: 13);
    for (var i = 0; i < 8; i++) {
      final y = top + i * rowH;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()..color = const Color(0xFFCCCCCC),
      );
      if (i > 0 && i - 1 < rows.length) {
        final row = rows[i - 1];
        if (row.label.trim().isNotEmpty) {
          _text(canvas, Offset(plot.left + 8, y + 8), row.label.trim());
        }
        if (row.value.trim().isNotEmpty) {
          _text(canvas, Offset(mid + 8, y + 8), row.value.trim());
        }
      }
    }
    canvas.drawLine(
      Offset(mid, top),
      Offset(mid, top + 8 * rowH),
      Paint()..color = const Color(0xFFAAAAAA),
    );
  }
}
