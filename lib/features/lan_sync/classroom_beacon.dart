import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../timetable/timetable_model.dart';

/// Anonymous classroom beacon: hash(room + subject + time window).
abstract final class ClassroomBeacon {
  static const windowMinutes = 45;

  static String hash({
    required String room,
    required String subject,
    required DateTime at,
  }) {
    final bucket = DateTime(
      at.year,
      at.month,
      at.day,
      at.hour,
      (at.minute / windowMinutes).floor() * windowMinutes,
    );
    final raw =
        '${room.trim().toLowerCase()}|${subject.trim().toLowerCase()}|${bucket.toIso8601String()}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  }

  static bool matchesTimetable({
    required String beaconHash,
    required Timetable timetable,
    required DateTime now,
  }) {
    for (final lesson in timetable.distinctLessons()) {
      if (lesson.subject.trim().isEmpty && lesson.room.trim().isEmpty) {
        continue;
      }
      final expected = hash(
        room: lesson.room,
        subject: lesson.subject,
        at: now,
      );
      if (expected == beaconHash) return true;
    }
    return false;
  }
}
