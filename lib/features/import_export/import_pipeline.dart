import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../shared/utils/file_store.dart';
import '../../shared/utils/page_size.dart';
import '../editor/domain/ink_models.dart';
import '../pdf/pdf_service.dart';
import 'import_models.dart';
import 'inbox_service.dart';

class ImportPipeline {
  ImportPipeline({
    required NotebookRepository repository,
    required PdfService pdfService,
    required InboxService inbox,
  }) : _repository = repository,
       _pdf = pdfService,
       _inbox = inbox;

  final NotebookRepository _repository;
  final PdfService _pdf;
  final InboxService _inbox;
  final FileStore _files = createFileStore();

  Future<ImportResult> importFile({
    required String notebookId,
    required InboxFile file,
  }) async {
    final bytes = file.bytes ?? await _files.readBytes(file.path);
    final kind = classifyImport(name: file.name, mimeType: file.mimeType);
    switch (kind) {
      case ImportKind.pdf:
        final pages = await _pdf.importPdfFromBytes(
          notebookId: notebookId,
          bytes: bytes,
        );
        return ImportResult(
          notebookId: notebookId,
          pageIds: [for (final page in pages) page.id],
        );
      case ImportKind.image:
        final page = await _importImagePage(notebookId, bytes, file.name);
        return ImportResult(notebookId: notebookId, pageIds: [page.id]);
      case ImportKind.goodnotes:
      case ImportKind.archive:
        return _importArchiveLike(
          notebookId: notebookId,
          bytes: bytes,
          originalName: file.name,
          keepOriginal: kind == ImportKind.goodnotes,
        );
      case ImportKind.office:
        return _importOffice(
          notebookId: notebookId,
          bytes: bytes,
          name: file.name,
        );
      case ImportKind.text:
        return _importTextLike(
          notebookId: notebookId,
          bytes: bytes,
          name: file.name,
        );
      case ImportKind.attachment:
        final page = await _importAttachmentCover(
          notebookId: notebookId,
          bytes: bytes,
          name: file.name,
        );
        return ImportResult(notebookId: notebookId, pageIds: [page.id]);
    }
  }

  Future<NotePage> _importImagePage(
    String notebookId,
    Uint8List bytes,
    String name,
  ) async {
    final notebook = await _repository.getNotebook(notebookId);
    final paperFormat = notebook?.defaultPaperFormat ?? PaperFormat.a4;
    final orientation =
        notebook?.defaultOrientation ?? PageOrientation.portrait;
    final pageSize = NotePageSize.resolve(paperFormat, orientation);
    final pngPath = await _writeBackgroundPng(
      notebookId: notebookId,
      bytes: bytes,
      pageWidth: pageSize.width,
      pageHeight: pageSize.height,
      label: p.basenameWithoutExtension(name),
    );
    return _repository.addPage(
      notebookId: notebookId,
      template: PageTemplate.blank,
      backgroundPdfPath: pngPath,
      paperFormat: paperFormat,
      orientation: orientation,
    );
  }

  Future<String?> _writeBackgroundPng({
    required String notebookId,
    required Uint8List bytes,
    required double pageWidth,
    required double pageHeight,
    required String label,
  }) async {
    final filesDir = await _repository.resolveFilesDir();
    Uint8List pngBytes = bytes;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final targetW = (pageWidth * 2).round();
        final targetH = (pageHeight * 2).round();
        final fitted = img.copyResize(
          decoded,
          width: targetW,
          height: targetH,
          interpolation: img.Interpolation.linear,
        );
        // Letterbox onto white page canvas.
        final canvas = img.Image(width: targetW, height: targetH);
        img.fill(canvas, color: img.ColorRgb8(255, 251, 245));
        final dx = ((targetW - fitted.width) / 2).round();
        final dy = ((targetH - fitted.height) / 2).round();
        img.compositeImage(canvas, fitted, dstX: dx, dstY: dy);
        pngBytes = Uint8List.fromList(img.encodePng(canvas));
      }
    } catch (_) {
      // Keep original bytes if decode/resize fails.
    }
    final outPath = p.join(
      filesDir,
      '${notebookId}_img_${DateTime.now().microsecondsSinceEpoch}_$label.png',
    );
    await _files.writeBytes(outPath, pngBytes);
    return outPath;
  }

  Future<ImportResult> _importArchiveLike({
    required String notebookId,
    required Uint8List bytes,
    required String originalName,
    required bool keepOriginal,
  }) async {
    final pageIds = <String>[];
    if (keepOriginal) {
      final cover = await _importAttachmentCover(
        notebookId: notebookId,
        bytes: bytes,
        name: originalName,
      );
      pageIds.add(cover.id);
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {
      if (pageIds.isEmpty) {
        final cover = await _importAttachmentCover(
          notebookId: notebookId,
          bytes: bytes,
          name: originalName,
        );
        pageIds.add(cover.id);
      }
      return ImportResult(
        notebookId: notebookId,
        pageIds: pageIds,
        message: 'archive_unreadable',
      );
    }

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name;
      final lower = name.toLowerCase();
      if (lower.endsWith('/')) continue;
      final data = entry.content;
      if (data.isEmpty) continue;
      final fileBytes = Uint8List.fromList(data);
      final base = p.basename(name);
      final kind = classifyImport(name: base);
      if (kind == ImportKind.pdf) {
        final pages = await _pdf.importPdfFromBytes(
          notebookId: notebookId,
          bytes: fileBytes,
        );
        pageIds.addAll(pages.map((e) => e.id));
      } else if (kind == ImportKind.image) {
        final page = await _importImagePage(notebookId, fileBytes, base);
        pageIds.add(page.id);
      } else if (kind == ImportKind.text) {
        final result = await _importTextLike(
          notebookId: notebookId,
          bytes: fileBytes,
          name: base,
        );
        pageIds.addAll(result.pageIds);
      }
    }

    if (pageIds.isEmpty) {
      final cover = await _importAttachmentCover(
        notebookId: notebookId,
        bytes: bytes,
        name: originalName,
      );
      pageIds.add(cover.id);
    }

    return ImportResult(notebookId: notebookId, pageIds: pageIds);
  }

  Future<ImportResult> _importOffice({
    required String notebookId,
    required String name,
    required Uint8List bytes,
  }) async {
    final pageIds = <String>[];
    final cover = await _importAttachmentCover(
      notebookId: notebookId,
      bytes: bytes,
      name: name,
    );
    pageIds.add(cover.id);

    Archive? archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {
      return ImportResult(notebookId: notebookId, pageIds: pageIds);
    }

    final mediaNames = <String>[];
    final textChunks = <String>[];

    for (final entry in archive) {
      if (!entry.isFile) continue;
      final entryName = entry.name.replaceAll('\\', '/');
      final lower = entryName.toLowerCase();
      final data = entry.content;
      if (data.isEmpty) continue;
      final fileBytes = Uint8List.fromList(data);

      final isMedia =
          lower.contains('/media/') ||
          lower.contains('word/media') ||
          lower.contains('ppt/media') ||
          lower.contains('xl/media');
      if (isMedia &&
          classifyImport(name: p.basename(entryName)) == ImportKind.image) {
        mediaNames.add(entryName);
        final page = await _importImagePage(
          notebookId,
          fileBytes,
          p.basename(entryName),
        );
        pageIds.add(page.id);
        continue;
      }

      if (lower.endsWith('.rtf')) {
        final text = _rtfToText(utf8.decode(fileBytes, allowMalformed: true));
        if (text.trim().isNotEmpty) textChunks.add(text.trim());
        continue;
      }

      if (lower.endsWith('word/document.xml') ||
          lower.contains('/ppt/slides/slide') && lower.endsWith('.xml') ||
          lower.endsWith('xl/sharedstrings.xml') ||
          lower.contains('index.xml') ||
          lower.endsWith('.xhtml') ||
          lower.endsWith('.html')) {
        final xml = utf8.decode(fileBytes, allowMalformed: true);
        final text = _stripXml(xml);
        if (text.trim().isNotEmpty) textChunks.add(text.trim());
      }
    }

    if (textChunks.isNotEmpty) {
      final combined = textChunks.join('\n\n');
      final page = await _importTextPage(notebookId, combined);
      pageIds.add(page.id);
    }

    return ImportResult(
      notebookId: notebookId,
      pageIds: pageIds,
      message: mediaNames.isEmpty && textChunks.isEmpty
          ? 'office_attachment_only'
          : null,
    );
  }

  Future<ImportResult> _importTextLike({
    required String notebookId,
    required Uint8List bytes,
    required String name,
  }) async {
    final ext = p.extension(name).toLowerCase();
    if (ext == '.gdoc' || ext == '.gsheet' || ext == '.gslides') {
      return _importGoogleShortcut(
        notebookId: notebookId,
        bytes: bytes,
        name: name,
      );
    }
    final raw = _decodeText(bytes);
    final text = switch (ext) {
      '.html' || '.htm' || '.xhtml' => _htmlToText(raw),
      '.rtf' => _rtfToText(raw),
      _ => raw,
    };
    if (text.trim().isEmpty) {
      final cover = await _importAttachmentCover(
        notebookId: notebookId,
        bytes: bytes,
        name: name,
      );
      return ImportResult(notebookId: notebookId, pageIds: [cover.id]);
    }
    final page = await _importTextPage(notebookId, text);
    return ImportResult(notebookId: notebookId, pageIds: [page.id]);
  }

  Future<ImportResult> _importGoogleShortcut({
    required String notebookId,
    required Uint8List bytes,
    required String name,
  }) async {
    String url = '';
    String title = p.basenameWithoutExtension(name);
    try {
      final json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (json is Map) {
        url = '${json['url'] ?? json['doc_url'] ?? ''}';
        final fromName = '${json['doc_id'] ?? ''}';
        if (fromName.isNotEmpty && title == p.basenameWithoutExtension(name)) {
          title = fromName;
        }
      }
    } catch (_) {
      final raw = utf8.decode(bytes, allowMalformed: true);
      final match = RegExp(r'https?://[^\s"]+').firstMatch(raw);
      url = match?.group(0) ?? '';
    }
    final page = await _importTextPage(
      notebookId,
      'Google-Dokument: $title\n\n'
      '${url.isEmpty ? '' : '$url\n\n'}'
      'Google Docs-Verknüpfungen enthalten den Text nicht lokal. '
      'In Google Docs unter Datei → Herunterladen als PDF oder DOCX '
      'exportieren und die Datei hier erneut importieren.',
    );
    return ImportResult(
      notebookId: notebookId,
      pageIds: [page.id],
      message: 'google_shortcut',
    );
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  String _htmlToText(String html) {
    var text = html
        .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'&#\d+;'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text;
  }

  String _rtfToText(String rtf) {
    final noGroups = rtf
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), ' ')
        .replaceAll(RegExp(r'[{}]'), ' ')
        .replaceAll('\\', ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return noGroups;
  }

  Future<NotePage> _importTextPage(String notebookId, String text) async {
    final notebook = await _repository.getNotebook(notebookId);
    final paperFormat = notebook?.defaultPaperFormat ?? PaperFormat.a4;
    final orientation =
        notebook?.defaultOrientation ?? PageOrientation.portrait;
    final page = await _repository.addPage(
      notebookId: notebookId,
      template: notebook?.defaultTemplate ?? PageTemplate.lined,
      paperFormat: paperFormat,
      orientation: orientation,
    );
    final pageSize = NotePageSize.resolve(paperFormat, orientation);
    final block = TextBlock.create(
      pageId: page.id,
      x: 48,
      y: 48,
      text: text.length > 8000 ? '${text.substring(0, 8000)}…' : text,
    ).copyWith(width: pageSize.width - 96, height: pageSize.height - 96);
    final updated = page.copyWith(textBlocks: [block]);
    await _repository.savePage(updated);
    return updated;
  }

  Future<NotePage> _importAttachmentCover({
    required String notebookId,
    required Uint8List bytes,
    required String name,
  }) async {
    final stored = await _inbox.persistAttachment(bytes: bytes, name: name);
    final notebook = await _repository.getNotebook(notebookId);
    final paperFormat = notebook?.defaultPaperFormat ?? PaperFormat.a4;
    final orientation =
        notebook?.defaultOrientation ?? PageOrientation.portrait;
    final page = await _repository.addPage(
      notebookId: notebookId,
      template: PageTemplate.blank,
      paperFormat: paperFormat,
      orientation: orientation,
    );
    final block = TextBlock.create(
      pageId: page.id,
      x: 48,
      y: 64,
      text:
          'Imported file\n\n$name\n\nStored at:\n$stored\n\n'
          'Open the original from your device files if needed.',
    ).copyWith(width: 420, height: 220);
    final updated = page.copyWith(textBlocks: [block]);
    await _repository.savePage(updated);
    return updated;
  }

  String _stripXml(String xml) {
    final noTags = xml
        .replaceAll(RegExp(r'<w:tab[^/]*/>'), '\t')
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<a:br[^/]*/>'), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#\d+;'), ' ');
    return noTags.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    );
  }
}
