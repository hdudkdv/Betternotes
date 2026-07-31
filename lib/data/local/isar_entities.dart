import 'package:isar_community/isar.dart';

part 'isar_entities.g.dart';

@collection
class NotebookEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String title;
  late int coverColor;
  late DateTime createdAt;
  late DateTime updatedAt;
  late int pageCount;
  late bool isFavorite;
  DateTime? lastOpenedAt;
  late String canvasMode;
  late String defaultPaperFormat;
  late String defaultOrientation;
  late String defaultTemplate;
}

@collection
class PageEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String notebookId;

  late int index;
  late String template;
  String? backgroundPdfPath;
  String? thumbnailPath;
  late String strokesJson;
  late String textBlocksJson;
  String? paperTemplateId;
  String? customPaperJson;
  DateTime? updatedAt;
  late String paperFormat;
  late String orientation;
}

@collection
class KvEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late String valueJson;
}
