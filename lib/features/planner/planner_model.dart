import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../library/providers/library_providers.dart';
import 'education_settings.dart';
import 'grade_period.dart';
import 'school_year.dart';

enum PlannerEventKind { appointment, exam, homework, other }

enum RecurrenceFrequency { daily, weekly, monthly }

enum GradeScale {
  /// Sek I: 1–6
  german,

  /// Sek II: 0–15 Punkte
  points,

  /// Studium: 1,0–5,0
  uni,

  percent,
}

/// Schriftlich (KA/Klausur) vs. mündlich / sonstige Mitarbeit.
enum GradeCategory { major, minor }

String subjectKey(String subject) => subject.trim().toLowerCase();

/// Compact serializable rule for a recurring planner event.
class EventRecurrence extends Equatable {
  const EventRecurrence({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const [],
    required this.until,
  });

  final RecurrenceFrequency frequency;
  final int interval;

  /// ISO weekdays (Mon = 1, Sun = 7). Used by weekly rules.
  final List<int> weekdays;
  final DateTime until;

  Map<String, dynamic> toJson() => {
    'frequency': frequency.name,
    'interval': interval,
    'weekdays': weekdays,
    'until': until.toIso8601String(),
  };

  factory EventRecurrence.fromJson(Map<String, dynamic> json) {
    return EventRecurrence(
      frequency: RecurrenceFrequency.values.firstWhere(
        (frequency) => frequency.name == json['frequency'],
        orElse: () => RecurrenceFrequency.weekly,
      ),
      interval: ((json['interval'] as num?)?.toInt() ?? 1).clamp(1, 52),
      weekdays: [
        for (final weekday in (json['weekdays'] as List? ?? const []))
          if (weekday is num && weekday >= 1 && weekday <= 7) weekday.toInt(),
      ],
      until:
          DateTime.tryParse(json['until']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [frequency, interval, weekdays, until];
}

class SubjectWeight extends Equatable {
  const SubjectWeight({required this.subject, this.majorPercent = 50});

  final String subject;

  /// Anteil schriftlich / Klausuren (0–100). Rest = mündlich / sonstige.
  final int majorPercent;

  int get minorPercent => 100 - majorPercent;

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'majorPercent': majorPercent,
  };

  factory SubjectWeight.fromJson(Map<String, dynamic> json) {
    return SubjectWeight(
      subject: json['subject'] as String? ?? '',
      majorPercent: (json['majorPercent'] as num?)?.round().clamp(0, 100) ?? 50,
    );
  }

  SubjectWeight copyWith({String? subject, int? majorPercent}) {
    return SubjectWeight(
      subject: subject ?? this.subject,
      majorPercent: majorPercent ?? this.majorPercent,
    );
  }

  @override
  List<Object?> get props => [subject, majorPercent];
}

class PlannerEvent extends Equatable {
  const PlannerEvent({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.folderId,
    this.subject = '',
    this.note = '',
    this.kind = PlannerEventKind.appointment,
    this.colorValue = 0xFF0F6E56,
    this.gradeId,
    this.recurrence,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? folderId;
  final String subject;
  final String note;
  final PlannerEventKind kind;
  final int colorValue;
  final String? gradeId;
  final EventRecurrence? recurrence;

  String get displaySubject =>
      subject.trim().isEmpty ? title.trim() : subject.trim();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'folderId': folderId,
    'subject': subject,
    'note': note,
    'kind': kind.name,
    'color': colorValue,
    'gradeId': gradeId,
    'recurrence': recurrence?.toJson(),
  };

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    return PlannerEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      start: DateTime.parse(json['start'] as String),
      end: json['end'] == null
          ? null
          : DateTime.tryParse(json['end'] as String),
      folderId: json['folderId'] as String?,
      subject: json['subject'] as String? ?? '',
      note: json['note'] as String? ?? '',
      kind: PlannerEventKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => PlannerEventKind.appointment,
      ),
      colorValue: json['color'] as int? ?? 0xFF0F6E56,
      gradeId: json['gradeId'] as String?,
      recurrence: json['recurrence'] is Map
          ? EventRecurrence.fromJson(
              Map<String, dynamic>.from(json['recurrence'] as Map),
            )
          : null,
    );
  }

  factory PlannerEvent.create({
    required String title,
    required DateTime start,
    DateTime? end,
    String? folderId,
    String subject = '',
    String note = '',
    PlannerEventKind kind = PlannerEventKind.appointment,
    int colorValue = 0xFF0F6E56,
    String? gradeId,
    EventRecurrence? recurrence,
  }) {
    return PlannerEvent(
      id: const Uuid().v4(),
      title: title,
      start: start,
      end: end,
      folderId: folderId,
      subject: subject,
      note: note,
      kind: kind,
      colorValue: colorValue,
      gradeId: gradeId,
      recurrence: recurrence,
    );
  }

  PlannerEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    String? folderId,
    bool clearFolder = false,
    String? subject,
    String? note,
    PlannerEventKind? kind,
    int? colorValue,
    String? gradeId,
    EventRecurrence? recurrence,
    bool clearRecurrence = false,
    bool clearGrade = false,
  }) {
    return PlannerEvent(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      subject: subject ?? this.subject,
      note: note ?? this.note,
      kind: kind ?? this.kind,
      colorValue: colorValue ?? this.colorValue,
      gradeId: clearGrade ? null : (gradeId ?? this.gradeId),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    );
  }

  /// Plain text ready to paste into chat / mail (share foundation).
  String toShareText() {
    final buf = StringBuffer()
      ..writeln(title.trim().isEmpty ? displaySubject : title.trim());
    if (subject.trim().isNotEmpty) buf.writeln('Fach: ${subject.trim()}');
    buf.writeln('Wann: ${_fmt(start)}${end != null ? ' – ${_fmt(end!)}' : ''}');
    if (note.trim().isNotEmpty) buf.writeln(note.trim());
    return buf.toString().trim();
  }

  /// Minimal ICS for later calendar forward / import.
  String toIcs() {
    String stamp(DateTime d) {
      final u = d.toUtc();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${u.year}${two(u.month)}${two(u.day)}T'
          '${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    final uid = '$id@betternotes';
    final summary = title.trim().isEmpty ? displaySubject : title.trim();
    final desc = [
      if (subject.trim().isNotEmpty) 'Fach: ${subject.trim()}',
      if (note.trim().isNotEmpty) note.trim(),
    ].join('\\n');
    final endDt = end ?? start.add(const Duration(hours: 1));
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Notis//Planner//DE',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${stamp(DateTime.now())}',
      'DTSTART:${stamp(start)}',
      'DTEND:${stamp(endDt)}',
      'SUMMARY:${_icsEscape(summary)}',
      if (desc.isNotEmpty) 'DESCRIPTION:${_icsEscape(desc)}',
      if (recurrence != null) _icsRecurrence(recurrence!),
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');
  }

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} '
        '${two(d.hour)}:${two(d.minute)}';
  }

  static String _icsEscape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll(',', '\\,').replaceAll(';', '\\;');

  static String _icsRecurrence(EventRecurrence recurrence) {
    String stamp(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.year}${two(d.month)}${two(d.day)}T235959Z';
    }

    const weekdayNames = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final frequency = switch (recurrence.frequency) {
      RecurrenceFrequency.daily => 'DAILY',
      RecurrenceFrequency.weekly => 'WEEKLY',
      RecurrenceFrequency.monthly => 'MONTHLY',
    };
    final byDay =
        recurrence.frequency == RecurrenceFrequency.weekly &&
            recurrence.weekdays.isNotEmpty
        ? ';BYDAY=${recurrence.weekdays.map((day) => weekdayNames[day - 1]).join(',')}'
        : '';
    return 'RRULE:FREQ=$frequency;INTERVAL=${recurrence.interval};UNTIL=${stamp(recurrence.until)}$byDay';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    start,
    end,
    folderId,
    subject,
    note,
    kind,
    colorValue,
    gradeId,
    recurrence,
  ];
}

class GradeEntry extends Equatable {
  const GradeEntry({
    required this.id,
    this.value,
    required this.date,
    this.folderId,
    this.subject = '',
    this.title = '',
    this.weight = 1,
    this.note = '',
    this.scale = GradeScale.german,
    this.category = GradeCategory.major,
    this.period = GradePeriod.h1,
    this.ects = 0,
    this.isAbiSubject = false,
    this.semesterLabel = '',
    this.educationLevel,
    this.attachmentPaths = const [],
    this.schoolYearStart,
    this.eventId,
  });

  final String id;

  /// Null until the teacher returns the marked exam.
  final double? value;
  final DateTime date;
  final String? folderId;
  final String subject;
  final String title;
  final double weight;
  final String note;
  final GradeScale scale;
  final GradeCategory category;
  final GradePeriod period;

  /// ECTS for university modules.
  final double ects;

  /// Marks subject/grade as relevant for Abitur exam projection.
  final bool isAbiSubject;

  /// Free label e.g. "WiSe 25/26" for university.
  final String semesterLabel;

  /// Which track this grade belongs to. Kept when switching levels.
  final EducationLevel? educationLevel;

  /// Local paths to scanned worksheets / exams.
  final List<String> attachmentPaths;

  /// Explicit school-year start (e.g. 2025 → 2025/26). Null → inferred from [date].
  final int? schoolYearStart;
  final String? eventId;

  SchoolYear get schoolYear => schoolYearStart != null
      ? SchoolYear(schoolYearStart!)
      : SchoolYear.fromDate(date);

  EducationLevel get resolvedLevel =>
      educationLevel ??
      switch (scale) {
        GradeScale.german || GradeScale.percent => EducationLevel.sek1,
        GradeScale.points => EducationLevel.sek2,
        GradeScale.uni => EducationLevel.university,
      };

  bool matchesLevel(EducationLevel level) => resolvedLevel == level;

  bool matchesYear(SchoolYear year) => schoolYear == year;

  String get displayValue {
    if (value == null) return '–';
    final numericValue = value!;
    switch (scale) {
      case GradeScale.german:
        // Tendenz formatted in UI via grade_value_codec; keep numeric fallback.
        final v = numericValue;
        if ((v * 4).roundToDouble() == v * 4 && v != v.roundToDouble()) {
          final base = v.round().clamp(1, 6);
          if (v < base) return '$base+';
          if (v > base) return '$base-';
        }
        if (v == v.roundToDouble()) return v.toStringAsFixed(0);
        return v.toStringAsFixed(1);
      case GradeScale.percent:
        return '${numericValue.toStringAsFixed(0)} %';
      case GradeScale.points:
        return numericValue.round().clamp(0, 15).toString();
      case GradeScale.uni:
        return numericValue.toStringAsFixed(1);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'value': value,
    'date': date.toIso8601String(),
    'folderId': folderId,
    'subject': subject,
    'title': title,
    'weight': weight,
    'note': note,
    'scale': scale.name,
    'category': category.name,
    'period': period.name,
    'ects': ects,
    'isAbiSubject': isAbiSubject,
    'semesterLabel': semesterLabel,
    'educationLevel': educationLevel?.name,
    'attachmentPaths': attachmentPaths,
    'schoolYearStart': schoolYearStart ?? schoolYear.startYear,
    'eventId': eventId,
  };

  factory GradeEntry.fromJson(Map<String, dynamic> json) {
    return GradeEntry(
      id: json['id'] as String,
      value: (json['value'] as num?)?.toDouble(),
      date: DateTime.parse(json['date'] as String),
      folderId: json['folderId'] as String?,
      subject: json['subject'] as String? ?? '',
      title: json['title'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      note: json['note'] as String? ?? '',
      scale: GradeScale.values.firstWhere(
        (s) => s.name == json['scale'],
        orElse: () => GradeScale.german,
      ),
      category: GradeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => GradeCategory.major,
      ),
      period: GradePeriod.values.firstWhere(
        (p) => p.name == json['period'],
        orElse: () => GradePeriod.h1,
      ),
      ects: (json['ects'] as num?)?.toDouble() ?? 0,
      isAbiSubject: json['isAbiSubject'] as bool? ?? false,
      semesterLabel: json['semesterLabel'] as String? ?? '',
      educationLevel: json['educationLevel'] == null
          ? null
          : EducationLevel.values.firstWhere(
              (e) => e.name == json['educationLevel'],
              orElse: () => EducationLevel.sek1,
            ),
      attachmentPaths: [
        for (final a in (json['attachmentPaths'] as List? ?? const []))
          a as String,
      ],
      schoolYearStart: (json['schoolYearStart'] as num?)?.toInt(),
      eventId: json['eventId'] as String?,
    );
  }

  factory GradeEntry.create({
    double? value,
    required DateTime date,
    String? folderId,
    String subject = '',
    String title = '',
    double weight = 1,
    String note = '',
    GradeScale scale = GradeScale.german,
    GradeCategory category = GradeCategory.major,
    GradePeriod period = GradePeriod.h1,
    double ects = 0,
    bool isAbiSubject = false,
    String semesterLabel = '',
    EducationLevel? educationLevel,
    List<String> attachmentPaths = const [],
    int? schoolYearStart,
    String? eventId,
  }) {
    return GradeEntry(
      id: const Uuid().v4(),
      value: value,
      date: date,
      folderId: folderId,
      subject: subject,
      title: title,
      weight: weight,
      note: note,
      scale: scale,
      category: category,
      period: period,
      ects: ects,
      isAbiSubject: isAbiSubject,
      semesterLabel: semesterLabel,
      educationLevel: educationLevel,
      attachmentPaths: attachmentPaths,
      schoolYearStart: schoolYearStart ?? SchoolYear.fromDate(date).startYear,
      eventId: eventId,
    );
  }

  GradeEntry copyWith({
    double? value,
    bool clearValue = false,
    DateTime? date,
    String? folderId,
    bool clearFolder = false,
    String? subject,
    String? title,
    double? weight,
    String? note,
    GradeScale? scale,
    GradeCategory? category,
    GradePeriod? period,
    double? ects,
    bool? isAbiSubject,
    String? semesterLabel,
    EducationLevel? educationLevel,
    List<String>? attachmentPaths,
    int? schoolYearStart,
    String? eventId,
    bool clearEvent = false,
  }) {
    return GradeEntry(
      id: id,
      value: clearValue ? null : (value ?? this.value),
      date: date ?? this.date,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      subject: subject ?? this.subject,
      title: title ?? this.title,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      scale: scale ?? this.scale,
      category: category ?? this.category,
      period: period ?? this.period,
      ects: ects ?? this.ects,
      isAbiSubject: isAbiSubject ?? this.isAbiSubject,
      semesterLabel: semesterLabel ?? this.semesterLabel,
      educationLevel: educationLevel ?? this.educationLevel,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      schoolYearStart: schoolYearStart ?? this.schoolYearStart,
      eventId: clearEvent ? null : (eventId ?? this.eventId),
    );
  }

  @override
  List<Object?> get props => [
    id,
    value,
    date,
    folderId,
    subject,
    title,
    weight,
    note,
    scale,
    category,
    period,
    ects,
    isAbiSubject,
    semesterLabel,
    educationLevel,
    attachmentPaths,
    schoolYearStart,
    eventId,
  ];
}

class PlannerState extends Equatable {
  const PlannerState({
    this.events = const [],
    this.grades = const [],
    this.subjectWeights = const [],
  });

  final List<PlannerEvent> events;
  final List<GradeEntry> grades;
  final List<SubjectWeight> subjectWeights;

  List<PlannerEvent> eventsOn(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return [
      for (final e in events)
        if (_occursOn(e, date)) _occurrenceFor(e, date),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  bool _occursOn(PlannerEvent event, DateTime day) {
    final startDay = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    if (day.isBefore(startDay)) return false;
    final rule = event.recurrence;
    if (rule == null) return day == startDay;
    final until = DateTime(rule.until.year, rule.until.month, rule.until.day);
    if (day.isAfter(until)) return false;

    final days = day.difference(startDay).inDays;
    return switch (rule.frequency) {
      RecurrenceFrequency.daily => days % rule.interval == 0,
      RecurrenceFrequency.weekly => _weeklyOccurs(startDay, day, rule),
      RecurrenceFrequency.monthly =>
        day.day == startDay.day &&
            _monthsBetween(startDay, day) % rule.interval == 0,
    };
  }

  bool _weeklyOccurs(DateTime startDay, DateTime day, EventRecurrence rule) {
    final weeks = day.difference(startDay).inDays ~/ 7;
    if (weeks < 0 || weeks % rule.interval != 0) return false;
    final weekdays = rule.weekdays.isEmpty
        ? <int>[startDay.weekday]
        : rule.weekdays;
    return weekdays.contains(day.weekday);
  }

  int _monthsBetween(DateTime start, DateTime end) =>
      (end.year - start.year) * 12 + end.month - start.month;

  PlannerEvent _occurrenceFor(PlannerEvent event, DateTime day) {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      event.start.hour,
      event.start.minute,
      event.start.second,
      event.start.millisecond,
      event.start.microsecond,
    );
    final duration = event.end?.difference(event.start);
    return event.copyWith(
      start: start,
      end: duration == null ? null : start.add(duration),
    );
  }

  List<PlannerEvent> upcoming({int limit = 5}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = <PlannerEvent>[];
    for (var offset = 0; offset < 365 && list.length < limit * 4; offset++) {
      list.addAll(eventsOn(today.add(Duration(days: offset))));
    }
    list.sort((a, b) => a.start.compareTo(b.start));
    return list.take(limit).toList();
  }

  /// Past appointments/exams of one subject, newest first, for linking a
  /// grade that was entered after the actual appointment.
  List<PlannerEvent> pastEventsForSubject(String subject, {DateTime? before}) {
    final cutoff = before ?? DateTime.now();
    final key = subjectKey(subject);
    return [
      for (final event in events)
        if (subjectKey(event.displaySubject) == key &&
            event.start.isBefore(cutoff))
          event,
    ]..sort((a, b) => b.start.compareTo(a.start));
  }

  SubjectWeight weightFor(String subject) {
    final key = subjectKey(subject);
    for (final w in subjectWeights) {
      if (subjectKey(w.subject) == key) return w;
    }
    return SubjectWeight(subject: subject.trim(), majorPercent: 50);
  }

  List<GradeEntry> gradesForLevel(EducationLevel level) => [
    for (final g in grades)
      if (g.matchesLevel(level)) g,
  ];

  List<GradeEntry> gradesForLevelYear(EducationLevel level, SchoolYear year) =>
      [
        for (final g in grades)
          if (g.matchesLevel(level) && g.matchesYear(year)) g,
      ];

  List<SchoolYear> yearsForLevel(EducationLevel level) {
    final set = <int>{};
    for (final g in grades) {
      if (g.matchesLevel(level)) set.add(g.schoolYear.startYear);
    }
    set.add(SchoolYear.current().startYear);
    final list = [for (final y in set) SchoolYear(y)]..sort();
    return list.reversed.toList();
  }

  List<GradeEntry> gradesForSubject(
    String subject, {
    GradePeriod? period,
    EducationLevel? level,
    SchoolYear? year,
  }) {
    final key = subjectKey(subject);
    return [
      for (final g in grades)
        if (subjectKey(g.subject) == key)
          if (level == null || g.matchesLevel(level))
            if (year == null || g.matchesYear(year))
              if (period == null || g.period == period) g,
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  double? _categoryAverage(List<GradeEntry> list, GradeCategory category) {
    final filtered = [
      for (final g in list)
        if (g.category == category && g.value != null) g,
    ];
    if (filtered.isEmpty) return null;
    var wSum = 0.0;
    var vSum = 0.0;
    for (final g in filtered) {
      wSum += g.weight;
      vSum += g.value! * g.weight;
    }
    if (wSum <= 0) return null;
    return vSum / wSum;
  }

  /// Legacy helper — prefer [GradeCalculator].
  double? weightedAverageForSubject(String subject, {GradePeriod? period}) {
    final list = gradesForSubject(subject, period: period);
    if (list.isEmpty) return null;
    final w = weightFor(subject);
    final major = _categoryAverage(list, GradeCategory.major);
    final minor = _categoryAverage(list, GradeCategory.minor);
    if (major != null && minor != null) {
      return major * (w.majorPercent / 100) + minor * (w.minorPercent / 100);
    }
    return major ?? minor;
  }

  double? overallAverage({
    required List<String> subjects,
    GradePeriod? period,
  }) {
    final avgs = [
      for (final s in subjects)
        if (weightedAverageForSubject(s, period: period) != null)
          weightedAverageForSubject(s, period: period)!,
    ];
    if (avgs.isEmpty) {
      if (grades.isEmpty) return null;
      final keys = {for (final g in grades) subjectKey(g.subject)};
      final computed = [
        for (final k in keys)
          if (weightedAverageForSubject(k, period: period) != null)
            weightedAverageForSubject(k, period: period)!,
      ];
      if (computed.isEmpty) return null;
      return computed.reduce((a, b) => a + b) / computed.length;
    }
    return avgs.reduce((a, b) => a + b) / avgs.length;
  }

  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
    'grades': grades.map((g) => g.toJson()).toList(),
    'subjectWeights': subjectWeights.map((w) => w.toJson()).toList(),
  };

  factory PlannerState.fromJson(Map<String, dynamic> json) {
    return PlannerState(
      events: [
        for (final e in (json['events'] as List? ?? const []))
          PlannerEvent.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      grades: [
        for (final g in (json['grades'] as List? ?? const []))
          GradeEntry.fromJson(Map<String, dynamic>.from(g as Map)),
      ],
      subjectWeights: [
        for (final w in (json['subjectWeights'] as List? ?? const []))
          SubjectWeight.fromJson(Map<String, dynamic>.from(w as Map)),
      ],
    );
  }

  PlannerState copyWith({
    List<PlannerEvent>? events,
    List<GradeEntry>? grades,
    List<SubjectWeight>? subjectWeights,
  }) {
    return PlannerState(
      events: events ?? this.events,
      grades: grades ?? this.grades,
      subjectWeights: subjectWeights ?? this.subjectWeights,
    );
  }

  @override
  List<Object?> get props => [events, grades, subjectWeights];
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  PlannerNotifier(this._prefs) : super(const PlannerState()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'plannerV1';

  void _load() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return;
      state = PlannerState.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> upsertEvent(PlannerEvent event) async {
    final next = [
      for (final e in state.events)
        if (e.id != event.id) e,
      event,
    ];
    state = state.copyWith(events: next);
    await _save();
  }

  Future<void> deleteEvent(String id) async {
    state = state.copyWith(
      events: [
        for (final e in state.events)
          if (e.id != id) e,
      ],
      grades: [
        for (final grade in state.grades)
          if (grade.eventId == id) grade.copyWith(clearEvent: true) else grade,
      ],
    );
    await _save();
  }

  Future<void> upsertGrade(GradeEntry grade) async {
    final next = [
      for (final g in state.grades)
        if (g.id != grade.id) g,
      grade,
    ];
    state = state.copyWith(
      grades: next,
      events: [
        for (final event in state.events)
          if (event.id == grade.eventId)
            event.copyWith(gradeId: grade.id)
          else if (event.gradeId == grade.id && event.id != grade.eventId)
            event.copyWith(clearGrade: true)
          else
            event,
      ],
    );
    await _save();
  }

  Future<void> deleteGrade(String id) async {
    state = state.copyWith(
      grades: [
        for (final g in state.grades)
          if (g.id != id) g,
      ],
      events: [
        for (final event in state.events)
          if (event.gradeId == id) event.copyWith(clearGrade: true) else event,
      ],
    );
    await _save();
  }

  Future<void> setSubjectWeight(SubjectWeight weight) async {
    final key = subjectKey(weight.subject);
    final next = [
      for (final w in state.subjectWeights)
        if (subjectKey(w.subject) != key) w,
      weight,
    ];
    state = state.copyWith(subjectWeights: next);
    await _save();
  }
}

final plannerProvider = StateNotifierProvider<PlannerNotifier, PlannerState>((
  ref,
) {
  return PlannerNotifier(ref.watch(sharedPreferencesProvider));
});
