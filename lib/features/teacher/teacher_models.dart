import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../library/providers/library_providers.dart';
import '../timetable/timetable_model.dart';

enum LessonStatus { planned, held, cancelled }

enum TraineeVerification { none, pending, verified, rejected }

class ClassroomParticipant extends Equatable {
  const ClassroomParticipant({
    required this.id,
    required this.name,
    this.canWrite = false,
    this.muted = false,
    this.focused = true,
    this.progress = 0,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final bool canWrite;
  final bool muted;
  final bool focused;
  final int progress;
  final DateTime? lastSeenAt;

  ClassroomParticipant copyWith({
    bool? canWrite,
    bool? muted,
    bool? focused,
    int? progress,
    DateTime? lastSeenAt,
  }) {
    return ClassroomParticipant(
      id: id,
      name: name,
      canWrite: canWrite ?? this.canWrite,
      muted: muted ?? this.muted,
      focused: focused ?? this.focused,
      progress: (progress ?? this.progress).clamp(0, 100),
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'canWrite': canWrite,
    'muted': muted,
    'focused': focused,
    'progress': progress,
    'lastSeenAt': lastSeenAt?.toIso8601String(),
  };

  factory ClassroomParticipant.fromJson(Map<String, dynamic> json) {
    return ClassroomParticipant(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      canWrite: json['canWrite'] as bool? ?? false,
      muted: json['muted'] as bool? ?? false,
      focused: json['focused'] as bool? ?? true,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    canWrite,
    muted,
    focused,
    progress,
    lastSeenAt,
  ];
}

class ClassroomSession extends Equatable {
  const ClassroomSession({
    required this.id,
    required this.code,
    required this.title,
    required this.startedAt,
    required this.subject,
    required this.room,
    this.notebookId,
    this.active = true,
    this.focusCheckEnabled = false,
    this.participants = const [],
  });

  final String id;
  final String code;
  final String title;
  final DateTime startedAt;
  final String subject;
  final String room;
  final String? notebookId;
  final bool active;
  final bool focusCheckEnabled;
  final List<ClassroomParticipant> participants;

  double get averageProgress => participants.isEmpty
      ? 0
      : participants.fold<int>(0, (sum, item) => sum + item.progress) /
            participants.length;

  ClassroomSession copyWith({
    bool? active,
    bool? focusCheckEnabled,
    List<ClassroomParticipant>? participants,
  }) {
    return ClassroomSession(
      id: id,
      code: code,
      title: title,
      startedAt: startedAt,
      subject: subject,
      room: room,
      notebookId: notebookId,
      active: active ?? this.active,
      focusCheckEnabled: focusCheckEnabled ?? this.focusCheckEnabled,
      participants: participants ?? this.participants,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'startedAt': startedAt.toIso8601String(),
    'subject': subject,
    'room': room,
    'notebookId': notebookId,
    'active': active,
    'focusCheckEnabled': focusCheckEnabled,
    'participants': participants.map((p) => p.toJson()).toList(),
  };

  factory ClassroomSession.fromJson(Map<String, dynamic> json) {
    return ClassroomSession(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      subject: json['subject'] as String? ?? '',
      room: json['room'] as String? ?? '',
      notebookId: json['notebookId'] as String?,
      active: json['active'] as bool? ?? false,
      focusCheckEnabled: json['focusCheckEnabled'] as bool? ?? false,
      participants: [
        for (final item in json['participants'] as List? ?? const [])
          ClassroomParticipant.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    startedAt,
    subject,
    room,
    notebookId,
    active,
    focusCheckEnabled,
    participants,
  ];
}

enum LessonAttachmentKind { material, whiteboard }

class LessonAttachment extends Equatable {
  const LessonAttachment({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.materialId,
    this.notebookId,
    this.pageId,
    this.snapshotId,
    this.url,
  });

  final String id;
  final LessonAttachmentKind kind;
  final String title;
  final DateTime createdAt;
  final String? materialId;
  final String? notebookId;
  final String? pageId;
  final String? snapshotId;
  final String? url;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'materialId': materialId,
    'notebookId': notebookId,
    'pageId': pageId,
    'snapshotId': snapshotId,
    'url': url,
  };

  factory LessonAttachment.fromJson(Map<String, dynamic> json) {
    return LessonAttachment(
      id: json['id'] as String,
      kind: LessonAttachmentKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => LessonAttachmentKind.material,
      ),
      title: json['title'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      materialId: json['materialId'] as String?,
      notebookId: json['notebookId'] as String?,
      pageId: json['pageId'] as String?,
      snapshotId: json['snapshotId'] as String?,
      url: json['url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    createdAt,
    materialId,
    notebookId,
    pageId,
    snapshotId,
    url,
  ];
}

class LessonJournalEntry extends Equatable {
  const LessonJournalEntry({
    required this.id,
    required this.subject,
    required this.title,
    required this.scheduledAt,
    this.periodIndex = 0,
    this.periodLabel = '',
    this.room = '',
    this.splitHalf,
    this.status = LessonStatus.planned,
    this.notebookId,
    this.homework = '',
    this.notes = '',
    this.attachments = const [],
  });

  final String id;
  final String subject;
  final String title;
  final DateTime scheduledAt;
  final int periodIndex;
  final String periodLabel;
  final String room;
  /// `first` / `second` for split blocks, otherwise null.
  final String? splitHalf;
  final LessonStatus status;
  final String? notebookId;
  final String homework;
  final String notes;
  final List<LessonAttachment> attachments;

  LessonJournalEntry copyWith({
    String? title,
    DateTime? scheduledAt,
    int? periodIndex,
    String? periodLabel,
    String? room,
    String? splitHalf,
    LessonStatus? status,
    String? notebookId,
    String? homework,
    String? notes,
    List<LessonAttachment>? attachments,
  }) {
    return LessonJournalEntry(
      id: id,
      subject: subject,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      periodIndex: periodIndex ?? this.periodIndex,
      periodLabel: periodLabel ?? this.periodLabel,
      room: room ?? this.room,
      splitHalf: splitHalf ?? this.splitHalf,
      status: status ?? this.status,
      notebookId: notebookId ?? this.notebookId,
      homework: homework ?? this.homework,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'title': title,
    'scheduledAt': scheduledAt.toIso8601String(),
    'periodIndex': periodIndex,
    'periodLabel': periodLabel,
    'room': room,
    'splitHalf': splitHalf,
    'status': status.name,
    'notebookId': notebookId,
    'homework': homework,
    'notes': notes,
    'attachments': attachments.map((item) => item.toJson()).toList(),
  };

  factory LessonJournalEntry.fromJson(Map<String, dynamic> json) {
    return LessonJournalEntry(
      id: json['id'] as String,
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      periodIndex: (json['periodIndex'] as num?)?.toInt() ?? 0,
      periodLabel: json['periodLabel'] as String? ?? '',
      room: json['room'] as String? ?? '',
      splitHalf: json['splitHalf'] as String?,
      status: LessonStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => LessonStatus.planned,
      ),
      notebookId: json['notebookId'] as String?,
      homework: json['homework'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      attachments: [
        for (final item in json['attachments'] as List? ?? const [])
          LessonAttachment.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  @override
  List<Object?> get props => [
    id,
    subject,
    title,
    scheduledAt,
    periodIndex,
    periodLabel,
    room,
    splitHalf,
    status,
    notebookId,
    homework,
    notes,
    attachments,
  ];
}

class TeacherMaterial extends Equatable {
  const TeacherMaterial({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.durationMinutes,
    this.germanState = 'Alle',
    this.localPath,
    this.cloudUrl,
    this.sharedBy = 'Ich',
    this.isOer = false,
  });

  final String id;
  final String title;
  final String subject;
  final String grade;
  final int durationMinutes;
  final String germanState;
  final String? localPath;
  final String? cloudUrl;
  final String sharedBy;
  final bool isOer;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'grade': grade,
    'durationMinutes': durationMinutes,
    'germanState': germanState,
    'localPath': localPath,
    'cloudUrl': cloudUrl,
    'sharedBy': sharedBy,
    'isOer': isOer,
  };

  factory TeacherMaterial.fromJson(Map<String, dynamic> json) {
    return TeacherMaterial(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 45,
      germanState: json['germanState'] as String? ?? 'Alle',
      localPath: json['localPath'] as String?,
      cloudUrl: json['cloudUrl'] as String?,
      sharedBy: json['sharedBy'] as String? ?? 'Community',
      isOer: json['isOer'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subject,
    grade,
    durationMinutes,
    germanState,
    localPath,
    cloudUrl,
    sharedBy,
    isOer,
  ];
}

class AudioExplanation extends Equatable {
  const AudioExplanation({
    required this.id,
    required this.title,
    required this.localPath,
    required this.createdAt,
    this.transcript = '',
    this.transcriptPending = true,
  });

  final String id;
  final String title;
  final String localPath;
  final DateTime createdAt;
  final String transcript;
  final bool transcriptPending;

  AudioExplanation copyWith({
    String? transcript,
    bool? transcriptPending,
  }) {
    return AudioExplanation(
      id: id,
      title: title,
      localPath: localPath,
      createdAt: createdAt,
      transcript: transcript ?? this.transcript,
      transcriptPending: transcriptPending ?? this.transcriptPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'localPath': localPath,
    'createdAt': createdAt.toIso8601String(),
    'transcript': transcript,
    'transcriptPending': transcriptPending,
  };

  factory AudioExplanation.fromJson(Map<String, dynamic> json) {
    return AudioExplanation(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      transcript: json['transcript'] as String? ?? '',
      transcriptPending: json['transcriptPending'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    localPath,
    createdAt,
    transcript,
    transcriptPending,
  ];
}

class TeacherState extends Equatable {
  const TeacherState({
    this.session,
    this.lessons = const [],
    this.materials = const [],
    this.audioExplanations = const [],
    this.traineeVerification = TraineeVerification.none,
  });

  final ClassroomSession? session;
  final List<LessonJournalEntry> lessons;
  final List<TeacherMaterial> materials;
  final List<AudioExplanation> audioExplanations;
  final TraineeVerification traineeVerification;

  TeacherState copyWith({
    ClassroomSession? session,
    bool clearSession = false,
    List<LessonJournalEntry>? lessons,
    List<TeacherMaterial>? materials,
    List<AudioExplanation>? audioExplanations,
    TraineeVerification? traineeVerification,
  }) {
    return TeacherState(
      session: clearSession ? null : (session ?? this.session),
      lessons: lessons ?? this.lessons,
      materials: materials ?? this.materials,
      audioExplanations: audioExplanations ?? this.audioExplanations,
      traineeVerification: traineeVerification ?? this.traineeVerification,
    );
  }

  Map<String, dynamic> toJson() => {
    'session': session?.toJson(),
    'lessons': lessons.map((e) => e.toJson()).toList(),
    'materials': materials.map((e) => e.toJson()).toList(),
    'audioExplanations': audioExplanations.map((e) => e.toJson()).toList(),
    'traineeVerification': traineeVerification.name,
  };

  factory TeacherState.fromJson(Map<String, dynamic> json) {
    return TeacherState(
      session: json['session'] is Map
          ? ClassroomSession.fromJson(
              Map<String, dynamic>.from(json['session'] as Map),
            )
          : null,
      lessons: [
        for (final item in json['lessons'] as List? ?? const [])
          LessonJournalEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ],
      materials: [
        for (final item in json['materials'] as List? ?? const [])
          TeacherMaterial.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      audioExplanations: [
        for (final item in json['audioExplanations'] as List? ?? const [])
          AudioExplanation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
      ],
      traineeVerification: TraineeVerification.values.firstWhere(
        (value) => value.name == json['traineeVerification'],
        orElse: () => TraineeVerification.none,
      ),
    );
  }

  @override
  List<Object?> get props => [
    session,
    lessons,
    materials,
    audioExplanations,
    traineeVerification,
  ];
}

class TeacherNotifier extends StateNotifier<TeacherState> {
  TeacherNotifier(this._prefs) : super(const TeacherState()) {
    _load();
  }

  static const _key = 'teacherWorkspaceV1';
  static const _uuid = Uuid();
  final SharedPreferences _prefs;

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        state = TeacherState.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {}
  }

  Future<void> _save() =>
      _prefs.setString(_key, jsonEncode(state.toJson()));

  Future<void> startSession({
    required String title,
    String? notebookId,
    String? code,
    String subject = '',
    String room = '',
  }) async {
    final now = DateTime.now();
    final seed = now.millisecondsSinceEpoch.remainder(1000000);
    state = state.copyWith(
      session: ClassroomSession(
        id: _uuid.v4(),
        code: code ?? seed.toString().padLeft(6, '0'),
        title: title,
        notebookId: notebookId,
        startedAt: now,
        subject: subject.trim(),
        room: room.trim(),
      ),
    );
    await _save();
  }

  Future<void> endSession() async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(session: session.copyWith(active: false));
    await _save();
  }

  Future<void> setFocusCheck(bool enabled) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(
      session: session.copyWith(focusCheckEnabled: enabled),
    );
    await _save();
  }

  Future<void> updateParticipant(
    String id, {
    bool? canWrite,
    bool? muted,
    bool? focused,
    int? progress,
  }) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(
      session: session.copyWith(
        participants: [
          for (final participant in session.participants)
            if (participant.id == id)
              participant.copyWith(
                canWrite: canWrite,
                muted: muted,
                focused: focused,
                progress: progress,
                lastSeenAt: DateTime.now(),
              )
            else
              participant,
        ],
      ),
    );
    await _save();
  }

  Future<void> addDemoParticipant(String name) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(
      session: session.copyWith(
        participants: [
          ...session.participants,
          ClassroomParticipant(
            id: _uuid.v4(),
            name: name,
            lastSeenAt: DateTime.now(),
          ),
        ],
      ),
    );
    await _save();
  }

  Future<void> applyNetworkSignal({
    required String deviceId,
    required String deviceName,
    required String kind,
    Object? value,
  }) async {
    final session = state.session;
    if (session == null) return;
    var participant = session.participants
        .where((item) => item.id == deviceId)
        .firstOrNull;
    participant ??= ClassroomParticipant(
      id: deviceId,
      name: deviceName,
      lastSeenAt: DateTime.now(),
    );
    participant = switch (kind) {
      'focus' => participant.copyWith(
        focused: value != false,
        lastSeenAt: DateTime.now(),
      ),
      'progress' => participant.copyWith(
        progress: (value as num?)?.toInt() ?? participant.progress,
        lastSeenAt: DateTime.now(),
      ),
      'left' => participant.copyWith(
        focused: false,
        lastSeenAt: DateTime.now(),
      ),
      _ => participant.copyWith(lastSeenAt: DateTime.now()),
    };
    state = state.copyWith(
      session: session.copyWith(
        participants: [
          for (final item in session.participants)
            if (item.id != deviceId) item,
          participant,
        ],
      ),
    );
    await _save();
  }

  Future<void> addLesson(LessonJournalEntry lesson) async {
    state = state.copyWith(lessons: [...state.lessons, lesson]);
    await _save();
  }

  Future<void> updateLesson(LessonJournalEntry lesson) async {
    state = state.copyWith(
      lessons: [
        for (final item in state.lessons)
          if (item.id == lesson.id) lesson else item,
      ],
    );
    await _save();
  }

  List<LessonJournalEntry> lessonsOn(DateTime day) {
    return [
      for (final lesson in state.lessons)
        if (lesson.scheduledAt.year == day.year &&
            lesson.scheduledAt.month == day.month &&
            lesson.scheduledAt.day == day.day)
          lesson,
    ]..sort((a, b) {
      final byPeriod = a.periodIndex.compareTo(b.periodIndex);
      if (byPeriod != 0) return byPeriod;
      return (a.splitHalf ?? '').compareTo(b.splitHalf ?? '');
    });
  }

  Future<void> ensureLessonsForDay(DateTime day, Timetable timetable) async {
    final dayIndex = Timetable.dayIndexFromWeekday(day.weekday);
    if (dayIndex == null) return;
    final dayStart = DateTime(day.year, day.month, day.day);
    final existing = lessonsOn(day);
    final toAdd = <LessonJournalEntry>[];

    bool exists(int period, String subject, String? half) {
      final key = subject.trim().toLowerCase();
      return existing.any(
        (lesson) =>
            lesson.periodIndex == period &&
            lesson.subject.trim().toLowerCase() == key &&
            lesson.splitHalf == half,
      );
    }

    void consider(
      TimetableLesson lesson,
      int period, {
      String? half,
    }) {
      if (lesson.isEmpty) return;
      if (exists(period, lesson.subject, half)) return;
      final periodInfo = timetable.periods[period];
      final startOffset = half == 'second'
          ? periodInfo.splitAtMinutes
          : periodInfo.startMinutes;
      toAdd.add(
        LessonJournalEntry(
          id: _uuid.v4(),
          subject: lesson.subject.trim(),
          title: '',
          scheduledAt: dayStart.add(Duration(minutes: startOffset)),
          periodIndex: period,
          periodLabel: periodInfo.label,
          room: lesson.room.trim(),
          splitHalf: half,
        ),
      );
    }

    for (var period = 0; period < timetable.periods.length; period++) {
      final slot = timetable.slotAt(dayIndex, period);
      if (slot == null || slot.isEmpty) continue;
      if (slot.split) {
        consider(slot.first, period, half: 'first');
        consider(slot.second, period, half: 'second');
      } else {
        consider(slot.first, period);
      }
    }

    if (toAdd.isEmpty) return;
    state = state.copyWith(lessons: [...state.lessons, ...toAdd]);
    await _save();
  }

  Future<LessonJournalEntry> ensureCurrentLesson({
    required Timetable timetable,
    String? subject,
    String? room,
    String? notebookId,
  }) async {
    final now = DateTime.now();
    await ensureLessonsForDay(now, timetable);
    final subjectKey =
        (subject ?? state.session?.subject ?? '').trim().toLowerCase();
    final roomKey = (room ?? state.session?.room ?? '').trim().toLowerCase();
    final dayLessons = lessonsOn(now);
    final minute = now.hour * 60 + now.minute;

    LessonJournalEntry? match;
    for (final lesson in dayLessons) {
      final subjectMatches = subjectKey.isEmpty ||
          lesson.subject.trim().toLowerCase() == subjectKey;
      final roomMatches = roomKey.isEmpty ||
          lesson.room.trim().toLowerCase() == roomKey;
      if (!subjectMatches && !roomMatches) continue;
      if (lesson.periodIndex < timetable.periods.length &&
          timetable.periods[lesson.periodIndex].containsMinuteOfDay(minute)) {
        match = lesson;
        break;
      }
      match ??= lesson;
    }

    if (match != null) {
      if (notebookId != null &&
          notebookId.isNotEmpty &&
          match.notebookId != notebookId) {
        match = match.copyWith(notebookId: notebookId);
        await updateLesson(match);
      }
      return match;
    }

    final dayIndex = Timetable.dayIndexFromWeekday(now.weekday);
    var periodIndex = 0;
    if (dayIndex != null) {
      for (var i = 0; i < timetable.periods.length; i++) {
        if (timetable.periods[i].containsMinuteOfDay(minute)) {
          periodIndex = i;
          break;
        }
      }
    }
    final periodLabel = periodIndex < timetable.periods.length
        ? timetable.periods[periodIndex].label
        : '';
    final created = LessonJournalEntry(
      id: _uuid.v4(),
      subject: subject ?? state.session?.subject ?? '',
      title: '',
      scheduledAt: DateTime(now.year, now.month, now.day, now.hour, now.minute),
      periodIndex: periodIndex,
      periodLabel: periodLabel,
      room: room ?? state.session?.room ?? '',
      notebookId: notebookId ?? state.session?.notebookId,
      status: LessonStatus.held,
    );
    await addLesson(created);
    return created;
  }

  Future<void> attachToLesson(
    String lessonId,
    LessonAttachment attachment,
  ) async {
    state = state.copyWith(
      lessons: [
        for (final lesson in state.lessons)
          if (lesson.id == lessonId)
            lesson.copyWith(
              attachments: [...lesson.attachments, attachment],
              status: lesson.status == LessonStatus.planned
                  ? LessonStatus.held
                  : lesson.status,
            )
          else
            lesson,
      ],
    );
    await _save();
  }

  Future<void> attachToCurrentLesson({
    required Timetable timetable,
    required LessonAttachment attachment,
    String? subject,
    String? room,
    String? notebookId,
  }) async {
    final lesson = await ensureCurrentLesson(
      timetable: timetable,
      subject: subject,
      room: room,
      notebookId: notebookId,
    );
    await attachToLesson(lesson.id, attachment);
  }

  Future<void> markLessonCancelledAndShift(String id) async {
    final cancelled = state.lessons.where((e) => e.id == id).firstOrNull;
    if (cancelled == null) return;
    state = state.copyWith(
      lessons: [
        for (final lesson in state.lessons)
          if (lesson.id == id)
            lesson.copyWith(status: LessonStatus.cancelled)
          else if (lesson.subject.trim().toLowerCase() ==
                  cancelled.subject.trim().toLowerCase() &&
              lesson.status == LessonStatus.planned &&
              lesson.scheduledAt.isAfter(cancelled.scheduledAt))
            lesson.copyWith(
              scheduledAt: lesson.scheduledAt.add(const Duration(days: 7)),
            )
          else
            lesson,
      ],
    );
    await _save();
  }

  Future<void> addMaterial(TeacherMaterial material) async {
    state = state.copyWith(materials: [...state.materials, material]);
    await _save();
  }

  Future<void> addAudioExplanation(AudioExplanation explanation) async {
    state = state.copyWith(
      audioExplanations: [...state.audioExplanations, explanation],
    );
    await _save();
  }

  Future<void> updateTranscript(String id, String transcript) async {
    state = state.copyWith(
      audioExplanations: [
        for (final explanation in state.audioExplanations)
          if (explanation.id == id)
            explanation.copyWith(
              transcript: transcript,
              transcriptPending: false,
            )
          else
            explanation,
      ],
    );
    await _save();
  }

  Future<void> setTraineeVerification(
    TraineeVerification verification,
  ) async {
    state = state.copyWith(traineeVerification: verification);
    await _save();
  }
}

final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherState>((
  ref,
) {
  return TeacherNotifier(ref.watch(sharedPreferencesProvider));
});

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
