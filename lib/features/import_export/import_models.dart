import 'package:path/path.dart' as p;

/// A file staged in the app inbox awaiting import into a notebook.
class InboxFile {
  const InboxFile({
    required this.path,
    required this.name,
    this.mimeType,
  });

  final String path;
  final String name;
  final String? mimeType;

  String get extension {
    final ext = p.extension(name).toLowerCase();
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }
}

enum ImportKind { pdf, image, office, goodnotes, archive, attachment, text }

ImportKind classifyImport({required String name, String? mimeType}) {
  final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
  final mime = (mimeType ?? '').toLowerCase();

  if (ext == 'pdf' || mime.contains('pdf')) return ImportKind.pdf;
  if (const {
        'png',
        'jpg',
        'jpeg',
        'jpe',
        'jfif',
        'webp',
        'gif',
        'bmp',
        'tif',
        'tiff',
        'heic',
        'heif',
        'avif',
      }.contains(ext) ||
      mime.startsWith('image/')) {
    return ImportKind.image;
  }
  if (ext == 'goodnotes' || name.toLowerCase().endsWith('.goodnotes')) {
    return ImportKind.goodnotes;
  }
  if (const {
        'docx',
        'pptx',
        'xlsx',
        'odt',
        'odp',
        'ods',
        'doc',
        'ppt',
        'xls',
      }.contains(ext) ||
      mime.contains('officedocument') ||
      mime.contains('msword') ||
      mime.contains('ms-excel') ||
      mime.contains('ms-powerpoint')) {
    return ImportKind.office;
  }
  if (const {'zip', 'epub', 'pages', 'key', 'numbers'}.contains(ext) ||
      mime.contains('epub') ||
      mime.contains('iwork')) {
    return ImportKind.archive;
  }
  if (const {
        'txt',
        'md',
        'markdown',
        'html',
        'htm',
        'xhtml',
        'csv',
        'tsv',
        'json',
        'xml',
        'opml',
        'ics',
        'tex',
        'log',
        'srt',
        'vtt',
        'gdoc',
        'gsheet',
        'gslides',
        'rtf',
      }.contains(ext) ||
      mime.startsWith('text/') ||
      mime.contains('html') ||
      mime.contains('rtf') ||
      mime.contains('google-apps')) {
    return ImportKind.text;
  }
  return ImportKind.attachment;
}

class ImportResult {
  const ImportResult({
    required this.notebookId,
    required this.pageIds,
    this.message,
  });

  final String notebookId;
  final List<String> pageIds;
  final String? message;

  String? get firstPageId => pageIds.isEmpty ? null : pageIds.first;
}
