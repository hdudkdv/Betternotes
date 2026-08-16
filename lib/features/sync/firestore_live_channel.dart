import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'crdt_delta.dart';
import 'live_channel.dart';

/// Broadcasts CRDT deltas through one mergeable Firestore document per notebook.
///
/// Writes happen only when [hasRemotePeer] is true so a single device does not
/// pay for live traffic. Presence docs are tiny heartbeats.
class FirestoreLiveChannel implements LiveChannel {
  FirestoreLiveChannel({
    required this.uid,
    required this.deviceId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final String deviceId;
  final FirebaseFirestore _firestore;
  final _seen = <String>{};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _watchSub;
  StreamController<CrdtDelta>? _controller;

  DocumentReference<Map<String, dynamic>> get _user =>
      _firestore.collection('users').doc(uid);

  @override
  Future<void> heartbeat({required String notebookId}) {
    return _user.collection('presence').doc(deviceId).set({
      'notebookId': notebookId,
      'lastSeen': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> hasRemotePeer() async {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 45));
    final snap = await _user.collection('presence').get();
    for (final doc in snap.docs) {
      if (doc.id == deviceId) continue;
      final last = DateTime.tryParse(doc.data()['lastSeen']?.toString() ?? '');
      if (last != null && last.isAfter(cutoff)) return true;
    }
    return false;
  }

  @override
  Future<void> publish(CrdtDelta delta) async {
    if (!await hasRemotePeer()) return;
    await _user.collection('live').doc(delta.notebookId).set({
      'deltas': {delta.id: delta.toJson()},
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<CrdtDelta> watch(String notebookId) {
    _controller?.close();
    final controller = StreamController<CrdtDelta>.broadcast();
    _controller = controller;
    _watchSub?.cancel();
    _watchSub = _user.collection('live').doc(notebookId).snapshots().listen((
      snapshot,
    ) {
      final deltas = snapshot.data()?['deltas'];
      if (deltas is! Map) return;
      for (final entry in deltas.entries) {
        final id = entry.key.toString();
        if (!_seen.add(id)) continue;
        if (entry.value is! Map) continue;
        final delta = CrdtDelta.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (delta.deviceId == deviceId) continue;
        controller.add(delta);
      }
    });
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _watchSub?.cancel();
    await _controller?.close();
    _watchSub = null;
    _controller = null;
  }
}
