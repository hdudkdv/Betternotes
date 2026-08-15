import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/editor/domain/ink_models.dart';
import '../../shared/utils/page_size.dart';
import '../models/content_models.dart';
import '../models/notebook.dart';
import '../repositories/isar_notebook_repository.dart';
import '../repositories/notebook_repository.dart';
import 'isar_entities.dart';

abstract final class LocalDatabase {
  static NotebookRepository? _repository;

  static NotebookRepository get repository {
    final repo = _repository;
    if (repo == null) {
      throw StateError('LocalDatabase not initialized');
    }
    return repo;
  }

  static Future<NotebookRepository> init() async {
    if (_repository != null) return _repository!;
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [NotebookEntitySchema, PageEntitySchema, KvEntitySchema],
      directory: dir.path,
      name: 'betternotes_v2',
    );
    _repository = IsarNotebookRepository(isar, dir.path);
    return _repository!;
  }
}

Notebook notebookFromEntity(NotebookEntity e) {
  return Notebook(
    id: e.uuid,
    title: e.title,
    coverColor: e.coverColor,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    pageCount: e.pageCount,
    isFavorite: e.isFavorite,
    lastOpenedAt: e.lastOpenedAt,
    canvasMode: CanvasMode.values.firstWhere(
      (m) => m.name == e.canvasMode,
      orElse: () => CanvasMode.page,
    ),
    defaultPaperFormat: PaperFormat.values.firstWhere(
      (format) => format.name == e.defaultPaperFormat,
      orElse: () => PaperFormat.a4,
    ),
    defaultOrientation: PageOrientation.values.firstWhere(
      (orientation) => orientation.name == e.defaultOrientation,
      orElse: () => PageOrientation.portrait,
    ),
    defaultTemplate: PageTemplate.values.firstWhere(
      (template) => template.name == e.defaultTemplate,
      orElse: () => PageTemplate.blank,
    ),
  );
}

void applyNotebookToEntity(Notebook n, NotebookEntity e) {
  e.uuid = n.id;
  e.title = n.title;
  e.coverColor = n.coverColor;
  e.createdAt = n.createdAt;
  e.updatedAt = n.updatedAt;
  e.pageCount = n.pageCount;
  e.isFavorite = n.isFavorite;
  e.lastOpenedAt = n.lastOpenedAt;
  e.canvasMode = n.canvasMode.name;
  e.defaultPaperFormat = n.defaultPaperFormat.name;
  e.defaultOrientation = n.defaultOrientation.name;
  e.defaultTemplate = n.defaultTemplate.name;
}

NotePage pageFromEntity(PageEntity e) {
  final strokeMaps = e.strokesJson.isEmpty
      ? <Map<String, dynamic>>[]
      : [
          for (final item in jsonDecode(e.strokesJson) as List)
            Map<String, dynamic>.from(item as Map),
        ];
  final decodedBlocks = e.textBlocksJson.isEmpty
      ? null
      : jsonDecode(e.textBlocksJson);
  List<Map<String, dynamic>> textMaps = [];
  List<Map<String, dynamic>> shapeMaps = [];
  List<Map<String, dynamic>> imageMaps = [];
  String? searchIndex;
  if (decodedBlocks is List) {
    textMaps = [
      for (final item in decodedBlocks) Map<String, dynamic>.from(item as Map),
    ];
  } else if (decodedBlocks is Map) {
    final map = Map<String, dynamic>.from(decodedBlocks);
    textMaps = [
      for (final item in (map['blocks'] as List? ?? const []))
        Map<String, dynamic>.from(item as Map),
    ];
    shapeMaps = [
      for (final item in (map['shapes'] as List? ?? const []))
        Map<String, dynamic>.from(item as Map),
    ];
    imageMaps = [
      for (final item in (map['images'] as List? ?? const []))
        Map<String, dynamic>.from(item as Map),
    ];
    searchIndex = map['searchIndex'] as String?;
  }
  return NotePage(
    id: e.uuid,
    notebookId: e.notebookId,
    index: e.index,
    template: PageTemplate.values.firstWhere(
      (t) => t.name == e.template,
      orElse: () => PageTemplate.blank,
    ),
    backgroundPdfPath: e.backgroundPdfPath,
    thumbnailPath: e.thumbnailPath,
    strokes: [for (final m in strokeMaps) InkStroke.fromJson(m)],
    textBlocks: [for (final m in textMaps) TextBlock.fromJson(m)],
    shapes: [for (final m in shapeMaps) ShapeElement.fromJson(m)],
    images: [for (final m in imageMaps) ImageElement.fromJson(m)],
    paperTemplateId: e.paperTemplateId,
    customPaper: e.customPaperJson == null || e.customPaperJson!.isEmpty
        ? null
        : PaperTemplate.fromJson(
            Map<String, dynamic>.from(jsonDecode(e.customPaperJson!) as Map),
          ),
    updatedAt: e.updatedAt,
    paperFormat: PaperFormat.values.firstWhere(
      (format) => format.name == e.paperFormat,
      orElse: () => PaperFormat.a4,
    ),
    orientation: PageOrientation.values.firstWhere(
      (orientation) => orientation.name == e.orientation,
      orElse: () => PageOrientation.portrait,
    ),
    searchIndex: searchIndex,
  );
}

void applyPageToEntity(NotePage p, PageEntity e) {
  e.uuid = p.id;
  e.notebookId = p.notebookId;
  e.index = p.index;
  e.template = p.template.name;
  e.backgroundPdfPath = p.backgroundPdfPath;
  e.thumbnailPath = p.thumbnailPath;
  e.strokesJson = jsonEncode(p.strokes.map((s) => s.toJson()).toList());
  e.textBlocksJson = jsonEncode({
    'blocks': p.textBlocks.map((t) => t.toJson()).toList(),
    'shapes': p.shapes.map((s) => s.toJson()).toList(),
    'images': p.images.map((i) => i.toJson()).toList(),
    'searchIndex': p.searchIndex,
  });
  e.paperTemplateId = p.paperTemplateId;
  e.customPaperJson = p.customPaper == null
      ? null
      : jsonEncode(p.customPaper!.toJson());
  e.updatedAt = p.updatedAt;
  e.paperFormat = p.paperFormat.name;
  e.orientation = p.orientation.name;
}
