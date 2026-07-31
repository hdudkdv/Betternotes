import 'dart:convert';

import '../../data/models/content_models.dart';

/// Wire protocol version for nearby / LAN notebook sync.
const int kLanSyncProtocolVersion = 2;

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
  }) => {
    'type': 'hello',
    'protocol': kLanSyncProtocolVersion,
    'code': code,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'autoReconnect': autoReconnect,
    if (expectedSubject != null) 'expectedSubject': expectedSubject,
    if (expectedRoom != null) 'expectedRoom': expectedRoom,
  };

  static Map<String, dynamic> welcome({
    required String deviceId,
    required String deviceName,
    required String notebookId,
    bool classroomMode = false,
    String? classroomSubject,
    String? classroomRoom,
  }) => {
    'type': 'welcome',
    'protocol': kLanSyncProtocolVersion,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'notebookId': notebookId,
    'classroomMode': classroomMode,
    if (classroomSubject != null) 'classroomSubject': classroomSubject,
    if (classroomRoom != null) 'classroomRoom': classroomRoom,
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
  }) => {
    'type': 'snapshot',
    'notebook': notebook,
    'pages': pages,
    'outline': outline,
    'assetCount': assetCount,
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
  }) => {
    'type': 'classroom_command',
    'targetDeviceId': targetDeviceId,
    if (canWrite != null) 'canWrite': canWrite,
    if (muted != null) 'muted': muted,
    if (focusCheckEnabled != null) 'focusCheckEnabled': focusCheckEnabled,
    if (materialUrl != null) 'materialUrl': materialUrl,
    if (materialTitle != null) 'materialTitle': materialTitle,
  };

  static Map<String, dynamic> ping() => {'type': 'ping'};
  static Map<String, dynamic> pong() => {'type': 'pong'};

  static String encode(Map<String, dynamic> message) => jsonEncode(message);

  static Map<String, dynamic> decode(String raw) =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);
}
