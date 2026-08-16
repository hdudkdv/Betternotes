import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/notebook.dart';
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

  Future<void> _shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mime,
  }) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mime, name: filename)]),
    );
  }

  String _safe(String title) =>
      title.replaceAll(RegExp(r'[^\w.\- ]+'), '_').trim().isEmpty
      ? 'Notis'
      : title.replaceAll(RegExp(r'[^\w.\- ]+'), '_').trim();
}
