import 'dart:async';

import '../../../data/models/notebook.dart';
import '../../editor/domain/ink_models.dart';
import 'recognition_bridge.dart';

/// Builds the invisible per-page search index (typed text + ink + photo OCR).
class RecognitionService {
  RecognitionService._();

  static final RecognitionService instance = RecognitionService._();

  final _bridge = RecognitionBridge();
  final Map<String, Future<NotePage?>> _inflight = {};

  /// Background index for a page that was just saved.
  Future<NotePage?> indexPage(NotePage page) {
    return _inflight.putIfAbsent(page.id, () {
      return _index(page).whenComplete(() => _inflight.remove(page.id));
    });
  }

  Future<NotePage?> _index(NotePage page) async {
    final text = await buildIndexText(page);
    if (text.trim() == (page.searchIndex ?? '').trim()) return null;
    return page.copyWith(searchIndex: text, updatedAt: page.updatedAt);
  }

  Future<String> buildIndexText(NotePage page) async {
    final parts = <String>[];
    for (final block in page.textBlocks) {
      final plain = block.plainText.trim();
      if (plain.isNotEmpty) parts.add(plain);
    }
    if (page.strokes.isNotEmpty) {
      final ink = await _bridge.recognizeInk(page.strokes);
      if (ink.trim().isNotEmpty) parts.add(ink.trim());
    }
    for (final image in page.images) {
      final ocr = await _bridge.recognizeImagePath(image.localPath);
      if (ocr.trim().isNotEmpty) parts.add(ocr.trim());
    }
    if (page.backgroundPdfPath != null &&
        page.backgroundPdfPath!.isNotEmpty &&
        !page.backgroundPdfPath!.toLowerCase().endsWith('.pdf')) {
      final ocr = await _bridge.recognizeImagePath(page.backgroundPdfPath!);
      if (ocr.trim().isNotEmpty) parts.add(ocr.trim());
    }
    return parts.join('\n');
  }

  Future<String> recognizeImagePath(String path) =>
      _bridge.recognizeImagePath(path);
}

/// Platform ML Kit / no-op bridge.
class RecognitionBridge {
  Future<String> recognizeInk(List<InkStroke> strokes) =>
      recognizeInkImpl(strokes);

  Future<String> recognizeImagePath(String path) =>
      recognizeImagePathImpl(path);
}
