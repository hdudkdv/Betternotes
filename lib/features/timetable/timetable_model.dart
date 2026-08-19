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
    this.schoolClass = '',
    this.folderId,
    this.colorValue = kDefaultLessonColor,
  });

  final String subject;
  final String room;
  final String schoolClass;
  final String? folderId;
  final int colorValue;

  bool get isEmpty => subject.trim().isEmpty && (folderId == null);

  TimetableLesson copyWith({
    String? subject,
    String? room,
    String? schoolClass,
    String? folderId,
    int? colorValue,
    bool clearFolder = false,
  }) {
    return TimetableLesson(
      subject: subject ?? this.subject,
      room: room ?? this.room,
      schoolClass: schoolClass ?? this.schoolClass,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'room': room,
    'schoolClass': schoolClass,
    'folderId': folderId,
    'color': colorValue,
  };

  factory TimetableLesson.fromJson(Map<String, dynamic> json) {
    return TimetableLesson(
      subject: json['subject'] as String? ?? '',
      room: json['room'] as String? ?? '',
      schoolClass: json['schoolClass'] as String? ?? '',
      folderId: json['folderId'] as String?,
      colorValue: json['color'] as int? ?? kDefaultLessonColor,
    );
  }

  @override
  List<Object?> get props => [subject, room, schoolClass, folderId, colorValue];
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
    this.schoolClass = '',
    required this.periods,
    required this.slots,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// Named class this plan belongs to (teachers). Empty for a shared/student plan.
  final String schoolClass;
  final List<TimetablePeriod> periods;
  final List<TimetableSlot> slots;
  final DateTime updatedAt;

  String get classLabel => schoolClass.trim();
  bool get hasClass => classLabel.isNotEmpty;

  /// Class names written on lesson cells (teacher grid).
  List<String> distinctClassNames() {
    final names = <String>{};
    void consider(TimetableLesson lesson) {
      final name = lesson.schoolClass.trim();
      if (name.isNotEmpty) names.add(name);
    }

    for (final slot in slots) {
      consider(slot.first);
      if (slot.split) consider(slot.second);
    }
    final out = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

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
    String? schoolClass,
    List<TimetablePeriod>? periods,
    List<TimetableSlot>? slots,
    DateTime? updatedAt,
  }) {
    return Timetable(
      id: id,
      title: title ?? this.title,
      schoolClass: schoolClass ?? this.schoolClass,
      periods: periods ?? this.periods,
      slots: slots ?? this.slots,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'schoolClass': schoolClass,
    'version': 2,
    'periods': periods.map((p) => p.toJson()).toList(),
    'slots': slots.map((s) => s.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Stundenplan',
      schoolClass: json['schoolClass'] as String? ?? '',
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
  factory Timetable.empty({
    String title = 'Stundenplan',
    String schoolClass = '',
    List<TimetablePeriod>? periods,
  }) {
    return Timetable(
      id: const Uuid().v4(),
      title: title,
      schoolClass: schoolClass,
      periods: periods ??
          const [
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

  Timetable stampedWithClass() {
    final cls = classLabel;
    if (cls.isEmpty) return this;
    return copyWith(
      slots: [
        for (final slot in slots) stampSlotWithClass(slot, cls),
      ],
    );
  }

  @override
  List<Object?> get props => [id, title, schoolClass, periods, slots, updatedAt];
}

TimetableSlot stampSlotWithClass(TimetableSlot slot, String schoolClass) {
  final cls = schoolClass.trim();
  if (cls.isEmpty) return slot;
  TimetableLesson stamp(TimetableLesson lesson) {
    if (lesson.isEmpty) return lesson;
    return lesson.copyWith(schoolClass: cls);
  }

  return slot.copyWith(first: stamp(slot.first), second: stamp(slot.second));
}

TimetableSlot mergeLessonSlots(TimetableSlot a, TimetableSlot b) {
  final lessons = <TimetableLesson>[];
  void add(TimetableLesson lesson) {
    if (lesson.isEmpty) return;
    final key =
        '${lesson.schoolClass.trim().toLowerCase()}|${lesson.subject.trim().toLowerCase()}';
    if (lessons.any(
      (item) =>
          '${item.schoolClass.trim().toLowerCase()}|${item.subject.trim().toLowerCase()}' ==
          key,
    )) {
      return;
    }
    lessons.add(lesson);
  }

  add(a.first);
  if (a.split) add(a.second);
  add(b.first);
  if (b.split) add(b.second);
  if (lessons.isEmpty) {
    return TimetableSlot(day: a.day, period: a.period);
  }
  if (lessons.length == 1) {
    return TimetableSlot(day: a.day, period: a.period, first: lessons.first);
  }
  return TimetableSlot(
    day: a.day,
    period: a.period,
    split: true,
    first: lessons[0],
    second: lessons[1],
  );
}

/// One teacher grid: class lives on the lesson cell, not as a separate plan.
Timetable mergeClassPlans(List<Timetable> tables) {
  if (tables.isEmpty) return Timetable.empty();
  var periods = tables.first.periods;
  for (final table in tables) {
    if (table.periods.length > periods.length) periods = table.periods;
  }
  final slots = <String, TimetableSlot>{};
  for (final table in tables) {
    for (final raw in table.slots) {
      if (raw.isEmpty) continue;
      final slot = table.hasClass
          ? stampSlotWithClass(raw, table.classLabel)
          : raw;
      final key = '${slot.day}-${slot.period}';
      final existing = slots[key];
      slots[key] = existing == null ? slot : mergeLessonSlots(existing, slot);
    }
  }
  final first = tables.first;
  final title = tables.length == 1 &&
          !(first.hasClass && first.title.trim() == first.classLabel)
      ? first.title
      : 'Stundenplan';
  return Timetable(
    id: first.id,
    title: title,
    periods: periods,
    slots: slots.values.toList(),
    updatedAt: first.updatedAt,
  );
}

class TimetableNotifier extends StateNotifier<Timetable> {
  TimetableNotifier(this._prefs) : super(Timetable.empty()) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'timetableV2';
  static const _legacyKey = 'timetableV1';

  List<Timetable> _tables = [];

  List<Timetable> get allTables => List.unmodifiable(_tables);

  List<Timetable> get classPlans {
    final named = [
      for (final table in _tables)
        if (table.hasClass) table,
    ];
    named.sort(
      (a, b) => a.classLabel.toLowerCase().compareTo(b.classLabel.toLowerCase()),
    );
    return named;
  }

  Timetable? tableForClass(String schoolClass) {
    final key = schoolClass.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final table in _tables) {
      if (table.classLabel.toLowerCase() == key) return table;
    }
    return null;
  }

  void _load() {
    try {
      final raw = _prefs.getString(_key) ?? _prefs.getString(_legacyKey);
      if (raw == null || raw.isEmpty) {
        _tables = [state];
        return;
      }
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final tablesJson = json['tables'];
      final loaded = <Timetable>[];
      if (tablesJson is List && tablesJson.isNotEmpty) {
        for (final item in tablesJson) {
          loaded.add(
            Timetable.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }
      } else {
        loaded.add(Timetable.fromJson(json));
      }
      final merged = mergeClassPlans(loaded);
      _tables = [merged];
      state = merged;
      if (loaded.length > 1 || loaded.any((table) => table.hasClass)) {
        _save();
      }
    } catch (_) {
      _tables = [state];
    }
  }

  Future<void> _save() async {
    _syncActiveIntoTables(state);
    if (_tables.length <= 1) {
      await _prefs.setString(_key, jsonEncode(state.toJson()));
      return;
    }
    await _prefs.setString(
      _key,
      jsonEncode({
        'version': 3,
        'activeId': state.id,
        'tables': [for (final table in _tables) table.toJson()],
      }),
    );
  }

  void _syncActiveIntoTables(Timetable next) {
    var found = false;
    final nextTables = <Timetable>[];
    for (final table in _tables) {
      if (table.id == next.id) {
        nextTables.add(next);
        found = true;
      } else {
        nextTables.add(table);
      }
    }
    if (!found) nextTables.add(next);
    _tables = nextTables;
  }

  Future<void> _commit(Timetable next) async {
    _syncActiveIntoTables(next);
    state = next;
    await _save();
  }

  Future<void> selectTable(String id) async {
    for (final table in _tables) {
      if (table.id == id) {
        state = table;
        await _save();
        return;
      }
    }
  }

  Future<void> addClassPlan(
    String className, {
    bool copySlots = false,
  }) async {
    final name = className.trim();
    if (name.isEmpty) return;
    final existing = tableForClass(name);
    if (existing != null) {
      await selectTable(existing.id);
      return;
    }
    if (_tables.length == 1 && !state.hasClass) {
      await _commit(
        state.copyWith(
          schoolClass: name,
          title: name,
          updatedAt: DateTime.now(),
        ).stampedWithClass(),
      );
      return;
    }
    final created = Timetable.empty(
      title: name,
      schoolClass: name,
      periods: state.periods,
    ).copyWith(
      slots: copySlots
          ? [
              for (final slot in state.slots)
                stampSlotWithClass(slot, name),
            ]
          : const [],
      updatedAt: DateTime.now(),
    );
    _tables = [..._tables, created];
    state = created;
    await _save();
  }

  Future<void> deleteClassPlan(String id) async {
    if (_tables.length <= 1) return;
    _tables = [for (final table in _tables) if (table.id != id) table];
    if (state.id == id) {
      state = _tables.first;
    } else {
      state = state.copyWith(updatedAt: DateTime.now());
    }
    await _save();
  }

  Future<void> setTitle(String title) async {
    await _commit(state.copyWith(title: title, updatedAt: DateTime.now()));
  }

  Future<void> setSlot(TimetableSlot slot) async {
    await _commit(state.upsertSlot(slot));
  }

  Future<void> clearSlot(int day, int period) async {
    await _commit(
      state.copyWith(
        slots: [
          for (final s in state.slots)
            if (!(s.day == day && s.period == period)) s,
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setPeriod(int index, TimetablePeriod period) async {
    if (index < 0 || index >= state.periods.length) return;
    var start = period.startMinutes;
    var end = period.endMinutes;
    if (end <= start) end = start + 90;
    final next = [...state.periods];
    next[index] = period.copyWith(startMinutes: start, endMinutes: end);
    await _commit(state.copyWith(periods: next, updatedAt: DateTime.now()));
  }

  Future<void> addPeriod({int durationMinutes = 90}) async {
    final n = state.periods.length + 1;
    final lastEnd = state.periods.isEmpty
        ? 7 * 60 + 30
        : state.periods.last.endMinutes + 15;
    await _commit(
      state.copyWith(
        periods: [
          ...state.periods,
          TimetablePeriod(
            label: '$n',
            startMinutes: lastEnd,
            endMinutes: lastEnd + durationMinutes,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeLastPeriod() async {
    if (state.periods.length <= 1) return;
    final last = state.periods.length - 1;
    await _commit(
      state.copyWith(
        periods: state.periods.sublist(0, last),
        slots: [
          for (final s in state.slots)
            if (s.period < last) s,
        ],
        updatedAt: DateTime.now(),
      ),
    );
  }
}

final timetableProvider = StateNotifierProvider<TimetableNotifier, Timetable>((
  ref,
) {
  return TimetableNotifier(ref.watch(sharedPreferencesProvider));
});

final timetableCatalogProvider = Provider<List<Timetable>>((ref) {
  ref.watch(timetableProvider);
  return ref.read(timetableProvider.notifier).allTables;
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

/// Class taught in the current period, or null between lessons / weekends.
final currentLessonClassProvider = Provider<String?>((ref) {
  final name = ref.watch(nowLessonProvider)?.lesson.schoolClass.trim();
  if (name == null || name.isEmpty) return null;
  return name;
});

TimetableLesson lessonFromFolder(LibraryFolder folder) {
  return TimetableLesson(
    subject: folder.name,
    folderId: folder.id,
    colorValue: folder.colorValue,
  );
}

/// Reuse a library folder that already has this subject name.
LibraryFolder? folderMatchingSubject(
  List<LibraryFolder> folders,
  String subject,
) {
  final key = subject.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final folder in folders) {
    if (folder.name.trim().toLowerCase() == key) return folder;
  }
  return null;
}
