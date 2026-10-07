import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

import '../scanner/document_scanner_service.dart';
import '../search/recognition/recognition_service.dart';
import 'timetable_pdf_parser.dart';

class TimetablePdfImport {
  const TimetablePdfImport();

  Future<ImportedTimetable?> pickPdf({
    Future<String?> Function()? onPassword,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    try {
      return await fromPdfBytes(bytes, onPassword: onPassword);
    } catch (_) {
      return null;
    }
  }

  Future<ImportedTimetable?> scanOrPickImage() async {
    final paths = await const DocumentScannerService().scanPages(maxPages: 4);
    if (paths.isNotEmpty) return fromImagePaths(paths);
    final picked = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    return fromImagePaths([
      for (final file in picked.files)
        if (file.path != null && file.path!.isNotEmpty) file.path!,
    ]);
  }

  Future<ImportedTimetable> fromPdfBytes(
    Uint8List bytes, {
    Future<String?> Function()? onPassword,
  }) async {
    await pdfrx.pdfrxFlutterInitialize();
    final doc = await pdfrx.PdfDocument.openData(
      bytes,
      firstAttemptByEmptyPassword: true,
      passwordProvider: onPassword,
    );
    try {
      final pages = <List<TimetableTextToken>>[];
      for (final page in doc.pages) {
        final structured = await page.loadStructuredText();
        pages.add(_tokensFromPdf(structured, page.height));
      }
      final parsed = TimetablePdfParser.parsePages(pages);
      if (parsed.slots.isNotEmpty) return parsed;
      final fallback = StringBuffer();
      for (final page in doc.pages) {
        fallback.writeln((await page.loadText())?.fullText ?? '');
      }
      return TimetablePdfParser.parsePlainText(fallback.toString());
    } finally {
      await doc.dispose();
    }
  }

  Future<ImportedTimetable> fromImagePaths(List<String> paths) async {
    final buffer = StringBuffer();
    for (final path in paths) {
      buffer.writeln(await RecognitionService.instance.recognizeImagePath(path));
    }
    return TimetablePdfParser.parsePlainText(buffer.toString());
  }

  List<TimetableTextToken> _tokensFromPdf(
    pdfrx.PdfPageText text,
    double pageHeight,
  ) {
    return [
      for (final fragment in text.fragments)
        if (fragment.text.trim().isNotEmpty)
          TimetableTextToken(
            text: fragment.text.trim(),
            left: fragment.bounds.left,
            top: pageHeight - fragment.bounds.top,
            width: fragment.bounds.width,
            height: fragment.bounds.height,
          ),
    ];
  }
}
