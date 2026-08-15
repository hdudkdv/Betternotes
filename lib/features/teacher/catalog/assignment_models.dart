import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class StudentTaskAnswer extends Equatable {
  const StudentTaskAnswer({
    required this.taskId,
    this.selectedOptionIds = const [],
    this.matchPairs = const [],
    this.text = '',
    this.calcResult = '',
    this.done = false,
  });

  final String taskId;
  final List<String> selectedOptionIds;
  final List<(String, String)> matchPairs;
  final String text;
  final String calcResult;
  final bool done;

  StudentTaskAnswer copyWith({
    List<String>? selectedOptionIds,
    List<(String, String)>? matchPairs,
    String? text,
    String? calcResult,
    bool? done,
  }) {
    return StudentTaskAnswer(
      taskId: taskId,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      matchPairs: matchPairs ?? this.matchPairs,
      text: text ?? this.text,
      calcResult: calcResult ?? this.calcResult,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'selectedOptionIds': selectedOptionIds,
    'matchPairs': [
      for (final pair in matchPairs) {'left': pair.$1, 'right': pair.$2},
    ],
    'text': text,
    'calcResult': calcResult,
    'done': done,
  };

  factory StudentTaskAnswer.fromJson(Map<String, dynamic> json) {
    return StudentTaskAnswer(
      taskId: json['taskId'] as String? ?? '',
      selectedOptionIds: [
        for (final id in json['selectedOptionIds'] as List? ?? const [])
          id.toString(),
      ],
      matchPairs: [
        for (final raw in json['matchPairs'] as List? ?? const [])
          (
            (raw as Map)['left'] as String? ?? '',
            raw['right'] as String? ?? '',
          ),
      ],
      text: json['text'] as String? ?? '',
      calcResult: json['calcResult'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    selectedOptionIds,
    matchPairs,
    text,
    calcResult,
    done,
  ];
}

enum GradeMethod { rule, manual, pending }

class TaskGrade extends Equatable {
  const TaskGrade({
    required this.taskId,
    required this.pointsAwarded,
    required this.maxPoints,
    required this.correct,
    this.issues = const [],
    this.method = GradeMethod.rule,
  });

  final String taskId;
  final double pointsAwarded;
  final int maxPoints;
  final bool correct;
  final List<String> issues;
  final GradeMethod method;

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'pointsAwarded': pointsAwarded,
    'maxPoints': maxPoints,
    'correct': correct,
    'issues': issues,
    'method': method.name,
  };

  factory TaskGrade.fromJson(Map<String, dynamic> json) {
    return TaskGrade(
      taskId: json['taskId'] as String? ?? '',
      pointsAwarded: (json['pointsAwarded'] as num?)?.toDouble() ?? 0,
      maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 1,
      correct: json['correct'] as bool? ?? false,
      issues: [
        for (final issue in json['issues'] as List? ?? const [])
          issue.toString(),
      ],
      method: GradeMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => GradeMethod.rule,
      ),
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    pointsAwarded,
    maxPoints,
    correct,
    issues,
    method,
  ];
}

class AssignmentRun extends Equatable {
  const AssignmentRun({
    required this.id,
    required this.catalogItemId,
    required this.title,
    required this.subject,
    required this.schoolClass,
    required this.startedAt,
    required this.endsAt,
    required this.timeLimitSec,
    required this.testMode,
    this.lessonId,
    this.allowImport = false,
    this.collected = false,
  });

  final String id;
  final String catalogItemId;
  final String title;
  final String subject;
  final String schoolClass;
  final DateTime startedAt;
  final DateTime endsAt;
  final int timeLimitSec;
  final bool testMode;
  final String? lessonId;
  final bool allowImport;
  final bool collected;

  bool get expired => DateTime.now().isAfter(endsAt);

  AssignmentRun copyWith({
    DateTime? endsAt,
    bool? allowImport,
    bool? collected,
    String? lessonId,
  }) {
    return AssignmentRun(
      id: id,
      catalogItemId: catalogItemId,
      title: title,
      subject: subject,
      schoolClass: schoolClass,
      startedAt: startedAt,
      endsAt: endsAt ?? this.endsAt,
      timeLimitSec: timeLimitSec,
      testMode: testMode,
      lessonId: lessonId ?? this.lessonId,
      allowImport: allowImport ?? this.allowImport,
      collected: collected ?? this.collected,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'catalogItemId': catalogItemId,
    'title': title,
    'subject': subject,
    'schoolClass': schoolClass,
    'startedAt': startedAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'timeLimitSec': timeLimitSec,
    'testMode': testMode,
    'lessonId': lessonId,
    'allowImport': allowImport,
    'collected': collected,
  };

  factory AssignmentRun.fromJson(Map<String, dynamic> json) {
    return AssignmentRun(
      id: json['id'] as String? ?? const Uuid().v4(),
      catalogItemId: json['catalogItemId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      schoolClass: json['schoolClass'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(json['endsAt'] as String? ?? '') ?? DateTime.now(),
      timeLimitSec: (json['timeLimitSec'] as num?)?.toInt() ?? 0,
      testMode: json['testMode'] as bool? ?? false,
      lessonId: json['lessonId'] as String?,
      allowImport: json['allowImport'] as bool? ?? false,
      collected: json['collected'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    catalogItemId,
    title,
    subject,
    schoolClass,
    startedAt,
    endsAt,
    timeLimitSec,
    testMode,
    lessonId,
    allowImport,
    collected,
  ];
}

class AssignmentSubmission extends Equatable {
  const AssignmentSubmission({
    required this.deviceId,
    required this.deviceName,
    required this.runId,
    required this.submittedAt,
    required this.answers,
    this.doneTaskIds = const [],
    this.ocrText = '',
    this.early = false,
    this.grades = const [],
    this.correctionText = '',
  });

  final String deviceId;
  final String deviceName;
  final String runId;
  final DateTime submittedAt;
  final List<StudentTaskAnswer> answers;
  final List<String> doneTaskIds;
  final String ocrText;
  final bool early;
  final List<TaskGrade> grades;
  final String correctionText;

  AssignmentSubmission copyWith({
    List<TaskGrade>? grades,
    String? correctionText,
  }) {
    return AssignmentSubmission(
      deviceId: deviceId,
      deviceName: deviceName,
      runId: runId,
      submittedAt: submittedAt,
      answers: answers,
      doneTaskIds: doneTaskIds,
      ocrText: ocrText,
      early: early,
      grades: grades ?? this.grades,
      correctionText: correctionText ?? this.correctionText,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'runId': runId,
    'submittedAt': submittedAt.toIso8601String(),
    'answers': [for (final a in answers) a.toJson()],
    'doneTaskIds': doneTaskIds,
    'ocrText': ocrText,
    'early': early,
    'grades': [for (final g in grades) g.toJson()],
    'correctionText': correctionText,
  };

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      submittedAt:
          DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      answers: [
        for (final item in json['answers'] as List? ?? const [])
          StudentTaskAnswer.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      doneTaskIds: [
        for (final id in json['doneTaskIds'] as List? ?? const [])
          id.toString(),
      ],
      ocrText: json['ocrText'] as String? ?? '',
      early: json['early'] as bool? ?? false,
      grades: [
        for (final item in json['grades'] as List? ?? const [])
          TaskGrade.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      correctionText: json['correctionText'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    runId,
    submittedAt,
    answers,
    doneTaskIds,
    ocrText,
    early,
    grades,
    correctionText,
  ];
}

class AssignmentProblem extends Equatable {
  const AssignmentProblem({
    required this.taskId,
    required this.title,
    required this.label,
    required this.count,
  });

  final String taskId;
  final String title;
  final String label;
  final int count;

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'title': title,
    'label': label,
    'count': count,
  };

  factory AssignmentProblem.fromJson(Map<String, dynamic> json) {
    return AssignmentProblem(
      taskId: json['taskId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [taskId, title, label, count];
}

class AssignmentSummary extends Equatable {
  const AssignmentSummary({
    required this.runId,
    required this.averagePercent,
    required this.submittedCount,
    required this.participantCount,
    this.topProblems = const [],
    this.groups = const [],
    required this.updatedAt,
  });

  final String runId;
  final double averagePercent;
  final int submittedCount;
  final int participantCount;
  final List<AssignmentProblem> topProblems;
  final List<AssignmentProblem> groups;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'runId': runId,
    'averagePercent': averagePercent,
    'submittedCount': submittedCount,
    'participantCount': participantCount,
    'topProblems': [for (final p in topProblems) p.toJson()],
    'groups': [for (final g in groups) g.toJson()],
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AssignmentSummary.fromJson(Map<String, dynamic> json) {
    return AssignmentSummary(
      runId: json['runId'] as String? ?? '',
      averagePercent: (json['averagePercent'] as num?)?.toDouble() ?? 0,
      submittedCount: (json['submittedCount'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      topProblems: [
        for (final item in json['topProblems'] as List? ?? const [])
          AssignmentProblem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      groups: [
        for (final item in json['groups'] as List? ?? const [])
          AssignmentProblem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    runId,
    averagePercent,
    submittedCount,
    participantCount,
    topProblems,
    groups,
    updatedAt,
  ];
}

class AssignmentLeaveEvent extends Equatable {
  const AssignmentLeaveEvent({
    required this.deviceId,
    required this.deviceName,
    required this.at,
    required this.kind,
  });

  final String deviceId;
  final String deviceName;
  final DateTime at;
  final String kind;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'at': at.toIso8601String(),
    'kind': kind,
  };

  factory AssignmentLeaveEvent.fromJson(Map<String, dynamic> json) {
    return AssignmentLeaveEvent(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      kind: json['kind'] as String? ?? 'pause',
    );
  }

  @override
  List<Object?> get props => [deviceId, deviceName, at, kind];
}

class AssignmentProgressSnapshot extends Equatable {
  const AssignmentProgressSnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.percent,
    this.doneTaskIds = const [],
    this.submitted = false,
  });

  final String deviceId;
  final String deviceName;
  final int percent;
  final List<String> doneTaskIds;
  final bool submitted;

  @override
  List<Object?> get props => [
    deviceId,
    deviceName,
    percent,
    doneTaskIds,
    submitted,
  ];
}
