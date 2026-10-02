import 'package:betternotes/features/planner/education_settings.dart';
import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('KMK 2025/26 holidays match official first and last days', () {
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.hh, DateTime(2025, 12, 17)),
      'christmas',
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.ni, DateTime(2025, 10, 6)),
      isNull,
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.sn, DateTime(2026, 3, 28)),
      isNull,
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.sn, DateTime(2026, 4, 3)),
      'easter',
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.th, DateTime(2026, 4, 7)),
      'easter',
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.he, DateTime(2026, 6, 29)),
      'summer',
    );
    expect(
      SchoolHolidays.holidayKeyOn(GermanState.sh, DateTime(2026, 7, 4)),
      'summer',
    );
  });

  test('university semester periods match the 90-minute OPAL grid', () {
    final periods = Timetable.universitySemesterPeriods();
    expect(periods, hasLength(8));
    expect(periods.first.timeRange, '08:00–09:30');
    expect(periods[2].timeRange, '11:30–13:00');
    expect(periods[3].timeRange, '12:00–13:30');
    expect(periods.last.timeRange, '19:00–20:30');
  });
}
