import 'package:betternotes/data/models/content_models.dart';
import 'package:betternotes/features/editor/domain/ink_models.dart';
import 'package:betternotes/features/editor/domain/paper_line_metrics.dart';
import 'package:betternotes/features/editor/domain/rich_text_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RichTextEditingController controllerFor(List<TextSpanStyle> runs) {
  return RichTextEditingController(
    runs: runs,
    resolveStyle: (_) => const TextStyle(),
  );
}

void main() {
  group('RichTextEditingController', () {
    test('typing inherits the formatting left of the caret', () {
      final controller = controllerFor(const [
        TextSpanStyle(text: 'ab', bold: true),
        TextSpanStyle(text: 'cd'),
      ]);

      controller.value = const TextEditingValue(
        text: 'abXcd',
        selection: TextSelection.collapsed(offset: 3),
      );

      expect(controller.runs.map((r) => r.text).toList(), ['abX', 'cd']);
      expect(controller.runs.first.bold, isTrue);
      expect(controller.runs.last.bold, isFalse);
    });

    test('formats only the selected range', () {
      final controller = controllerFor(const [TextSpanStyle(text: 'abcd')]);

      controller.applyToSelection(
        const TextSelection(baseOffset: 0, extentOffset: 2),
        (run) => run.copyWith(bold: true),
      );

      expect(controller.runs.length, 2);
      expect(controller.runs[0].text, 'ab');
      expect(controller.runs[0].bold, isTrue);
      expect(controller.runs[1].text, 'cd');
      expect(controller.runs[1].bold, isFalse);
    });

    test('a collapsed selection formats the whole block', () {
      final controller = controllerFor(const [TextSpanStyle(text: 'abcd')]);

      controller.applyToSelection(
        const TextSelection.collapsed(offset: 2),
        (run) => run.copyWith(underline: true),
      );

      expect(controller.runs.length, 1);
      expect(controller.runs.single.underline, isTrue);
    });

    test('deleting across runs keeps the remaining formatting', () {
      final controller = controllerFor(const [
        TextSpanStyle(text: 'ab', bold: true),
        TextSpanStyle(text: 'cd'),
      ]);

      controller.value = const TextEditingValue(
        text: 'ad',
        selection: TextSelection.collapsed(offset: 1),
      );

      expect(controller.runs.map((r) => r.text).toList(), ['a', 'd']);
      expect(controller.runs.first.bold, isTrue);
      expect(controller.runs.last.bold, isFalse);
    });

    test('runs collapse again when formatting matches', () {
      final controller = controllerFor(const [
        TextSpanStyle(text: 'ab', bold: true),
        TextSpanStyle(text: 'cd'),
      ]);

      controller.applyToSelection(
        const TextSelection(baseOffset: 0, extentOffset: 4),
        (run) => run.copyWith(bold: false),
      );

      expect(controller.runs.length, 1);
      expect(controller.runs.single.text, 'abcd');
    });

    test('reports changed runs to the owner', () {
      final controller = controllerFor(const [TextSpanStyle(text: 'ab')]);
      List<TextSpanStyle>? reported;
      controller.onRunsChanged = (runs) => reported = runs;

      controller.applyToSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
        (run) => run.copyWith(italic: true),
      );

      expect(reported, isNotNull);
      expect(reported!.first.italic, isTrue);
    });
  });

  group('PaperLineMetrics', () {
    test('lined paper snaps onto the painted rules', () {
      final metrics = PaperLineMetrics.from(template: PageTemplate.lined);

      expect(metrics.snapToLine(60), 48);
      expect(metrics.snapToLine(70), 76);
      expect(metrics.snapToLine(0), 48);
    });

    test('grid paper snaps onto multiples of the grid size', () {
      final metrics = PaperLineMetrics.from(template: PageTemplate.grid);

      expect(metrics.snapToLine(50) % metrics.lineSpacing, 0);
      expect(metrics.snapToLine(100) % metrics.lineSpacing, 0);
    });

    test('custom paper snaps onto its own rules', () {
      final paper = PaperTemplate.create(
        name: 'test',
        style: 'custom',
        horizontalLines: const [40, 80, 120],
      );
      final metrics = PaperLineMetrics.from(paper: paper);

      expect(metrics.snapToLine(75), 80);
      expect(metrics.snapToLine(41), 40);
    });
  });
}
