import 'dart:math';

import '../gradebook/gradebook_models.dart';
import '../../lan_sync/lan_sync_controller.dart';

String normalizeClassroomName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool classroomNamesMatch(String a, String b) {
  final left = normalizeClassroomName(a);
  final right = normalizeClassroomName(b);
  if (left.isEmpty || right.isEmpty) return false;
  if (left == right) return true;
  final leftFirst = left.split(' ').first;
  final rightFirst = right.split(' ').first;
  return leftFirst == rightFirst && leftFirst.length >= 3;
}

T? pickRandomItem<T>(List<T> items, {Random? random}) {
  if (items.isEmpty) return null;
  return items[(random ?? Random()).nextInt(items.length)];
}

List<RosterStudent> poolWithoutRepeat({
  required List<RosterStudent> pool,
  required Set<String> drawnIds,
  bool resetWhenEmpty = true,
}) {
  final remaining = [
    for (final student in pool)
      if (!drawnIds.contains(student.id)) student,
  ];
  if (remaining.isNotEmpty) return remaining;
  return resetWhenEmpty ? pool : const [];
}

ClassroomPick pickToClassroomPick({
  required String kind,
  required String name,
  String? groupName,
  List<RosterStudent> members = const [],
  required List<({String id, String name})> peers,
  bool sticky = true,
  int holdMs = 3000,
}) {
  final self = matchConnectedPeer(studentName: name, peers: peers);
  final memberIds = <String>[];
  for (final member in members) {
    final match = matchConnectedPeer(studentName: member.name, peers: peers);
    if (match.deviceId != null) memberIds.add(match.deviceId!);
  }
  return ClassroomPick(
    kind: kind,
    name: name,
    groupName: groupName,
    deviceId: self.deviceId,
    members: [for (final member in members) member.name],
    memberDeviceIds: memberIds,
    sticky: sticky,
    holdMs: holdMs,
  );
}

({String? deviceId, String? deviceName}) matchConnectedPeer({
  required String studentName,
  required List<({String id, String name})> peers,
}) {
  final exact = [
    for (final peer in peers)
      if (normalizeClassroomName(peer.name) ==
          normalizeClassroomName(studentName))
        peer,
  ];
  if (exact.length == 1) {
    return (deviceId: exact.first.id, deviceName: exact.first.name);
  }
  final fuzzy = [
    for (final peer in peers)
      if (classroomNamesMatch(peer.name, studentName)) peer,
  ];
  if (fuzzy.length == 1) {
    return (deviceId: fuzzy.first.id, deviceName: fuzzy.first.name);
  }
  return (deviceId: null, deviceName: null);
}
