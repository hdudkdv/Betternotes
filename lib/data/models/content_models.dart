import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TextLayoutMode { free, lineBound, sticky }

enum CanvasMode { page, infinite }

/// How to browse multiple pages in the editor (GoodNotes-like).
enum PageBrowseMode {
  /// Swipe left/right between pages.
  swipeHorizontal,

  /// Continuously scroll through all pages vertically.
  scrollVertical,
}

enum ShapeKind { line, rect, ellipse, arrow, circle }

/// Formatted run inside a text block (span-level formatting).
class TextSpanStyle extends Equatable {
  const TextSpanStyle({
    required this.text,
    this.fontSize = 16,
    this.colorValue = 0xFF1A1A1A,
    this.fontFamily = 'Source Sans 3',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
  });

  final String text;
  final double fontSize;
  final int colorValue;
  final String fontFamily;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;

  Color get color => Color(colorValue);

  TextSpanStyle copyWith({
    String? text,
    double? fontSize,
    int? colorValue,
    String? fontFamily,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
  }) {
    return TextSpanStyle(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
    );
  }

  /// True when both runs carry the same formatting, ignoring their text.
  bool sameFormatting(TextSpanStyle other) =>
      fontSize == other.fontSize &&
      colorValue == other.colorValue &&
      fontFamily == other.fontFamily &&
      bold == other.bold &&
      italic == other.italic &&
      underline == other.underline &&
      strikethrough == other.strikethrough;

  Map<String, dynamic> toJson() => {
    'text': text,
    'fontSize': fontSize,
    'color': colorValue,
    'fontFamily': fontFamily,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikethrough': strikethrough,
  };

  factory TextSpanStyle.fromJson(Map<String, dynamic> json) {
    return TextSpanStyle(
      text: json['text'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16,
      colorValue: json['color'] as int? ?? 0xFF1A1A1A,
      fontFamily: json['fontFamily'] as String? ?? 'Source Sans 3',
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    text,
    fontSize,
    colorValue,
    fontFamily,
    bold,
    italic,
    underline,
    strikethrough,
  ];
}

/// Horizontal alignment of a text block.
enum TextBlockAlign { left, center, right, justify }

class TextBlock extends Equatable {
  const TextBlock({
    required this.id,
    required this.pageId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.layoutMode,
    required this.spans,
    this.align = TextBlockAlign.left,
    this.fillColor,
  });

  final String id;
  final String pageId;
  final double x;
  final double y;
  final double width;
  final double height;
  final TextLayoutMode layoutMode;
  final List<TextSpanStyle> spans;
  final TextBlockAlign align;

  /// Paper fill for sticky notes. Regular text boxes leave this null.
  final int? fillColor;

  bool get isSticky => layoutMode == TextLayoutMode.sticky;

  String get plainText => spans.map((s) => s.text).join();

  TextBlock copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    TextLayoutMode? layoutMode,
    List<TextSpanStyle>? spans,
    TextBlockAlign? align,
    int? fillColor,
    bool clearFill = false,
  }) {
    return TextBlock(
      id: id,
      pageId: pageId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      layoutMode: layoutMode ?? this.layoutMode,
      spans: spans ?? this.spans,
      align: align ?? this.align,
      fillColor: clearFill ? null : (fillColor ?? this.fillColor),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'layoutMode': layoutMode.name,
    'spans': spans.map((s) => s.toJson()).toList(),
    'align': align.name,
    if (fillColor != null) 'fillColor': fillColor,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      layoutMode: TextLayoutMode.values.firstWhere(
        (m) => m.name == json['layoutMode'],
        orElse: () => TextLayoutMode.free,
      ),
      spans: [
        for (final s in (json['spans'] as List? ?? const []))
          TextSpanStyle.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      align: TextBlockAlign.values.firstWhere(
        (a) => a.name == json['align'],
        orElse: () => TextBlockAlign.left,
      ),
      fillColor: json['fillColor'] as int?,
    );
  }

  factory TextBlock.create({
    required String pageId,
    required double x,
    required double y,
    TextLayoutMode layoutMode = TextLayoutMode.free,
    String text = 'Text',
    int? fillColor,
    double width = 220,
    double height = 48,
  }) {
    return TextBlock(
      id: const Uuid().v4(),
      pageId: pageId,
      x: x,
      y: y,
      width: width,
      height: height,
      layoutMode: layoutMode,
      spans: [TextSpanStyle(text: text)],
      fillColor: fillColor,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pageId,
    x,
    y,
    width,
    height,
    layoutMode,
    spans,
    align,
    fillColor,
  ];
}

class OutlineNode extends Equatable {
  const OutlineNode({
    required this.id,
    required this.notebookId,
    required this.title,
    required this.depth,
    this.parentId,
    this.pageId,
    this.anchorY,
    this.sortIndex = 0,
  });

  final String id;
  final String notebookId;
  final String? parentId;
  final String title;
  final int depth;
  final String? pageId;
  final double? anchorY;
  final int sortIndex;

  OutlineNode copyWith({
    String? parentId,
    String? title,
    int? depth,
    String? pageId,
    double? anchorY,
    int? sortIndex,
    bool clearParent = false,
    bool clearPage = false,
  }) {
    return OutlineNode(
      id: id,
      notebookId: notebookId,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      title: title ?? this.title,
      depth: depth ?? this.depth,
      pageId: clearPage ? null : (pageId ?? this.pageId),
      anchorY: anchorY ?? this.anchorY,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'parentId': parentId,
    'title': title,
    'depth': depth,
    'pageId': pageId,
    'anchorY': anchorY,
    'sortIndex': sortIndex,
  };

  factory OutlineNode.fromJson(Map<String, dynamic> json) {
    return OutlineNode(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      depth: json['depth'] as int? ?? 0,
      pageId: json['pageId'] as String?,
      anchorY: (json['anchorY'] as num?)?.toDouble(),
      sortIndex: json['sortIndex'] as int? ?? 0,
    );
  }

  factory OutlineNode.create({
    required String notebookId,
    required String title,
    String? parentId,
    int depth = 0,
    String? pageId,
    double? anchorY,
    int sortIndex = 0,
  }) {
    return OutlineNode(
      id: const Uuid().v4(),
      notebookId: notebookId,
      parentId: parentId,
      title: title,
      depth: depth,
      pageId: pageId,
      anchorY: anchorY,
      sortIndex: sortIndex,
    );
  }

  @override
  List<Object?> get props => [
    id,
    notebookId,
    parentId,
    title,
    depth,
    pageId,
    anchorY,
    sortIndex,
  ];
}

class PaperTemplate extends Equatable {
  const PaperTemplate({
    required this.id,
    required this.name,
    required this.lineSpacing,
    required this.gridSize,
    required this.marginLeft,
    required this.marginTop,
    required this.backgroundColor,
    required this.lineColor,
    required this.style,
    this.isBuiltin = false,
    this.horizontalLines,
    this.verticalLines,
  });

  final String id;
  final String name;
  final double lineSpacing;
  final double gridSize;
  final double marginLeft;
  final double marginTop;
  final int backgroundColor;
  final int lineColor;

  /// `blank` | `lined` | `grid` | `dotted` | `custom`
  final String style;
  final bool isBuiltin;

  /// Explicit horizontal line Y positions (page coordinates). Used by `custom`.
  final List<double>? horizontalLines;

  /// Explicit vertical line X positions (page coordinates). Used by `custom`.
  final List<double>? verticalLines;

  bool get hasRuledLines {
    if (style == 'blank') return false;
    if (style == 'custom') {
      return (horizontalLines?.isNotEmpty ?? false) ||
          (verticalLines?.isNotEmpty ?? false);
    }
    return true;
  }

  PaperTemplate copyWith({
    String? name,
    double? lineSpacing,
    double? gridSize,
    double? marginLeft,
    double? marginTop,
    int? backgroundColor,
    int? lineColor,
    String? style,
    List<double>? horizontalLines,
    List<double>? verticalLines,
    bool clearHorizontalLines = false,
    bool clearVerticalLines = false,
  }) {
    return PaperTemplate(
      id: id,
      name: name ?? this.name,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      gridSize: gridSize ?? this.gridSize,
      marginLeft: marginLeft ?? this.marginLeft,
      marginTop: marginTop ?? this.marginTop,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      lineColor: lineColor ?? this.lineColor,
      style: style ?? this.style,
      isBuiltin: isBuiltin,
      horizontalLines: clearHorizontalLines
          ? null
          : (horizontalLines ?? this.horizontalLines),
      verticalLines: clearVerticalLines
          ? null
          : (verticalLines ?? this.verticalLines),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lineSpacing': lineSpacing,
    'gridSize': gridSize,
    'marginLeft': marginLeft,
    'marginTop': marginTop,
    'backgroundColor': backgroundColor,
    'lineColor': lineColor,
    'style': style,
    'isBuiltin': isBuiltin,
    if (horizontalLines != null) 'horizontalLines': horizontalLines,
    if (verticalLines != null) 'verticalLines': verticalLines,
  };

  factory PaperTemplate.fromJson(Map<String, dynamic> json) {
    return PaperTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 28,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 24,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 72,
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 48,
      backgroundColor: json['backgroundColor'] as int? ?? 0xFFFFFBF5,
      lineColor: json['lineColor'] as int? ?? 0xFFD7D2C8,
      style: json['style'] as String? ?? 'lined',
      isBuiltin: json['isBuiltin'] as bool? ?? false,
      horizontalLines: json['horizontalLines'] is List
          ? [
              for (final v in json['horizontalLines'] as List)
                (v as num).toDouble(),
            ]
          : null,
      verticalLines: json['verticalLines'] is List
          ? [
              for (final v in json['verticalLines'] as List)
                (v as num).toDouble(),
            ]
          : null,
    );
  }

  factory PaperTemplate.create({
    required String name,
    double lineSpacing = 28,
    double gridSize = 24,
    double marginLeft = 72,
    double marginTop = 48,
    int backgroundColor = 0xFFFFFBF5,
    int lineColor = 0xFFD7D2C8,
    String style = 'lined',
    List<double>? horizontalLines,
    List<double>? verticalLines,
  }) {
    return PaperTemplate(
      id: const Uuid().v4(),
      name: name,
      lineSpacing: lineSpacing,
      gridSize: gridSize,
      marginLeft: marginLeft,
      marginTop: marginTop,
      backgroundColor: backgroundColor,
      lineColor: lineColor,
      style: style,
      horizontalLines: horizontalLines,
      verticalLines: verticalLines,
    );
  }

  /// Builds evenly spaced ruled lines that meet the page edges.
  static List<double> evenlySpacedLines({
    required double start,
    required double spacing,
    required double end,
  }) {
    if (spacing <= 0) return const [];
    final lines = <double>[];
    for (var y = start; y <= end + 0.01; y += spacing) {
      lines.add(y);
    }
    return lines;
  }

  static List<PaperTemplate> builtins() => const [
    PaperTemplate(
      id: 'builtin_blank',
      name: 'Blank',
      lineSpacing: 28,
      gridSize: 24,
      marginLeft: 72,
      marginTop: 48,
      backgroundColor: 0xFFFFFBF5,
      lineColor: 0xFFD7D2C8,
      style: 'blank',
      isBuiltin: true,
    ),
    PaperTemplate(
      id: 'builtin_lined',
      name: 'Lined',
      lineSpacing: 28,
      gridSize: 24,
      marginLeft: 72,
      marginTop: 48,
      backgroundColor: 0xFFFFFBF5,
      lineColor: 0xFFD7D2C8,
      style: 'lined',
      isBuiltin: true,
    ),
    PaperTemplate(
      id: 'builtin_college',
      name: 'College',
      lineSpacing: 24,
      gridSize: 24,
      marginLeft: 64,
      marginTop: 40,
      backgroundColor: 0xFFFFFFF8,
      lineColor: 0xFFC5CCD6,
      style: 'lined',
      isBuiltin: true,
    ),
    PaperTemplate(
      id: 'builtin_narrow',
      name: 'Narrow',
      lineSpacing: 20,
      gridSize: 24,
      marginLeft: 56,
      marginTop: 36,
      backgroundColor: 0xFFF3F7FF,
      lineColor: 0xFFB0B8C4,
      style: 'lined',
      isBuiltin: true,
    ),
    PaperTemplate(
      id: 'builtin_grid',
      name: 'Grid',
      lineSpacing: 28,
      gridSize: 24,
      marginLeft: 36,
      marginTop: 36,
      backgroundColor: 0xFFFFFBF5,
      lineColor: 0xFFD7D2C8,
      style: 'grid',
      isBuiltin: true,
    ),
    PaperTemplate(
      id: 'builtin_dots',
      name: 'Fine grid',
      lineSpacing: 28,
      gridSize: 16,
      marginLeft: 24,
      marginTop: 24,
      backgroundColor: 0xFFFFFFF8,
      lineColor: 0xFFD0D5DC,
      style: 'dotted',
      isBuiltin: true,
    ),
  ];

  @override
  List<Object?> get props => [
    id,
    name,
    lineSpacing,
    gridSize,
    marginLeft,
    marginTop,
    backgroundColor,
    lineColor,
    style,
    isBuiltin,
    horizontalLines,
    verticalLines,
  ];
}

class ShapeElement extends Equatable {
  const ShapeElement({
    required this.id,
    required this.pageId,
    required this.kind,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.colorValue = 0xFF1A1A1A,
    this.strokeWidth = 2.5,
    this.style = 'solid',
  });

  final String id;
  final String pageId;
  final ShapeKind kind;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final int colorValue;
  final double strokeWidth;

  /// Stroke pattern name (`solid`, `dashed`, `dotted`, `dashDot`).
  final String style;

  Rect get bounds {
    if (kind == ShapeKind.circle) {
      final radius = Offset(x2 - x1, y2 - y1).distance;
      return Rect.fromCircle(center: Offset(x1, y1), radius: radius);
    }
    return Rect.fromPoints(Offset(x1, y1), Offset(x2, y2));
  }

  ShapeElement copyWith({
    ShapeKind? kind,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    int? colorValue,
    double? strokeWidth,
    String? style,
  }) {
    return ShapeElement(
      id: id,
      pageId: pageId,
      kind: kind ?? this.kind,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      colorValue: colorValue ?? this.colorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'kind': kind.name,
    'x1': x1,
    'y1': y1,
    'x2': x2,
    'y2': y2,
    'color': colorValue,
    'strokeWidth': strokeWidth,
    'style': style,
  };

  factory ShapeElement.fromJson(Map<String, dynamic> json) {
    return ShapeElement(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      kind: ShapeKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ShapeKind.rect,
      ),
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      colorValue: json['color'] as int? ?? 0xFF1A1A1A,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.5,
      style: json['style'] as String? ?? 'solid',
    );
  }

  factory ShapeElement.create({
    required String pageId,
    required ShapeKind kind,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    int colorValue = 0xFF1A1A1A,
    double strokeWidth = 2.5,
    String style = 'solid',
  }) {
    return ShapeElement(
      id: const Uuid().v4(),
      pageId: pageId,
      kind: kind,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
      style: style,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pageId,
    kind,
    x1,
    y1,
    x2,
    y2,
    colorValue,
    strokeWidth,
    style,
  ];
}

class ImageElement extends Equatable {
  const ImageElement({
    required this.id,
    required this.pageId,
    required this.localPath,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final String pageId;
  final String localPath;
  final double x;
  final double y;
  final double width;
  final double height;

  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  ImageElement copyWith({
    String? localPath,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return ImageElement(
      id: id,
      pageId: pageId,
      localPath: localPath ?? this.localPath,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'localPath': localPath,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory ImageElement.fromJson(Map<String, dynamic> json) {
    return ImageElement(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      localPath: json['localPath'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  factory ImageElement.create({
    required String pageId,
    required String localPath,
    required double x,
    required double y,
    double width = 240,
    double height = 180,
  }) {
    return ImageElement(
      id: const Uuid().v4(),
      pageId: pageId,
      localPath: localPath,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  @override
  List<Object?> get props => [id, pageId, localPath, x, y, width, height];
}

/// Built-in decorative sticker placed on a page (GoodNotes-style).
class StickerElement extends Equatable {
  const StickerElement({
    required this.id,
    required this.pageId,
    required this.catalogId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final String pageId;
  final String catalogId;
  final double x;
  final double y;
  final double width;
  final double height;

  Rect get bounds => Rect.fromLTWH(x, y, width, height);

  StickerElement copyWith({
    String? catalogId,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return StickerElement(
      id: id,
      pageId: pageId,
      catalogId: catalogId ?? this.catalogId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'catalogId': catalogId,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory StickerElement.fromJson(Map<String, dynamic> json) {
    return StickerElement(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      catalogId: json['catalogId'] as String? ?? 'star',
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  factory StickerElement.create({
    required String pageId,
    required String catalogId,
    required double x,
    required double y,
    double width = 72,
    double height = 72,
  }) {
    return StickerElement(
      id: const Uuid().v4(),
      pageId: pageId,
      catalogId: catalogId,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  @override
  List<Object?> get props => [id, pageId, catalogId, x, y, width, height];
}

class NoteTag extends Equatable {
  const NoteTag({
    required this.id,
    required this.notebookId,
    required this.label,
  });

  final String id;
  final String notebookId;
  final String label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'label': label,
  };

  factory NoteTag.fromJson(Map<String, dynamic> json) {
    return NoteTag(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      label: json['label'] as String,
    );
  }

  factory NoteTag.create({required String notebookId, required String label}) {
    return NoteTag(id: const Uuid().v4(), notebookId: notebookId, label: label);
  }

  @override
  List<Object?> get props => [id, notebookId, label];
}

class NoteLink extends Equatable {
  const NoteLink({
    required this.id,
    required this.fromNotebookId,
    required this.toNotebookId,
    this.fromPageId,
    this.toPageId,
    this.label,
  });

  final String id;
  final String fromNotebookId;
  final String toNotebookId;
  final String? fromPageId;
  final String? toPageId;
  final String? label;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromNotebookId': fromNotebookId,
    'toNotebookId': toNotebookId,
    'fromPageId': fromPageId,
    'toPageId': toPageId,
    'label': label,
  };

  factory NoteLink.fromJson(Map<String, dynamic> json) {
    return NoteLink(
      id: json['id'] as String,
      fromNotebookId: json['fromNotebookId'] as String,
      toNotebookId: json['toNotebookId'] as String,
      fromPageId: json['fromPageId'] as String?,
      toPageId: json['toPageId'] as String?,
      label: json['label'] as String?,
    );
  }

  factory NoteLink.create({
    required String fromNotebookId,
    required String toNotebookId,
    String? fromPageId,
    String? toPageId,
    String? label,
  }) {
    return NoteLink(
      id: const Uuid().v4(),
      fromNotebookId: fromNotebookId,
      toNotebookId: toNotebookId,
      fromPageId: fromPageId,
      toPageId: toPageId,
      label: label,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fromNotebookId,
    toNotebookId,
    fromPageId,
    toPageId,
    label,
  ];
}

class SearchHit extends Equatable {
  const SearchHit({
    required this.kind,
    required this.snippet,
    this.notebookId,
    this.notebookTitle,
    this.folderId,
    this.deckId,
    this.pageId,
    this.outlineId,
    this.subtitle,
    this.path,
    this.exactMatch = false,
  });

  /// folder | notebook | outline | text | tag | flashcard
  final String kind;
  final String snippet;
  final String? notebookId;
  final String? notebookTitle;
  final String? folderId;
  final String? deckId;
  final String? pageId;
  final String? outlineId;
  final String? subtitle;

  /// Breadcrumb such as `Musik/` or `Musik/Hi`.
  final String? path;
  final bool exactMatch;

  int get rank {
    final base = switch (kind) {
      'folder' => 0,
      'notebook' => 1,
      'outline' => 2,
      'flashcard' => 3,
      'tag' => 4,
      'text' => 5,
      _ => 9,
    };
    return exactMatch ? base : base + 10;
  }

  @override
  List<Object?> get props => [
    kind,
    snippet,
    notebookId,
    notebookTitle,
    folderId,
    deckId,
    pageId,
    outlineId,
    subtitle,
    path,
    exactMatch,
  ];
}

class LibraryFolder extends Equatable {
  const LibraryFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
    this.colorValue = 0xFF1D4E89,
    this.iconKey = 'folder',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? parentId;
  final int colorValue;
  final String iconKey;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'parentId': parentId,
    'color': colorValue,
    'iconKey': iconKey,
  };

  factory LibraryFolder.fromJson(Map<String, dynamic> json) {
    return LibraryFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      parentId: json['parentId'] as String?,
      colorValue: json['color'] as int? ?? 0xFF1D4E89,
      iconKey: json['iconKey'] as String? ?? 'folder',
    );
  }

  factory LibraryFolder.create({
    required String name,
    String? parentId,
    int colorValue = 0xFF1D4E89,
    String iconKey = 'folder',
  }) {
    return LibraryFolder(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      parentId: parentId,
      colorValue: colorValue,
      iconKey: iconKey,
    );
  }

  LibraryFolder copyWith({
    String? name,
    String? parentId,
    int? colorValue,
    String? iconKey,
  }) {
    return LibraryFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      parentId: parentId ?? this.parentId,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    parentId,
    colorValue,
    iconKey,
  ];
}

class FlashcardDeck extends Equatable {
  const FlashcardDeck({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.colorValue = 0xFF9A5B13,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final int colorValue;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'folderId': folderId,
    'color': colorValue,
  };

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) {
    return FlashcardDeck(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      folderId: json['folderId'] as String?,
      colorValue: json['color'] as int? ?? 0xFF9A5B13,
    );
  }

  factory FlashcardDeck.create({
    required String title,
    String? folderId,
    int colorValue = 0xFF9A5B13,
  }) {
    final now = DateTime.now();
    return FlashcardDeck(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
      colorValue: colorValue,
    );
  }

  FlashcardDeck copyWith({
    String? title,
    DateTime? updatedAt,
    String? folderId,
    int? colorValue,
    bool clearFolder = false,
  }) {
    return FlashcardDeck(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    updatedAt,
    folderId,
    colorValue,
  ];
}

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.intervalDays = 0,
    this.ease = 2.5,
    this.repetitions = 0,
    this.dueAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;

  /// Days until the next review (SM-2 style).
  final int intervalDays;

  /// Ease factor (typically ≥ 1.3).
  final double ease;

  /// Successful review streak.
  final int repetitions;

  /// Next time this card is due. Null = new / due now.
  final DateTime? dueAt;

  bool get isDue {
    final due = dueAt;
    if (due == null) return true;
    return !due.isAfter(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'front': front,
    'back': back,
    'intervalDays': intervalDays,
    'ease': ease,
    'repetitions': repetitions,
    if (dueAt != null) 'dueAt': dueAt!.toIso8601String(),
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.tryParse(json['dueAt'] as String),
    );
  }

  factory Flashcard.create({
    required String deckId,
    required String front,
    required String back,
  }) {
    return Flashcard(
      id: const Uuid().v4(),
      deckId: deckId,
      front: front,
      back: back,
    );
  }

  Flashcard copyWith({
    String? front,
    String? back,
    int? intervalDays,
    double? ease,
    int? repetitions,
    DateTime? dueAt,
    bool clearDueAt = false,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      repetitions: repetitions ?? this.repetitions,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    deckId,
    front,
    back,
    intervalDays,
    ease,
    repetitions,
    dueAt,
  ];
}

/// Simple SM-2 inspired scheduling for flashcard reviews.
enum FlashcardRating { again, hard, good, easy }

Flashcard applyFlashcardRating(Flashcard card, FlashcardRating rating) {
  final now = DateTime.now();
  switch (rating) {
    case FlashcardRating.again:
      return card.copyWith(
        intervalDays: 0,
        repetitions: 0,
        ease: (card.ease - 0.2).clamp(1.3, 3.0),
        dueAt: now.add(const Duration(minutes: 10)),
      );
    case FlashcardRating.hard:
      final interval = card.repetitions == 0
          ? 1
          : (card.intervalDays * 1.2).round().clamp(1, 3650);
      return card.copyWith(
        intervalDays: interval,
        repetitions: card.repetitions + 1,
        ease: (card.ease - 0.15).clamp(1.3, 3.0),
        dueAt: now.add(Duration(days: interval)),
      );
    case FlashcardRating.good:
      final interval = card.repetitions == 0
          ? 1
          : card.repetitions == 1
          ? 3
          : (card.intervalDays * card.ease).round().clamp(1, 3650);
      return card.copyWith(
        intervalDays: interval,
        repetitions: card.repetitions + 1,
        dueAt: now.add(Duration(days: interval)),
      );
    case FlashcardRating.easy:
      final ease = (card.ease + 0.15).clamp(1.3, 3.0);
      final interval = card.repetitions == 0
          ? 2
          : ((card.intervalDays == 0 ? 1 : card.intervalDays) * ease * 1.3)
                .round()
                .clamp(1, 3650);
      return card.copyWith(
        intervalDays: interval,
        repetitions: card.repetitions + 1,
        ease: ease,
        dueAt: now.add(Duration(days: interval)),
      );
  }
}

class SyncOp extends Equatable {
  const SyncOp({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    required this.createdAt,
    this.synced = false,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String payloadJson;
  final DateTime createdAt;
  final bool synced;

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'payloadJson': payloadJson,
    'createdAt': createdAt.toIso8601String(),
    'synced': synced,
  };

  factory SyncOp.fromJson(Map<String, dynamic> json) {
    return SyncOp(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      payloadJson: json['payloadJson'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      synced: json['synced'] as bool? ?? false,
    );
  }

  SyncOp copyWith({bool? synced}) {
    return SyncOp(
      id: id,
      entityType: entityType,
      entityId: entityId,
      payloadJson: payloadJson,
      createdAt: createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  List<Object?> get props => [
    id,
    entityType,
    entityId,
    payloadJson,
    createdAt,
    synced,
  ];
}

/// Local page version history entry (strokes/text/shapes snapshot).
class PageLocalSnapshot extends Equatable {
  const PageLocalSnapshot({
    required this.id,
    required this.pageId,
    required this.notebookId,
    required this.label,
    required this.createdAt,
    required this.pageJson,
  });

  final String id;
  final String pageId;
  final String notebookId;
  final String label;
  final DateTime createdAt;
  final String pageJson;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'notebookId': notebookId,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
    'pageJson': pageJson,
  };

  factory PageLocalSnapshot.fromJson(Map<String, dynamic> json) {
    return PageLocalSnapshot(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      notebookId: json['notebookId'] as String,
      label: json['label'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageJson: json['pageJson'] as String,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pageId,
    notebookId,
    label,
    createdAt,
    pageJson,
  ];
}
