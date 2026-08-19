import 'dart:convert';

import '../../data/models/content_models.dart';

/// Wire protocol version for nearby / LAN notebook sync.
const int kLanSyncProtocolVersion = 4;

/// Default TCP port for nearby sessions (guest only needs host IP + code).
const int kLanSyncPort = 47821;

/// Bonjour / NSD service type (must match iOS NSBonjourServices).
const String kLanSyncServiceType = '_betternotes-nearby._tcp';

enum LanSyncRole { host, guest }

enum LanSyncPhase {
  idle,
  hosting,
  connecting,
  syncing,
  connected,
  error,
}

/// Length-prefixed JSON messages exchanged over the LAN socket.
abstract final class LanSyncMessage {
  static Map<String, dynamic> hello({
    required String code,
    required String deviceId,
    required String deviceName,
    bool autoReconnect = false,
    String? expectedSubject,
    String? expectedRoom,
    String? shareId,
  }) => {
    'type': 'hello',
    'protocol': kLanSyncProtocolVersion,
    'code': code,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'autoReconnect': autoReconnect,
    if (expectedSubject != null) 'expectedSubject': expectedSubject,
    if (expectedRoom != null) 'expectedRoom': expectedRoom,
    if (shareId != null && shareId.isNotEmpty) 'shareId': shareId,
  };

  static Map<String, dynamic> welcome({
    required String deviceId,
    required String deviceName,
    required String notebookId,
    bool classroomMode = false,
    String? classroomSubject,
    String? classroomRoom,
    String? shareId,
    String? shareName,
  }) => {
    'type': 'welcome',
    'protocol': kLanSyncProtocolVersion,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'notebookId': notebookId,
    'classroomMode': classroomMode,
    if (classroomSubject != null) 'classroomSubject': classroomSubject,
    if (classroomRoom != null) 'classroomRoom': classroomRoom,
    if (shareId != null && shareId.isNotEmpty) 'shareId': shareId,
    if (shareName != null && shareName.isNotEmpty) 'shareName': shareName,
  };

  static Map<String, dynamic> reject(String reason) => {
    'type': 'reject',
    'reason': reason,
  };

  static Map<String, dynamic> snapshot({
    required Map<String, dynamic> notebook,
    required List<Map<String, dynamic>> pages,
    required List<Map<String, dynamic>> outline,
    int assetCount = 0,
    String mode = 'live',
  }) => {
    'type': 'snapshot',
    'notebook': notebook,
    'pages': pages,
    'outline': outline,
    'assetCount': assetCount,
    'mode': mode,
  };

  static Map<String, dynamic> libraryShare({
    required String kind,
    required Map<String, dynamic> payload,
    String? title,
  }) => {
    'type': 'library_share',
    'kind': kind,
    'payload': payload,
    if (title != null) 'title': title,
  };

  static Map<String, dynamic> assetsDone() => {'type': 'assets_done'};

  static Map<String, dynamic> op({
    required SyncOp syncOp,
    required String originDeviceId,
  }) => {
    'type': 'op',
    'originDeviceId': originDeviceId,
    'op': syncOp.toJson(),
  };

  static Map<String, dynamic> classroomSignal({
    required String deviceId,
    required String deviceName,
    required String kind,
    Object? value,
  }) => {
    'type': 'classroom_signal',
    'deviceId': deviceId,
    'deviceName': deviceName,
    'kind': kind,
    'value': value,
  };

  static Map<String, dynamic> classroomCommand({
    required String targetDeviceId,
    bool? canWrite,
    bool? muted,
    bool? focusCheckEnabled,
    String? materialUrl,
    String? materialTitle,
    String? pickKind,
    String? pickName,
    String? pickGroupName,
    String? pickDeviceId,
    List<String>? pickMembers,
    List<String>? pickMemberDeviceIds,
    bool? pickSticky,
    int? pickHoldMs,
  }) => {
    'type': 'classroom_command',
    'targetDeviceId': targetDeviceId,
    if (canWrite != null) 'canWrite': canWrite,
    if (muted != null) 'muted': muted,
    if (focusCheckEnabled != null) 'focusCheckEnabled': focusCheckEnabled,
    if (materialUrl != null) 'materialUrl': materialUrl,
    if (materialTitle != null) 'materialTitle': materialTitle,
    if (pickKind != null) 'pickKind': pickKind,
    if (pickName != null) 'pickName': pickName,
    if (pickGroupName != null) 'pickGroupName': pickGroupName,
    if (pickDeviceId != null) 'pickDeviceId': pickDeviceId,
    if (pickMembers != null) 'pickMembers': pickMembers,
    if (pickMemberDeviceIds != null) 'pickMemberDeviceIds': pickMemberDeviceIds,
    if (pickSticky != null) 'pickSticky': pickSticky,
    if (pickHoldMs != null) 'pickHoldMs': pickHoldMs,
  };

  static Map<String, dynamic> assignmentStart(Map<String, dynamic> payload) => {
    'type': 'assignment_start',
    'protocol': kLanSyncProtocolVersion,
    ...payload,
  };

  static Map<String, dynamic> assignmentProgress({
    required String deviceId,
    required String deviceName,
    required String runId,
    required int percent,
    required List<String> doneTaskIds,
  }) => {
    'type': 'assignment_progress',
    'deviceId': deviceId,
    'deviceName': deviceName,
    'runId': runId,
    'percent': percent,
    'doneTaskIds': doneTaskIds,
  };

  static Map<String, dynamic> assignmentExtend({
    required String runId,
    required String endsAt,
  }) => {
    'type': 'assignment_extend',
    'runId': runId,
    'endsAt': endsAt,
  };

  static Map<String, dynamic> assignmentCollect({required String runId}) => {
    'type': 'assignment_collect',
    'runId': runId,
  };

  static Map<String, dynamic> assignmentAllowImport({
    required String runId,
  }) => {
    'type': 'assignment_allow_import',
    'runId': runId,
  };

  static Map<String, dynamic> assignmentSubmit(Map<String, dynamic> payload) => {
    'type': 'assignment_submit',
    ...payload,
  };

  static Map<String, dynamic> assignmentLeave({
    required String deviceId,
    required String deviceName,
    required String runId,
    required String kind,
  }) => {
    'type': 'assignment_leave',
    'deviceId': deviceId,
    'deviceName': deviceName,
    'runId': runId,
    'kind': kind,
  };

  static Map<String, dynamic> assignmentReturn({
    required String runId,
    required String targetDeviceId,
    required String correctionText,
  }) => {
    'type': 'assignment_return',
    'runId': runId,
    'targetDeviceId': targetDeviceId,
    'correctionText': correctionText,
  };

  static Map<String, dynamic> ping() => {'type': 'ping'};
  static Map<String, dynamic> pong() => {'type': 'pong'};

  static String encode(Map<String, dynamic> message) => jsonEncode(message);

  static Map<String, dynamic> decode(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);
}
