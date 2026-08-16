import 'dart:typed_data';

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
