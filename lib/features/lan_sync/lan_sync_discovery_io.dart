import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import 'lan_sync_protocol.dart';

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
    this.classroomBeacon,
  });

  final String name;
  final String host;
  final int port;
  final String sessionCode;
  final String? notebookTitle;
  final String? deviceId;
  final String? classroomSubject;
  final String? classroomRoom;
  final String? classroomBeacon;

  String get key => '$host:$port:$sessionCode';
}

/// Bonjour / NSD discovery for BetterNotes nearby sessions.
class LanSyncDiscovery {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _sub;
  final Map<String, NearbyDiscoveredHost> _hosts = {};
  final _controller = StreamController<List<NearbyDiscoveredHost>>.broadcast();

  List<NearbyDiscoveredHost> get hosts =>
      List.unmodifiable(_hosts.values.toList());

  Stream<List<NearbyDiscoveredHost>> get hostsStream => _controller.stream;

  void _publish() {
    if (!_controller.isClosed) {
      _controller.add(hosts);
    }
  }

  Future<void> startAdvertising({
    required String serviceName,
    required int port,
    required String sessionCode,
    required String deviceId,
    String? notebookTitle,
    String? classroomSubject,
    String? classroomRoom,
    String? classroomBeacon,
  }) async {
    await stopAdvertising();
    if (kIsWeb) return;
    final safeName = serviceName.trim().isEmpty
        ? 'Notis'
        : serviceName.trim();
    final service = BonsoirService(
      name: safeName.length > 60 ? safeName.substring(0, 60) : safeName,
      type: kLanSyncServiceType,
      port: port,
      attributes: {
        'code': sessionCode,
        'did': deviceId.length > 32 ? deviceId.substring(0, 32) : deviceId,
        if (notebookTitle != null && notebookTitle.trim().isNotEmpty)
          'title': notebookTitle.trim().length > 40
              ? notebookTitle.trim().substring(0, 40)
              : notebookTitle.trim(),
        if (classroomSubject != null && classroomSubject.trim().isNotEmpty)
          'subject': classroomSubject.trim().length > 40
              ? classroomSubject.trim().substring(0, 40)
              : classroomSubject.trim(),
        if (classroomRoom != null && classroomRoom.trim().isNotEmpty)
          'room': classroomRoom.trim().length > 24
              ? classroomRoom.trim().substring(0, 24)
              : classroomRoom.trim(),
        if (classroomBeacon != null && classroomBeacon.isNotEmpty)
          'bh': classroomBeacon,
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  Future<void> stopAdvertising() async {
    try {
      await _broadcast?.stop();
    } catch (_) {}
    _broadcast = null;
  }

  Future<void> startBrowsing() async {
    await stopBrowsing();
    if (kIsWeb) return;
    _discovery = BonsoirDiscovery(type: kLanSyncServiceType);
    await _discovery!.initialize();
    _sub = _discovery!.eventStream?.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent(:final service):
          service.resolve(_discovery!.serviceResolver);
        case BonsoirDiscoveryServiceResolvedEvent(:final service):
          final host = service.hostAddress;
          final code = service.attributes['code'];
          if (host == null || host.isEmpty || code == null || code.isEmpty) {
            return;
          }
          final item = NearbyDiscoveredHost(
            name: service.name,
            host: host,
            port: service.port,
            sessionCode: code.toUpperCase(),
            notebookTitle: service.attributes['title'],
            deviceId: service.attributes['did'],
            classroomSubject: service.attributes['subject'],
            classroomRoom: service.attributes['room'],
            classroomBeacon: service.attributes['bh'],
          );
          _hosts[item.key] = item;
          _publish();
        case BonsoirDiscoveryServiceLostEvent(:final service):
          _hosts.removeWhere(
            (key, value) =>
                value.name == service.name && value.port == service.port,
          );
          _publish();
        default:
          break;
      }
    });
    await _discovery!.start();
  }

  Future<void> stopBrowsing() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _discovery?.stop();
    } catch (_) {}
    _discovery = null;
    _hosts.clear();
    _publish();
  }

  Future<void> dispose() async {
    await stopAdvertising();
    await stopBrowsing();
    await _controller.close();
  }
}

LanSyncDiscovery createLanSyncDiscovery() => LanSyncDiscovery();
