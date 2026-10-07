import 'timetable_model.dart';

/// One piece of text on a timetable page. [top] grows downward.
class TimetableTextToken {
  const TimetableTextToken({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  double get cx => left + width / 2;
  double get cy => top + height / 2;
  double get right => left + width;
  double get bottom => top + height;
}

class ImportedTimetable {
  const ImportedTimetable({
    required this.title,
    required this.slots,
  });

  final String title;
  final List<TimetableSlot> slots;

  int get lessonCount {
    var n = 0;
    for (final slot in slots) {
      if (!slot.first.isEmpty) n++;
      if (slot.split && !slot.second.isEmpty) n++;
    }
    return n;
  }
}

class _DraftLesson {
  const _DraftLesson({
    required this.day,
    required this.period,
    required this.subject,
    required this.room,
    required this.week,
    required this.startMinutes,
    required this.endMinutes,
    this.hourKind = TimetableHourKind.none,
    this.professor = '',
  });

  final int day;
  final int period;
  final String subject;
  final String room;
  final TimetableWeek week;
  final int startMinutes;
  final int endMinutes;
  final TimetableHourKind hourKind;
  final String professor;

  String get identity =>
      '$day|$period|${subject.trim().toLowerCase()}|${hourKind.name}|${room.trim().toLowerCase()}|${professor.trim().toLowerCase()}';
}

/// Parses OPAL / HTW-style semester PDFs (and similar campus grids).
class TimetablePdfParser {
  static final _timeRange = RegExp(
    r'(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})',
  );
  static final _clock = RegExp(r'^(\d{1,2})[:.](\d{2})$');
  static final _dayNames = <RegExp, int>{
    RegExp(r'^montag$|^mo$|^mon$', caseSensitive: false): 0,
    RegExp(r'^dienstag$|^di$|^die$|^tue$', caseSensitive: false): 1,
    RegExp(r'^mittwoch$|^mi$|^mit$|^wed$', caseSensitive: false): 2,
    RegExp(r'^donnerstag$|^do$|^don$|^thu$', caseSensitive: false): 3,
    RegExp(r'^freitag$|^fr$|^fre$|^fri$', caseSensitive: false): 4,
  };
  static final _noise = RegExp(
    r'^(opal|onlineopal|online|seite|page|stundenplan|erstellt|'
    r'wintersemester|sommersemester|semester|kw)\b',
    caseSensitive: false,
  );
  static final _roomLine = RegExp(
    r'^([A-ZÄÖÜ]\s?\d{2,4}[a-zA-Z]?)\s*[-–—]\s*(.+)$',
  );
  static final _roomOnly = RegExp(r'^[A-ZÄÖÜ]\s?\d{2,4}[a-zA-Z]?$');

  static ImportedTimetable parsePages(List<List<TimetableTextToken>> pages) {
    final drafts = <_DraftLesson>[];
    var title = '';
    for (final page in pages) {
      final parsed = _parsePage(mergeLineFragments(page));
      if (title.isEmpty && parsed.title.isNotEmpty) title = parsed.title;
      drafts.addAll(parsed.lessons);
    }
    return ImportedTimetable(title: title, slots: _merge(drafts));
  }

  /// Joins character/word fragments that sit on one line.
  static List<TimetableTextToken> mergeLineFragments(
    List<TimetableTextToken> tokens,
  ) {
    if (tokens.length < 2) return tokens;
    final sorted = [...tokens]..sort((a, b) {
      final y = a.cy.compareTo(b.cy);
      if (y != 0) return y;
      return a.left.compareTo(b.left);
    });
    final merged = <TimetableTextToken>[];
    var current = sorted.first;
    for (final next in sorted.skip(1)) {
      final sameLine = (next.cy - current.cy).abs() <= 6;
      final gap = next.left - current.right;
      if (sameLine && gap >= -2 && gap <= 10) {
        current = TimetableTextToken(
          text: '${current.text}${gap > 2.2 ? ' ' : ''}${next.text}',
          left: current.left,
          top: current.top < next.top ? current.top : next.top,
          width: next.right - current.left,
          height: current.height > next.height ? current.height : next.height,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }

  static ImportedTimetable parsePlainText(String text) {
    return parsePages([_tokensFromPlainText(text)]);
  }

  /// OPAL suffixes: V = lecture, S = seminar, Ü = exercise, Pr = lab.
  static TimetableHourKind hourKindFromText(String raw) {
    final folded = raw.toLowerCase();
    if (folded.contains('praktik')) return TimetableHourKind.practical;
    if (folded.contains('seminar')) return TimetableHourKind.seminar;
    if (folded.contains('vorles')) return TimetableHourKind.lecture;
    if (folded.contains('übung') || folded.contains('uebung')) {
      return TimetableHourKind.exercise;
    }
    final matches = RegExp(
      r'(?:^|[\s])(pr|ü|ue|v|s)(\d*)(?:/[A-Za-z0-9+]|$)',
      caseSensitive: false,
    ).allMatches(raw);
    if (matches.isEmpty) return TimetableHourKind.none;
    switch (matches.last.group(1)!.toLowerCase()) {
      case 'pr':
        return TimetableHourKind.practical;
      case 'ü':
      case 'ue':
        return TimetableHourKind.exercise;
      case 's':
        return TimetableHourKind.seminar;
      case 'v':
        return TimetableHourKind.lecture;
      default:
        return TimetableHourKind.none;
    }
  }

  static String tidySubject(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.startsWith('o') && s.length > 2 && RegExp(r'^o[A-Z]').hasMatch(s)) {
      s = s.substring(1);
    }
    s = s.replaceFirst(RegExp(r'\s*/[A-Z0-9+üÜ]+$'), '');
    s = s.replaceFirst(RegExp(r'(?<=[VÜüPpr]{1,3})\d+$'), '');
    return s.trim();
  }

  static TimetableWeek? weekFromText(String raw) {
    final t = _fold(raw);
    if (t.contains('wochentlich') ||
        t.contains('woechentlich') ||
        t.contains('weekly') ||
        t.contains('jede woche')) {
      return TimetableWeek.both;
    }
    if (t.contains('ungerade')) return TimetableWeek.a;
    if (t.contains('gerade')) return TimetableWeek.b;
    return null;
  }

  static ({String room, String lecturer}) splitRoomLecturer(String raw) {
    final line = raw.trim();
    final match = _roomLine.firstMatch(line);
    if (match != null) {
      return (
        room: match.group(1)!.replaceAll(' ', ''),
        lecturer: match.group(2)!.trim(),
      );
    }
    if (_roomOnly.hasMatch(line)) {
      return (room: line.replaceAll(' ', ''), lecturer: '');
    }
    return (room: '', lecturer: line);
  }

  static int periodIndexFor(int start, int end, List<TimetablePeriod> periods) {
    var best = 0;
    var bestScore = 1 << 30;
    for (var i = 0; i < periods.length; i++) {
      final score =
          (periods[i].startMinutes - start).abs() +
          (periods[i].endMinutes - end).abs();
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  static ({String title, List<_DraftLesson> lessons}) _parsePage(
    List<TimetableTextToken> raw,
  ) {
    final tokens = [
      for (final token in raw)
        if (token.text.trim().isNotEmpty) token,
    ];
    if (tokens.isEmpty) {
      return (title: '', lessons: const <_DraftLesson>[]);
    }

    final title = _titleFrom(tokens);
    final pageWeek = _pageWeek(tokens);
    final days = _dayColumns(tokens);
    final periods = _timeRows(tokens, days);
    if (days.isEmpty || periods.isEmpty) {
      return (title: title, lessons: const <_DraftLesson>[]);
    }

    final used = <TimetableTextToken>{
      ...days.map((d) => d.token),
      for (final row in periods) ...row.tokens,
    };
    final leftover = [
      for (final token in tokens)
        if (!used.contains(token) && !_isNoise(token.text)) token,
    ];

    final buckets = <String, List<TimetableTextToken>>{};
    for (final token in leftover) {
      final day = _nearestDay(token.cx, days);
      final period = _periodAt(token.cy, periods);
      if (day == null || period == null) continue;
      buckets.putIfAbsent('$day|${period.index}', () => []).add(token);
    }

    final lessons = <_DraftLesson>[];
    for (final entry in buckets.entries) {
      final parts = entry.key.split('|');
      final day = int.parse(parts[0]);
      final periodIndex = int.parse(parts[1]);
      final row = periods[periodIndex];
      for (final block in _splitCellLessons(entry.value)) {
        final parsed = _lessonFromLines(block, fallbackWeek: pageWeek);
        if (parsed == null) continue;
        lessons.add(
          _DraftLesson(
            day: day,
            period: row.periodIndex,
            subject: parsed.subject,
            room: parsed.room,
            week: parsed.week,
            startMinutes: row.start,
            endMinutes: row.end,
            hourKind: parsed.hourKind,
            professor: parsed.professor,
          ),
        );
      }
    }
    return (title: title, lessons: lessons);
  }

  static List<TimetableSlot> _merge(List<_DraftLesson> drafts) {
    if (drafts.isEmpty) return const [];
    final weeksById = <String, Set<TimetableWeek>>{};
    final firstById = <String, _DraftLesson>{};
    for (final draft in drafts) {
      firstById.putIfAbsent(draft.identity, () => draft);
      weeksById.putIfAbsent(draft.identity, () => <TimetableWeek>{}).add(draft.week);
    }

    final byCell = <String, List<_DraftLesson>>{};
    for (final draft in firstById.values) {
      final weeks = weeksById[draft.identity]!;
      final week = weeks.contains(TimetableWeek.both) ||
              (weeks.contains(TimetableWeek.a) && weeks.contains(TimetableWeek.b))
          ? TimetableWeek.both
          : weeks.single;
      final merged = _DraftLesson(
        day: draft.day,
        period: draft.period,
        subject: draft.subject,
        room: draft.room,
        week: week,
        startMinutes: draft.startMinutes,
        endMinutes: draft.endMinutes,
        hourKind: draft.hourKind,
        professor: draft.professor,
      );
      byCell.putIfAbsent('${draft.day}|${draft.period}|${week.name}', () => []).add(merged);
    }

    final slots = <TimetableSlot>[];
    for (final group in byCell.values) {
      final first = group.first;
      final second = group.length > 1 ? group[1] : null;
      slots.add(
        TimetableSlot(
          day: first.day,
          period: first.period,
          week: first.week,
          startMinutes: first.startMinutes,
          endMinutes: first.endMinutes,
          split: second != null,
          first: TimetableLesson(
            subject: first.subject,
            room: first.room,
            colorValue: colorForSubject(first.subject),
            hourKind: first.hourKind,
            professor: first.professor,
          ),
          second: second == null
              ? const TimetableLesson()
              : TimetableLesson(
                  subject: second.subject,
                  room: second.room,
                  colorValue: colorForSubject(second.subject),
                  hourKind: second.hourKind,
                  professor: second.professor,
                ),
        ),
      );
    }
    slots.sort((a, b) {
      final day = a.day.compareTo(b.day);
      if (day != 0) return day;
      final period = a.period.compareTo(b.period);
      if (period != 0) return period;
      return a.week.index.compareTo(b.week.index);
    });
    return slots;
  }

  static String _titleFrom(List<TimetableTextToken> tokens) {
    final joined = tokens.map((t) => t.text.trim()).join(' ');
    final quoted = RegExp(r'"([^"]{3,80})"').firstMatch(joined);
    if (quoted != null) return quoted.group(1)!.trim();
    for (final token in tokens.take(12)) {
      final text = token.text.trim();
      if (text.length >= 8 &&
          !_timeRange.hasMatch(text) &&
          weekFromText(text) == null &&
          !_isDay(text) &&
          !_isNoise(text)) {
        return text
            .replaceFirst(RegExp(r'^Stundenplan\s+(für|fuer|for)\s+', caseSensitive: false), '')
            .trim();
      }
    }
    return '';
  }

  static TimetableWeek _pageWeek(List<TimetableTextToken> tokens) {
    final minTop = tokens.map((t) => t.top).reduce((a, b) => a < b ? a : b);
    final headerBottom = minTop + 70;
    for (final token in tokens) {
      if (token.top > headerBottom) continue;
      final week = weekFromText(token.text);
      if (week != null) return week;
    }
    return TimetableWeek.both;
  }

  static List<({int index, double cx, TimetableTextToken token})> _dayColumns(
    List<TimetableTextToken> tokens,
  ) {
    final found = <({int index, double cx, TimetableTextToken token})>[];
    for (final token in tokens) {
      final day = _dayIndex(token.text);
      if (day == null) continue;
      if (found.any((item) => item.index == day)) continue;
      found.add((index: day, cx: token.cx, token: token));
    }
    found.sort((a, b) => a.cx.compareTo(b.cx));
    return found;
  }

  static List<
      ({
        int index,
        int periodIndex,
        int start,
        int end,
        double cy,
        List<TimetableTextToken> tokens,
      })> _timeRows(
    List<TimetableTextToken> tokens,
    List<({int index, double cx, TimetableTextToken token})> days,
  ) {
    final leftBound = days.isEmpty
        ? double.infinity
        : days.map((d) => d.cx).reduce((a, b) => a < b ? a : b) - 40;
    final template = Timetable.universitySemesterPeriods();
    final rows = <({
      int start,
      int end,
      double cy,
      List<TimetableTextToken> tokens,
    })>[];

    for (final token in tokens) {
      if (token.cx > leftBound && days.isNotEmpty) continue;
      final range = _timeRange.firstMatch(token.text.trim());
      if (range == null) continue;
      rows.add((
        start: _hm(range.group(1)!, range.group(2)!),
        end: _hm(range.group(3)!, range.group(4)!),
        cy: token.cy,
        tokens: [token],
      ));
    }

    if (rows.isEmpty) {
      final clocks = [
        for (final token in tokens)
          if ((days.isEmpty || token.cx <= leftBound) &&
              _clock.hasMatch(token.text.trim()))
            token,
      ]..sort((a, b) => a.cy.compareTo(b.cy));
      for (var i = 0; i + 1 < clocks.length; i += 2) {
        final a = _clock.firstMatch(clocks[i].text.trim())!;
        final b = _clock.firstMatch(clocks[i + 1].text.trim())!;
        rows.add((
          start: _hm(a.group(1)!, a.group(2)!),
          end: _hm(b.group(1)!, b.group(2)!),
          cy: (clocks[i].cy + clocks[i + 1].cy) / 2,
          tokens: [clocks[i], clocks[i + 1]],
        ));
      }
    }

    rows.sort((a, b) => a.cy.compareTo(b.cy));
    return [
      for (var i = 0; i < rows.length; i++)
        (
          index: i,
          periodIndex: periodIndexFor(rows[i].start, rows[i].end, template),
          start: rows[i].start,
          end: rows[i].end,
          cy: rows[i].cy,
          tokens: rows[i].tokens,
        ),
    ];
  }

  static int? _nearestDay(
    double x,
    List<({int index, double cx, TimetableTextToken token})> days,
  ) {
    if (days.isEmpty) return null;
    var best = days.first;
    var bestDist = (x - best.cx).abs();
    for (final day in days.skip(1)) {
      final dist = (x - day.cx).abs();
      if (dist < bestDist) {
        best = day;
        bestDist = dist;
      }
    }
    final gap = days.length == 1
        ? 160.0
        : (days.last.cx - days.first.cx) / (days.length - 1);
    if (bestDist > gap * 0.62) return null;
    return best.index;
  }

  static ({int index, int periodIndex, int start, int end, double cy, List<TimetableTextToken> tokens})?
      _periodAt(
    double y,
    List<
            ({
              int index,
              int periodIndex,
              int start,
              int end,
              double cy,
              List<TimetableTextToken> tokens
            })>
        periods,
  ) {
    if (periods.isEmpty) return null;
    var best = periods.first;
    var bestDist = (y - best.cy).abs();
    for (final period in periods.skip(1)) {
      final dist = (y - period.cy).abs();
      if (dist < bestDist) {
        best = period;
        bestDist = dist;
      }
    }
    return best;
  }

  static List<List<String>> _splitCellLessons(List<TimetableTextToken> tokens) {
    final lines = [...tokens]..sort((a, b) {
        final y = a.cy.compareTo(b.cy);
        if (y != 0) return y;
        return a.left.compareTo(b.left);
      });
    final grouped = <List<String>>[];
    var current = <String>[];
    TimetableTextToken? last;
    for (final token in lines) {
      final text = token.text.trim();
      if (text.isEmpty) continue;
      final newBlock = last != null && token.top - last.bottom > 18 && current.length >= 2;
      if (newBlock) {
        grouped.add(current);
        current = <String>[];
      }
      current.add(text);
      last = token;
    }
    if (current.isNotEmpty) grouped.add(current);
    return grouped;
  }

  static ({
    String subject,
    String room,
    String professor,
    TimetableWeek week,
    TimetableHourKind hourKind,
  })?
  _lessonFromLines(
    List<String> lines, {
    required TimetableWeek fallbackWeek,
  }) {
    var week = fallbackWeek;
    var room = '';
    var lecturer = '';
    final subjectParts = <String>[];
    for (final raw in lines) {
      final detected = weekFromText(raw);
      if (detected != null) {
        week = detected;
        continue;
      }
      if (_isNoise(raw) || _isDay(raw) || _timeRange.hasMatch(raw)) continue;
      final split = splitRoomLecturer(raw);
      if (split.room.isNotEmpty) {
        room = split.room;
        if (split.lecturer.isNotEmpty) lecturer = split.lecturer;
        continue;
      }
      if (room.isEmpty && lecturer.isEmpty && subjectParts.isNotEmpty && !_looksLikeCourse(raw)) {
        lecturer = raw;
        continue;
      }
      if (_looksLikeCourse(raw) || subjectParts.isEmpty) {
        subjectParts.add(raw);
      }
    }
    if (subjectParts.isEmpty) return null;
    final joined = subjectParts.join(' ');
    final subject = tidySubject(joined);
    if (subject.isEmpty) return null;
    return (
      subject: subject,
      room: room,
      professor: lecturer,
      week: week,
      hourKind: hourKindFromText(joined),
    );
  }

  static bool _looksLikeCourse(String raw) {
    return RegExp(
      r'^(o)?[A-ZÄÖÜ]\d{2,4}|Gremien|Blockzeit',
      caseSensitive: false,
    ).hasMatch(raw.trim());
  }

  static bool _isNoise(String raw) => _noise.hasMatch(raw.trim());

  static bool _isDay(String raw) => _dayIndex(raw) != null;

  static int? _dayIndex(String raw) {
    final key = _fold(raw);
    for (final entry in _dayNames.entries) {
      if (entry.key.hasMatch(key)) return entry.value;
    }
    return null;
  }

  static int _hm(String h, String m) =>
      (int.parse(h) % 24) * 60 + (int.parse(m) % 60);

  static String _fold(String raw) => raw
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');

  /// Last-resort layout when a PDF only yields reading-order text.
  static List<TimetableTextToken> _tokensFromPlainText(String text) {
    final lines = [
      for (final line in text.replaceAll('\r\n', '\n').split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    final tokens = <TimetableTextToken>[];
    var y = 8.0;
    const dayXs = [160.0, 300.0, 440.0, 580.0, 720.0];
    var dayCursor = 0;
    var seenDays = false;
    var inSlot = false;

    void add(String value, double x, {double width = 110}) {
      tokens.add(
        TimetableTextToken(
          text: value,
          left: x,
          top: y,
          width: width,
          height: 14,
        ),
      );
    }

    for (final line in lines) {
      if (_dayIndex(line) != null) {
        if (!seenDays) {
          add(line, dayXs[_dayIndex(line)!], width: 70);
          if (_dayIndex(line) == 4) seenDays = true;
        } else {
          add(line, 20, width: 90);
        }
        y += 18;
        continue;
      }
      if (_timeRange.hasMatch(line) || _clock.hasMatch(line)) {
        add(line, 18, width: 90);
        y += 22;
        dayCursor = 0;
        inSlot = true;
        continue;
      }
      final week = weekFromText(line);
      if (week != null && !inSlot) {
        add(line, 18, width: 120);
        y += 18;
        continue;
      }
      if (inSlot &&
          (_looksLikeCourse(line) || week != null || _isNoise(line) || splitRoomLecturer(line).room.isNotEmpty)) {
        if (_looksLikeCourse(line)) {
          dayCursor = dayCursor.clamp(0, 4);
        }
        add(line, dayXs[dayCursor.clamp(0, 4)]);
        if (week != null || line.toLowerCase().contains('blockzeit')) {
          dayCursor++;
          y += 28;
        } else {
          y += 16;
        }
        continue;
      }
      add(line, 24, width: 220);
      y += 16;
    }
    return tokens;
  }
}
