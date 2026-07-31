import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

typedef LanMessageHandler = void Function(Map<String, dynamic> message);
typedef LanPeerHandler = void Function(LanPeerConnection peer);

/// One connected peer (host side keeps many; guest side keeps one).
class LanPeerConnection {
  LanPeerConnection(this.socket, {this.remoteName = ''}) {
    _subscription = socket.listen(
      _onData,
      onDone: () => onClosed?.call(this),
      onError: (_) => onClosed?.call(this),
      cancelOnError: true,
    );
  }

  final Socket socket;
  String remoteName;
  String? remoteDeviceId;
  void Function(LanPeerConnection peer)? onClosed;
  LanMessageHandler? onMessage;

  final BytesBuilder _buffer = BytesBuilder(copy: false);
  StreamSubscription<List<int>>? _subscription;

  InternetAddress get address => socket.remoteAddress;
  int get port => socket.remotePort;

  void _onData(List<int> chunk) {
    _buffer.add(chunk);
    while (true) {
      final bytes = _buffer.toBytes();
      if (bytes.length < 4) return;
      final length = ByteData.sublistView(
        Uint8List.fromList(bytes),
      ).getUint32(0, Endian.big);
      if (bytes.length < 4 + length) return;
      final payload = utf8.decode(bytes.sublist(4, 4 + length));
      final rest = bytes.sublist(4 + length);
      _buffer.clear();
      if (rest.isNotEmpty) _buffer.add(rest);
      try {
        final message = Map<String, dynamic>.from(jsonDecode(payload) as Map);
        onMessage?.call(message);
      } catch (_) {
        // Ignore malformed frames; keep reading.
      }
    }
  }

  Future<void> send(Map<String, dynamic> message) async {
    final payload = utf8.encode(jsonEncode(message));
    final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
    socket.add(header.buffer.asUint8List());
    socket.add(payload);
    await socket.flush();
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await socket.close();
    } catch (_) {}
  }
}

/// TCP transport for nearby notebook sync (same Wi‑Fi / hotspot).
class LanSyncTransport {
  ServerSocket? _server;
  LanPeerConnection? _client;
  final List<LanPeerConnection> _peers = [];

  bool get isHosting => _server != null;
  bool get hasClient => _client != null;
  List<LanPeerConnection> get peers => List.unmodifiable(_peers);
  int? get boundPort => _server?.port;

  LanMessageHandler? onMessage;
  LanPeerHandler? onPeerJoined;
  LanPeerHandler? onPeerLeft;
  void Function(Object error)? onError;

  Future<int> startHost({int port = 47821}) async {
    await stop();
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen((socket) {
      final peer = LanPeerConnection(socket);
      peer.onMessage = (message) => onMessage?.call(message);
      peer.onClosed = _removePeer;
      // Temporarily stash until hello binds the handler with peer context.
      peer.onMessage = (message) {
        message['_peer'] = peer;
        onMessage?.call(message);
      };
      _peers.add(peer);
      onPeerJoined?.call(peer);
    }, onError: (Object e) => onError?.call(e));
    return _server!.port;
  }

  Future<void> connect({
    required String host,
    required int port,
  }) async {
    await stop();
    final socket = await Socket.connect(
      host.trim(),
      port,
      timeout: const Duration(seconds: 8),
    );
    _client = LanPeerConnection(socket);
    _client!.onMessage = (message) {
      message['_peer'] = _client;
      onMessage?.call(message);
    };
    _client!.onClosed = (peer) {
      _client = null;
      onPeerLeft?.call(peer);
    };
  }

  Future<void> sendTo(LanPeerConnection peer, Map<String, dynamic> message) =>
      peer.send(message);

  Future<void> disconnectPeer(LanPeerConnection peer) => _removePeer(peer);

  Future<void> broadcast(Map<String, dynamic> message) async {
    if (_client != null) {
      await _client!.send(message);
      return;
    }
    for (final peer in List<LanPeerConnection>.from(_peers)) {
      try {
        await peer.send(message);
      } catch (_) {
        await _removePeer(peer);
      }
    }
  }

  Future<void> _removePeer(LanPeerConnection peer) async {
    _peers.remove(peer);
    if (identical(_client, peer)) _client = null;
    onPeerLeft?.call(peer);
    await peer.close();
  }

  Future<void> stop() async {
    for (final peer in List<LanPeerConnection>.from(_peers)) {
      await peer.close();
    }
    _peers.clear();
    if (_client != null) {
      await _client!.close();
      _client = null;
    }
    await _server?.close();
    _server = null;
  }

  /// Local IPv4 addresses useful for showing the join target.
  static Future<List<String>> localIPv4Addresses() async {
    final out = <String>[];
    try {
      for (final iface in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      )) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          out.add(addr.address);
        }
      }
    } catch (_) {}
    return out;
  }
}
