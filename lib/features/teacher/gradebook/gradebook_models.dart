import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../planner/school_year.dart';

class RosterStudent extends Equatable {
  const RosterStudent({required this.id, required this.name});

  final String id;
  final String name;

  RosterStudent copyWith({String? name}) =>
      RosterStudent(id: id, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory RosterStudent.fromJson(Map<String, dynamic> json) {
    return RosterStudent(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class ClassGroup extends Equatable {
  const ClassGroup({
    required this.id,
    required this.name,
    this.studentIds = const [],
  });

  final String id;
  final String name;
  final List<String> studentIds;

  ClassGroup copyWith({String? name, List<String>? studentIds}) {
    return ClassGroup(
      id: id,
      name: name ?? this.name,
      studentIds: studentIds ?? this.studentIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'studentIds': studentIds,
  };

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      studentIds: [
        for (final id in (json['studentIds'] as List? ?? const []))
          id.toString(),
      ],
    );
  }

  @override
  List<Object?> get props => [id, name, studentIds];
}

class TeacherClassRoster extends Equatable {
  const TeacherClassRoster({
    required this.id,
    required this.name,
    this.students = const [],
    this.groups = const [],
  });

  final String id;
  final String name;
  final List<RosterStudent> students;
  final List<ClassGroup> groups;

  List<RosterStudent> studentsInGroup(ClassGroup group) {
    final ids = group.studentIds.toSet();
    return [for (final student in students) if (ids.contains(student.id)) student];
  }

  TeacherClassRoster copyWith({
    String? name,
    List<RosterStudent>? students,
    List<ClassGroup>? groups,
  }) {
    return TeacherClassRoster(
      id: id,
      name: name ?? this.name,
      students: students ?? this.students,
      groups: groups ?? this.groups,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'students': [for (final s in students) s.toJson()],
    'groups': [for (final g in groups) g.toJson()],
  };

  factory TeacherClassRoster.fromJson(Map<String, dynamic> json) {
    return TeacherClassRoster(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      students: [
        for (final item in (json['students'] as List? ?? const []))
          RosterStudent.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      groups: [
        for (final item in (json['groups'] as List? ?? const []))
          ClassGroup.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  @override
  List<Object?> get props => [id, name, students, groups];
}

class ClassTopic extends Equatable {
  const ClassTopic({
    required this.id,
    required this.classId,
    required this.name,
    required this.schoolYearStart,
  });

  final String id;
  final String classId;
  final String name;
  final int schoolYearStart;

  SchoolYear get schoolYear => SchoolYear(schoolYearStart);

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'name': name,
    'schoolYearStart': schoolYearStart,
  };

  factory ClassTopic.fromJson(Map<String, dynamic> json) {
    return ClassTopic(
      id: json['id'] as String? ?? const Uuid().v4(),
      classId: json['classId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      schoolYearStart:
          (json['schoolYearStart'] as num?)?.toInt() ??
          SchoolYear.current().startYear,
    );
  }

  @override
  List<Object?> get props => [id, classId, name, schoolYearStart];
}

class ClassAssessment extends Equatable {
  const ClassAssessment({
    required this.id,
    required this.classId,
    required this.topicId,
    required this.title,
    required this.date,
    required this.schoolYearStart,
  });

  final String id;
  final String classId;
  final String topicId;
  final String title;
  final DateTime date;
  final int schoolYearStart;

  SchoolYear get schoolYear => SchoolYear(schoolYearStart);

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'topicId': topicId,
    'title': title,
    'date': date.toIso8601String(),
    'schoolYearStart': schoolYearStart,
  };

  factory ClassAssessment.fromJson(Map<String, dynamic> json) {
    return ClassAssessment(
      id: json['id'] as String? ?? const Uuid().v4(),
      classId: json['classId'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date:
          DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      schoolYearStart:
          (json['schoolYearStart'] as num?)?.toInt() ??
          SchoolYear.fromDate(DateTime.now()).startYear,
    );
  }

  @override
  List<Object?> get props =>
      [id, classId, topicId, title, date, schoolYearStart];
}

class ClassGrade extends Equatable {
  const ClassGrade({
    required this.assessmentId,
    required this.studentId,
    required this.value,
  });

  final String assessmentId;
  final String studentId;

  /// German school grade 1–6.
  final int value;

  Map<String, dynamic> toJson() => {
    'assessmentId': assessmentId,
    'studentId': studentId,
    'value': value,
  };

  factory ClassGrade.fromJson(Map<String, dynamic> json) {
    return ClassGrade(
      assessmentId: json['assessmentId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      value: ((json['value'] as num?)?.toInt() ?? 0).clamp(1, 6),
    );
  }

  @override
  List<Object?> get props => [assessmentId, studentId, value];
}

enum SavedPickerKind { flash, datacheck }

class SavedPicker extends Equatable {
  const SavedPicker({
    required this.id,
    required this.name,
    required this.classId,
    required this.kind,
    this.groupId,
    this.connectedOnly = false,
    this.drawnIds = const [],
    this.lastName,
    this.lastDetail,
  });

  final String id;
  final String name;
  final String classId;
  final SavedPickerKind kind;
  final String? groupId;
  final bool connectedOnly;
  final List<String> drawnIds;
  final String? lastName;
  final String? lastDetail;

  bool get isDatacheck => kind == SavedPickerKind.datacheck;
  bool get isFlash => kind == SavedPickerKind.flash;

  SavedPicker copyWith({
    String? name,
    String? classId,
    SavedPickerKind? kind,
    String? groupId,
    bool clearGroup = false,
    bool? connectedOnly,
    List<String>? drawnIds,
    String? lastName,
    String? lastDetail,
    bool clearLast = false,
  }) {
    return SavedPicker(
      id: id,
      name: name ?? this.name,
      classId: classId ?? this.classId,
      kind: kind ?? this.kind,
      groupId: clearGroup ? null : (groupId ?? this.groupId),
      connectedOnly: connectedOnly ?? this.connectedOnly,
      drawnIds: drawnIds ?? this.drawnIds,
      lastName: clearLast ? null : (lastName ?? this.lastName),
      lastDetail: clearLast ? null : (lastDetail ?? this.lastDetail),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'classId': classId,
    'kind': kind.name,
    'groupId': groupId,
    'connectedOnly': connectedOnly,
    'drawnIds': drawnIds,
    'lastName': lastName,
    'lastDetail': lastDetail,
  };

  factory SavedPicker.fromJson(Map<String, dynamic> json) {
    return SavedPicker(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      kind: SavedPickerKind.values.firstWhere(
        (item) => item.name == json['kind'],
        orElse: () => SavedPickerKind.flash,
      ),
      groupId: json['groupId'] as String?,
      connectedOnly: json['connectedOnly'] as bool? ?? false,
      drawnIds: [
        for (final id in (json['drawnIds'] as List? ?? const [])) id.toString(),
      ],
      lastName: json['lastName'] as String?,
      lastDetail: json['lastDetail'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    classId,
    kind,
    groupId,
    connectedOnly,
    drawnIds,
    lastName,
    lastDetail,
  ];
}

class TeacherGradebook extends Equatable {
  const TeacherGradebook({
    this.classes = const [],
    this.topics = const [],
    this.assessments = const [],
    this.grades = const [],
    this.pickers = const [],
    this.activePickerId,
  });

  final List<TeacherClassRoster> classes;
  final List<ClassTopic> topics;
  final List<ClassAssessment> assessments;
  final List<ClassGrade> grades;
  final List<SavedPicker> pickers;
  final String? activePickerId;

  TeacherClassRoster? classById(String id) {
    for (final item in classes) {
      if (item.id == id) return item;
    }
    return null;
  }

  TeacherClassRoster? classByName(String name) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final item in classes) {
      if (item.name.trim().toLowerCase() == key) return item;
    }
    return null;
  }

  SavedPicker? pickerById(String? id) {
    if (id == null) return null;
    for (final item in pickers) {
      if (item.id == id) return item;
    }
    return null;
  }

  SavedPicker? get activePicker => pickerById(activePickerId) ??
      (pickers.isEmpty ? null : pickers.first);

  TeacherGradebook copyWith({
    List<TeacherClassRoster>? classes,
    List<ClassTopic>? topics,
    List<ClassAssessment>? assessments,
    List<ClassGrade>? grades,
    List<SavedPicker>? pickers,
    String? activePickerId,
    bool clearActivePicker = false,
  }) {
    return TeacherGradebook(
      classes: classes ?? this.classes,
      topics: topics ?? this.topics,
      assessments: assessments ?? this.assessments,
      grades: grades ?? this.grades,
      pickers: pickers ?? this.pickers,
      activePickerId: clearActivePicker
          ? null
          : (activePickerId ?? this.activePickerId),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'classes': [for (final item in classes) item.toJson()],
    'topics': [for (final item in topics) item.toJson()],
    'assessments': [for (final item in assessments) item.toJson()],
    'grades': [for (final item in grades) item.toJson()],
    'pickers': [for (final item in pickers) item.toJson()],
    'activePickerId': activePickerId,
  };

  factory TeacherGradebook.fromJson(Map<String, dynamic> json) {
    return TeacherGradebook(
      classes: [
        for (final item in (json['classes'] as List? ?? const []))
          TeacherClassRoster.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      topics: [
        for (final item in (json['topics'] as List? ?? const []))
          ClassTopic.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      assessments: [
        for (final item in (json['assessments'] as List? ?? const []))
          ClassAssessment.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      grades: [
        for (final item in (json['grades'] as List? ?? const []))
          ClassGrade.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      pickers: [
        for (final item in (json['pickers'] as List? ?? const []))
          SavedPicker.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      activePickerId: json['activePickerId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [classes, topics, assessments, grades, pickers, activePickerId];
}
