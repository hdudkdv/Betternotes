import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../library/providers/library_providers.dart';
import '../sync/sync_merge.dart';
import '../sync/transport_manager.dart';
import 'classroom_beacon.dart';
import 'lan_sync_assets.dart';
import 'lan_sync_discovery.dart';
import 'lan_sync_protocol.dart';
import 'lan_sync_transport.dart';

enum LanSyncEventKind {
  peerJoined,
  peerLeft,
  snapshotApplied,
  pageUpdated,
  notebookUpdated,
  status,
  error,
  hostsChanged,
  classroomSignal,
  assignment,
}

class LanSyncEvent {
  const LanSyncEvent({
    required this.kind,
    this.notebookId,
    this.pageId,
    this.message,
  });

  final LanSyncEventKind kind;
  final String? notebookId;
  final String? pageId;
  final String? message;
}

class LanClassroomSignal {
  const LanClassroomSignal({
    required this.deviceId,
    required this.deviceName,
    required this.kind,
    this.value,
  });

  final String deviceId;
  final String deviceName;
  final String kind;
  final Object? value;
}

class LanAssignmentEvent {
  const LanAssignmentEvent({
    required this.type,
    required this.payload,
  });

  final String type;
  final Map<String, dynamic> payload;
}

class _IncomingAsset {
  _IncomingAsset({
    required this.fileName,
    required this.size,
    required this.totalChunks,
  });

  final String fileName;
  final int size;
  final int totalChunks;
  final Map<int, Uint8List> chunks = {};

  bool get isComplete => chunks.length >= totalChunks;

  Uint8List assemble() {
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < totalChunks; i++) {
      final part = chunks[i];
      if (part == null) {
        throw StateError('Missing asset chunk $i');
      }
      out.add(part);
    }
    return out.toBytes();
  }
}

/// Hosts or joins a local Wi‑Fi / hotspot session and exchanges notebook
/// snapshots plus incremental page/notebook ops (including binary assets).
class LanSyncController extends ChangeNotifier {
  LanSyncController(this._repository) {
    _deviceId = const Uuid().v4();
    _discovery = createLanSyncDiscovery();
    _hostsSub = _discovery.hostsStream.listen((_) {
      discoveredHosts = _discovery.hosts;
      _emit(const LanSyncEvent(kind: LanSyncEventKind.hostsChanged));
    });
  }

  final NotebookRepository _repository;
  final LanSyncTransport _transport = LanSyncTransport();
  late final LanSyncDiscovery _discovery;
  StreamSubscription<List<NearbyDiscoveredHost>>? _hostsSub;

  late final String _deviceId;
  String deviceName = 'Notis';
  String? sessionCode;
  String? notebookId;
  LanSyncRole? role;
  LanSyncPhase phase = LanSyncPhase.idle;
  String? errorMessage;
  List<String> localAddresses = const [];
  List<NearbyDiscoveredHost> discoveredHosts = const [];
  int port = kLanSyncPort;
  int peerCount = 0;
  String? peerName;
  LanSyncEvent? lastEvent;
  int eventSeq = 0;
  bool browsing = false;
  bool classroomMode = false;
  String? classroomSubject;
  String? classroomRoom;
  bool classroomCanWrite = true;
  bool classroomMuted = false;
  bool classroomFocusCheckEnabled = false;
  bool classroomFocusConsent = false;
  String? classroomMaterialUrl;
  String? classroomMaterialTitle;
  LanClassroomSignal? lastClassroomSignal;
  int classroomSignalSeq = 0;
  LanAssignmentEvent? lastAssignmentEvent;
  int assignmentEventSeq = 0;
  Map<String, dynamic>? _activeAssignmentStart;
  final Map<String, bool> _peerWritePermissions = {};
  bool _applyingRemote = false;
  bool _disposed = false;
  Future<void> _messageQueue = Future.value();

  /// Pending snapshot pages while assets are still arriving.
  Map<String, dynamic>? _pendingNotebook;
  List<Map<String, dynamic>>? _pendingPages;
  List<Map<String, dynamic>>? _pendingOutline;
  int _pendingAssetCount = 0;
  bool _pendingLibraryImport = false;
  final Map<String, _IncomingAsset> _incomingAssets = {};
  final Map<String, String> _assetKeyToPath = {};

  bool get isActive =>
      phase == LanSyncPhase.hosting ||
      phase == LanSyncPhase.connected ||
      phase == LanSyncPhase.syncing ||
      phase == LanSyncPhase.connecting;

  String get deviceId => _deviceId;

  bool get canBroadcast =>
      isActive &&
      notebookId != null &&
      (role == LanSyncRole.guest
          ? _transport.hasClient
          : _transport.peers.isNotEmpty);

  void _emit(LanSyncEvent event) {
    lastEvent = event;
    eventSeq++;
    notifyListeners();
  }

  Future<void> refreshAddresses() async {
    localAddresses = await LanSyncTransport.localIPv4Addresses();
    notifyListeners();
  }

  Future<void> startBrowsing() async {
    browsing = true;
    notifyListeners();
    try {
      await _discovery.startBrowsing();
      discoveredHosts = _discovery.hosts;
      notifyListeners();
    } catch (e) {
      browsing = false;
      errorMessage = '$e';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    }
  }

  Future<void> stopBrowsing() async {
    browsing = false;
    await _discovery.stopBrowsing();
    discoveredHosts = const [];
    notifyListeners();
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => alphabet[rand.nextInt(alphabet.length)])
        .join();
  }

  Future<void> startHost({
    required String notebookId,
    String? displayName,
    bool classroomMode = false,
    String? classroomSubject,
    String? classroomRoom,
  }) async {
    if (kIsWeb) {
      phase = LanSyncPhase.error;
      errorMessage = 'web_unsupported';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
      return;
    }
    await stop();
    this.notebookId = notebookId;
    this.classroomMode = classroomMode;
    this.classroomSubject = classroomSubject?.trim();
    this.classroomRoom = classroomRoom?.trim();
    role = LanSyncRole.host;
    deviceName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : 'Host';
    sessionCode = _generateCode();
    phase = LanSyncPhase.hosting;
    errorMessage = null;
    notifyListeners();

    _transport.onMessage = _onMessage;
    _transport.onPeerJoined = (_) {
      peerCount = _transport.peers.length;
      _emit(const LanSyncEvent(kind: LanSyncEventKind.peerJoined));
    };
    _transport.onPeerLeft = (peer) {
      peerCount = _transport.peers.length;
      if (peerCount == 0) peerName = null;
      if (classroomMode && peer.remoteDeviceId != null) {
        lastClassroomSignal = LanClassroomSignal(
          deviceId: peer.remoteDeviceId!,
          deviceName: peer.remoteName,
          kind: 'left',
        );
        classroomSignalSeq++;
      }
      _emit(const LanSyncEvent(kind: LanSyncEventKind.peerLeft));
    };
    _transport.onError = (error) {
      errorMessage = '$error';
      phase = LanSyncPhase.error;
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    };

    try {
      port = await _transport.startHost(port: kLanSyncPort);
      await refreshAddresses();
      final notebook = await _repository.getNotebook(notebookId);
      await _discovery.startAdvertising(
        serviceName: deviceName,
        port: port,
        sessionCode: sessionCode!,
        deviceId: _deviceId,
        notebookTitle: notebook?.title,
        classroomSubject: this.classroomSubject,
        classroomRoom: this.classroomRoom,
        classroomBeacon: this.classroomSubject != null ||
                this.classroomRoom != null
            ? ClassroomBeacon.hash(
                room: this.classroomRoom ?? '',
                subject: this.classroomSubject ?? '',
                at: DateTime.now(),
              )
            : null,
      );
      _emit(LanSyncEvent(
        kind: LanSyncEventKind.status,
        notebookId: notebookId,
        message: 'hosting',
      ));
    } catch (e) {
      phase = LanSyncPhase.error;
      errorMessage = '$e';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    }
  }

  Future<void> join({
    required String host,
    required String code,
    String? displayName,
    int port = kLanSyncPort,
    bool autoReconnect = false,
    String? expectedSubject,
    String? expectedRoom,
  }) async {
    if (kIsWeb) {
      phase = LanSyncPhase.error;
      errorMessage = 'web_unsupported';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
      return;
    }
    await _discovery.stopAdvertising();
    // Keep browsing optional; stop transport from previous session.
    await _transport.stop();
    role = LanSyncRole.guest;
    deviceName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : 'Gast';
    sessionCode = code.trim().toUpperCase();
    this.port = port;
    notebookId = null;
    classroomMode = false;
    classroomSubject = null;
    classroomRoom = null;
    phase = LanSyncPhase.connecting;
    errorMessage = null;
    _resetIncoming();
    notifyListeners();

    _transport.onMessage = _onMessage;
    _transport.onPeerLeft = (_) {
      peerCount = 0;
      peerName = null;
      phase = LanSyncPhase.error;
      errorMessage = 'disconnected';
      _emit(LanSyncEvent(
        kind: LanSyncEventKind.peerLeft,
        message: 'disconnected',
      ));
    };
    _transport.onError = (error) {
      errorMessage = '$error';
      phase = LanSyncPhase.error;
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    };

    try {
      await _transport.connect(host: host, port: port);
      phase = LanSyncPhase.syncing;
      notifyListeners();
      await _transport.broadcast(
        LanSyncMessage.hello(
          code: sessionCode!,
          deviceId: _deviceId,
          deviceName: deviceName,
          autoReconnect: autoReconnect,
          expectedSubject: expectedSubject,
          expectedRoom: expectedRoom,
        ),
      );
    } catch (e) {
      phase = LanSyncPhase.error;
      errorMessage = '$e';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    }
  }

  Future<void> joinDiscovered(
    NearbyDiscoveredHost host, {
    String? displayName,
    bool autoReconnect = false,
    String? expectedSubject,
    String? expectedRoom,
  }) {
    return join(
      host: host.host,
      code: host.sessionCode,
      port: host.port,
      displayName: displayName,
      autoReconnect: autoReconnect,
      expectedSubject: expectedSubject,
      expectedRoom: expectedRoom,
    );
  }

  Future<void> stop() async {
    await _discovery.stopAdvertising();
    await _transport.stop();
    phase = LanSyncPhase.idle;
    role = null;
    sessionCode = null;
    notebookId = null;
    peerCount = 0;
    peerName = null;
    errorMessage = null;
    classroomMode = false;
    classroomSubject = null;
    classroomRoom = null;
    classroomCanWrite = true;
    classroomMuted = false;
    classroomFocusCheckEnabled = false;
    classroomFocusConsent = false;
    classroomMaterialUrl = null;
    classroomMaterialTitle = null;
    lastClassroomSignal = null;
    _peerWritePermissions.clear();
    _resetIncoming();
    notifyListeners();
  }

  void _resetIncoming() {
    _pendingNotebook = null;
    _pendingPages = null;
    _pendingOutline = null;
    _pendingAssetCount = 0;
    _pendingLibraryImport = false;
    _incomingAssets.clear();
    _assetKeyToPath.clear();
  }

  Future<void> _sendAssets(
    LanPeerConnection? peer,
    List<LanAssetDescriptor> assets,
  ) async {
    for (final asset in assets) {
      for (final message in chunkAssetMessages(asset)) {
        if (peer != null) {
          await _transport.sendTo(peer, message);
        } else {
          await _transport.broadcast(message);
        }
      }
    }
    final done = LanSyncMessage.assetsDone();
    if (peer != null) {
      await _transport.sendTo(peer, done);
    } else {
      await _transport.broadcast(done);
    }
  }

  /// Called after a local page save while a session is active.
  Future<void> noteLocalPageSaved(NotePage page) async {
    if (_applyingRemote || !canBroadcast) return;
    if (page.notebookId != notebookId) return;
    final packed = await packPageAssets([page]);
    await _sendAssets(null, packed.assets);
    final op = SyncOp(
      id: const Uuid().v4(),
      entityType: 'page',
      entityId: page.id,
      payloadJson: jsonEncode(packed.pagesJson.first),
      createdAt: DateTime.now(),
    );
    await _transport.broadcast(
      LanSyncMessage.op(syncOp: op, originDeviceId: _deviceId),
    );
  }

  Future<void> sendClassroomSignal(String kind, [Object? value]) async {
    if (!isActive) return;
    await _transport.broadcast(
      LanSyncMessage.classroomSignal(
        deviceId: _deviceId,
        deviceName: deviceName,
        kind: kind,
        value: value,
      ),
    );
  }

  Future<void> setClassroomFocusConsent(bool consent) async {
    classroomFocusConsent = consent;
    notifyListeners();
    if (consent) await sendClassroomSignal('focus', true);
  }

  Future<void> setPeerClassroomPermissions({
    required String deviceId,
    bool? canWrite,
    bool? muted,
  }) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    if (canWrite != null) _peerWritePermissions[deviceId] = canWrite;
    final peer = _transport.peers
        .where((item) => item.remoteDeviceId == deviceId)
        .firstOrNull;
    if (peer != null) {
      await _transport.sendTo(
        peer,
        LanSyncMessage.classroomCommand(
          targetDeviceId: deviceId,
          canWrite: canWrite,
          muted: muted,
        ),
      );
    }
  }

  Future<void> setClassroomFocusCheck(bool enabled) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    classroomFocusCheckEnabled = enabled;
    notifyListeners();
    await _transport.broadcast(
      LanSyncMessage.classroomCommand(
        targetDeviceId: '*',
        focusCheckEnabled: enabled,
      ),
    );
  }

  Future<void> distributeClassroomMaterial({
    required String url,
    required String title,
  }) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    await _transport.broadcast(
      LanSyncMessage.classroomCommand(
        targetDeviceId: '*',
        materialUrl: url,
        materialTitle: title,
      ),
    );
  }

  /// Sends a notebook into students' libraries without replacing the live board.
  Future<void> shareNotebookToClass(String id) async {
    if (role != LanSyncRole.host || !canBroadcast) return;
    final notebook = await _repository.getNotebook(id);
    if (notebook == null) return;
    final pages = await _repository.getPages(id);
    final outline = await _repository.getOutline(id);
    final packed = await packPageAssets(pages);
    await _transport.broadcast(
      LanSyncMessage.snapshot(
        notebook: notebook.toJson(),
        pages: packed.pagesJson,
        outline: [for (final n in outline) n.toJson()],
        assetCount: packed.assets.length,
        mode: 'library',
      ),
    );
    await _sendAssets(null, packed.assets);
  }

  Future<void> startAssignment(Map<String, dynamic> payload) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    _activeAssignmentStart = payload;
    await _transport.broadcast(LanSyncMessage.assignmentStart(payload));
  }

  Future<void> extendAssignment({
    required String runId,
    required DateTime endsAt,
  }) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    final payload = LanSyncMessage.assignmentExtend(
      runId: runId,
      endsAt: endsAt.toIso8601String(),
    );
    if (_activeAssignmentStart != null) {
      _activeAssignmentStart = {
        ..._activeAssignmentStart!,
        'endsAt': endsAt.toIso8601String(),
      };
    }
    await _transport.broadcast(payload);
  }

  Future<void> collectAssignment(String runId) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    await _transport.broadcast(LanSyncMessage.assignmentCollect(runId: runId));
  }

  Future<void> allowAssignmentImport(String runId) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    if (_activeAssignmentStart != null) {
      _activeAssignmentStart = {
        ..._activeAssignmentStart!,
        'allowImport': true,
      };
    }
    await _transport.broadcast(
      LanSyncMessage.assignmentAllowImport(runId: runId),
    );
  }

  Future<void> returnAssignmentCorrection({
    required String runId,
    required String targetDeviceId,
    required String correctionText,
  }) async {
    if (role != LanSyncRole.host || !classroomMode) return;
    await _transport.broadcast(
      LanSyncMessage.assignmentReturn(
        runId: runId,
        targetDeviceId: targetDeviceId,
        correctionText: correctionText,
      ),
    );
  }

  Future<void> sendAssignmentProgress({
    required String runId,
    required int percent,
    required List<String> doneTaskIds,
  }) async {
    if (role != LanSyncRole.guest || !isActive) return;
    await _transport.broadcast(
      LanSyncMessage.assignmentProgress(
        deviceId: _deviceId,
        deviceName: deviceName,
        runId: runId,
        percent: percent,
        doneTaskIds: doneTaskIds,
      ),
    );
  }

  Future<void> sendAssignmentSubmit(Map<String, dynamic> payload) async {
    if (role != LanSyncRole.guest || !isActive) return;
    await _transport.broadcast(LanSyncMessage.assignmentSubmit(payload));
  }

  Future<void> sendAssignmentLeave(String runId, String kind) async {
    if (role != LanSyncRole.guest || !isActive) return;
    await _transport.broadcast(
      LanSyncMessage.assignmentLeave(
        deviceId: _deviceId,
        deviceName: deviceName,
        runId: runId,
        kind: kind,
      ),
    );
  }

  void _emitAssignment(String type, Map<String, dynamic> payload) {
    lastAssignmentEvent = LanAssignmentEvent(type: type, payload: payload);
    assignmentEventSeq++;
    _emit(LanSyncEvent(kind: LanSyncEventKind.assignment, message: type));
    notifyListeners();
  }

  Future<void> shareFlashcardsToClass({
    required FlashcardDeck deck,
    required List<Flashcard> cards,
  }) async {
    if (role != LanSyncRole.host || !canBroadcast) return;
    await _transport.broadcast(
      LanSyncMessage.libraryShare(
        kind: 'flashcards',
        title: deck.title,
        payload: {
          'deck': deck.toJson(),
          'cards': [for (final card in cards) card.toJson()],
        },
      ),
    );
  }

  Future<void> noteLocalNotebookSaved(Notebook notebook) async {
    if (_applyingRemote || !canBroadcast) return;
    if (notebook.id != notebookId) return;
    final op = SyncOp(
      id: const Uuid().v4(),
      entityType: 'notebook',
      entityId: notebook.id,
      payloadJson: jsonEncode(notebook.toJson()),
      createdAt: DateTime.now(),
    );
    await _transport.broadcast(
      LanSyncMessage.op(syncOp: op, originDeviceId: _deviceId),
    );
  }

  Future<void> noteLocalPageDeleted({
    required String pageId,
    required String notebookId,
  }) async {
    if (_applyingRemote || !canBroadcast) return;
    if (notebookId != this.notebookId) return;
    final op = SyncOp(
      id: const Uuid().v4(),
      entityType: 'delete_page',
      entityId: pageId,
      payloadJson: jsonEncode({
        'id': pageId,
        'notebookId': notebookId,
      }),
      createdAt: DateTime.now(),
    );
    await _transport.broadcast(
      LanSyncMessage.op(syncOp: op, originDeviceId: _deviceId),
    );
  }

  Future<void> _onMessage(Map<String, dynamic> message) async {
    _messageQueue = _messageQueue
        .then((_) => _handleMessage(message))
        .catchError((Object e) {
          errorMessage = '$e';
          _emit(
            LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage),
          );
        });
    await _messageQueue;
  }

  Future<void> _handleMessage(Map<String, dynamic> message) async {
    if (_disposed) return;
    final peer = message.remove('_peer');
    final type = message['type']?.toString();
    switch (type) {
      case 'hello':
        await _handleHello(message, peer is LanPeerConnection ? peer : null);
      case 'welcome':
        await _handleWelcome(message);
      case 'reject':
        phase = LanSyncPhase.error;
        errorMessage = message['reason']?.toString() ?? 'rejected';
        _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
      case 'snapshot':
        await _handleSnapshot(message);
      case 'library_share':
        await _handleLibraryShare(message);
      case 'asset_meta':
        _handleAssetMeta(message);
      case 'asset_chunk':
        await _handleAssetChunk(message);
      case 'assets_done':
        await _finishPendingSnapshotIfReady();
      case 'op':
        await _handleOp(
          message,
          peer is LanPeerConnection ? peer : null,
        );
      case 'classroom_signal':
        _handleClassroomSignal(message);
      case 'classroom_command':
        _handleClassroomCommand(message);
      case 'assignment_start':
      case 'assignment_progress':
      case 'assignment_extend':
      case 'assignment_collect':
      case 'assignment_allow_import':
      case 'assignment_submit':
      case 'assignment_leave':
      case 'assignment_return':
        _handleAssignmentMessage(type!, message);
      case 'ping':
        if (peer is LanPeerConnection) {
          await _transport.sendTo(peer, LanSyncMessage.pong());
        }
      default:
        break;
    }
  }

  Future<void> _handleHello(
    Map<String, dynamic> message,
    LanPeerConnection? peer,
  ) async {
    if (role != LanSyncRole.host || peer == null || notebookId == null) return;
    final code = '${message['code'] ?? ''}'.toUpperCase();
    if (code != sessionCode) {
      await _transport.sendTo(peer, LanSyncMessage.reject('invalid_code'));
      await _transport.disconnectPeer(peer);
      return;
    }
    if (classroomMode && message['autoReconnect'] == true) {
      final expectedSubject = message['expectedSubject']?.toString().trim();
      final expectedRoom = message['expectedRoom']?.toString().trim();
      final subjectMatches =
          expectedSubject != null &&
          expectedSubject.isNotEmpty &&
          classroomSubject != null &&
          classroomSubject!.isNotEmpty &&
          expectedSubject.toLowerCase() == classroomSubject!.toLowerCase();
      final roomMatches =
          expectedRoom != null &&
          expectedRoom.isNotEmpty &&
          classroomRoom != null &&
          classroomRoom!.isNotEmpty &&
          expectedRoom.toLowerCase() == classroomRoom!.toLowerCase();
      if (!subjectMatches && !roomMatches) {
        await _transport.sendTo(
          peer,
          LanSyncMessage.reject('classroom_mismatch'),
        );
        await _transport.disconnectPeer(peer);
        return;
      }
    }
    peer.remoteDeviceId = message['deviceId']?.toString();
    peer.remoteName = message['deviceName']?.toString() ?? 'Peer';
    peerName = peer.remoteName;
    peerCount = _transport.peers.length;
    if (classroomMode && peer.remoteDeviceId != null) {
      _peerWritePermissions.putIfAbsent(peer.remoteDeviceId!, () => false);
    }
    notifyListeners();

    await _transport.sendTo(
      peer,
      LanSyncMessage.welcome(
        deviceId: _deviceId,
        deviceName: deviceName,
        notebookId: notebookId!,
        classroomMode: classroomMode,
        classroomSubject: classroomSubject,
        classroomRoom: classroomRoom,
      ),
    );

    final notebook = await _repository.getNotebook(notebookId!);
    if (notebook == null) {
      await _transport.sendTo(peer, LanSyncMessage.reject('missing_notebook'));
      return;
    }
    final pages = await _repository.getPages(notebookId!);
    final outline = await _repository.getOutline(notebookId!);
    final packed = await packPageAssets(pages);
    await _transport.sendTo(
      peer,
      LanSyncMessage.snapshot(
        notebook: notebook.toJson(),
        pages: packed.pagesJson,
        outline: [for (final n in outline) n.toJson()],
        assetCount: packed.assets.length,
      ),
    );
    await _sendAssets(peer, packed.assets);
    phase = LanSyncPhase.connected;
    _emit(LanSyncEvent(
      kind: LanSyncEventKind.peerJoined,
      notebookId: notebookId,
      message: peer.remoteName,
    ));
    if (classroomMode && peer.remoteDeviceId != null) {
      lastClassroomSignal = LanClassroomSignal(
        deviceId: peer.remoteDeviceId!,
        deviceName: peer.remoteName,
        kind: 'joined',
      );
      classroomSignalSeq++;
      _emit(
        LanSyncEvent(
          kind: LanSyncEventKind.classroomSignal,
          message: peer.remoteDeviceId,
        ),
      );
      await _transport.sendTo(
        peer,
        LanSyncMessage.classroomCommand(
          targetDeviceId: peer.remoteDeviceId!,
          canWrite: false,
          muted: false,
          focusCheckEnabled: classroomFocusCheckEnabled,
        ),
      );
      if (_activeAssignmentStart != null) {
        await _transport.sendTo(
          peer,
          LanSyncMessage.assignmentStart(_activeAssignmentStart!),
        );
      }
    }
  }

  Future<void> _handleWelcome(Map<String, dynamic> message) async {
    notebookId = message['notebookId']?.toString();
    peerName = message['deviceName']?.toString();
    peerCount = 1;
    classroomMode = message['classroomMode'] as bool? ?? false;
    classroomSubject = message['classroomSubject']?.toString();
    classroomRoom = message['classroomRoom']?.toString();
    phase = LanSyncPhase.syncing;
    notifyListeners();
  }

  Future<void> _handleSnapshot(Map<String, dynamic> message) async {
    _pendingLibraryImport = message['mode']?.toString() == 'library';
    _pendingNotebook = Map<String, dynamic>.from(message['notebook'] as Map);
    _pendingPages = (message['pages'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _pendingOutline = (message['outline'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _pendingAssetCount = (message['assetCount'] as num?)?.toInt() ?? 0;
    _incomingAssets.clear();
    _assetKeyToPath.clear();
    if (_pendingAssetCount == 0) {
      await _commitPendingSnapshot();
    }
  }

  void _handleAssetMeta(Map<String, dynamic> message) {
    final key = message['key']?.toString();
    if (key == null) return;
    _incomingAssets[key] = _IncomingAsset(
      fileName: message['fileName']?.toString() ?? '$key.bin',
      size: (message['size'] as num?)?.toInt() ?? 0,
      totalChunks: (message['totalChunks'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> _handleAssetChunk(Map<String, dynamic> message) async {
    final key = message['key']?.toString();
    final index = (message['index'] as num?)?.toInt();
    final data = message['data']?.toString();
    if (key == null || index == null || data == null) return;
    final asset = _incomingAssets[key];
    if (asset == null) return;
    asset.chunks[index] = base64Decode(data);
    if (!asset.isComplete) return;

    final notebookId = _pendingLibraryImport
        ? (_pendingNotebook?['id']?.toString() ??
              this.notebookId ??
              'unknown')
        : (this.notebookId ??
              _pendingNotebook?['id']?.toString() ??
              'unknown');
    final path = await writeNearbyAsset(
      repository: _repository,
      notebookId: notebookId,
      key: key,
      fileName: asset.fileName,
      bytes: asset.assemble(),
    );
    _assetKeyToPath[key] = path;
    _incomingAssets.remove(key);
    await _finishPendingSnapshotIfReady();
  }

  Future<void> _finishPendingSnapshotIfReady() async {
    if (_pendingNotebook == null) return;
    if (_pendingAssetCount > 0 &&
        _assetKeyToPath.length < _pendingAssetCount) {
      return;
    }
    await _commitPendingSnapshot();
  }

  Future<void> _commitPendingSnapshot() async {
    final notebookJson = _pendingNotebook;
    final pagesJson = _pendingPages;
    final outlineJson = _pendingOutline;
    if (notebookJson == null || pagesJson == null || outlineJson == null) {
      return;
    }
    _pendingNotebook = null;
    _pendingPages = null;
    _pendingOutline = null;
    final importCopy = _pendingLibraryImport;
    _pendingLibraryImport = false;

    _applyingRemote = true;
    try {
      final notebook = Notebook.fromJson(notebookJson);
      if (!importCopy) {
        notebookId = notebook.id;
      }
      await _repository.upsertRemoteNotebook(notebook);
      for (final pageJson in pagesJson) {
        final remapped = remapPageAssetPaths(pageJson, _assetKeyToPath);
        final remote = NotePage.fromJson(remapped);
        final local = await _repository.getPage(remote.id);
        if (local == null) {
          await _repository.upsertRemotePage(remote);
          continue;
        }
        final remoteUpdated = remote.updatedAt ?? notebook.updatedAt;
        final localUpdated =
            local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final merged = NotePage.fromJson(
          SyncMerge.mergeCrdtMaps(
            local.toJson(),
            remote.toJson(),
            localUpdated: localUpdated,
            remoteUpdated: remoteUpdated,
          ),
        );
        await _repository.upsertRemotePage(merged);
      }
      final outline = [
        for (final n in outlineJson) OutlineNode.fromJson(n),
      ];
      await _repository.saveOutline(notebook.id, outline);
      if (importCopy) {
        _emit(
          LanSyncEvent(
            kind: LanSyncEventKind.notebookUpdated,
            notebookId: notebook.id,
            message: 'shared',
          ),
        );
      } else {
        phase = LanSyncPhase.connected;
        await stopBrowsing();
        _emit(
          LanSyncEvent(
            kind: LanSyncEventKind.snapshotApplied,
            notebookId: notebook.id,
          ),
        );
      }
    } catch (e) {
      phase = LanSyncPhase.error;
      errorMessage = '$e';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    } finally {
      _applyingRemote = false;
    }
  }

  Future<void> _handleOp(
    Map<String, dynamic> message,
    LanPeerConnection? peer,
  ) async {
    final origin = message['originDeviceId']?.toString();
    if (origin == _deviceId) return;
    if (role == LanSyncRole.host &&
        classroomMode &&
        peer?.remoteDeviceId != null &&
        _peerWritePermissions[peer!.remoteDeviceId] != true) {
      return;
    }
    final opJson = Map<String, dynamic>.from(message['op'] as Map);
    final op = SyncOp.fromJson(opJson);
    _applyingRemote = true;
    try {
      switch (op.entityType) {
        case 'page':
          final raw = Map<String, dynamic>.from(
            jsonDecode(op.payloadJson) as Map,
          );
          final remapped = remapPageAssetPaths(raw, _assetKeyToPath);
          final remote = NotePage.fromJson(remapped);
          final local = await _repository.getPage(remote.id);
          if (local == null) {
            await _repository.upsertRemotePage(remote);
          } else {
            final remoteUpdated = remote.updatedAt ?? DateTime.now();
            final localUpdated =
                local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final merged = NotePage.fromJson(
              SyncMerge.mergeCrdtMaps(
                local.toJson(),
                remote.toJson(),
                localUpdated: localUpdated,
                remoteUpdated: remoteUpdated,
              ),
            );
            await _repository.upsertRemotePage(merged);
          }
          _emit(LanSyncEvent(
            kind: LanSyncEventKind.pageUpdated,
            notebookId: remote.notebookId,
            pageId: remote.id,
          ));
        case 'notebook':
          final remote = Notebook.fromJson(
            Map<String, dynamic>.from(jsonDecode(op.payloadJson) as Map),
          );
          await _repository.upsertRemoteNotebook(remote);
          _emit(LanSyncEvent(
            kind: LanSyncEventKind.notebookUpdated,
            notebookId: remote.id,
          ));
        case 'delete_page':
          final payload = Map<String, dynamic>.from(
            jsonDecode(op.payloadJson) as Map,
          );
          final pageId = payload['id']?.toString() ?? op.entityId;
          await _repository.deletePage(pageId);
          _emit(LanSyncEvent(
            kind: LanSyncEventKind.pageUpdated,
            notebookId: payload['notebookId']?.toString() ?? notebookId,
            pageId: pageId,
          ));
        default:
          break;
      }
      if (role == LanSyncRole.host && classroomMode) {
        await _transport.broadcast(message);
      }
    } catch (e) {
      errorMessage = '$e';
      _emit(LanSyncEvent(kind: LanSyncEventKind.error, message: errorMessage));
    } finally {
      _applyingRemote = false;
    }
  }

  Future<void> _handleLibraryShare(Map<String, dynamic> message) async {
    if (role != LanSyncRole.guest) return;
    final kind = message['kind']?.toString();
    final payload = Map<String, dynamic>.from(message['payload'] as Map? ?? {});
    if (kind == 'flashcards') {
      final deckJson = Map<String, dynamic>.from(payload['deck'] as Map);
      final deck = FlashcardDeck.fromJson(deckJson);
      await _repository.updateFlashcardDeck(deck);
      for (final item in payload['cards'] as List? ?? const []) {
        await _repository.saveFlashcard(
          Flashcard.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      }
      _emit(
        LanSyncEvent(
          kind: LanSyncEventKind.notebookUpdated,
          message: 'shared',
        ),
      );
    }
  }

  void _handleClassroomSignal(Map<String, dynamic> message) {
    if (role != LanSyncRole.host || !classroomMode) return;
    lastClassroomSignal = LanClassroomSignal(
      deviceId: message['deviceId']?.toString() ?? '',
      deviceName: message['deviceName']?.toString() ?? 'Teilnehmer',
      kind: message['kind']?.toString() ?? 'status',
      value: message['value'],
    );
    classroomSignalSeq++;
    _emit(
      LanSyncEvent(
        kind: LanSyncEventKind.classroomSignal,
        message: lastClassroomSignal!.deviceId,
      ),
    );
  }

  void _handleAssignmentMessage(String type, Map<String, dynamic> message) {
    final hostOnly = type == 'assignment_progress' ||
        type == 'assignment_submit' ||
        type == 'assignment_leave';
    final guestOnly = type == 'assignment_start' ||
        type == 'assignment_extend' ||
        type == 'assignment_collect' ||
        type == 'assignment_allow_import' ||
        type == 'assignment_return';
    if (hostOnly && (role != LanSyncRole.host || !classroomMode)) return;
    if (guestOnly && role != LanSyncRole.guest) return;
    if (type == 'assignment_return') {
      final target = message['targetDeviceId']?.toString();
      if (target != null && target != '*' && target != _deviceId) return;
    }
    _emitAssignment(type, message);
    if (role == LanSyncRole.host && classroomMode && hostOnly) {
      unawaited(_transport.broadcast(message));
    }
  }

  void _handleClassroomCommand(Map<String, dynamic> message) {
    if (role != LanSyncRole.guest) return;
    final target = message['targetDeviceId']?.toString();
    if (target != '*' && target != _deviceId) return;
    if (message['canWrite'] is bool) {
      classroomCanWrite = message['canWrite'] as bool;
    }
    if (message['muted'] is bool) {
      classroomMuted = message['muted'] as bool;
    }
    if (message['focusCheckEnabled'] is bool) {
      classroomFocusCheckEnabled = message['focusCheckEnabled'] as bool;
    }
    if (message['materialUrl'] is String) {
      classroomMaterialUrl = message['materialUrl'] as String;
      classroomMaterialTitle =
          message['materialTitle']?.toString() ?? 'Material';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _hostsSub?.cancel();
    _discovery.dispose();
    _transport.stop();
    super.dispose();
  }
}

final lanSyncProvider = ChangeNotifierProvider<LanSyncController>((ref) {
  final controller = LanSyncController(ref.watch(notebookRepositoryProvider));
  final transport = ref.read(transportManagerProvider);
  void syncRoute() {
    transport.setP2pActive(
      controller.phase == LanSyncPhase.connected ||
          controller.phase == LanSyncPhase.hosting ||
          controller.phase == LanSyncPhase.syncing,
    );
  }

  controller.addListener(syncRoute);
  ref.onDispose(() {
    controller.removeListener(syncRoute);
    controller.dispose();
  });
  return controller;
});
