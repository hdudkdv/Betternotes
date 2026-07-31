import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/domain/paper_line_metrics.dart';
import 'package:betternotes/features/editor/domain/text_block_registry.dart';
import 'package:betternotes/features/editor/presentation/widgets/text_block_layer.dart';
import 'package:betternotes/features/editor/presentation/widgets/text_format_bar.dart';
import 'package:betternotes/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _pageSize = Size(794, 1123);

TextBlock _lineBoundBlock(PaperLineMetrics metrics, {required String text}) {
  return TextBlock(
    id: 'block',
    pageId: 'page',
    x: 0,
    y: metrics.snapToLine(300),
    width: 0,
    height: 0,
    layoutMode: TextLayoutMode.lineBound,
    spans: [TextSpanStyle(text: text)],
  );
}

Future<void> _pumpLayer(
  WidgetTester tester, {
  required TextBlock block,
  required PaperLineMetrics metrics,
  TextScaler textScaler = TextScaler.noScaling,
  double zoom = 1,
  bool editable = false,
  String? selectedId,
  String? editingId,
  ValueChanged<TextBlock>? onChanged,
  ValueChanged<String?>? onSelect,
  ValueChanged<String>? onBeginEdit,
}) async {
  await tester.pumpWidget(
    // MaterialApp supplies the localizations a live TextField needs.
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: _pageSize, textScaler: textScaler),
        child: Align(
          alignment: Alignment.topLeft,
          child: Transform.scale(
            scale: zoom,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _pageSize.width,
              height: _pageSize.height,
              child: TextBlockLayer(
                blocks: [block],
                selectedId: selectedId,
                editingId: editingId,
                editable: editable,
                onSelect: onSelect ?? (_) {},
                onBeginEdit: onBeginEdit ?? (_) {},
                onChanged: onChanged ?? (_) {},
                onDelete: (_) {},
                metrics: metrics,
                registry: TextBlockRegistry(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(find.byType(RichText));

/// Global y of the top of every rendered line, derived from caret positions.
List<double> _lineTops(RenderParagraph paragraph, String text) {
  final top = paragraph.localToGlobal(Offset.zero).dy;
  final tops = <double>[];
  for (var offset = 0; offset <= text.length; offset++) {
    final dy =
        top +
        paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dy;
    if (tops.isEmpty || (dy - tops.last).abs() > 0.5) tops.add(dy);
  }
  return tops;
}

void main() {
  group('line-bound text', () {
    testWidgets('every wrapped line sits on a ruled line', (tester) async {
      final metrics = PaperLineMetrics.from(
        template: PageTemplate.lined,
        pageSize: _pageSize,
      );
      final block = _lineBoundBlock(
        metrics,
        text:
            'Dieser Satz ist absichtlich sehr lang damit er über mehrere '
            'Zeilen umbricht und wir prüfen können ob jede Grundlinie exakt '
            'auf einer Linie des Papiers landet.',
      );
      await _pumpLayer(tester, block: block, metrics: metrics);
      final paragraph = _paragraph(tester);

      final baselineOffset = measureBaselineOffset(
        metrics: metrics,
        style: resolveRunStyle(
          run: const TextSpanStyle(text: ''),
          lineBound: true,
          metrics: metrics,
        ),
      );
      final tops = _lineTops(paragraph, block.plainText);
      expect(tops.length, greaterThan(2));
      for (var i = 0; i < tops.length; i++) {
        expect(
          tops[i] + baselineOffset,
          closeTo(block.y + i * metrics.lineSpacing, 0.5),
          reason: 'line ${i + 1} baseline drifted off its rule',
        );
      }
    });

    testWidgets('system font scaling does not move the lines', (tester) async {
      final metrics = PaperLineMetrics.from(
        template: PageTemplate.lined,
        pageSize: _pageSize,
      );
      final block = _lineBoundBlock(
        metrics,
        text:
            'Auch bei großer Systemschrift muss der Zeilenabstand dem Papier '
            'folgen, sonst wandert der Text über die Linien hinweg.',
      );
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        textScaler: const TextScaler.linear(1.6),
      );
      final paragraph = _paragraph(tester);

      final baselineOffset = measureBaselineOffset(
        metrics: metrics,
        style: resolveRunStyle(
          run: const TextSpanStyle(text: ''),
          lineBound: true,
          metrics: metrics,
        ),
      );
      final tops = _lineTops(paragraph, block.plainText);
      expect(tops.length, greaterThan(1));
      for (var i = 0; i < tops.length; i++) {
        expect(
          tops[i] + baselineOffset,
          closeTo(block.y + i * metrics.lineSpacing, 0.5),
          reason: 'line ${i + 1} moved when the system font scale changed',
        );
      }
    });
  });

  group('page text behaves like a word processor', () {
    final metrics = PaperLineMetrics.from(
      template: PageTemplate.lined,
      pageSize: _pageSize,
    );

    testWidgets('a tap puts a caret in it, without handles', (tester) async {
      final block = _lineBoundBlock(metrics, text: 'Seitentext');
      final moves = <TextBlock>[];
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onChanged: moves.add,
      );

      expect(find.byType(EditableText), findsOneWidget);
      expect(find.byIcon(Icons.open_with_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);

      await tester.tapAt(
        textBlockBounds(block: block, metrics: metrics).centerLeft +
            const Offset(20, 0),
      );
      await tester.pump();
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(moves, isEmpty);
    });

    testWidgets('dragging it does not move it', (tester) async {
      final block = _lineBoundBlock(metrics, text: 'Bleibt auf seiner Zeile');
      final moves = <TextBlock>[];
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onChanged: moves.add,
      );

      await tester.dragFrom(
        textBlockBounds(block: block, metrics: metrics).center,
        const Offset(0, 90),
      );
      await tester.pump();

      expect(moves, isEmpty);
    });

    testWidgets('the writing column owns taps below existing text', (
      tester,
    ) async {
      final block = _lineBoundBlock(metrics, text: 'Erste Zeile');
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        editingId: block.id,
      );

      await tester.tapAt(Offset(metrics.marginLeft + 20, 650));
      await tester.pump();

      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .widget
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('a tap on an existing lower line moves the caret there', (
      tester,
    ) async {
      final block = _lineBoundBlock(metrics, text: 'Erste\nZweite');
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        editingId: block.id,
      );
      final baselineOffset = measureBaselineOffset(
        metrics: metrics,
        style: resolveRunStyle(
          run: const TextSpanStyle(text: ''),
          lineBound: true,
          metrics: metrics,
        ),
      );

      await tester.tapAt(
        Offset(
          metrics.marginLeft + 10,
          block.y - baselineOffset + metrics.lineSpacing + 4,
        ),
      );
      await tester.pump();

      final controller = tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .controller;
      expect(controller.selection.baseOffset, greaterThanOrEqualTo(6));
    });

    testWidgets('the caret follows the rules across wrapped lines', (
      tester,
    ) async {
      final block = _lineBoundBlock(
        metrics,
        text:
            'Ein langer Absatz der über mehrere Zeilen läuft damit wir den '
            'Cursor auf jeder Zeile prüfen können und sehen ob er sauber auf '
            'den Linien sitzt.',
      );
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        editingId: block.id,
      );

      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final top = editable.localToGlobal(Offset.zero).dy;
      final tops = <double>[];
      for (var offset = 0; offset <= block.plainText.length; offset++) {
        final dy =
            top +
            editable.getLocalRectForCaret(TextPosition(offset: offset)).top;
        if (tops.isEmpty || (dy - tops.last).abs() > 0.5) tops.add(dy);
      }

      expect(tops.length, greaterThan(2));
      for (var i = 1; i < tops.length; i++) {
        expect(
          tops[i] - tops[i - 1],
          closeTo(metrics.lineSpacing, 0.5),
          reason: 'caret on line ${i + 1} left the ruled grid',
        );
      }
    });
  });

  group('formatting a selection', () {
    testWidgets('only the marked word changes and it stays marked', (
      tester,
    ) async {
      // Desktop drops focus on any tap outside the field, which is exactly what
      // the format bar must not trigger.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final metrics = PaperLineMetrics.from(
        template: PageTemplate.lined,
        pageSize: _pageSize,
      );
      final registry = TextBlockRegistry();
      var block = const TextBlock(
        id: 'free',
        pageId: 'page',
        x: 60,
        y: 60,
        width: 300,
        height: 48,
        layoutMode: TextLayoutMode.free,
        spans: [TextSpanStyle(text: 'Hallo Welt hier')],
      );
      final controller = registry.obtain(
        block: block,
        resolveStyle: (run) =>
            resolveRunStyle(run: run, lineBound: false, metrics: metrics),
        onRunsChanged: (_) {},
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextFormatBar(
                  block: block,
                  controller: controller,
                  onBlockChanged: (updated) => setState(() => block = updated),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: _pageSize.width,
                      height: 400,
                      child: TextBlockLayer(
                        blocks: [block],
                        selectedId: block.id,
                        editingId: block.id,
                        editable: true,
                        onSelect: (_) {},
                        onBeginEdit: (_) {},
                        onChanged: (updated) => setState(() => block = updated),
                        onDelete: (_) {},
                        metrics: metrics,
                        registry: registry,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      const selection = TextSelection(baseOffset: 6, extentOffset: 10);
      controller.selection = selection;
      await tester.pump();

      await tester.tap(find.byIcon(Icons.format_italic_rounded));
      await tester.pump();

      expect(controller.selection, selection);
      expect(block.plainText, 'Hallo Welt hier');
      expect(
        block.spans.where((run) => run.italic).map((run) => run.text).join(),
        'Welt',
      );

      await tester.tap(find.byIcon(Icons.format_bold_rounded));
      await tester.pump();
      expect(
        block.spans.where((run) => run.bold).map((run) => run.text).join(),
        'Welt',
      );
      expect(block.spans.where((run) => !run.italic).length, 2);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('free text block', () {
    final metrics = PaperLineMetrics.from(
      template: PageTemplate.lined,
      pageSize: _pageSize,
    );
    const block = TextBlock(
      id: 'free',
      pageId: 'page',
      x: 120,
      y: 240,
      width: 220,
      height: 48,
      layoutMode: TextLayoutMode.free,
      spans: [TextSpanStyle(text: 'Verschiebbar')],
    );

    testWidgets('dragging the body moves it and it stays where released', (
      tester,
    ) async {
      final moves = <TextBlock>[];
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onChanged: moves.add,
      );

      await tester.dragFrom(
        textBlockBounds(block: block, metrics: metrics).center,
        const Offset(60, 40),
      );
      await tester.pump();

      expect(moves, hasLength(1));
      expect(moves.single.x, closeTo(block.x + 60, 0.5));
      expect(moves.single.y, closeTo(block.y + 40, 0.5));
    });

    testWidgets('dragging works again after the block was placed', (
      tester,
    ) async {
      final moves = <TextBlock>[];
      var current = block;
      await _pumpLayer(
        tester,
        block: current,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onChanged: (updated) {
          moves.add(updated);
          current = updated;
        },
      );

      await tester.dragFrom(
        textBlockBounds(block: current, metrics: metrics).center,
        const Offset(30, 20),
      );
      await tester.pump();
      await _pumpLayer(
        tester,
        block: current,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onChanged: (updated) {
          moves.add(updated);
          current = updated;
        },
      );
      await tester.dragFrom(
        textBlockBounds(block: current, metrics: metrics).center,
        const Offset(25, 15),
      );
      await tester.pump();

      expect(moves, hasLength(2));
      expect(current.x, closeTo(block.x + 55, 0.5));
      expect(current.y, closeTo(block.y + 35, 0.5));
    });

    testWidgets('a zoomed page moves the block by the same page distance', (
      tester,
    ) async {
      final moves = <TextBlock>[];
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        zoom: 2,
        onChanged: moves.add,
      );

      final center = textBlockBounds(block: block, metrics: metrics).center * 2;
      await tester.dragFrom(center, const Offset(60, 40));
      await tester.pump();

      expect(moves, hasLength(1));
      expect(moves.single.x, closeTo(block.x + 30, 0.5));
      expect(moves.single.y, closeTo(block.y + 20, 0.5));
    });

    testWidgets('tapping selects first and opens the keyboard second', (
      tester,
    ) async {
      final selected = <String?>[];
      final edited = <String>[];
      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        onSelect: selected.add,
        onBeginEdit: edited.add,
      );
      final center = textBlockBounds(block: block, metrics: metrics).center;
      await tester.tapAt(center);
      await tester.pump();
      expect(selected, [block.id]);
      expect(edited, isEmpty);

      await _pumpLayer(
        tester,
        block: block,
        metrics: metrics,
        editable: true,
        selectedId: block.id,
        onSelect: selected.add,
        onBeginEdit: edited.add,
      );
      await tester.tapAt(center);
      await tester.pump();
      expect(edited, [block.id]);
    });

    testWidgets('bounds cover the block so the canvas skips a new one', (
      tester,
    ) async {
      final bounds = textBlockBounds(block: block, metrics: metrics);
      expect(bounds.contains(Offset(block.x + 4, block.y + 4)), isTrue);
      expect(bounds.contains(const Offset(600, 600)), isFalse);
      expect(bounds.height, greaterThanOrEqualTo(block.height));
    });
  });
}
