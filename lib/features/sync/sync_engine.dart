import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/content_models.dart';
import '../../data/models/notebook.dart';
import '../../data/repositories/notebook_repository.dart';
import '../auth/auth_repository.dart';
import '../entitlements/entitlement_model.dart';
import '../library/providers/library_providers.dart';
import 'crdt_apply.dart';
import 'crdt_delta.dart';
import 'firebase_bootstrap.dart';
import 'firestore_live_channel.dart';
import 'firestore_sync_adapter.dart';
import 'live_channel.dart';
import 'cloud_sync_selection.dart';
import 'sync_merge.dart';
import 'transport_manager.dart';
import 'vector_clock.dart';

enum SyncStatus {
  idle,
  upToDate,
  syncing,
  synced,
  firebaseNotConfigured,
  authenticationRequired,
  preparingCloud,
  paused,
  cloudNotEntitled,
}

/// Offline-first sync engine with local queue and CRDT-oriented merge stubs.
class SyncEngine extends ChangeNotifier with WidgetsBindingObserver {
  SyncEngine(
    this._repo,
    this._preferences,
    this._firebaseAvailable, {
    TransportManager? transport,
    this.cloudPaid = PaidTier.free,
    this.cloudSelectedIds = const {},
  }) : _transport = transport {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
  }

  final NotebookRepository _repo;
  final SharedPreferences _preferences;
  final bool _firebaseAvailable;
  final TransportManager? _transport;
  final PaidTier cloudPaid;
  final Set<String> cloudSelectedIds;
  Timer? _timer;
  FirestoreSyncAdapter? _adapter;
  LiveChannel? _live;
  StreamSubscription<CrdtDelta>? _liveSub;
  String? _watchingNotebookId;
  final _appliedDeltaIds = <String>{};
  final _remoteListeners = <String, void Function(NotePage page)>{};
  VectorClock _clock = VectorClock.empty();
  bool syncing = false;
  SyncStatus syncStatus = SyncStatus.idle;
  String? errorMessage;
  int pending = 0;
  DateTime? lastSyncAt;

  static const _idleFlush = Duration(seconds: 8);
  static const _deviceIdKey = 'syncDeviceIdV1';

  String get deviceId {
    final existing = _preferences.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    _preferences.setString(_deviceIdKey, created);
    return created;
  }

  String? _publicError(Object error) {
    if (AuthFailure.map(error).cancelled) return null;
    return 'Cloud-Sync hat nicht geklappt. Bitte nochmal versuchen.';
  }

  bool get _cloudAllowed => _transport?.cloudPremium == true;

  bool _cloudSyncsNotebook(String? notebookId) {
    if (notebookId == null || notebookId.isEmpty) {
      return cloudNotebookLimit(cloudPaid) == null;
    }
    return cloudSyncsNotebook(
      notebookId,
      paid: cloudPaid,
      selected: cloudSelectedIds,
    );
  }

  List<SyncOp> _pushableOps(List<SyncOp> ops) {
    return [
      for (final op in ops)
        if (shouldPushCloudOp(
          op,
          paid: cloudPaid,
          selected: cloudSelectedIds,
        ))
          op,
    ];
  }

  Future<void> _refresh() async {
    pending = _pushableOps(await _repo.getPendingSyncOps()).length;
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

  Future<void> _tick() async {
    if (syncing) return;
    final ops = _pushableOps(await _repo.getPendingSyncOps());
    pending = ops.length;
    if (ops.isEmpty) {
      if (syncStatus == SyncStatus.idle) notifyListeners();
      return;
    }
    final newest = ops
        .map((op) => op.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    if (DateTime.now().difference(newest) >= _idleFlush) {
      await flush();
    } else {
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(flush(force: true));
    }
  }

  Future<void> flush({bool force = false}) async {
    if (syncing) return;
    final route = _transport?.routeAfterLocalPersist();
    if (route == TransportRoute.p2p && !_cloudAllowed) {
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
    if (!_cloudAllowed) {
      syncStatus = SyncStatus.cloudNotEntitled;
      await _refresh();
      return;
    }
    final ops = _pushableOps(await _repo.getPendingSyncOps());
    if (ops.isEmpty) {
      if (!force) {
        syncStatus = SyncStatus.upToDate;
        pending = 0;
        notifyListeners();
        return;
      }
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
      errorMessage = _publicError(e);
    } finally {
      syncing = false;
      pending = _pushableOps(await _repo.getPendingSyncOps()).length;
      notifyListeners();
    }
  }

  /// Imports the cloud state after a successful Google/Apple sign-in.
  ///
  /// On web, local IndexedDB/prefs notebooks are replaced so the browser does
  /// not keep showing a stale copy. Writes still require [FeatureKeys.cloudSync].
  Future<void> bootstrapCloud({bool replaceLocal = false}) async {
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
      await adapter.syncAppState(preferRemote: replaceLocal || kIsWeb);
      final replace = replaceLocal || kIsWeb;
      if (replace) {
        await _repo.clearLocalNotebooksForCloudReload();
      }
      await adapter.pullRemoteChanges(
        full: true,
        preferRemote: replace,
      );
      if (_cloudAllowed && !kIsWeb) {
        await adapter.pushLocalSnapshot(
          allowedNotebookIds: cloudNotebookLimit(cloudPaid) == null
              ? null
              : cloudSelectedIds,
        );
        final ops = _pushableOps(await _repo.getPendingSyncOps());
        for (final op in ops) {
          await adapter.push(op);
          await _repo.markSyncOpSynced(op.id);
        }
        await _repo.pruneSyncedOps();
      } else if (_cloudAllowed) {
        final ops = _pushableOps(await _repo.getPendingSyncOps());
        for (final op in ops) {
          await adapter.push(op);
          await _repo.markSyncOpSynced(op.id);
        }
        await _repo.pruneSyncedOps();
      }
      lastSyncAt = DateTime.now();
      syncStatus = _cloudAllowed
          ? SyncStatus.synced
          : SyncStatus.cloudNotEntitled;
      errorMessage = null;
    } catch (error) {
      syncStatus = SyncStatus.paused;
      errorMessage = _publicError(error);
    } finally {
      syncing = false;
      await _refresh();
    }
  }

  Future<void> publishLocalEdit({
    required NotePage? previous,
    required NotePage next,
  }) async {
    if (!_cloudAllowed || !_firebaseAvailable) return;
    if (FirebaseAuth.instance.currentUser == null) return;
    if (!_cloudSyncsNotebook(next.notebookId)) return;
    final deltas = diffsBetweenPages(
      previous: previous,
      next: next,
      deviceId: deviceId,
      clock: _clock,
    );
    if (deltas.isEmpty) return;
    _clock = deltas.last.clock;
    final live = _ensureLive();
    await live.heartbeat(notebookId: next.notebookId);
    if (!await live.hasRemotePeer()) return;
    for (final delta in deltas) {
      _appliedDeltaIds.add(delta.id);
      await live.publish(delta);
    }
  }

  void watchNotebook(
    String notebookId, {
    required void Function(NotePage page) onRemotePage,
  }) {
    _remoteListeners[notebookId] = onRemotePage;
    if (_watchingNotebookId == notebookId) return;
    unawaited(_startWatch(notebookId));
  }

  void unwatchNotebook(String notebookId) {
    _remoteListeners.remove(notebookId);
    if (_watchingNotebookId == notebookId) {
      unawaited(_stopWatch());
    }
  }

  LiveChannel _ensureLive() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _live ??= FirestoreLiveChannel(uid: uid, deviceId: deviceId);
  }

  Future<void> _startWatch(String notebookId) async {
    await _stopWatch();
    if (!_cloudAllowed || FirebaseAuth.instance.currentUser == null) return;
    if (!_cloudSyncsNotebook(notebookId)) return;
    _watchingNotebookId = notebookId;
    final live = _ensureLive();
    await live.heartbeat(notebookId: notebookId);
    _liveSub = live.watch(notebookId).listen(_onRemoteDelta);
  }

  Future<void> _stopWatch() async {
    await _liveSub?.cancel();
    _liveSub = null;
    _watchingNotebookId = null;
  }

  Future<void> _onRemoteDelta(CrdtDelta delta) async {
    if (!_appliedDeltaIds.add(delta.id)) return;
    _clock = _clock.merge(delta.clock);
    final pageId = delta.pageId;
    if (pageId == null) return;
    final page = await _repo.getPage(pageId);
    if (page == null) return;
    final updated = applyCrdtDelta(page, delta);
    await _repo.upsertRemotePage(updated);
    _remoteListeners[updated.notebookId]?.call(updated);
  }

  Future<void> enqueueDelta(CrdtDelta delta) async {
    _clock = _clock.merge(delta.clock).increment(deviceId);
    if (_cloudAllowed && _cloudSyncsNotebook(delta.notebookId)) {
      final live = _ensureLive();
      await live.heartbeat(notebookId: delta.notebookId);
      if (await live.hasRemotePeer()) {
        _appliedDeltaIds.add(delta.id);
        await live.publish(delta);
        return;
      }
    }
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
    await flush(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_stopWatch());
    unawaited(_live?.dispose());
    super.dispose();
  }
}

final syncEngineProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final transport = ref.watch(transportManagerProvider);
  final entitlements = ref.watch(entitlementProvider);
  final firebase = ref.watch(firebaseBootstrapProvider).available;
  final signedIn = ref.watch(authProvider).signedIn;
  transport.setCloud(
    premium: entitlements.hasAccess(FeatureKeys.cloudSync),
    reachable: firebase && signedIn,
  );
  return SyncEngine(
    ref.watch(notebookRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
    firebase,
    transport: transport,
    cloudPaid: entitlements.paidTier,
    cloudSelectedIds: ref.watch(cloudSyncSelectionProvider).ids,
  );
});
