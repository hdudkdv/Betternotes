/// Web stub — dart:io sockets are unavailable in the browser.
class LanPeerConnection {
  LanPeerConnection();
  String remoteName = '';
  String? remoteDeviceId;
}

class LanSyncTransport {
  bool get isHosting => false;
  bool get hasClient => false;
  List<LanPeerConnection> get peers => const [];
  int? get boundPort => null;

  void Function(Map<String, dynamic> message)? onMessage;
  void Function(LanPeerConnection peer)? onPeerJoined;
  void Function(LanPeerConnection peer)? onPeerLeft;
  void Function(Object error)? onError;

  Future<int> startHost({int port = 47821}) async {
    throw UnsupportedError('Nearby sync host is not available on web.');
  }

  Future<void> connect({required String host, required int port}) async {
    throw UnsupportedError('Nearby sync is not available on web.');
  }

  Future<void> sendTo(LanPeerConnection peer, Map<String, dynamic> message) async {}

  Future<void> disconnectPeer(LanPeerConnection peer) async {}

  Future<void> broadcast(Map<String, dynamic> message) async {}

  Future<void> stop() async {}

  static Future<List<String>> localIPv4Addresses() async => const [];
}
