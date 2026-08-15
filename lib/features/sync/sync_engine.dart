import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/content_models.dart';
import '../../data/repositories/notebook_repository.dart';
import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';
import 'firebase_bootstrap.dart';
import 'firestore_sync_adapter.dart';
import 'crdt_delta.dart';
import 'sync_merge.dart';
import 'transport_manager.dart';

enum SyncStatus {
  idle,
  upToDate,
  syncing,
  synced,
  firebaseNotConfigured,
  authenticationRequired,
  preparingCloud,
  paused,
}

/// Offline-first sync engine with local queue and CRDT-oriented merge stubs.
class SyncEngine extends ChangeNotifier {
  SyncEngine(
    this._repo,
    this._preferences,
    this._firebaseAvailable, {
    TransportManager? transport,
  }) : _transport = transport {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => flush());
  }

  final NotebookRepository _repo;
  final SharedPreferences _preferences;
  final bool _firebaseAvailable;
  final TransportManager? _transport;
  Timer? _timer;
  FirestoreSyncAdapter? _adapter;
  bool syncing = false;
  SyncStatus syncStatus = SyncStatus.idle;
  String? errorMessage;
  int pending = 0;
  DateTime? lastSyncAt;

  Future<void> _refresh() async {
    pending = await _repo.pendingSyncCount();
    notifyListeners();
  }

  /// Delegates to [SyncMerge.mergeCrdtMaps] for tests and call sites.
  static Map<String, dynamic> mergeCrdtMaps(
    Map<String, dynamic> local,
    Map<String, dynamic> remote, {
    required DateTime localUpdated,
    required DateTime remoteUpdated,
  }) => SyncMerge.mergeCrdtMaps(
    local,
    remote,
    localUpdated: localUpdated,
    remoteUpdated: remoteUpdated,
  );

  Future<void> flush() async {
    if (syncing) return;
    final route = _transport?.routeAfterLocalPersist();
    if (route == TransportRoute.p2p && _transport?.cloudPremium != true) {
      // Live P2P already carries deltas; park cloud until premium + no P2P.
      syncStatus = SyncStatus.upToDate;
      await _refresh();
      return;
    }
    if (!_firebaseAvailable) {
      syncStatus = SyncStatus.firebaseNotConfigured;
      await _refresh();
      return;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      syncStatus = SyncStatus.authenticationRequired;
      await _refresh();
      return;
    }
    final ops = await _repo.getPendingSyncOps();
    if (ops.isEmpty) {
      syncStatus = SyncStatus.upToDate;
      pending = 0;
      notifyListeners();
      return;
    }

    syncing = true;
    syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final adapter = _adapter ??= FirestoreSyncAdapter(
        _repo,
        preferences: _preferences,
      );
      await adapter.ensureProfile();
      for (final op in ops) {
        jsonDecode(op.payloadJson);
        await adapter.push(op);
        await _repo.markSyncOpSynced(op.id);
      }
      await adapter.pullRemoteChanges();
      await adapter.syncAppState();
      await _repo.pruneSyncedOps();
      lastSyncAt = DateTime.now();
      syncStatus = SyncStatus.synced;
      errorMessage = null;
    } catch (e) {
      syncStatus = SyncStatus.paused;
      errorMessage = '$e';
    } finally {
      syncing = false;
      pending = await _repo.pendingSyncCount();
      notifyListeners();
    }
  }

  /// Imports the cloud state and uploads the one-time local migration after
  /// a successful Google/Apple sign-in.
  Future<void> bootstrapCloud() async {
    if (!_firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }
    if (syncing) return;
    syncing = true;
    syncStatus = SyncStatus.preparingCloud;
    notifyListeners();
    try {
      final adapter = _adapter ??= FirestoreSyncAdapter(
        _repo,
        preferences: _preferences,
      );
      await adapter.ensureProfile();
      await adapter.pullRemoteChanges();
      await adapter.syncAppState();
      await adapter.pushLocalSnapshot();
      final ops = await _repo.getPendingSyncOps();
      for (final op in ops) {
        await adapter.push(op);
        await _repo.markSyncOpSynced(op.id);
      }
      await _repo.pruneSyncedOps();
      lastSyncAt = DateTime.now();
      syncStatus = SyncStatus.synced;
      errorMessage = null;
    } catch (error) {
      syncStatus = SyncStatus.paused;
      errorMessage = '$error';
    } finally {
      syncing = false;
      await _refresh();
    }
  }

  Future<void> enqueueDelta(CrdtDelta delta) async {
    await _repo.enqueueSyncOp(
      SyncOp(
        id: delta.id,
        entityType: 'crdt',
        entityId: delta.notebookId,
        payloadJson: jsonEncode(delta.toJson()),
        createdAt: delta.createdAt,
      ),
    );
    await _refresh();
    await flush();
  }

  Future<void> enqueueManualCheckpoint(String notebookId) async {
    await _repo.enqueueSyncOp(
      SyncOp(
        id: const Uuid().v4(),
        entityType: 'checkpoint',
        entityId: notebookId,
        payloadJson: jsonEncode({
          'notebookId': notebookId,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
        createdAt: DateTime.now(),
      ),
    );
    await _refresh();
    await flush();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final syncEngineProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final transport = ref.read(transportManagerProvider);
  final entitlements = ref.read(entitlementProvider);
  final firebase = ref.watch(firebaseBootstrapProvider).available;
  transport.setCloud(
    premium: entitlements.hasAccess(FeatureKeys.cloudSync),
    reachable: firebase && FirebaseAuth.instance.currentUser != null,
  );
  return SyncEngine(
    ref.watch(notebookRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
    firebase,
    transport: transport,
  );
});
