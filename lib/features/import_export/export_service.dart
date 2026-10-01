import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/notebook.dart';
import '../../shared/utils/page_size.dart';
import '../pdf/pdf_service.dart';

class ExportService {
  ExportService({
    required PdfService pdfService,
  }) : _pdf = pdfService;

  final PdfService _pdf;

  Future<void> sharePageAsImage({
    required Notebook notebook,
    required List<NotePage> pages,
    required int pageIndex,
  }) async {
    final pdfBytes = await _pdf.buildNotebookPdfBytes(
      notebook,
      pages,
      onlyPageIndex: pageIndex,
    );
    final raster = await Printing.raster(pdfBytes, pages: [0], dpi: 150).first;
    final png = await raster.toPng();
    final n = pageIndex + 1;
    await _shareBytes(
      bytes: png,
      filename: '${_safe(notebook.title)}_page_$n.png',
      mime: 'image/png',
    );
  }

  Future<void> sharePageRegionAsImage({
    required Notebook notebook,
    required List<NotePage> pages,
    required int pageIndex,
    required Rect pageRect,
  }) async {
    if (pageRect.width < 2 || pageRect.height < 2) return;
    final page = pages[pageIndex];
    final pageSize = NotePageSize.resolve(page.paperFormat, page.orientation);
    final pdfBytes = await _pdf.buildNotebookPdfBytes(
      notebook,
      pages,
      onlyPageIndex: pageIndex,
    );
    final raster = await Printing.raster(pdfBytes, pages: [0], dpi: 180).first;
    final png = await raster.toPng();
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final sx = image.width / pageSize.width;
    final sy = image.height / pageSize.height;
    const pad = 16.0;
    final src = Rect.fromLTRB(
      ((pageRect.left - pad) * sx).clamp(0, image.width.toDouble()),
      ((pageRect.top - pad) * sy).clamp(0, image.height.toDouble()),
      ((pageRect.right + pad) * sx).clamp(0, image.width.toDouble()),
      ((pageRect.bottom + pad) * sy).clamp(0, image.height.toDouble()),
    );
    final w = src.width.round().clamp(1, image.width);
    final h = src.height.round().clamp(1, image.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      src,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(w, h);
    final bytes = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();
    picture.dispose();
    if (bytes == null) return;
    final n = pageIndex + 1;
    await _shareBytes(
      bytes: bytes.buffer.asUint8List(),
      filename: '${_safe(notebook.title)}_auswahl_$n.png',
      mime: 'image/png',
    );
  }

  Future<void> _shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mime,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mime, name: filename)],
      ),
    );
  }

  String _safe(String title) =>
      title.replaceAll(RegExp(r'[^\w.\- ]+'), '_').trim().isEmpty
      ? 'Notis'
      : title.replaceAll(RegExp(r'[^\w.\- ]+'), '_').trim();
}
