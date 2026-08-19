import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyBleBeacon {
  const NearbyBleBeacon({
    required this.id,
    required this.name,
    required this.rssi,
    this.shareId,
  });

  final String id;
  final String name;
  final int rssi;
  final String? shareId;
}

class NearbyBlePayload {
  const NearbyBlePayload({
    required this.shareId,
    required this.notebookId,
    required this.displayName,
    required this.hostDeviceId,
    this.ip,
    this.port = 47821,
    this.ssid,
    this.password,
  });

  final String shareId;
  final String notebookId;
  final String displayName;
  final String hostDeviceId;
  final String? ip;
  final int port;
  final String? ssid;
  final String? password;

  Map<String, dynamic> toJson() => {
    'sid': shareId,
    'nid': notebookId,
    'name': displayName,
    'did': hostDeviceId,
    'port': port,
    if (ip != null && ip!.isNotEmpty) 'ip': ip,
    if (ssid != null && ssid!.isNotEmpty) 'ssid': ssid,
    if (password != null && password!.isNotEmpty) 'pw': password,
  };

  factory NearbyBlePayload.fromJson(Map<String, dynamic> json) {
    return NearbyBlePayload(
      shareId: json['sid']?.toString() ?? '',
      notebookId: json['nid']?.toString() ?? '',
      displayName: json['name']?.toString() ?? '',
      hostDeviceId: json['did']?.toString() ?? '',
      ip: json['ip']?.toString(),
      port: (json['port'] as num?)?.toInt() ?? 47821,
      ssid: json['ssid']?.toString(),
      password: json['pw']?.toString(),
    );
  }
}

/// BLE advertise / scan / GATT read for nearby share discovery.
///
/// Transfer still uses the existing TCP session. BLE is the cross-platform
/// way iOS and Android find each other without a shared router (the same
/// pattern as Nearby Connections: BLE to meet, then the fastest local path).
class NearbyBle {
  NearbyBle._() {
    _events.receiveBroadcastStream().listen(_onEvent, onError: (_) {});
  }

  static final NearbyBle instance = NearbyBle._();

  static const _channel = MethodChannel('notis/nearby_ble');
  static const _events = EventChannel('notis/nearby_ble_events');

  final _beacons = <String, NearbyBleBeacon>{};
  final _controller = StreamController<List<NearbyBleBeacon>>.broadcast();

  Stream<List<NearbyBleBeacon>> get beacons => _controller.stream;

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    final event = map['event']?.toString();
    if (event == 'clear') {
      _beacons.clear();
      _publish();
      return;
    }
    if (event != 'beacon') return;
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) return;
    _beacons[id] = NearbyBleBeacon(
      id: id,
      name: map['name']?.toString() ?? 'Notis',
      rssi: (map['rssi'] as num?)?.toInt() ?? 0,
      shareId: map['shareId']?.toString(),
    );
    _publish();
  }

  void _publish() {
    if (!_controller.isClosed) {
      _controller.add(_beacons.values.toList());
    }
  }

  Future<bool> ensurePermissions() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.request();
      final advertise = await Permission.bluetoothAdvertise.request();
      final connect = await Permission.bluetoothConnect.request();
      if (scan.isGranted && advertise.isGranted && connect.isGranted) {
        return true;
      }
      final location = await Permission.locationWhenInUse.request();
      return location.isGranted;
    }
    if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted || bluetooth.isLimited;
    }
    return false;
  }

  Future<void> startAdvertise({
    required String name,
    required NearbyBlePayload payload,
  }) async {
    if (kIsWeb) return;
    if (!await ensurePermissions()) return;
    try {
      await _channel.invokeMethod<void>('startAdvertise', {
        'name': name,
        'payload': jsonEncode(payload.toJson()),
        'shareId': payload.shareId,
      });
    } on PlatformException {
      // Plugin missing on desktop.
    }
  }

  Future<void> stopAdvertise() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('stopAdvertise');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> startScan() async {
    if (kIsWeb) return;
    if (!await ensurePermissions()) return;
    _beacons.clear();
    _publish();
    try {
      await _channel.invokeMethod<void>('startScan');
    } on PlatformException {
      // ignore
    }
  }

  Future<void> stopScan() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('stopScan');
    } on PlatformException {
      // ignore
    }
  }

  Future<NearbyBlePayload?> readPayload(String id) async {
    if (kIsWeb || id.isEmpty) return null;
    try {
      final raw = await _channel.invokeMethod<String>('readPayload', {'id': id});
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      return NearbyBlePayload.fromJson(Map<String, dynamic>.from(json));
    } on PlatformException {
      return null;
    }
  }
}
