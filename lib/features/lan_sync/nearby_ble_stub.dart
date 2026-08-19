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

/// Web stub — BLE is unavailable in the browser.
class NearbyBle {
  NearbyBle._();
  static final NearbyBle instance = NearbyBle._();

  Stream<List<NearbyBleBeacon>> get beacons => const Stream.empty();

  Future<bool> ensurePermissions() async => false;

  Future<void> startAdvertise({
    required String name,
    required NearbyBlePayload payload,
  }) async {}

  Future<void> stopAdvertise() async {}

  Future<void> startScan() async {}

  Future<void> stopScan() async {}

  Future<NearbyBlePayload?> readPayload(String id) async => null;
}
