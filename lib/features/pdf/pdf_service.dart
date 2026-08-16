import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:printing/printing.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../shared/utils/file_store.dart';
import '../../shared/utils/page_size.dart';
import '../editor/domain/ink_models.dart';

class PdfService {
  PdfService(this._repository);

  final NotebookRepository _repository;
  final FileStore _files = createFileStore();

  Future<List<NotePage>> importPdfAsPages({required String notebookId}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return [];

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return [];
    return importPdfFromBytes(notebookId: notebookId, bytes: bytes);
  }

  Future<List<NotePage>> importPdfFromBytes({
    required String notebookId,
    required Uint8List bytes,
    void Function(int done, int total)? onProgress,
  }) async {
    await pdfrx.pdfrxFlutterInitialize();

    final notebook = await _repository.getNotebook(notebookId);
    final paperFormat = notebook?.defaultPaperFormat ?? PaperFormat.a4;
    final orientation =
        notebook?.defaultOrientation ?? PageOrientation.portrait;
    final pageSize = NotePageSize.resolve(paperFormat, orientation);
    final doc = await pdfrx.PdfDocument.openData(bytes);
    final filesDir = await _repository.resolveFilesDir();
    final drafts = <NotePageDraft>[];
    // 1.5× is sharp enough on tablets and much cheaper than 2× PNG.
    final renderW = pageSize.width * 1.5;
    final renderH = pageSize.height * 1.5;
    final stamp = DateTime.now().microsecondsSinceEpoch;

    try {
      final total = doc.pages.length;
      for (var i = 0; i < total; i++) {
        final pdfPage = doc.pages[i];
        String? imagePath;

        try {
          final rendered = await pdfPage.render(
            fullWidth: renderW,
            fullHeight: renderH,
          );
          if (rendered != null) {
            final dartImage = rendered.createImageNF(pixelSizeThreshold: 1400);
            rendered.dispose();
            // JPEG is far cheaper than PNG; run encode off the UI isolate.
            final rgba = dartImage.getBytes(order: img.ChannelOrder.rgba);
            final encoded = await compute(_encodeJpegIsolate, <String, dynamic>{
              'width': dartImage.width,
              'height': dartImage.height,
              'bytes': rgba,
            });

            final outPath = p.join(
              filesDir,
              '${notebookId}_pdf_${stamp}_${i + 1}.jpg',
            );
            await _files.writeBytes(outPath, encoded);
            imagePath = outPath;
          }
        } catch (_) {
          // Keep importing remaining pages.
        }

        drafts.add(
          NotePageDraft(
            template: PageTemplate.blank,
            backgroundPdfPath: imagePath,
            paperFormat: paperFormat,
            orientation: orientation,
          ),
        );
        onProgress?.call(i + 1, total);
        // Let the UI breathe between heavy raster pages.
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      await doc.dispose();
    }

    return _repository.addPages(notebookId: notebookId, drafts: drafts);
  }

  /// Turns system-scanner / camera images into notebook pages.
  Future<List<NotePage>> importScannedImages({
    required String notebookId,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) return const [];
    final notebook = await _repository.getNotebook(notebookId);
    final paperFormat = notebook?.defaultPaperFormat ?? PaperFormat.a4;
    final orientation =
        notebook?.defaultOrientation ?? PageOrientation.portrait;
    final filesDir = await _repository.resolveFilesDir();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final drafts = <NotePageDraft>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final src = imagePaths[i];
      String imagePath = src;
      try {
        if (kIsWeb) {
          final bytes = await _files.readBytes(src);
          imagePath = 'memory:${base64Encode(bytes)}';
        } else {
          final bytes = await _files.readBytes(src);
          final outPath = p.join(
            filesDir,
            '${notebookId}_scan_${stamp}_${i + 1}.jpg',
          );
          await _files.writeBytes(outPath, bytes);
          imagePath = outPath;
        }
      } catch (_) {}
      drafts.add(
        NotePageDraft(
          template: PageTemplate.blank,
          backgroundPdfPath: imagePath,
          paperFormat: paperFormat,
          orientation: orientation,
        ),
      );
    }
    return _repository.addPages(notebookId: notebookId, drafts: drafts);
  }

  Future<Uint8List> buildNotebookPdfBytes(
    Notebook notebook,
    List<NotePage> pages, {
    int? onlyPageIndex,
  }) async {
    final doc = pw.Document();
    final selected = onlyPageIndex == null
        ? pages
        : [pages[onlyPageIndex.clamp(0, pages.length - 1)]];

    for (final page in selected) {
      final pageSize = NotePageSize.resolve(page.paperFormat, page.orientation);
      final pageFormat = pdf.PdfPageFormat(pageSize.width, pageSize.height);
      pw.MemoryImage? bg;
      if (page.backgroundPdfPath != null) {
        try {
          final path = page.backgroundPdfPath!;
          if (path.startsWith('memory:')) {
            bg = pw.MemoryImage(base64Decode(path.substring(7)));
          } else if (!kIsWeb) {
            bg = pw.MemoryImage(await _files.readBytes(path));
          }
        } catch (_) {}
      }

      final imageWidgets = <pw.Widget>[];
      for (final image in page.images) {
        try {
          late Uint8List bytes;
          if (image.localPath.startsWith('memory:')) {
            bytes = base64Decode(image.localPath.substring(7));
          } else if (!kIsWeb) {
            bytes = await _files.readBytes(image.localPath);
          } else {
            continue;
          }
          imageWidgets.add(
            pw.Positioned(
              left: image.x,
              top: image.y,
              child: pw.SizedBox(
                width: image.width,
                height: image.height,
                child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
              ),
            ),
          );
        } catch (_) {}
      }

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Stack(
              children: [
                if (bg != null)
                  pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.fill))
                else
                  pw.Container(
                    color: pdf.PdfColor.fromInt(
                      page.customPaper?.backgroundColor ?? 0xFFFFFBF5,
                    ),
                  ),
                pw.CustomPaint(
                  size: pdf.PdfPoint(pageSize.width, pageSize.height),
                  painter: (canvas, size) {
                    // PDF origin is bottom-left; notebook ink uses top-left.
                    final h = size.y;
                    _paintTemplate(canvas, size, page, h);
                    for (final shape in page.shapes) {
                      _paintShape(canvas, shape, h);
                    }
                    for (final stroke in page.strokes) {
                      _paintStroke(canvas, stroke, h);
                    }
                  },
                ),
                ...imageWidgets,
                for (final block in page.textBlocks)
                  pw.Positioned(
                    left: block.x,
                    top: block.y,
                    child: pw.SizedBox(
                      width: block.width,
                      child: pw.Text(
                        block.plainText,
                        style: pw.TextStyle(
                          fontSize: block.spans.isEmpty
                              ? 16
                              : block.spans.first.fontSize,
                          color: pdf.PdfColor.fromInt(
                            block.spans.isEmpty
                                ? 0xFF1A1A1A
                                : block.spans.first.colorValue,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  Future<void> printNotebook(Notebook notebook, List<NotePage> pages) async {
    final bytes = await buildNotebookPdfBytes(notebook, pages);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${notebook.title}.pdf',
    );
  }

  Future<void> shareNotebookPdf(Notebook notebook, List<NotePage> pages) async {
    final bytes = await buildNotebookPdfBytes(notebook, pages);
    await Printing.sharePdf(bytes: bytes, filename: '${notebook.title}.pdf');
  }

  Future<void> shareCurrentPagePdf(
    Notebook notebook,
    List<NotePage> pages,
    int pageIndex,
  ) async {
    final bytes = await buildNotebookPdfBytes(
      notebook,
      pages,
      onlyPageIndex: pageIndex,
    );
    final n = pageIndex + 1;
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${notebook.title}_page_$n.pdf',
    );
  }

  /// Legacy entry used by older call sites.
  Future<void> exportNotebook(Notebook notebook, List<NotePage> pages) {
    return printNotebook(notebook, pages);
  }

  Future<ui.Image?> loadBackgroundImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      late Uint8List bytes;
      if (path.startsWith('memory:')) {
        bytes = base64Decode(path.substring(7));
      } else {
        bytes = await _files.readBytes(path);
      }
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _paintTemplate(
    pdf.PdfGraphics canvas,
    pdf.PdfPoint size,
    NotePage page,
    double pageH,
  ) {
    double fy(double y) => pageH - y;
    final paper = page.customPaper;
    final line = pdf.PdfColor.fromInt(paper?.lineColor ?? 0xFFD7D2C8);
    final style = paper?.style ?? page.template.name;
    switch (style) {
      case 'blank':
        return;
      case 'dotted':
        final spacing = paper?.gridSize ?? 16.0;
        canvas.setFillColor(line);
        for (var x = spacing; x < size.x - 12; x += spacing) {
          for (var y = spacing; y < size.y - 12; y += spacing) {
            canvas
              ..drawEllipse(x, fy(y), 0.9, 0.9)
              ..fillPath();
          }
        }
        return;
      case 'grid':
        final spacing = paper?.gridSize ?? 24.0;
        final margin = paper?.marginTop ?? 36.0;
        for (var x = margin; x < size.x - 24; x += spacing) {
          canvas
            ..setStrokeColor(line)
            ..setLineWidth(0.8)
            ..drawLine(x, fy(margin), x, fy(size.y - margin))
            ..strokePath();
        }
        for (var y = margin; y < size.y - 24; y += spacing) {
          canvas
            ..setStrokeColor(line)
            ..setLineWidth(0.8)
            ..drawLine(margin, fy(y), size.x - margin, fy(y))
            ..strokePath();
        }
        return;
      default:
        final spacing = paper?.lineSpacing ?? 28.0;
        final marginTop = paper?.marginTop ?? 48.0;
        final marginLeft = paper?.marginLeft ?? 72.0;
        for (var y = marginTop; y < size.y - 24; y += spacing) {
          canvas
            ..setStrokeColor(line)
            ..setLineWidth(0.8)
            ..drawLine(36, fy(y), size.x - 36, fy(y))
            ..strokePath();
        }
        canvas
          ..setStrokeColor(pdf.PdfColor.fromInt(0xFFE8A0A0))
          ..setLineWidth(1)
          ..drawLine(marginLeft, fy(24), marginLeft, fy(size.y - 24))
          ..strokePath();
    }
  }

  void _paintShape(pdf.PdfGraphics canvas, ShapeElement shape, double pageH) {
    double fy(double y) => pageH - y;
    canvas
      ..setStrokeColor(pdf.PdfColor.fromInt(shape.colorValue))
      ..setLineWidth(shape.strokeWidth)
      ..setLineCap(pdf.PdfLineCap.round)
      ..setLineJoin(pdf.PdfLineJoin.round);

    switch (shape.kind) {
      case ShapeKind.line:
      case ShapeKind.arrow:
        canvas
          ..moveTo(shape.x1, fy(shape.y1))
          ..lineTo(shape.x2, fy(shape.y2))
          ..strokePath();
        if (shape.kind == ShapeKind.arrow) {
          final dx = shape.x2 - shape.x1;
          final dy = shape.y2 - shape.y1;
          final len = (dx * dx + dy * dy);
          if (len > 1) {
            final inv = 1 / math.sqrt(len);
            final ux = dx * inv;
            final uy = dy * inv;
            final lx = -uy;
            final ly = ux;
            final bx = shape.x2 - ux * 12;
            final by = shape.y2 - uy * 12;
            canvas
              ..moveTo(shape.x2, fy(shape.y2))
              ..lineTo(bx + lx * 7, fy(by + ly * 7))
              ..lineTo(bx - lx * 7, fy(by - ly * 7))
              ..closePath()
              ..setFillColor(pdf.PdfColor.fromInt(shape.colorValue))
              ..fillPath();
          }
        }
      case ShapeKind.rect:
        final left = shape.x1 < shape.x2 ? shape.x1 : shape.x2;
        final top = shape.y1 < shape.y2 ? shape.y1 : shape.y2;
        final w = (shape.x2 - shape.x1).abs();
        final h = (shape.y2 - shape.y1).abs();
        canvas
          ..drawRect(left, fy(top + h), w, h)
          ..strokePath();
      case ShapeKind.ellipse:
        final left = shape.x1 < shape.x2 ? shape.x1 : shape.x2;
        final top = shape.y1 < shape.y2 ? shape.y1 : shape.y2;
        final w = (shape.x2 - shape.x1).abs();
        final h = (shape.y2 - shape.y1).abs();
        canvas
          ..drawEllipse(left + w / 2, fy(top + h / 2), w / 2, h / 2)
          ..strokePath();
      case ShapeKind.circle:
        final radius = math.sqrt(
          math.pow(shape.x2 - shape.x1, 2) + math.pow(shape.y2 - shape.y1, 2),
        );
        canvas
          ..drawEllipse(shape.x1, fy(shape.y1), radius, radius)
          ..strokePath();
    }
  }

  void _paintStroke(pdf.PdfGraphics canvas, InkStroke stroke, double pageH) {
    if (stroke.points.isEmpty) return;
    double fy(double y) => pageH - y;
    final base = pdf.PdfColor.fromInt(stroke.colorValue);

    if (stroke.isFountain || stroke.isPencil) {
      for (var i = 1; i < stroke.points.length; i++) {
        final a = stroke.points[i - 1];
        final b = stroke.points[i];
        final pressure = ((a.pressure + b.pressure) / 2).clamp(0.05, 1.0);
        final width = stroke.isFountain
            ? stroke.width * (0.35 + pressure * 1.10)
            : stroke.width;
        final alpha = stroke.isPencil
            ? (0.12 + pressure * 0.82).clamp(0.08, 0.95)
            : 1.0;
        canvas
          ..setStrokeColor(pdf.PdfColor(base.red, base.green, base.blue, alpha))
          ..setLineWidth(width)
          ..setLineCap(pdf.PdfLineCap.round)
          ..moveTo(a.x, fy(a.y))
          ..lineTo(b.x, fy(b.y))
          ..strokePath();
      }
      if (stroke.points.length == 1) {
        final p = stroke.points.first;
        final pressure = p.pressure.clamp(0.05, 1.0);
        final width = stroke.isFountain
            ? stroke.width * (0.35 + pressure * 1.10)
            : stroke.width;
        final alpha = stroke.isPencil
            ? (0.12 + pressure * 0.82).clamp(0.08, 0.95)
            : 1.0;
        canvas
          ..setFillColor(pdf.PdfColor(base.red, base.green, base.blue, alpha))
          ..drawEllipse(p.x, fy(p.y), width / 2, width / 2)
          ..fillPath();
      }
      return;
    }

    canvas
      ..setStrokeColor(
        stroke.isMarker
            ? pdf.PdfColor(base.red, base.green, base.blue, 0.35)
            : base,
      )
      ..setLineWidth(stroke.width)
      ..setLineCap(pdf.PdfLineCap.round)
      ..setLineJoin(pdf.PdfLineJoin.round);

    final first = stroke.points.first;
    canvas.moveTo(first.x, fy(first.y));
    for (final point in stroke.points.skip(1)) {
      canvas.lineTo(point.x, fy(point.y));
    }
    canvas.strokePath();
  }
}

/// Isolate entry: JPEG encode is CPU-heavy and blocked the UI before.
Uint8List _encodeJpegIsolate(Map<String, dynamic> args) {
  final width = args['width'] as int;
  final height = args['height'] as int;
  final bytes = args['bytes'] as Uint8List;
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    bytesOffset: bytes.offsetInBytes,
    rowStride: width * 4,
    order: img.ChannelOrder.rgba,
  );
  return Uint8List.fromList(img.encodeJpg(image, quality: 82));
}
