import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../data/repositories/notebook_repository.dart';

class NearbySharePeer {
  const NearbySharePeer({
    required this.deviceId,
    required this.name,
    required this.grantedAt,
  });

  final String deviceId;
  final String name;
  final DateTime grantedAt;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'grantedAt': grantedAt.toIso8601String(),
  };

  factory NearbySharePeer.fromJson(Map<String, dynamic> json) {
    return NearbySharePeer(
      deviceId: json['deviceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      grantedAt:
          DateTime.tryParse(json['grantedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Host-side durable share for a notebook.
class NearbyHostedShare {
  const NearbyHostedShare({
    required this.shareId,
    required this.notebookId,
    required this.displayName,
    required this.accessCode,
    this.autoHost = true,
    this.granted = const [],
    this.revoked = const [],
  });

  final String shareId;
  final String notebookId;

  /// Name guests see in discovery. Not necessarily the notebook title.
  final String displayName;
  final String accessCode;
  final bool autoHost;
  final List<NearbySharePeer> granted;
  final List<String> revoked;

  NearbyHostedShare copyWith({
    String? displayName,
    String? accessCode,
    bool? autoHost,
    List<NearbySharePeer>? granted,
    List<String>? revoked,
  }) {
    return NearbyHostedShare(
      shareId: shareId,
      notebookId: notebookId,
      displayName: displayName ?? this.displayName,
      accessCode: accessCode ?? this.accessCode,
      autoHost: autoHost ?? this.autoHost,
      granted: granted ?? this.granted,
      revoked: revoked ?? this.revoked,
    );
  }

  bool isGranted(String deviceId) {
    final id = deviceId.trim();
    if (id.isEmpty) return false;
    if (revoked.contains(id)) return false;
    return granted.any((peer) => peer.deviceId == id);
  }

  bool isRevoked(String deviceId) => revoked.contains(deviceId.trim());

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'notebookId': notebookId,
    'displayName': displayName,
    'accessCode': accessCode,
    'autoHost': autoHost,
    'granted': [for (final peer in granted) peer.toJson()],
    'revoked': revoked,
  };

  factory NearbyHostedShare.fromJson(Map<String, dynamic> json) {
    return NearbyHostedShare(
      shareId: json['shareId']?.toString() ?? '',
      notebookId: json['notebookId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      accessCode: (json['accessCode']?.toString() ?? '').toUpperCase(),
      autoHost: json['autoHost'] as bool? ?? true,
      granted: [
        for (final item in (json['granted'] as List? ?? const []))
          if (item is Map)
            NearbySharePeer.fromJson(Map<String, dynamic>.from(item)),
      ],
      revoked: [
        for (final item in (json['revoked'] as List? ?? const []))
          item.toString(),
      ],
    );
  }
}

/// Guest-side remembered access after the code was accepted once.
class NearbyGuestGrant {
  const NearbyGuestGrant({
    required this.shareId,
    required this.notebookId,
    required this.displayName,
    required this.hostDeviceId,
    this.hostName = '',
  });

  final String shareId;
  final String notebookId;
  final String displayName;
  final String hostDeviceId;

  /// Person / device name of the host, shown in the Live folder.
  final String hostName;

  String get hostLabel {
    final person = hostName.trim();
    if (person.isNotEmpty) return person;
    return displayName.trim();
  }

  Map<String, dynamic> toJson() => {
    'shareId': shareId,
    'notebookId': notebookId,
    'displayName': displayName,
    'hostDeviceId': hostDeviceId,
    'hostName': hostName,
  };

  factory NearbyGuestGrant.fromJson(Map<String, dynamic> json) {
    return NearbyGuestGrant(
      shareId: json['shareId']?.toString() ?? '',
      notebookId: json['notebookId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      hostDeviceId: json['hostDeviceId']?.toString() ?? '',
      hostName: json['hostName']?.toString() ?? '',
    );
  }
}

enum NearbyHelloDecision { allowGranted, allowCode, rejectRevoked, rejectInvalid }

NearbyHelloDecision decideNearbyHello({
  required String deviceId,
  required String code,
  required NearbyHostedShare share,
  String? sessionCode,
  bool classroomMode = false,
}) {
  final id = deviceId.trim();
  if (id.isEmpty) return NearbyHelloDecision.rejectInvalid;
  if (share.isRevoked(id)) return NearbyHelloDecision.rejectRevoked;
  if (share.isGranted(id)) return NearbyHelloDecision.allowGranted;
  final typed = code.trim().toUpperCase();
  if (typed.isNotEmpty && typed == share.accessCode) {
    return NearbyHelloDecision.allowCode;
  }
  if (classroomMode) {
    final session = sessionCode?.trim().toUpperCase() ?? '';
    if (typed.isNotEmpty && typed == session) {
      return NearbyHelloDecision.allowCode;
    }
  }
  return NearbyHelloDecision.rejectInvalid;
}

String generateNearbyAccessCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random.secure();
  return List.generate(6, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
}

class NearbyShareStore {
  NearbyShareStore(this._repository);

  final NotebookRepository _repository;

  static const _hostedKey = 'nearby_hosted_shares_v1';
  static const _grantsKey = 'nearby_guest_grants_v1';

  Future<List<NearbyHostedShare>> hostedShares() async {
    final raw = await _repository.readKv(_hostedKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        if (item is Map)
          NearbyHostedShare.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<NearbyHostedShare?> hostedForNotebook(String notebookId) async {
    final all = await hostedShares();
    for (final share in all) {
      if (share.notebookId == notebookId) return share;
    }
    return null;
  }

  Future<NearbyHostedShare?> hostedForShareId(String shareId) async {
    final all = await hostedShares();
    for (final share in all) {
      if (share.shareId == shareId) return share;
    }
    return null;
  }

  Future<NearbyHostedShare> ensureHosted({
    required String notebookId,
    required String displayName,
  }) async {
    final existing = await hostedForNotebook(notebookId);
    final name = displayName.trim();
    if (existing != null) {
      if (name.isEmpty || existing.displayName == name) return existing;
      final updated = existing.copyWith(displayName: name);
      await saveHosted(updated);
      return updated;
    }
    final created = NearbyHostedShare(
      shareId: const Uuid().v4(),
      notebookId: notebookId,
      displayName: name.isEmpty ? 'Notis' : name,
      accessCode: generateNearbyAccessCode(),
    );
    await saveHosted(created);
    return created;
  }

  Future<void> saveHosted(NearbyHostedShare share) async {
    final all = await hostedShares();
    final next = [
      for (final item in all)
        if (item.notebookId != share.notebookId) item,
      share,
    ];
    await _repository.writeKv(
      _hostedKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }

  Future<NearbyHostedShare> grantPeer(
    NearbyHostedShare share,
    NearbySharePeer peer,
  ) async {
    final granted = [
      for (final item in share.granted)
        if (item.deviceId != peer.deviceId) item,
      peer,
    ];
    final revoked = [
      for (final id in share.revoked)
        if (id != peer.deviceId) id,
    ];
    final updated = share.copyWith(granted: granted, revoked: revoked);
    await saveHosted(updated);
    return updated;
  }

  Future<NearbyHostedShare> revokePeer(
    NearbyHostedShare share,
    String deviceId,
  ) async {
    final id = deviceId.trim();
    final granted = [
      for (final item in share.granted)
        if (item.deviceId != id) item,
    ];
    final revoked = {
      ...share.revoked,
      if (id.isNotEmpty) id,
    }.toList();
    final updated = share.copyWith(granted: granted, revoked: revoked);
    await saveHosted(updated);
    return updated;
  }

  Future<List<NearbyGuestGrant>> guestGrants() async {
    final raw = await _repository.readKv(_grantsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return [
      for (final item in list)
        if (item is Map)
          NearbyGuestGrant.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<NearbyGuestGrant?> grantForNotebook(String notebookId) async {
    final all = await guestGrants();
    for (final grant in all) {
      if (grant.notebookId == notebookId) return grant;
    }
    return null;
  }

  Future<NearbyGuestGrant?> grantForShare(String shareId) async {
    if (shareId.isEmpty) return null;
    final all = await guestGrants();
    for (final grant in all) {
      if (grant.shareId == shareId) return grant;
    }
    return null;
  }

  Future<void> saveGuestGrant(NearbyGuestGrant grant) async {
    final all = await guestGrants();
    final next = [
      for (final item in all)
        if (item.shareId != grant.shareId && item.notebookId != grant.notebookId)
          item,
      grant,
    ];
    await _repository.writeKv(
      _grantsKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }

  Future<void> removeGuestGrant({String? shareId, String? notebookId}) async {
    final all = await guestGrants();
    final next = [
      for (final item in all)
        if (item.shareId != shareId && item.notebookId != notebookId) item,
    ];
    await _repository.writeKv(
      _grantsKey,
      jsonEncode([for (final item in next) item.toJson()]),
    );
  }
}
