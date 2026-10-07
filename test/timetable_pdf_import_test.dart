import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:betternotes/features/timetable/timetable_pdf_parser.dart';
import 'package:flutter_test/flutter_test.dart';

TimetableTextToken _t(
  String text,
  double x,
  double y, {
  double w = 100,
  double h = 12,
}) {
  return TimetableTextToken(text: text, left: x, top: y, width: w, height: h);
}

List<TimetableTextToken> _dayHeader(double y, {required String week}) => [
  _t(week, 16, y, w: 120),
  _t('Montag', 160, y, w: 70),
  _t('Dienstag', 300, y, w: 70),
  _t('Mittwoch', 440, y, w: 70),
  _t('Donnerstag', 580, y, w: 80),
  _t('Freitag', 720, y, w: 70),
];

List<TimetableTextToken> _lesson(
  String subject,
  String room,
  String week,
  double x,
  double y,
) =>
    [
      _t(subject, x, y, w: 118),
      _t('OPAL', x, y + 14, w: 50),
      _t(room, x, y + 28, w: 118),
      _t(week, x, y + 42, w: 90),
    ];

void main() {
  test('tidySubject keeps course code and type', () {
    expect(TimetablePdfParser.tidySubject('I130 BS Pr1/IM2'), 'I130 BS Pr');
    expect(TimetablePdfParser.tidySubject('I382 Mathe V1/IM'), 'I382 Mathe V');
    expect(TimetablePdfParser.tidySubject('oI120 Prog Ü1/IM'), 'I120 Prog Ü');
    expect(TimetablePdfParser.tidySubject('Gremien-Blockzeit'), 'Gremien-Blockzeit');
  });

  test('hourKindFromText reads OPAL suffixes', () {
    expect(
      TimetablePdfParser.hourKindFromText('I382 Mathe V1/IM'),
      TimetableHourKind.lecture,
    );
    expect(
      TimetablePdfParser.hourKindFromText('I130 BS Pr1/IM2'),
      TimetableHourKind.practical,
    );
    expect(
      TimetablePdfParser.hourKindFromText('S413 EnglB2 Ü1/IM2'),
      TimetableHourKind.exercise,
    );
    expect(
      TimetablePdfParser.hourKindFromText('Seminar Softwaretechnik'),
      TimetableHourKind.seminar,
    );
    expect(
      TimetablePdfParser.hourKindFromText('Gremien-Blockzeit'),
      TimetableHourKind.none,
    );
  });

  test('week and room lines parse OPAL cells', () {
    expect(TimetablePdfParser.weekFromText('Ungerade Woche'), TimetableWeek.a);
    expect(TimetablePdfParser.weekFromText('wöchentlich'), TimetableWeek.both);
    expect(TimetablePdfParser.weekFromText('Gerade Woche'), TimetableWeek.b);
    final room = TimetablePdfParser.splitRoomLecturer('U 515 - Baumgartl');
    expect(room.room, 'U515');
    expect(room.lecturer, 'Baumgartl');
  });

  test('positioned OPAL pages fill odd/even and weekly slots', () {
    const mo = 160.0;
    const di = 300.0;
    const mi = 440.0;
    const do_ = 580.0;
    final odd = [
      _t('Stundenplan für "Medieninformatik - Bachelor"', 16, 4, w: 360),
      ..._dayHeader(28, week: 'Ungerade Woche'),
      _t('08:00 - 09:30', 16, 80, w: 90),
      ..._lesson('I382 Mathe V1/IM', 'L 211 - Lange, S.', 'Ungerade Woche', mo, 88),
      _t('09:45 - 11:15', 16, 160, w: 90),
      ..._lesson('I110 GdI V1/IM', 'N 101 - Kühn,S.', 'wöchentlich', di, 168),
      ..._lesson('I130 BS V1/II+IM', 'S 239 - Baumgartl', 'wöchentlich', do_, 168),
      _t('11:30 - 13:00', 16, 250, w: 90),
      ..._lesson('I120 Prog V1/IM', 'N 101 - Bruns', 'wöchentlich', mo, 258),
      ..._lesson('S413 EnglB2 Ü1/IM2', 'S 530 - Camber', 'Ungerade Woche', mi, 258),
      _t('12:00 - 13:30', 16, 340, w: 90),
      ..._lesson('I130 BS Pr1/IM2', 'U 515 - Baumgartl', 'wöchentlich', mo, 348),
    ];
    final even = [
      ..._dayHeader(28, week: 'Gerade Woche'),
      _t('08:00 - 09:30', 16, 80, w: 90),
      ..._lesson('I350 GdG Pr1/IM2', 'U 527 - Kammer', 'Gerade Woche', mo, 88),
      _t('09:45 - 11:15', 16, 160, w: 90),
      ..._lesson('I110 GdI V1/IM', 'N 101 - Kühn,S.', 'wöchentlich', di, 168),
      _t('11:30 - 13:00', 16, 250, w: 90),
      ..._lesson('I120 Prog V1/IM', 'N 101 - Bruns', 'wöchentlich', mo, 258),
      _t('12:00 - 13:30', 16, 340, w: 90),
      ..._lesson('I130 BS Pr1/IM2', 'U 515 - Baumgartl', 'wöchentlich', mo, 348),
      _t('13:45 - 15:15', 16, 420, w: 90),
      ..._lesson('S413 EnglB2 Ü1/IM2', 'S 313 - Camber', 'Gerade Woche', do_, 428),
    ];

    final imported = TimetablePdfParser.parsePages([odd, even]);
    expect(imported.title, 'Medieninformatik - Bachelor');
    expect(imported.lessonCount, greaterThanOrEqualTo(6));

    TimetableSlot slot(int day, int period, TimetableWeek week) => imported
        .slots
        .firstWhere((s) => s.day == day && s.period == period && s.week == week);

    expect(slot(0, 0, TimetableWeek.a).first.subject, contains('Mathe'));
    expect(slot(0, 0, TimetableWeek.a).first.hourKind, TimetableHourKind.lecture);
    expect(slot(0, 0, TimetableWeek.b).first.subject, contains('GdG'));
    expect(slot(0, 0, TimetableWeek.b).first.hourKind, TimetableHourKind.practical);
    expect(slot(1, 1, TimetableWeek.both).first.subject, contains('GdI'));
    expect(slot(0, 3, TimetableWeek.both).first.subject, contains('BS Pr'));
    expect(slot(2, 2, TimetableWeek.a).first.subject, contains('Engl'));
    expect(slot(3, 4, TimetableWeek.b).first.subject, contains('Engl'));
    expect(slot(0, 3, TimetableWeek.both).first.room, contains('U515'));
    expect(slot(0, 3, TimetableWeek.both).first.professor, contains('Baumgartl'));
    expect(slot(0, 0, TimetableWeek.a).first.professor, contains('Lange'));
  });

  test('mergeLineFragments joins split OPAL words', () {
    final merged = TimetablePdfParser.mergeLineFragments([
      _t('I', 160, 90, w: 6),
      _t('382', 167, 90, w: 22),
      _t('Mathe', 194, 90, w: 40),
      _t('V1/IM', 238, 90, w: 36),
    ]);
    expect(merged, hasLength(1));
    expect(merged.single.text, 'I382 Mathe V1/IM');
  });

  test('overlapping 12:00 row maps to university period 4', () {
    expect(
      TimetablePdfParser.periodIndexFor(
        12 * 60,
        13 * 60 + 30,
        Timetable.universitySemesterPeriods(),
      ),
      3,
    );
    expect(
      TimetablePdfParser.periodIndexFor(
        11 * 60 + 30,
        13 * 60,
        Timetable.universitySemesterPeriods(),
      ),
      2,
    );
  });
}
