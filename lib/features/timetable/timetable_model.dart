import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/content_models.dart';
import '../library/providers/library_providers.dart';

int parseHm(String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return 8 * 60;
  final h = int.tryParse(parts[0].trim()) ?? 8;
  final m = int.tryParse(parts[1].trim()) ?? 0;
  return (h.clamp(0, 23) * 60) + m.clamp(0, 59);
}

String formatHm(int minutes) {
  final m = minutes.clamp(0, 24 * 60 - 1);
  final h = m ~/ 60;
  final min = m % 60;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

const int kDefaultLessonColor = 0xFF0F6E56;

const List<int> kSubjectPalette = [
  0xFF0F6E56,
  0xFF1D4E89,
  0xFF9A3412,
  0xFF5B3A8C,
  0xFF0E7490,
  0xFF9F1239,
  0xFF3F6212,
  0xFF9A6B12,
  0xFF1E3A5F,
  0xFF7C2D12,
  0xFF155E75,
  0xFF6B21A8,
];

/// Stable color from the subject name so Englisch and Mathe never share a tint.
int colorForSubject(String subject) {
  final key = subject.trim().toLowerCase();
  if (key.isEmpty) return kDefaultLessonColor;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = 0x1fffffff & (hash * 31 + unit);
  }
  return kSubjectPalette[hash % kSubjectPalette.length];
}

int displayLessonColor(TimetableLesson lesson) {
  if (lesson.folderId != null) return lesson.colorValue;
  if (lesson.subject.trim().isEmpty) return lesson.colorValue;
  return colorForSubject(lesson.subject);
}

/// One subject filling (full block or one half of a split block).
class TimetableLesson extends Equatable {
  const TimetableLesson({
    this.subject = '',
    this.room = '',
    this.folderId,
    this.colorValue = kDefaultLessonColor,
  });

  final String subject;
  final String room;
  final String? folderId;
  final int colorValue;

  bool get isEmpty => subject.trim().isEmpty && (folderId == null);

  TimetableLesson copyWith({
    String? subject,
    String? room,
    String? folderId,
    int? colorValue,
    bool clearFolder = false,
  }) {
    return TimetableLesson(
      subject: subject ?? this.subject,
      room: room ?? this.room,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'room': room,
    'folderId': folderId,
    'color': colorValue,
  };

  factory TimetableLesson.fromJson(Map<String, dynamic> json) {
    return TimetableLesson(
      subject: json['subject'] as String? ?? '',
      room: json['room'] as String? ?? '',
      folderId: json['folderId'] as String?,
      colorValue: json['color'] as int? ?? kDefaultLessonColor,
    );
  }

  @override
  List<Object?> get props => [subject, room, folderId, colorValue];
}

/// Cell for one day × block. Can be a single lesson or a split 45/45 block.
class TimetableSlot extends Equatable {
  const TimetableSlot({
    required this.day,
    required this.period,
    this.split = false,
    this.first = const TimetableLesson(),
    this.second = const TimetableLesson(),
  });

  /// 0 = Monday … 4 = Friday
  final int day;
  final int period;
  final bool split;
  final TimetableLesson first;
  final TimetableLesson second;

  bool get isEmpty => first.isEmpty && (!split || second.isEmpty);

  /// Display name for the whole cell (joined if split).
  String get displayLabel {
    if (!split) return first.subject;
    final a = first.subject.trim();
    final b = second.subject.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a / $b';
  }

  TimetableSlot copyWith({
    bool? split,
    TimetableLesson? first,
    TimetableLesson? second,
  }) {
    return TimetableSlot(
      day: day,
      period: period,
      split: split ?? this.split,
      first: first ?? this.first,
      second: second ?? this.second,
    );
  }

  Map<String, dynamic> toJson() => {
    'day': day,
    'period': period,
    'split': split,
    'first': first.toJson(),
    'second': second.toJson(),
    // legacy fields for older readers
    'subject': first.subject,
    'room': first.room,
    'color': first.colorValue,
  };

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    if (json['first'] is Map) {
      return TimetableSlot(
        day: (json['day'] as num?)?.toInt() ?? 0,
        period: (json['period'] as num?)?.toInt() ?? 0,
        split: json['split'] as bool? ?? false,
        first: TimetableLesson.fromJson(
          Map<String, dynamic>.from(json['first'] as Map),
        ),
        second: json['second'] is Map
            ? TimetableLesson.fromJson(
                Map<String, dynamic>.from(json['second'] as Map),
              )
            : const TimetableLesson(),
      );
    }
    // Migrate v1 flat slots.
    return TimetableSlot(
      day: (json['day'] as num?)?.toInt() ?? 0,
      period: (json['period'] as num?)?.toInt() ?? 0,
      split: false,
      first: TimetableLesson(
        subject: json['subject'] as String? ?? '',
        room: json['room'] as String? ?? '',
        colorValue: json['color'] as int? ?? kDefaultLessonColor,
      ),
    );
  }

  @override
  List<Object?> get props => [day, period, split, first, second];
}

class TimetablePeriod extends Equatable {
  const TimetablePeriod({
    required this.label,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String label;
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => (endMinutes - startMinutes).clamp(0, 24 * 60);

  String get start => formatHm(startMinutes);
  String get end => formatHm(endMinutes);
  String get timeRange => '$start–$end';

  bool containsMinuteOfDay(int minuteOfDay) =>
      minuteOfDay >= startMinutes && minuteOfDay < endMinutes;

  /// Midpoint for split blocks (first half / second half).
  int get splitAtMinutes => startMinutes + (durationMinutes ~/ 2);

  TimetablePeriod copyWith({
    String? label,
    int? startMinutes,
    int? endMinutes,
  }) {
    return TimetablePeriod(
      label: label ?? this.label,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'start': start,
    'end': end,
  };

  factory TimetablePeriod.fromJson(Map<String, dynamic> json) {
    if (json['startMinutes'] != null && json['endMinutes'] != null) {
      return TimetablePeriod(
        label: json['label'] as String? ?? '',
        startMinutes: (json['startMinutes'] as num).toInt(),
        endMinutes: (json['endMinutes'] as num).toInt(),
      );
    }
    return TimetablePeriod(
      label: json['label'] as String? ?? '',
      startMinutes: parseHm(json['start'] as String? ?? '08:00'),
      endMinutes: parseHm(json['end'] as String? ?? '09:30'),
    );
  }

  @override
  List<Object?> get props => [label, startMinutes, endMinutes];
}

class NowLesson extends Equatable {
  const NowLesson({
    required this.lesson,
    required this.day,
    required this.period,
    required this.half,
    required this.periodLabel,
    required this.timeRange,
  });

  final TimetableLesson lesson;
  final int day;
  final int period;

  /// 0 = first half / full, 1 = second half of split.
  final int half;
  final String periodLabel;
  final String timeRange;

  @override
  List<Object?> get props => [
    lesson,
    day,
    period,
    half,
    periodLabel,
    timeRange,
  ];
}

class Timetable extends Equatable {
  const Timetable({
    required this.id,
    required this.title,
    required this.periods,
    required this.slots,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<TimetablePeriod> periods;
  final List<TimetableSlot> slots;
  final DateTime updatedAt;

  static const dayCount = 5;

  TimetableSlot? slotAt(int day, int period) {
    for (final s in slots) {
      if (s.day == day && s.period == period) return s;
    }
    return null;
  }

  /// Timetable day index 0=Mon … 4=Fri from a calendar [DateTime.weekday].
  static int? dayIndexFromWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.friday) return null;
    return weekday - DateTime.monday;
  }

  /// Distinct non-empty lessons (by subject name), optionally for one day index.
  List<TimetableLesson> distinctLessons({int? day}) {
    final seen = <String>{};
    final out = <TimetableLesson>[];
    for (final slot in slots) {
      if (day != null && slot.day != day) continue;
      if (slot.isEmpty) continue;
      void add(TimetableLesson lesson) {
        if (lesson.isEmpty) return;
        final key = lesson.subject.trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) return;
        out.add(lesson);
      }

      add(slot.first);
      if (slot.split) add(slot.second);
    }
    out.sort(
      (a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
    );
    return out;
  }

  List<String> distinctSubjectNames({int? day}) => [
    for (final l in distinctLessons(day: day)) l.subject.trim(),
  ];

  Timetable upsertSlot(TimetableSlot slot) {
    final next = [
      for (final s in slots)
        if (!(s.day == slot.day && s.period == slot.period)) s,
    ];
    if (!slot.isEmpty) next.add(slot);
    return copyWith(slots: next, updatedAt: DateTime.now());
  }

  /// Active lesson for [now] (local time), or null if free / weekend.
  NowLesson? lessonAt(DateTime now) {
    final weekday = now.weekday; // 1=Mon … 7=Sun
    if (weekday < 1 || weekday > 5) return null;
    final day = weekday - 1;
    final minuteOfDay = now.hour * 60 + now.minute;

    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      if (!period.containsMinuteOfDay(minuteOfDay)) continue;
      final slot = slotAt(day, p);
      if (slot == null || slot.isEmpty) return null;

      if (slot.split) {
        final half = minuteOfDay < period.splitAtMinutes ? 0 : 1;
        final lesson = half == 0 ? slot.first : slot.second;
        if (lesson.isEmpty) return null;
        final range = half == 0
            ? '${period.start}–${formatHm(period.splitAtMinutes)}'
            : '${formatHm(period.splitAtMinutes)}–${period.end}';
        return NowLesson(
          lesson: lesson,
          day: day,
          period: p,
          half: half,
          periodLabel: period.label,
          timeRange: range,
        );
      }

      if (slot.first.isEmpty) return null;
      return NowLesson(
        lesson: slot.first,
        day: day,
        period: p,
        half: 0,
        periodLabel: period.label,
        timeRange: period.timeRange,
      );
    }
    return null;
  }

  Timetable copyWith({
    String? title,
    List<TimetablePeriod>? periods,
    List<TimetableSlot>? slots,
    DateTime? updatedAt,
  }) {
    return Timetable(
      id: id,
      title: title ?? this.title,
      periods: periods ?? this.periods,
      slots: slots ?? this.slots,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'version': 2,
    'periods': periods.map((p) => p.toJson()).toList(),
    'slots': slots.map((s) => s.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Stundenplan',
      periods: [
        for (final p in (json['periods'] as List? ?? const []))
          TimetablePeriod.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
      slots: [
        for (final s in (json['slots'] as List? ?? const []))
          TimetableSlot.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Default school day as 90-minute blocks.
  factory Timetable.empty({String title = 'Stundenplan'}) {
    return Timetable(
      id: const Uuid().v4(),
      title: title,
      periods: const [
        TimetablePeriod(
          label: '1',
          startMinutes: 7 * 60 + 30,
          endMinutes: 9 * 60,
        ),
        TimetablePeriod(
          label: '2',
          startMinutes: 9 * 60 + 15,
          endMinutes: 10 * 60 + 45,
        ),
        TimetablePeriod(
          label: '3',
          startMinutes: 11 * 60,
          endMinutes: 12 * 60 + 30,
        ),
        TimetablePeriod(
          label: '4',
          startMinutes: 13 * 60 + 15,
          endMinutes: 14 * 60 + 45,
        ),
        TimetablePeriod(
          label: '5',
          startMinutes: 15 * 60,
          endMinutes: 16 * 60 + 30,
        ),
      ],
      slots: const [],
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, title, periods, slots, updatedAt];
}

class TimetableNotifier extends StateNotifier<Timetable> {
  TimetableNotifier(this._prefs) : super(Timetable.empty()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'timetableV2';
  static const _legacyKey = 'timetableV1';

  void _load() {
    try {
      final raw = _prefs.getString(_key) ?? _prefs.getString(_legacyKey);
      if (raw == null || raw.isEmpty) return;
      state = Timetable.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setTitle(String title) async {
    state = state.copyWith(title: title, updatedAt: DateTime.now());
    await _save();
  }

  Future<void> setSlot(TimetableSlot slot) async {
    state = state.upsertSlot(slot);
    await _save();
  }

  Future<void> clearSlot(int day, int period) async {
    state = state.copyWith(
      slots: [
        for (final s in state.slots)
          if (!(s.day == day && s.period == period)) s,
      ],
      updatedAt: DateTime.now(),
    );
    await _save();
  }

  Future<void> setPeriod(int index, TimetablePeriod period) async {
    if (index < 0 || index >= state.periods.length) return;
    var start = period.startMinutes;
    var end = period.endMinutes;
    if (end <= start) end = start + 90;
    final next = [...state.periods];
    next[index] = period.copyWith(startMinutes: start, endMinutes: end);
    state = state.copyWith(periods: next, updatedAt: DateTime.now());
    await _save();
  }

  Future<void> addPeriod({int durationMinutes = 90}) async {
    final n = state.periods.length + 1;
    final lastEnd = state.periods.isEmpty
        ? 7 * 60 + 30
        : state.periods.last.endMinutes + 15;
    state = state.copyWith(
      periods: [
        ...state.periods,
        TimetablePeriod(
          label: '$n',
          startMinutes: lastEnd,
          endMinutes: lastEnd + durationMinutes,
        ),
      ],
      updatedAt: DateTime.now(),
    );
    await _save();
  }

  Future<void> removeLastPeriod() async {
    if (state.periods.length <= 1) return;
    final last = state.periods.length - 1;
    state = state.copyWith(
      periods: state.periods.sublist(0, last),
      slots: [
        for (final s in state.slots)
          if (s.period < last) s,
      ],
      updatedAt: DateTime.now(),
    );
    await _save();
  }
}

final timetableProvider = StateNotifierProvider<TimetableNotifier, Timetable>((
  ref,
) {
  return TimetableNotifier(ref.watch(sharedPreferencesProvider));
});

/// Ticks every minute so the "now" banner stays accurate.
final _clockTickProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  ).asBroadcastStream();
});

final nowLessonProvider = Provider<NowLesson?>((ref) {
  ref.watch(_clockTickProvider);
  return ref.watch(timetableProvider).lessonAt(DateTime.now());
});

TimetableLesson lessonFromFolder(LibraryFolder folder) {
  return TimetableLesson(
    subject: folder.name,
    folderId: folder.id,
    colorValue: folder.colorValue,
  );
}
