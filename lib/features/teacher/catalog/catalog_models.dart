import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum CatalogKind { task, test, exam }

enum CatalogVisibility { private, school, public }

enum TaskPartKind { text, image, link }

enum AnswerKind { text, multipleChoice, calculation, matching }

class TaskPart extends Equatable {
  const TaskPart({
    required this.id,
    required this.kind,
    this.text = '',
    this.imagePath,
    this.url = '',
  });

  final String id;
  final TaskPartKind kind;
  final String text;
  final String? imagePath;
  final String url;

  TaskPart copyWith({
    String? text,
    String? imagePath,
    String? url,
    bool clearImage = false,
  }) {
    return TaskPart(
      id: id,
      kind: kind,
      text: text ?? this.text,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'text': text,
    'imagePath': imagePath,
    'url': url,
  };

  factory TaskPart.fromJson(Map<String, dynamic> json) {
    return TaskPart(
      id: json['id'] as String? ?? const Uuid().v4(),
      kind: TaskPartKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => TaskPartKind.text,
      ),
      text: json['text'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      url: json['url'] as String? ?? '',
    );
  }

  factory TaskPart.text(String text) =>
      TaskPart(id: const Uuid().v4(), kind: TaskPartKind.text, text: text);

  factory TaskPart.image(String path) =>
      TaskPart(id: const Uuid().v4(), kind: TaskPartKind.image, imagePath: path);

  factory TaskPart.link(String url) =>
      TaskPart(id: const Uuid().v4(), kind: TaskPartKind.link, url: url);

  @override
  List<Object?> get props => [id, kind, text, imagePath, url];
}

class McOption extends Equatable {
  const McOption({
    required this.id,
    required this.text,
    this.correct = false,
  });

  final String id;
  final String text;
  final bool correct;

  McOption copyWith({String? text, bool? correct}) {
    return McOption(
      id: id,
      text: text ?? this.text,
      correct: correct ?? this.correct,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'correct': correct,
  };

  factory McOption.fromJson(Map<String, dynamic> json) {
    return McOption(
      id: json['id'] as String? ?? const Uuid().v4(),
      text: json['text'] as String? ?? '',
      correct: json['correct'] as bool? ?? false,
    );
  }

  factory McOption.create({String text = '', bool correct = false}) =>
      McOption(id: const Uuid().v4(), text: text, correct: correct);

  @override
  List<Object?> get props => [id, text, correct];
}

class MatchItem extends Equatable {
  const MatchItem({required this.id, required this.text});

  final String id;
  final String text;

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      text: json['text'] as String? ?? '',
    );
  }

  factory MatchItem.create([String text = '']) =>
      MatchItem(id: const Uuid().v4(), text: text);

  @override
  List<Object?> get props => [id, text];
}

class CatalogTask extends Equatable {
  const CatalogTask({
    required this.id,
    required this.title,
    required this.parts,
    required this.answerKind,
    this.maxPoints = 1,
    this.options = const [],
    this.leftItems = const [],
    this.rightItems = const [],
    this.matchPairs = const [],
    this.sampleAnswer = '',
    this.calcResult = '',
    this.calcTolerance = 0.01,
  });

  final String id;
  final String title;
  final List<TaskPart> parts;
  final AnswerKind answerKind;
  final int maxPoints;
  final List<McOption> options;
  final List<MatchItem> leftItems;
  final List<MatchItem> rightItems;
  final List<(String, String)> matchPairs;
  final String sampleAnswer;
  final String calcResult;
  final double calcTolerance;

  CatalogTask copyWith({
    String? title,
    List<TaskPart>? parts,
    AnswerKind? answerKind,
    int? maxPoints,
    List<McOption>? options,
    List<MatchItem>? leftItems,
    List<MatchItem>? rightItems,
    List<(String, String)>? matchPairs,
    String? sampleAnswer,
    String? calcResult,
    double? calcTolerance,
  }) {
    return CatalogTask(
      id: id,
      title: title ?? this.title,
      parts: parts ?? this.parts,
      answerKind: answerKind ?? this.answerKind,
      maxPoints: maxPoints ?? this.maxPoints,
      options: options ?? this.options,
      leftItems: leftItems ?? this.leftItems,
      rightItems: rightItems ?? this.rightItems,
      matchPairs: matchPairs ?? this.matchPairs,
      sampleAnswer: sampleAnswer ?? this.sampleAnswer,
      calcResult: calcResult ?? this.calcResult,
      calcTolerance: calcTolerance ?? this.calcTolerance,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'parts': [for (final p in parts) p.toJson()],
    'answerKind': answerKind.name,
    'maxPoints': maxPoints,
    'options': [for (final o in options) o.toJson()],
    'leftItems': [for (final i in leftItems) i.toJson()],
    'rightItems': [for (final i in rightItems) i.toJson()],
    'matchPairs': [
      for (final pair in matchPairs) {'left': pair.$1, 'right': pair.$2},
    ],
    'sampleAnswer': sampleAnswer,
    'calcResult': calcResult,
    'calcTolerance': calcTolerance,
  };

  factory CatalogTask.fromJson(Map<String, dynamic> json) {
    return CatalogTask(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? '',
      parts: [
        for (final item in json['parts'] as List? ?? const [])
          TaskPart.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      answerKind: AnswerKind.values.firstWhere(
        (k) => k.name == json['answerKind'],
        orElse: () => AnswerKind.text,
      ),
      maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 1,
      options: [
        for (final item in json['options'] as List? ?? const [])
          McOption.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      leftItems: [
        for (final item in json['leftItems'] as List? ?? const [])
          MatchItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      rightItems: [
        for (final item in json['rightItems'] as List? ?? const [])
          MatchItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      matchPairs: [
        for (final item in json['matchPairs'] as List? ?? const [])
          (
            (item as Map)['left'] as String? ?? '',
            item['right'] as String? ?? '',
          ),
      ],
      sampleAnswer: json['sampleAnswer'] as String? ?? '',
      calcResult: json['calcResult'] as String? ?? '',
      calcTolerance: (json['calcTolerance'] as num?)?.toDouble() ?? 0.01,
    );
  }

  /// Student packet: parts + answer UI, never keys or sample solutions.
  Map<String, dynamic> toStudentJson() => {
    'id': id,
    'title': title,
    'parts': [for (final p in parts) p.toJson()],
    'answerKind': answerKind.name,
    'maxPoints': maxPoints,
    'options': [
      for (final o in options) {'id': o.id, 'text': o.text},
    ],
    'leftItems': [for (final i in leftItems) i.toJson()],
    'rightItems': [for (final i in rightItems) i.toJson()],
  };

  factory CatalogTask.fromStudentJson(Map<String, dynamic> json) {
    return CatalogTask.fromJson({
      ...json,
      'options': [
        for (final item in json['options'] as List? ?? const [])
          {
            ...Map<String, dynamic>.from(item as Map),
            'correct': false,
          },
      ],
      'matchPairs': const [],
      'sampleAnswer': '',
      'calcResult': '',
    });
  }

  factory CatalogTask.create({
    String title = '',
    AnswerKind answerKind = AnswerKind.text,
  }) {
    return CatalogTask(
      id: const Uuid().v4(),
      title: title,
      parts: [TaskPart.text('')],
      answerKind: answerKind,
      options: answerKind == AnswerKind.multipleChoice
          ? [McOption.create(), McOption.create()]
          : const [],
      leftItems: answerKind == AnswerKind.matching
          ? [MatchItem.create(), MatchItem.create()]
          : const [],
      rightItems: answerKind == AnswerKind.matching
          ? [MatchItem.create(), MatchItem.create()]
          : const [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    parts,
    answerKind,
    maxPoints,
    options,
    leftItems,
    rightItems,
    matchPairs,
    sampleAnswer,
    calcResult,
    calcTolerance,
  ];
}

class CatalogItem extends Equatable {
  const CatalogItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.schoolClass,
    required this.germanState,
    required this.kind,
    required this.visibility,
    required this.tasks,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.schoolId,
    this.needsReview = false,
    this.confirmed = false,
    this.suggestedDurationMinutes = 45,
    this.ownerUid = 'local',
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String subject;
  final String schoolClass;
  final String germanState;
  final CatalogKind kind;
  final CatalogVisibility visibility;
  final List<CatalogTask> tasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? schoolId;
  final bool needsReview;
  final bool confirmed;
  final int suggestedDurationMinutes;
  final String ownerUid;
  final Map<String, dynamic> metadata;

  CatalogItem copyWith({
    String? title,
    String? subject,
    String? schoolClass,
    String? germanState,
    CatalogKind? kind,
    CatalogVisibility? visibility,
    List<CatalogTask>? tasks,
    DateTime? updatedAt,
    List<String>? tags,
    String? schoolId,
    bool? needsReview,
    bool? confirmed,
    int? suggestedDurationMinutes,
    String? ownerUid,
    bool clearSchoolId = false,
    Map<String, dynamic>? metadata,
  }) {
    return CatalogItem(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      schoolClass: schoolClass ?? this.schoolClass,
      germanState: germanState ?? this.germanState,
      kind: kind ?? this.kind,
      visibility: visibility ?? this.visibility,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      schoolId: clearSchoolId ? null : (schoolId ?? this.schoolId),
      needsReview: needsReview ?? this.needsReview,
      confirmed: confirmed ?? this.confirmed,
      suggestedDurationMinutes:
          suggestedDurationMinutes ?? this.suggestedDurationMinutes,
      ownerUid: ownerUid ?? this.ownerUid,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'schoolClass': schoolClass,
    'germanState': germanState,
    'kind': kind.name,
    'visibility': visibility.name,
    'tasks': [for (final t in tasks) t.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
    'schoolId': schoolId,
    'needsReview': needsReview,
    'confirmed': confirmed,
    'suggestedDurationMinutes': suggestedDurationMinutes,
    'ownerUid': ownerUid,
    'metadata': metadata,
  };

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      schoolClass: json['schoolClass'] as String? ?? '',
      germanState: json['germanState'] as String? ?? '',
      kind: CatalogKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => CatalogKind.task,
      ),
      visibility: CatalogVisibility.values.firstWhere(
        (v) => v.name == json['visibility'],
        orElse: () => CatalogVisibility.private,
      ),
      tasks: [
        for (final item in json['tasks'] as List? ?? const [])
          CatalogTask.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      tags: [
        for (final tag in json['tags'] as List? ?? const []) tag.toString(),
      ],
      schoolId: json['schoolId'] as String?,
      needsReview: json['needsReview'] as bool? ?? false,
      confirmed: json['confirmed'] as bool? ?? false,
      suggestedDurationMinutes:
          (json['suggestedDurationMinutes'] as num?)?.toInt() ?? 45,
      ownerUid: json['ownerUid'] as String? ?? 'local',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  Map<String, dynamic> toStudentJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'schoolClass': schoolClass,
    'germanState': germanState,
    'kind': kind.name,
    'tags': tags,
    'suggestedDurationMinutes': suggestedDurationMinutes,
    'tasks': [for (final t in tasks) t.toStudentJson()],
  };

  factory CatalogItem.create({
    required String title,
    required String subject,
    required String schoolClass,
    required String germanState,
  }) {
    final now = DateTime.now();
    return CatalogItem(
      id: const Uuid().v4(),
      title: title,
      subject: subject,
      schoolClass: schoolClass,
      germanState: germanState,
      kind: CatalogKind.task,
      visibility: CatalogVisibility.private,
      tasks: [CatalogTask.create(title: '1')],
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subject,
    schoolClass,
    germanState,
    kind,
    visibility,
    tasks,
    createdAt,
    updatedAt,
    tags,
    schoolId,
    needsReview,
    confirmed,
    suggestedDurationMinutes,
    ownerUid,
    metadata,
  ];
}

class TeacherSchool extends Equatable {
  const TeacherSchool({
    required this.name,
    required this.joinCode,
  });

  final String name;
  final String joinCode;

  String get schoolId => joinCode.trim().toUpperCase();

  TeacherSchool copyWith({String? name, String? joinCode}) {
    return TeacherSchool(
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'joinCode': joinCode,
  };

  factory TeacherSchool.fromJson(Map<String, dynamic> json) {
    return TeacherSchool(
      name: json['name'] as String? ?? '',
      joinCode: json['joinCode'] as String? ?? '',
    );
  }

  factory TeacherSchool.create(String name) {
    final seed = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    return TeacherSchool(
      name: name.trim(),
      joinCode: seed.toString().padLeft(6, '0'),
    );
  }

  @override
  List<Object?> get props => [name, joinCode];
}
