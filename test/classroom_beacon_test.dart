import 'package:betternotes/features/lan_sync/classroom_beacon.dart';
import 'package:betternotes/features/timetable/timetable_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same room/subject/window produce the same hash', () {
    final at = DateTime(2026, 8, 15, 10, 12);
    final a = ClassroomBeacon.hash(room: 'B12', subject: 'Mathe', at: at);
    final b = ClassroomBeacon.hash(room: 'b12', subject: 'mathe', at: at);
    expect(a, b);
    expect(a.length, 16);
  });

  test('matches a timetable lesson in the current window', () {
    final now = DateTime(2026, 8, 15, 10, 12);
    final hash = ClassroomBeacon.hash(
      room: 'B12',
      subject: 'Mathe',
      at: now,
    );
    final table = Timetable(
      id: 't1',
      title: 'Test',
      periods: const [],
      slots: [
        TimetableSlot(
          day: 0,
          period: 0,
          first: const TimetableLesson(subject: 'Mathe', room: 'B12'),
        ),
      ],
      updatedAt: now,
    );
    expect(
      ClassroomBeacon.matchesTimetable(
        beaconHash: hash,
        timetable: table,
        now: now,
      ),
      isTrue,
    );
  });
}
