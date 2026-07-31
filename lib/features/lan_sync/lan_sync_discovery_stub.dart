import 'dart:async';

/// A resolved nearby host discovered via mDNS.
class NearbyDiscoveredHost {
  const NearbyDiscoveredHost({
    required this.name,
    required this.host,
    required this.port,
    required this.sessionCode,
    this.notebookTitle,
    this.deviceId,
    this.classroomSubject,
    this.classroomRoom,
  });

  final String name;
  final String host;
  final int port;
  final String sessionCode;
  final String? notebookTitle;
  final String? deviceId;
  final String? classroomSubject;
  final String? classroomRoom;

  String get key => '$host:$port:$sessionCode';
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
    String? classroomSubject,
    String? classroomRoom,
  }) async {}

  Future<void> stopAdvertising() async {}

  Future<void> startBrowsing() async {}

  Future<void> stopBrowsing() async {}

  Future<void> dispose() async {
    await _controller.close();
  }
}

LanSyncDiscovery createLanSyncDiscovery() => LanSyncDiscovery();
