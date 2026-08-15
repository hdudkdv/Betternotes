import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../features/editor/domain/ink_models.dart';
import '../../shared/utils/page_size.dart';
import 'content_models.dart';

class Notebook extends Equatable {
  const Notebook({
    required this.id,
    required this.title,
    required this.coverColor,
    required this.createdAt,
    required this.updatedAt,
    this.pageCount = 1,
    this.isFavorite = false,
    this.lastOpenedAt,
    this.canvasMode = CanvasMode.page,
    this.folderId,
    this.schoolClass,
    this.subjectKey,
    this.defaultPaperFormat = PaperFormat.a4,
    this.defaultOrientation = PageOrientation.portrait,
    this.defaultTemplate = PageTemplate.blank,
  });

  final String id;
  final String title;
  final int coverColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageCount;
  final bool isFavorite;
  final DateTime? lastOpenedAt;
  final CanvasMode canvasMode;
  final String? folderId;

  /// German school class year (1–13). Used to import chapters from last year.
  final int? schoolClass;

  /// Normalized subject name linking this notebook to timetable/grades.
  final String? subjectKey;
  final PaperFormat defaultPaperFormat;
  final PageOrientation defaultOrientation;
  final PageTemplate defaultTemplate;

  Notebook copyWith({
    String? title,
    int? coverColor,
    DateTime? updatedAt,
    int? pageCount,
    bool? isFavorite,
    DateTime? lastOpenedAt,
    CanvasMode? canvasMode,
    String? folderId,
    int? schoolClass,
    String? subjectKey,
    PaperFormat? defaultPaperFormat,
    PageOrientation? defaultOrientation,
    PageTemplate? defaultTemplate,
    bool clearFolder = false,
    bool clearSchoolClass = false,
    bool clearSubjectKey = false,
  }) {
    return Notebook(
      id: id,
      title: title ?? this.title,
      coverColor: coverColor ?? this.coverColor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      canvasMode: canvasMode ?? this.canvasMode,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      schoolClass: clearSchoolClass ? null : (schoolClass ?? this.schoolClass),
      subjectKey: clearSubjectKey ? null : (subjectKey ?? this.subjectKey),
      defaultPaperFormat: defaultPaperFormat ?? this.defaultPaperFormat,
      defaultOrientation: defaultOrientation ?? this.defaultOrientation,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'coverColor': coverColor,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pageCount': pageCount,
    'isFavorite': isFavorite,
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    'canvasMode': canvasMode.name,
    'folderId': folderId,
    'schoolClass': schoolClass,
    'subjectKey': subjectKey,
    'defaultPaperFormat': defaultPaperFormat.name,
    'defaultOrientation': defaultOrientation.name,
    'defaultTemplate': defaultTemplate.name,
  };

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] as String,
      title: json['title'] as String,
      coverColor: json['coverColor'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pageCount: json['pageCount'] as int? ?? 1,
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastOpenedAt: json['lastOpenedAt'] != null
          ? DateTime.parse(json['lastOpenedAt'] as String)
          : null,
      canvasMode: CanvasMode.values.firstWhere(
        (m) => m.name == json['canvasMode'],
        orElse: () => CanvasMode.page,
      ),
      folderId: json['folderId'] as String?,
      schoolClass: json['schoolClass'] as int?,
      subjectKey: json['subjectKey'] as String?,
      defaultPaperFormat: PaperFormat.values.firstWhere(
        (format) => format.name == json['defaultPaperFormat'],
        orElse: () => PaperFormat.a4,
      ),
      defaultOrientation: PageOrientation.values.firstWhere(
        (orientation) => orientation.name == json['defaultOrientation'],
        orElse: () => PageOrientation.portrait,
      ),
      defaultTemplate: PageTemplate.values.firstWhere(
        (template) => template.name == json['defaultTemplate'],
        orElse: () => PageTemplate.blank,
      ),
    );
  }

  factory Notebook.create({
    required String title,
    required int coverColor,
    String? folderId,
    int? schoolClass,
    String? subjectKey,
    CanvasMode canvasMode = CanvasMode.page,
    PaperFormat defaultPaperFormat = PaperFormat.a4,
    PageOrientation defaultOrientation = PageOrientation.portrait,
    PageTemplate defaultTemplate = PageTemplate.blank,
  }) {
    final now = DateTime.now();
    return Notebook(
      id: const Uuid().v4(),
      title: title,
      coverColor: coverColor,
      createdAt: now,
      updatedAt: now,
      pageCount: 1,
      lastOpenedAt: now,
      canvasMode: canvasMode,
      folderId: folderId,
      schoolClass: schoolClass,
      subjectKey: subjectKey,
      defaultPaperFormat: defaultPaperFormat,
      defaultOrientation: defaultOrientation,
      defaultTemplate: defaultTemplate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    coverColor,
    createdAt,
    updatedAt,
    pageCount,
    isFavorite,
    lastOpenedAt,
    canvasMode,
    folderId,
    schoolClass,
    subjectKey,
    defaultPaperFormat,
    defaultOrientation,
    defaultTemplate,
  ];
}

class NotePage extends Equatable {
  const NotePage({
    required this.id,
    required this.notebookId,
    required this.index,
    required this.template,
    this.backgroundPdfPath,
    this.thumbnailPath,
    this.strokes = const [],
    this.textBlocks = const [],
    this.shapes = const [],
    this.images = const [],
    this.paperTemplateId,
    this.customPaper,
    this.updatedAt,
    this.paperFormat = PaperFormat.a4,
    this.orientation = PageOrientation.portrait,
    this.searchIndex,
  });

  final String id;
  final String notebookId;
  final int index;
  final PageTemplate template;
  final String? backgroundPdfPath;
  final String? thumbnailPath;
  final List<InkStroke> strokes;
  final List<TextBlock> textBlocks;
  final List<ShapeElement> shapes;
  final List<ImageElement> images;
  final String? paperTemplateId;
  final PaperTemplate? customPaper;

  /// Per-page revision timestamp used by the offline-first sync merge.
  ///
  /// Older local and cloud documents do not have it; in that case the
  /// containing notebook timestamp remains the compatibility fallback.
  final DateTime? updatedAt;
  final PaperFormat paperFormat;
  final PageOrientation orientation;

  /// Invisible OCR / ink-recognition text used only by global search.
  final String? searchIndex;

  NotePage copyWith({
    int? index,
    PageTemplate? template,
    String? backgroundPdfPath,
    String? thumbnailPath,
    List<InkStroke>? strokes,
    List<TextBlock>? textBlocks,
    List<ShapeElement>? shapes,
    List<ImageElement>? images,
    String? paperTemplateId,
    PaperTemplate? customPaper,
    DateTime? updatedAt,
    PaperFormat? paperFormat,
    PageOrientation? orientation,
    String? searchIndex,
    bool clearBackgroundPdf = false,
    bool clearPaperTemplate = false,
    bool clearCustomPaper = false,
  }) {
    return NotePage(
      id: id,
      notebookId: notebookId,
      index: index ?? this.index,
      template: template ?? this.template,
      backgroundPdfPath: clearBackgroundPdf
          ? null
          : (backgroundPdfPath ?? this.backgroundPdfPath),
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      strokes: strokes ?? this.strokes,
      textBlocks: textBlocks ?? this.textBlocks,
      shapes: shapes ?? this.shapes,
      images: images ?? this.images,
      paperTemplateId: clearPaperTemplate
          ? null
          : (paperTemplateId ?? this.paperTemplateId),
      customPaper: clearCustomPaper ? null : (customPaper ?? this.customPaper),
      updatedAt: updatedAt ?? this.updatedAt,
      paperFormat: paperFormat ?? this.paperFormat,
      orientation: orientation ?? this.orientation,
      searchIndex: searchIndex ?? this.searchIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'index': index,
    'template': template.name,
    'backgroundPdfPath': backgroundPdfPath,
    'thumbnailPath': thumbnailPath,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'textBlocks': textBlocks.map((t) => t.toJson()).toList(),
    'shapes': shapes.map((s) => s.toJson()).toList(),
    'images': images.map((i) => i.toJson()).toList(),
    'paperTemplateId': paperTemplateId,
    'customPaper': customPaper?.toJson(),
    'updatedAt': updatedAt?.toIso8601String(),
    'paperFormat': paperFormat.name,
    'orientation': orientation.name,
    'searchIndex': searchIndex,
  };

  factory NotePage.fromJson(Map<String, dynamic> json) {
    return NotePage(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      index: json['index'] as int,
      template: PageTemplate.values.firstWhere(
        (t) => t.name == json['template'],
        orElse: () => PageTemplate.blank,
      ),
      backgroundPdfPath: json['backgroundPdfPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      strokes: [
        for (final s in (json['strokes'] as List? ?? const []))
          InkStroke.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      textBlocks: [
        for (final t in (json['textBlocks'] as List? ?? const []))
          TextBlock.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
      shapes: [
        for (final s in (json['shapes'] as List? ?? const []))
          ShapeElement.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      images: [
        for (final i in (json['images'] as List? ?? const []))
          ImageElement.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
      paperTemplateId: json['paperTemplateId'] as String?,
      customPaper: json['customPaper'] != null
          ? PaperTemplate.fromJson(
              Map<String, dynamic>.from(json['customPaper'] as Map),
            )
          : null,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      paperFormat: PaperFormat.values.firstWhere(
        (format) => format.name == json['paperFormat'],
        orElse: () => PaperFormat.a4,
      ),
      orientation: PageOrientation.values.firstWhere(
        (orientation) => orientation.name == json['orientation'],
        orElse: () => PageOrientation.portrait,
      ),
      searchIndex: json['searchIndex'] as String?,
    );
  }

  factory NotePage.create({
    required String notebookId,
    required int index,
    PageTemplate template = PageTemplate.blank,
    String? backgroundPdfPath,
    String? paperTemplateId,
    PaperTemplate? customPaper,
    PaperFormat paperFormat = PaperFormat.a4,
    PageOrientation orientation = PageOrientation.portrait,
  }) {
    final now = DateTime.now();
    return NotePage(
      id: const Uuid().v4(),
      notebookId: notebookId,
      index: index,
      template: template,
      backgroundPdfPath: backgroundPdfPath,
      paperTemplateId: paperTemplateId,
      customPaper: customPaper,
      updatedAt: now,
      paperFormat: paperFormat,
      orientation: orientation,
    );
  }

  @override
  List<Object?> get props => [
    id,
    notebookId,
    index,
    template,
    backgroundPdfPath,
    thumbnailPath,
    strokes,
    textBlocks,
    shapes,
    images,
    paperTemplateId,
    customPaper,
    updatedAt,
    paperFormat,
    orientation,
    searchIndex,
  ];
}
