import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/providers/library_providers.dart';

abstract final class ClassroomAutoConnect {
  static const enabledKey = 'classroomAutoConnectEnabled';
  static const askedKey = 'classroomAutoConnectAsked';
  static const subjectKey = 'classroomAutoConnectSubject';
  static const roomKey = 'classroomAutoConnectRoom';

  static bool isEnabled(SharedPreferences prefs) =>
      prefs.getBool(enabledKey) == true;

  static bool hasMatchingCriteria(
    SharedPreferences prefs, {
    required String? subject,
    required String? room,
  }) {
    return matches(
      expectedSubject: prefs.getString(subjectKey),
      expectedRoom: prefs.getString(roomKey),
      actualSubject: subject,
      actualRoom: room,
    );
  }

  static bool matches({
    required String? expectedSubject,
    required String? expectedRoom,
    required String? actualSubject,
    required String? actualRoom,
  }) {
    String normalized(String? value) => value?.trim().toLowerCase() ?? '';
    final expectedSubjectValue = normalized(expectedSubject);
    final expectedRoomValue = normalized(expectedRoom);
    final actualSubjectValue = normalized(actualSubject);
    final actualRoomValue = normalized(actualRoom);
    final subjectMatches =
        expectedSubjectValue.isNotEmpty &&
        actualSubjectValue.isNotEmpty &&
        expectedSubjectValue == actualSubjectValue;
    final roomMatches =
        expectedRoomValue.isNotEmpty &&
        actualRoomValue.isNotEmpty &&
        expectedRoomValue == actualRoomValue;
    return subjectMatches || roomMatches;
  }

  static Future<void> enable(
    SharedPreferences prefs, {
    required String? subject,
    required String? room,
  }) async {
    await prefs.setBool(askedKey, true);
    await prefs.setBool(enabledKey, true);
    await prefs.setString(subjectKey, subject?.trim() ?? '');
    await prefs.setString(roomKey, room?.trim() ?? '');
  }

  static Future<void> decline(SharedPreferences prefs) async {
    await prefs.setBool(askedKey, true);
    await prefs.setBool(enabledKey, false);
  }
}

final classroomAutoConnectEnabledProvider = StateProvider<bool>((ref) {
  return ClassroomAutoConnect.isEnabled(ref.watch(sharedPreferencesProvider));
});
