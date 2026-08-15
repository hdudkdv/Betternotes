import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:uuid/uuid.dart';

import '../../../data/repositories/notebook_repository.dart';
import '../../../shared/utils/file_store.dart';
import '../../../shared/utils/page_size.dart';
import '../../search/recognition/recognition_service.dart';
import 'catalog_models.dart';
import 'catalog_pdf_parser.dart';

class CatalogImportService {
  CatalogImportService(this._repository);

  final NotebookRepository _repository;
  final FileStore _files = createFileStore();
  static const _uuid = Uuid();

  Future<CatalogItem> fromPdfBytes({
    required Uint8List bytes,
    required String title,
    required String subject,
    required String schoolClass,
    required String germanState,
    void Function(int done, int total)? onProgress,
  }) async {
    final itemId = _uuid.v4();
    final images = await _renderPdfPages(
      bytes: bytes,
      itemId: itemId,
      onProgress: onProgress,
    );
    return _fromStoredImages(
      itemId: itemId,
      imagePaths: images,
      title: title,
      subject: subject,
      schoolClass: schoolClass,
      germanState: germanState,
    );
  }

  Future<CatalogItem> fromImagePaths({
    required List<String> paths,
    required String title,
    required String subject,
    required String schoolClass,
    required String germanState,
  }) async {
    final itemId = _uuid.v4();
    final stored = <String>[];
    for (var i = 0; i < paths.length; i++) {
      stored.add(await _copyIntoCatalog(paths[i], itemId, i));
    }
    return _fromStoredImages(
      itemId: itemId,
      imagePaths: stored,
      title: title,
      subject: subject,
      schoolClass: schoolClass,
      germanState: germanState,
    );
  }

  Future<String> storePickedImage({
    required String itemId,
    required Uint8List bytes,
    required String name,
  }) async {
    if (kIsWeb) return 'memory:${base64Encode(bytes)}';
    final dir = await _catalogDir();
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final outPath = p.join(dir, '${itemId}_${_uuid.v4()}_$safe');
    await _files.writeBytes(outPath, bytes);
    return outPath;
  }

  Future<CatalogItem> _fromStoredImages({
    required String itemId,
    required List<String> imagePaths,
    required String title,
    required String subject,
    required String schoolClass,
    required String germanState,
  }) async {
    final texts = <String>[];
    for (final path in imagePaths) {
      try {
        texts.add(await RecognitionService.instance.recognizeImagePath(path));
      } catch (_) {
        texts.add('');
      }
    }
    final drafts = CatalogPdfParser.splitPages(texts);
    final now = DateTime.now();
    final tasks = [
      for (final draft in drafts)
        CatalogTask(
          id: _uuid.v4(),
          title: draft.title,
          parts: [
            if (draft.text.trim().isNotEmpty) TaskPart.text(draft.text),
            for (final page in draft.sourcePageIndexes)
              if (page >= 0 && page < imagePaths.length)
                TaskPart.image(imagePaths[page]),
            if (draft.text.trim().isEmpty &&
                draft.sourcePageIndexes.isEmpty &&
                imagePaths.isNotEmpty)
              TaskPart.image(imagePaths.first),
          ],
          answerKind: draft.answerKind,
          options: [
            for (final option in draft.options) McOption.create(text: option),
          ],
        ),
    ];
    return CatalogItem(
      id: itemId,
      title: title,
      subject: subject,
      schoolClass: schoolClass,
      germanState: germanState,
      kind: CatalogKind.task,
      visibility: CatalogVisibility.private,
      tasks: tasks.isEmpty
          ? [
              CatalogTask(
                id: _uuid.v4(),
                title: '1',
                parts: [
                  for (final path in imagePaths) TaskPart.image(path),
                ],
                answerKind: AnswerKind.text,
              ),
            ]
          : tasks,
      createdAt: now,
      updatedAt: now,
      needsReview: true,
      confirmed: false,
    );
  }

  Future<List<String>> _renderPdfPages({
    required Uint8List bytes,
    required String itemId,
    void Function(int done, int total)? onProgress,
  }) async {
    await pdfrx.pdfrxFlutterInitialize();
    final pageSize = NotePageSize.resolve(
      PaperFormat.a4,
      PageOrientation.portrait,
    );
    final doc = await pdfrx.PdfDocument.openData(bytes);
    final dir = await _catalogDir();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final paths = <String>[];
    try {
      final total = doc.pages.length;
      for (var i = 0; i < total; i++) {
        try {
          final rendered = await doc.pages[i].render(
            fullWidth: pageSize.width * 1.5,
            fullHeight: pageSize.height * 1.5,
          );
          if (rendered == null) continue;
          final dartImage = rendered.createImageNF(pixelSizeThreshold: 1400);
          rendered.dispose();
          final rgba = dartImage.getBytes(order: img.ChannelOrder.rgba);
          final encoded = await compute(_encodeJpegIsolate, <String, dynamic>{
            'width': dartImage.width,
            'height': dartImage.height,
            'bytes': rgba,
          });
          if (kIsWeb) {
            paths.add('memory:${base64Encode(encoded)}');
          } else {
            final outPath = p.join(dir, '${itemId}_${stamp}_${i + 1}.jpg');
            await _files.writeBytes(outPath, encoded);
            paths.add(outPath);
          }
        } catch (_) {}
        onProgress?.call(i + 1, total);
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      await doc.dispose();
    }
    return paths;
  }

  Future<String> _copyIntoCatalog(String src, String itemId, int index) async {
    try {
      final bytes = await _files.readBytes(src);
      if (kIsWeb) return 'memory:${base64Encode(bytes)}';
      final dir = await _catalogDir();
      final outPath = p.join(dir, '${itemId}_scan_${index + 1}.jpg');
      await _files.writeBytes(outPath, bytes);
      return outPath;
    } catch (_) {
      return src;
    }
  }

  Future<String> _catalogDir() async {
    final root = await _repository.resolveFilesDir();
    return p.join(root, 'catalog');
  }
}

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
