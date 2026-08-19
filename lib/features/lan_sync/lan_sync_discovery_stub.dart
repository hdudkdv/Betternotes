import 'dart:async';

/// A resolved nearby host discovered via mDNS.
class NearbyDiscoveredHost {
  const NearbyDiscoveredHost({
    required this.name,
    required this.host,
    required this.port,
    this.sessionCode = '',
    this.notebookTitle,
    this.deviceId,
    this.shareId,
    this.bleId,
    this.classroomSubject,
    this.classroomRoom,
    this.classroomBeacon,
  });

  final String name;
  final String host;
  final int port;
  final String sessionCode;
  final String? notebookTitle;
  final String? deviceId;
  final String? shareId;
  final String? bleId;
  final String? classroomSubject;
  final String? classroomRoom;
  final String? classroomBeacon;

  String get publicName {
    final title = notebookTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return name;
  }

  String get key {
    if (shareId != null && shareId!.isNotEmpty) return 'sid:$shareId';
    if (bleId != null && bleId!.isNotEmpty) return 'ble:$bleId';
    return '$host:$port:$sessionCode';
  }
}

/// Web stub — mDNS is unavailable in the browser.
class LanSyncDiscovery {
  final _controller = StreamController<List<NearbyDiscoveredHost>>.broadcast();

  List<NearbyDiscoveredHost> get hosts => const [];

  Stream<List<NearbyDiscoveredHost>> get hostsStream => _controller.stream;

  Future<void> startAdvertising({
    required String serviceName,
    required int port,
    required String sessionCode,
    required String deviceId,
    String? notebookTitle,
    String? shareId,
    bool advertiseCode = true,
    String? classroomSubject,
    String? classroomRoom,
    String? classroomBeacon,
  }) async {}

  Future<void> stopAdvertising() async {}

  Future<void> startBrowsing() async {}

  Future<void> stopBrowsing() async {}

  Future<void> dispose() async {
    await _controller.close();
  }
}

LanSyncDiscovery createLanSyncDiscovery() => LanSyncDiscovery();
